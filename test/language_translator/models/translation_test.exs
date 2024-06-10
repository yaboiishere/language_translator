defmodule LanguageTranslator.Models.TranslationTest do
  use LanguageTranslator.DataCase
  alias LanguageTranslator.Models.{Translation, Word}
  alias LanguageTranslator.Repo

  test "invalid changeset without similarity" do
    source_word =
      insert_word(%Word{text: "source", romanized_text: "source", language_code: "en"})

    target_word =
      insert_word(%Word{text: "target", romanized_text: "target", language_code: "fr"})

    changeset =
      Translation.changeset(%Translation{}, %{})
      |> Ecto.Changeset.put_assoc(:source_word, source_word)
      |> Ecto.Changeset.put_assoc(:target_word, target_word)

    assert {:error, changeset.errors} ==
             {:error,
              [
                {:target_word, {"is invalid", [type: :map]}},
                {:source_word, {"is invalid", [type: :map]}},
                {:similarity, {"can't be blank", [validation: :required]}}
              ]}
  end

  test "invalid changeset without source word" do
    changeset =
      Translation.changeset(%Translation{}, %{similarity: 0.5})
      |> Ecto.Changeset.put_assoc(
        :target_word,
        insert_word(%Word{text: "target", romanized_text: "target", language_code: "fr"})
      )

    assert {:error, changeset.errors} == {:error, [target_word: {"is invalid", [type: :map]}]}
  end

  test "invalid changeset without target word" do
    changeset =
      Translation.changeset(%Translation{}, %{similarity: 0.5})
      |> Ecto.Changeset.put_assoc(
        :source_word,
        insert_word(%Word{text: "source", romanized_text: "source", language_code: "en"})
      )

    assert {:error, changeset.errors} == {:error, [source_word: {"is invalid", [type: :map]}]}
  end

  test "valid changeset with source and target words" do
    {:ok, source_word} =
      insert_word(%Word{text: "source", romanized_text: "source", language_code: "en"})

    {:ok, target_word} =
      insert_word(%Word{text: "target", romanized_text: "source", language_code: "fr"})

    changeset =
      Translation.changeset(%Translation{}, %{
        similarity: 0.5,
        source_word_id: source_word.id,
        target_word_id: target_word.id
      })

    assert changeset.valid?
  end

  defp insert_word(word) do
    Repo.insert(word)
  end
end
