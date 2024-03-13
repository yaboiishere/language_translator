defmodule LanguageTranslator.Models.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Word

  schema "translations" do
    belongs_to :source_word, Word
    belongs_to :target_word, Word

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [])
    |> validate_required([])
    |> cast_assoc(:source_word, with: &Word.changeset/2)
    |> cast_assoc(:target_word, with: &Word.changeset/2)
  end
end
