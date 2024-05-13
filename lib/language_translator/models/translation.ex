defmodule LanguageTranslator.Models.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.AnalysisTranslation

  schema "translations" do
    belongs_to :source_word, Word
    belongs_to :target_word, Word
    field :similarity, :float

    many_to_many :analysis, Analysis,
      join_through: AnalysisTranslation,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:similarity])
    |> validate_required([:similarity])
    |> cast_assoc(:source_word, with: &Word.changeset/2)
    |> cast_assoc(:target_word, with: &Word.changeset/2)
  end
end
