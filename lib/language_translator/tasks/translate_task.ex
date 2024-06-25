defmodule LanguageTranslator.Tasks.TranslateTask do
  use Task, restart: :transient

  require Logger

  alias LanguageTranslator.Translator.AnalysisMonitor
  alias LanguageTranslator.Models
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator.Aggregator
  alias LanguageTranslator.TaskSupervisor

  def start_link(analysis) do
    Task.start_link(__MODULE__, :run, [analysis])
  end

  def run(analysis) do
    :ok = AnalysisMonitor.add_analysis(analysis)

    if Application.get_env(:language_translator, :env) == :test do
      {:ok, translate(analysis)}
    else
      Repo.transaction(fn ->
        translate(analysis)
      end)
      |> case do
        {:ok, analysis} ->
          {:ok, analysis}

        {:error, reason} ->
          Logger.error("Failed to translate analysis: #{inspect(reason)}")
          {:error, reason}
      end
    end
    |> case do
      {:ok, analysis} ->
        ProcessGroups.Analysis.update_analysis(analysis)

      {:error, reason} ->
        Logger.error("Failed to translate analysis: #{inspect(reason)}")
    end
  end

  defp translate(%Analysis{} = analysis) do
    if Application.get_env(:language_translator, :env) == :test do
      do_translate(analysis)
    else
      Repo.transaction(fn ->
        do_translate(analysis)
      end)
    end
  end

  defp do_translate(
         %Analysis{source_words: words, source_language: %Language{} = language} = analysis
       ) do
    parent = self()

    Enum.map(
      words,
      &Task.Supervisor.async({TaskSupervisor, Node.self()}, fn ->
        if Application.get_env(:language_translator, :env) == :test do
          Ecto.Adapters.SQL.Sandbox.allow(Repo, parent, self())
        end

        translate_word(&1, language)
      end)
    )
    |> Enum.flat_map(&Task.await(&1, 600_000))
    |> Enum.map(fn translation ->
      %{translation_id: translation.id, analysis_id: analysis.id}
    end)
    |> Enum.uniq()
    |> then(fn entries ->
      Repo.insert_all(AnalysisTranslation, entries,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:translation_id, :analysis_id]
      )
    end)

    {:ok, analysis} = Models.update_analysis(analysis, %{status: :completed})

    analysis
    |> Repo.preload([:source_language, :user])
  end

  defp translate_word(word, %Language{code: code} = language) do
    translations = Aggregator.translate(language, word)

    romanized_text = romanize(word)

    %Word{language_code: code, text: word, romanized_text: romanized_text}
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:language_code, :text]
    )
    |> case do
      {:ok, initial_word} ->
        persist_translations(translations, initial_word)

      {:error, changeset} ->
        Logger.error("Failed to persist word: #{inspect(changeset)}")
        []
    end
  end

  defp persist_translations([translation | translations], initial_word) do
    [
      persist_translation(translation, initial_word)
      | persist_translations(translations, initial_word)
    ]
  end

  defp persist_translations([], _initial_word), do: []

  defp persist_translation(
         {translated_language, translated_word},
         %Word{romanized_text: initial_word_romanized_text} = initial_word
       ) do
    translated_word_romanized_text = romanize(translated_word)

    %Word{
      language_code: translated_language,
      text: translated_word,
      romanized_text: translated_word_romanized_text
    }
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:language_code, :text]
    )
    |> case do
      {:ok, target_word} ->
        similarity =
          Akin.Levenshtein.compare(initial_word_romanized_text, target_word.romanized_text) *
            100.0

        Translation.changeset(
          %Translation{
            source_word: initial_word,
            target_word: target_word,
            similarity: similarity
          },
          %{}
        )
        |> Repo.insert(
          returning: true,
          conflict_target: [:source_word_id, :target_word_id],
          on_conflict: {:replace_all_except, [:id, :inserted_at]}
        )
        |> case do
          {:ok, translation} ->
            translation

          {:error, changeset} ->
            Logger.error("Failed to persist translation: #{inspect(changeset)}")
            changeset
        end
    end
  end

  defp romanize(word) do
    AnyAscii.transliterate(word) |> IO.iodata_to_binary() |> String.downcase()
  end
end
