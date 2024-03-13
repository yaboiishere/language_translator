defmodule LanguageTranslator.Translator do
  require Logger

  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Translator.Aggregator

  def translate(words, language) when is_list(words) and is_binary(language) do
    Repo.transaction(fn ->
      analysis = Repo.insert!(%Analysis{})

      Stream.flat_map(words, fn word ->
        translations = Aggregator.translate(language, word)

        %Word{language: language, text: word}
        |> Repo.insert(
          on_conflict: {:replace_all_except, [:id, :inserted_at]},
          conflict_target: [:language, :text]
        )
        |> case do
          {:ok, initial_word} ->
            persist_translations(translations, initial_word)

          {:error, changeset} ->
            Logger.error("Failed to persist word: #{inspect(changeset)}")
            []
        end
      end)
      |> Enum.map(fn translation ->
        %{translation_id: translation.id, analysis_id: analysis.id}
      end)
      |> then(fn entries ->
        Repo.insert_all(AnalysisTranslation, entries)
      end)

      Repo.preload(analysis, :translations)
    end)
  end

  defp persist_translations([translation | translations], initial_word) do
    [
      persist_translation(translation, initial_word)
      | persist_translations(translations, initial_word)
    ]
  end

  defp persist_translations([], _initial_word), do: []

  defp persist_translation({translated_language, translated_word}, %Word{} = initial_word) do
    %Word{language: translated_language, text: translated_word}
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:language, :text]
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
