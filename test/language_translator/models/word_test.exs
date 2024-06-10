defmodule LanguageTranslator.Models.WordTest do
  use LanguageTranslator.DataCase

  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  test "invalid changeset without text" do
    changeset = Word.changeset(%Word{}, %{language_code: "en", romanized_text: "rom"})

    assert {:error, changeset.errors} ==
             {:error, [{:text, {"can't be blank", [validation: :required]}}]}
  end

  test "invalid changeset without language code" do
    changeset = Word.changeset(%Word{}, %{text: "text", romanized_text: "rom"})

    assert {:error, changeset.errors} ==
             {:error, [{:language_code, {"can't be blank", [validation: :required]}}]}
  end

  test "invalid changeset without romanized text" do
    changeset = Word.changeset(%Word{}, %{text: "text", language_code: "en"})

    assert {:error, changeset.errors} ==
             {:error, [{:romanized_text, {"can't be blank", [validation: :required]}}]}
  end

  test "invalid changeset with text exceeding maximum length" do
    changeset =
      Word.changeset(%Word{}, %{
        text: String.duplicate("t", 81),
        language_code: "en",
        romanized_text: "rom"
      })

    assert {:error, changeset.errors} ==
             {:error,
              [
                text:
                  {"should be at most %{count} character(s)",
                   [{:count, 80}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
              ]}
  end

  test "valid changeset with required fields" do
    changeset =
      Word.changeset(%Word{}, %{text: "text", language_code: "en", romanized_text: "rom"})

    assert changeset.valid?
  end

  test "search by text and language code" do
    word = insert_word(%Word{text: "apple", language_code: "en", romanized_text: "rom"})
    assert result = Word.get!(word.text, word.language_code)
    assert result == word
  end

  test "search by invalid text and language code raises error" do
    assert_raise Ecto.NoResultsError, fn ->
      Word.get!("invalid_text", "en")
    end
  end

  describe "order and filter" do
    setup do
      # Insert test data
      Repo.delete_all(Language)
      language = insert_language(%Language{display_name: "English", code: "en"})
      word1 = insert_word(%Word{text: "apple", language_code: "en", romanized_text: "apple_rom"})

      word2 =
        insert_word(%Word{text: "banana", language_code: "en", romanized_text: "banana_rom"})

      word3 =
        insert_word(%Word{text: "cherry", language_code: "en", romanized_text: "cherry_rom"})

      {:ok, %{language: language, words: [word1, word2, word3]}}
    end

    test "filter by text" do
      query = %{order_by: "id_desc", filter_by: %{"text" => "apple"}}
      result = Word.all_query(query) |> Repo.all()
      assert length(result) == 1
      assert Enum.at(result, 0).text == "apple"
    end

    test "filter by romanized text" do
      query = %{order_by: "id_desc", filter_by: %{"romanized_text" => "apple_rom"}}
      result = Word.all_query(query) |> Repo.all()
      assert length(result) == 1
      assert Enum.at(result, 0).romanized_text == "apple_rom"
    end

    test "filter by language code" do
      query = %{order_by: "id_desc", filter_by: %{"language_code" => ["en"]}}
      result = Word.all_query(query) |> Repo.all()
      assert length(result) == 3
      assert Enum.map(result, & &1.language_code) == ["en", "en", "en"]
    end

    test "filter by multiple fields" do
      query = %{order_by: "id_desc", filter_by: %{"text" => "banana", "language_code" => ["en"]}}
      result = Word.all_query(query) |> Repo.all()
      assert length(result) == 1
      assert Enum.at(result, 0).text == "banana"
      assert Enum.at(result, 0).language_code == "en"
    end

    test "filter by unknown field" do
      query = %{filter_by: %{"unknown_field" => "value"}, order_by: "id_desc"}
      result = Word.all_query(query) |> Repo.all()
      assert length(result) == 3
    end

    test "order by text ascending" do
      order_by = "text_asc"
      result = Word.all_query(%{order_by: order_by, filter_by: %{}}) |> Repo.all()
      assert Enum.map(result, & &1.text) == ["apple", "banana", "cherry"]
    end

    test "order by text descending" do
      order_by = "text_desc"
      result = Word.all_query(%{order_by: order_by, filter_by: %{}}) |> Repo.all()
      assert Enum.map(result, & &1.text) == ["cherry", "banana", "apple"]
    end

    test "order by romanized text ascending" do
      order_by = "romanization_asc"
      result = Word.all_query(%{order_by: order_by, filter_by: %{}}) |> Repo.all()
      assert Enum.map(result, & &1.romanized_text) == ["apple_rom", "banana_rom", "cherry_rom"]
    end

    test "order by romanized text descending" do
      order_by = "romanization_desc"
      result = Word.all_query(%{filter_by: %{}, order_by: order_by}) |> Repo.all()
      assert Enum.map(result, & &1.romanized_text) == ["cherry_rom", "banana_rom", "apple_rom"]
    end

    test "order by language code ascending" do
      order_by = "language_code_asc"
      result = Word.all_query(%{filter_by: %{}, order_by: order_by}) |> Repo.all()
      assert Enum.map(result, & &1.language_code) == ["en", "en", "en"]
    end

    test "order by language code descending" do
      order_by = "language_code_desc"
      result = Word.all_query(%{order_by: order_by, filter_by: %{}}) |> Repo.all()
      assert Enum.map(result, & &1.language_code) == ["en", "en", "en"]
    end

    test "order by created_at ascending" do
      order_by = "created_at_asc"
      result = Word.all_query(%{filter_by: %{}, order_by: order_by}) |> Repo.all()

      assert [List.first(Enum.map(result, & &1.inserted_at))] == [
               Enum.min(Enum.map(result, & &1.inserted_at))
             ]
    end

    test "order by created_at descending" do
      order_by = "created_at_desc"
      result = Word.all_query(%{filter_by: %{}, order_by: order_by}) |> Repo.all()

      assert [List.first(Enum.map(result, & &1.inserted_at))] == [
               Enum.max(Enum.map(result, & &1.inserted_at))
             ]
    end
  end

  defp insert_language(language) do
    Repo.insert(language)
  end

  defp insert_word(word) do
    Repo.insert!(word)
  end
end
