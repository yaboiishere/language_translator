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

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def translate(%Language{} = source_language, word) do
    GenServer.call(__MODULE__, {:translate, source_language, word}, 60000)
  end

  def translate(source_language, word) when is_binary(source_language) do
    Language
    |> Repo.get_by(code: source_language)
    |> translate(word)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:translate, %Language{} = source_language, word}, from, state) do
    pg_members_count = ProcessGroup.count_members()

    ref = make_ref()

    case pg_members_count do
      0 ->
        {:reply, "No translators available", state}

      _ ->
        state =
          Map.put(state, ref, %LeftToReceiveWithTranslations{
            to_receive: pg_members_count,
            initial_word: word,
            from: from
          })

        ProcessGroup.translate(source_language, word, {self(), ref})

        {:noreply, state}
    end
  end

  def handle_info({:translated, %Language{code: code}, translated_word, ref}, state) do
    case Map.fetch(state, ref) do
      {:ok,
       %LeftToReceiveWithTranslations{
         to_receive: to_receive,
         translations: translations,
         from: from
       } = old_state} ->
        new_translations = [{code, translated_word} | translations]

        if to_receive == 1 do
          GenServer.reply(from, new_translations)
          {:noreply, Map.delete(state, ref)}
        else
          new_state =
            Map.put(state, ref, %LeftToReceiveWithTranslations{
              old_state
              | to_receive: to_receive - 1,
                translations: new_translations
            })

          {:noreply, new_state}
        end
    end
  end

  def handle_info(
        {:error, %Language{display_name: display_name, code: code}, ref} = retry_params,
        state
      ) do
    case Map.fetch(state, ref) do
      {:ok,
       %LeftToReceiveWithTranslations{
         to_receive: to_receive,
         translations: translations,
         from: from
       } = old_state} ->
        Logger.error("No translator available for #{display_name} (#{code})")

        case to_receive do
          1 ->
            GenServer.reply(from, translations)
            {:noreply, Map.delete(state, ref)}

          _ ->
            {:noreply, %LeftToReceiveWithTranslations{old_state | to_receive: to_receive - 1}}
        end

      _ ->
        Process.send_after(self(), retry_params, 50)
    end
  end
end
