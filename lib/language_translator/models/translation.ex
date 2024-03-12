defmodule LanguageTranslator.Models.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Word

  schema "translations" do
    has_one :source_word, Word
    has_one :target_word, Word

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [])
    |> validate_required([])
  end
end
