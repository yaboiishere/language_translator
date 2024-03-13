defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation

  @required_fields ~w(source_language_code)a
  @available_fields ~w(name description)a
  schema "analysis" do
    field :name, :string
    field :description, :string

    belongs_to :source_language, Language,
      foreign_key: :source_language_code,
      references: :code,
      type: :string

    many_to_many :translations, Translation,
      join_through: AnalysisTranslation,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(analysis, attrs) do
    analysis
    |> cast(attrs, @available_fields)
    |> validate_required(@required_fields)
  end
end
