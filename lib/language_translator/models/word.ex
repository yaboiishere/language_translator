defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset

  schema "words" do
    field :text, :string

    belongs_to :language, LanguageTranslator.Models.Language,
      foreign_key: :language_code,
      references: :code,
      type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:text, :language_code])
    |> validate_required([:text, :language_code])
    |> unique_constraint([:language_code, :text], name: :words_language_code_text_index)
  end
end
