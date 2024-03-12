defmodule LanguageTranslator.Models.AnalysisTranslation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "analysis_translations" do

    field :analysis_id, :id
    field :translation_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(analysis_translation, attrs) do
    analysis_translation
    |> cast(attrs, [])
    |> validate_required([])
  end
end
