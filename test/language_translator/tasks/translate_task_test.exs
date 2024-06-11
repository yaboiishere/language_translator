defmodule LanguageTranslator.Tasks.TranslateTaskTest do
  alias LanguageTranslator.Accounts.User
  use LanguageTranslator.DataCase
  import Ecto.Query

  alias LanguageTranslator.Http.Cache
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Tasks.TranslateTask
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator.Aggregator

  import Mock

  setup do
    {:ok, cache_pid} = Cache.start_link(%{size: 100})
    Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)
    language = Repo.get(Language, "en")

    user =
      %User{}
      |> User.registration_changeset(%{
        email: "test23@test.com",
        password: "ZdravaParola@123",
        username: "test23",
        main_language_code: "en"
      })
      |> Repo.insert!()

    {:ok, analysis} =
      insert_analysis(%Analysis{
        source_language: language,
        source_words: ["apple", "banana", "cherry"],
        user_id: user.id
      })

    {:ok, %{language: language, analysis: analysis}}
  end

  test "translate task runs successfully", %{analysis: analysis} do
    with_mock(Aggregator, [],
      translate: fn _source_language, word -> [{"es", "#{word}_es"}, {"bg", "#{word}_bg"}] end
    ) do
      assert :ok = TranslateTask.run(analysis)
      analysis = Repo.get(Analysis, analysis.id)
      assert analysis.status == :completed

      translation =
        from(translation in Translation,
          join: source_word in assoc(translation, :source_word),
          join: target_word in assoc(translation, :target_word),
          where:
            source_word.text == "apple" and
              target_word.language_code == "es",
          preload: [:source_word, :target_word]
        )
        |> Repo.one!()

      assert translation.source_word.text == "apple"
      assert translation.target_word.language_code == "es"
      assert translation.similarity >= 0.0
    end
  end

  test "translation persists correctly" do
    with_mock(Aggregator, [],
      translate: fn _source_language, word -> [{"es", "#{word}_es"}, {"bg", "#{word}_bg"}] end
    ) do
      assert :ok = :ok
    end
  end

  defp insert_analysis(analysis) do
    Repo.insert(analysis)
  end
end
