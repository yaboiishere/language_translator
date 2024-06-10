defmodule LanguageTranslator.Models.AnalysisTest do
  alias LanguageTranslator.Accounts.User
  use LanguageTranslator.DataCase, async: false
  alias LanguageTranslator.Repo

  test "create_auto_analysis/2 creates analysis and translates source word" do
    word = %LanguageTranslator.Models.Word{
      language_code: "en",
      text: "hello"
    }

    user =
      %LanguageTranslator.Accounts.User{}
      |> User.registration_changeset(%{
        email: "test@test.com",
        username: "test",
        password: "ZdravaParola@123",
        main_language_code: "en"
      })
      |> Repo.insert!()

    _expected_changeset = %{
      source_language_code: "en",
      source_words: ["hello"],
      user_id: 1,
      is_public: false,
      description: "Auto-generated analysis for hello",
      status: :pending,
      type: :auto
    }

    _expected_analysis = %LanguageTranslator.Models.Analysis{
      source_language_code: "en",
      source_words: ["hello"],
      user_id: 1,
      is_public: false,
      description: "Auto-generated analysis for hello",
      status: :pending,
      type: :auto
    }

    assert {:ok, _pid} =
             LanguageTranslator.Models.Analysis.create_auto_analysis(word, user)
  end

  test "create_analysis_for_merge/3 creates merged analysis" do
    user =
      %LanguageTranslator.Accounts.User{}
      |> User.registration_changeset(%{
        email: "test@test.com",
        username: "test",
        password: "ZdravaParola@123",
        main_language_code: "en"
      })
      |> Repo.insert!()

    analysis1 =
      %LanguageTranslator.Models.Analysis{
        source_language_code: "en",
        source_words: ["hello"],
        user_id: user.id
      }
      |> Repo.insert!()

    analysis2 =
      %LanguageTranslator.Models.Analysis{
        source_language_code: "en",
        source_words: ["world"],
        user_id: user.id
      }
      |> Repo.insert!()

    expected_changeset = %{
      source_language_code: "en",
      words: "hello,world",
      description: "Merged analysis (#{analysis1.id}, #{analysis2.id})",
      type: "merged",
      is_file: false,
      id: nil,
      is_public: false,
      separator: ","
    }

    assert changeset =
             LanguageTranslator.Models.Analysis.create_analysis_for_merge(
               analysis1,
               [analysis2.id],
               user
             )

    assert changeset == expected_changeset
  end

  test "order and filter analysis" do
    user =
      %LanguageTranslator.Accounts.User{}
      |> User.registration_changeset(%{
        email: "test@test.com",
        username: "test",
        password: "ZdravaParola@123",
        main_language_code: "en"
      })
      |> Repo.insert!()

    user2 =
      %LanguageTranslator.Accounts.User{}
      |> User.registration_changeset(%{
        email: "test2@test.com",
        username: "test2",
        password: "ZdravaParola@123",
        main_language_code: "en"
      })
      |> Repo.insert!()

    _analysis1 =
      %LanguageTranslator.Models.Analysis{
        source_language_code: "en",
        user_id: user.id,
        status: :completed,
        description: "Analysis 1",
        source_words: ["hello"]
      }
      |> Repo.insert!()

    _analysis2 =
      %LanguageTranslator.Models.Analysis{
        source_language_code: "fr",
        user_id: user.id,
        status: :processing,
        description: "Analysis 2",
        source_words: ["bonjour"]
      }
      |> Repo.insert!()

    _analysis3 =
      %LanguageTranslator.Models.Analysis{
        source_language_code: "es",
        user_id: user2.id,
        status: :completed,
        description: "Analysis 3",
        source_words: ["hola"]
      }
      |> Repo.insert!()

    assert _analysis_statuses = LanguageTranslator.Models.Analysis.statuses_for_select()

    assert analysis_by_status =
             LanguageTranslator.Models.Analysis.paginate_all(
               user,
               %{filter_by: %{"status" => ["completed"]}, order_by: "id_desc"},
               %{page: 1, page_size: 10}
             )

    assert Enum.count(analysis_by_status.entries) == 1

    # Test filtering by source language
    assert analysis_by_source_language =
             LanguageTranslator.Models.Analysis.paginate_all(
               user,
               %{filter_by: %{"source_language" => ["en"]}, order_by: "id_desc"},
               %{page: 1, page_size: 10}
             )

    assert Enum.count(analysis_by_source_language.entries) == 1

    # Test ordering by ID
    assert ordered_by_id_desc =
             LanguageTranslator.Models.Analysis.paginate_all(
               user,
               %{order_by: "id_desc", filter_by: %{}},
               %{page: 1, page_size: 10}
             )

    assert length(ordered_by_id_desc.entries) == 2
  end
end
