defmodule LanguageTranslator.Http.Cache do
  use GenServer
  import Ecto.Query, only: [from: 2]

  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  @cleanup_interval 1000 * 60 * 60

  defstruct(size: 0, words: %{}, tick: 0)

  def start_link(%{size: size}) do
    GenServer.start_link(__MODULE__, %__MODULE__{size: size, words: %{}}, name: __MODULE__)
  end

  def fetch(word, source_language, target_language) when is_binary(word) do
    GenServer.call(__MODULE__, {:fetch, word, source_language, target_language})
  end

  def store(word, source_language, translated_word, target_language)
      when is_binary(word) and is_binary(translated_word) do
    GenServer.cast(__MODULE__, {:store, word, source_language, translated_word, target_language})
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:fetch, word, %Language{code: source_code} = source_language,
         %Language{code: target_code} = target_language},
        _from,
        %__MODULE__{words: words} = state
      ) do
    words
    |> Map.fetch({source_code, target_code, word})
    |> case do
      {:ok, translated_word} ->
        {:reply, translated_word, state}

      _ ->
        word
        |> check_db_for_word(source_language, target_language)
        |> case do
          nil ->
            {:reply, nil, state}

          db_word ->
            {:reply, db_word,
             %{
               state
               | words:
                   Map.put(
                     words,
                     {source_code, target_code, word},
                     db_word
                   )
             }}
        end
    end
  end

  @impl true
  def handle_cast(
        {:store, source_word, %Language{code: source_code}, target_word,
         %Language{code: target_code}},
        %__MODULE__{words: words} = state
      ) do
    case Map.fetch(words, {source_code, target_code, source_word}) do
      {:ok, _translated_word} ->
        {:noreply, state}

      _ ->
        {:noreply,
         %{state | words: Map.put(words, {source_code, target_code, source_word}, target_word)}}
    end
  end

  @impl true
  def handle_info(:cleanup, %__MODULE__{words: words, size: size} = state) do
    Process.send_after(self(), :cleanup, @cleanup_interval)
    words = cleanup(words, size)
    {:noreply, %{state | words: words}}
  end

  defp check_db_for_word(word, %Language{code: source_code}, %Language{code: target_code})
       when is_binary(word) do
    from(t in Translation,
      join: sw in assoc(t, :source_word),
      join: tw in assoc(t, :target_word),
      where:
        sw.text == ^word and sw.language_code == ^source_code and tw.language_code == ^target_code,
      select: tw.text
    )
    |> Repo.one()
  end

  defp cleanup(words, size) do
    if map_size(words) > size do
      Map.new(Enum.take(MapSet.to_list(words), size))
    else
      words
    end
  end
end
