defmodule LanguageTranslator.Translator do
  require Logger

  alias LanguageTranslator.Models
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator.Aggregator

  def translate(%Analysis{} = analysis, words, language)
      when is_list(words) and is_binary(language) do
    Language
    |> Repo.get_by(code: language)
    |> case do
      %Language{} = language_struct -> translate(analysis, words, language_struct)
      _ -> {:error, "Language not found"}
    end
  end

  def translate(%Analysis{} = analysis, words, %Language{} = language)
      when is_list(words) do
    Repo.transaction(fn ->
      Enum.map(
        words,
        &Task.async(fn -> translate_word(&1, language) end)
      )
      |> Enum.flat_map(&Task.await(&1, 60_000))
      |> Enum.map(fn translation ->
        %{translation_id: translation.id, analysis_id: analysis.id}
      end)
      |> then(fn entries ->
        Repo.insert_all(AnalysisTranslation, entries)
      end)

      {:ok, analysis} = Models.update_analysis(analysis, %{status: :completed})
      analysis
    end)
  end

  def async_translate(%Analysis{} = analysis, words, %Language{} = language) do
    Task.Supervisor.start_child(LanguageTranslator.TaskSupervisor, fn ->
      translate(analysis, words, language)
      |> case do
        {:ok, analysis} ->
          ProcessGroups.Analysis.update_analysis(analysis)

        {:error, reason} ->
          Logger.error("Failed to translate analysis: #{inspect(reason)}")
      end
    end)
  end

  defp translate_word(word, %Language{code: code} = language) do
    translations = Aggregator.translate(language, word)

    %Word{language_code: code, text: word}
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

  defp persist_translation({translated_language, translated_word}, %Word{} = initial_word) do
    %Word{language_code: translated_language, text: translated_word}
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:language_code, :text]
    )
    |> case do
      {:ok, target_word} ->
        Translation.changeset(
          %Translation{
            source_word: initial_word,
            target_word: target_word
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
end
