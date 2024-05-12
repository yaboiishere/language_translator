defmodule LanguageTranslator.Translator.Aggregator do
  use GenServer
  require Logger

  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Translator.ProcessGroup
  alias LanguageTranslator.Repo
  # The state is a map that holds a ref pointing to the number of translations left to be received

  defmodule LeftToReceiveWithTranslations do
    defstruct to_receive: 0, translations: [], initial_word: "", from: nil
  end

  def start_link(source_language = %Language{code: code}) do
    name = String.to_atom("#{code}_aggregator")
    GenServer.start_link(__MODULE__, source_language, name: name)
  end

  def translate(%Language{code: code} = source_language, word) do
    name = String.to_atom("#{code}_aggregator")

    try do
      GenServer.call(name, {:translate, word})
    catch
      :exit, {:timeout, _} ->
        Logger.error("Timeout while translating #{word}, retrying...")
        translate(source_language, word)
    end
  end

  def translate(source_language, word) when is_binary(source_language) do
    Language
    |> Repo.get_by(code: source_language)
    |> translate(word)
  end

  def init(%Language{} = source_language) do
    state = %{source_language: source_language, translations: %{}}
    {:ok, state}
  end

  def handle_call(
        {:translate, word},
        from,
        %{source_language: source_language, translations: translations} = state
      ) do
    pg_members_count = ProcessGroup.count_members()

    ref = make_ref()

    case pg_members_count do
      0 ->
        {:reply, "No translators available", state}

      _ ->
        translations =
          Map.put(translations, ref, %LeftToReceiveWithTranslations{
            to_receive: pg_members_count,
            initial_word: word,
            from: from
          })

        ProcessGroup.translate(source_language, word, {self(), ref})

        {:noreply, %{state | translations: translations}}
    end
  end

  def handle_info(
        {:translated, %Language{code: code}, translated_word, ref},
        %{translations: translations_state} = state
      ) do
    case Map.fetch(translations_state, ref) do
      {:ok,
       %LeftToReceiveWithTranslations{
         to_receive: to_receive,
         translations: translations,
         from: from
       } = old_translation} ->
        new_translations = [{code, translated_word} | translations]

        if to_receive == 1 do
          GenServer.reply(from, new_translations)
          {:noreply, %{state | translations: Map.delete(translations_state, ref)}}
        else
          new_translations_state =
            Map.put(translations_state, ref, %LeftToReceiveWithTranslations{
              old_translation
              | to_receive: to_receive - 1,
                translations: new_translations
            })

          {:noreply, %{state | translations: new_translations_state}}
        end
    end
  end

  def handle_info(
        {:error, %Language{display_name: display_name, code: code}, ref} = retry_params,
        %{translations: translations} = state
      ) do
    case Map.fetch(translations, ref) do
      {:ok,
       %LeftToReceiveWithTranslations{
         to_receive: to_receive,
         translations: translations,
         from: from
       } = old_translation} ->
        Logger.error("No translator available for #{display_name} (#{code})")

        case to_receive do
          1 ->
            GenServer.reply(from, translations)
            {:noreply, %{state | translations: Map.delete(translations, ref)}}

          _ ->
            {:noreply,
             %{
               state
               | translations: %LeftToReceiveWithTranslations{
                   old_translation
                   | to_receive: to_receive - 1
                 }
             }}
        end

      _ ->
        Process.send_after(self(), retry_params, 50)
    end
  end
end
