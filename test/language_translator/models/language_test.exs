defmodule LanguageTranslator.Models.LanguageTest do
  use LanguageTranslator.DataCase, async: false

  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  setup do
    Repo.delete_all(Language)
    {:ok, %{}}
  end

  test "valid changeset" do
    changeset = Language.changeset(%Language{}, %{display_name: "English", code: "en"})
    assert changeset.valid?
  end

  test "invalid changeset without display_name" do
    changeset = Language.changeset(%Language{}, %{code: "en"})
    refute changeset.valid?

    assert {:error, changeset.errors} ==
             {:error, [{:display_name, {"can't be blank", [validation: :required]}}]}
  end

  test "invalid changeset without code" do
    changeset = Language.changeset(%Language{}, %{display_name: "English"})
    refute changeset.valid?

    assert {:error, changeset.errors} ==
             {:error, [{:code, {"can't be blank", [validation: :required]}}]}
  end

  test "get all languages" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})

    languages = Language.get_all()
    assert length(languages) == 2
    assert Enum.map(languages, & &1.code) == ["en", "fr"]
  end

  test "languages for select option" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})

    options = Language.languages_for_select()
    assert options == [{"English", "en"}, {"French", "fr"}]
  end

  test "language codes for select option" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})

    codes = Language.language_codes_for_select()
    assert codes == ["en", "fr"]
  end

  test "search display name" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})

    search_results = Language.search_display_name("Eng")
    assert length(search_results) == 1
  end

  test "search code" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})

    search_results = Language.search_code("en")
    assert length(search_results) == 1
  end

  test "paginate all languages" do
    assert {:ok, _} = Repo.insert(%Language{display_name: "English", code: "en"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "French", code: "fr"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "German", code: "de"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "Spanish", code: "es"})
    assert {:ok, _} = Repo.insert(%Language{display_name: "Italian", code: "it"})

    pagination = %{page: 1, page_size: 2}

    paginated_languages =
      Language.paginate_all(%{order_by: "id_desc", filter_by: %{}}, pagination)

    assert Enum.count(paginated_languages.entries) == 2
  end
end
