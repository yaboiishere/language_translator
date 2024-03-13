defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset

  schema "words" do
    field :text, :string
    field :language, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:text, :language])
    |> validate_required([:text, :language])
    |> unique_constraint([:language, :text], name: :words_language_text_index)
  end
end
