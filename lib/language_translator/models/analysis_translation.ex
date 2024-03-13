defmodule LanguageTranslator.Models.AnalysisTranslation do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Analysis

  @required_fields ~w(analysis_id translation_id)a
  schema "analysis_translations" do
    belongs_to :analysis, Analysis
    belongs_to :translation, Translation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(analysis_translation, attrs) do
    analysis_translation
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
