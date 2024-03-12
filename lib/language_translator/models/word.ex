defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset

  schema "words" do
    field :text, :string
    field :language_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
