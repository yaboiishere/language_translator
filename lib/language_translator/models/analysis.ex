defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation

  schema "analysis" do
    field :name, :string

    many_to_many :translations, Translation, join_through: AnalysisTranslation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(analysis, attrs) do
    analysis
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
