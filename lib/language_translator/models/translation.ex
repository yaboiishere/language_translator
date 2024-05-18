defmodule LanguageTranslator.Models.Translation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Repo

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

  def get_by_source_word_and_language(%Word{id: id}, language_code) do
    from(t in __MODULE__,
      where: t.source_word_id == ^id,
      join: w in assoc(t, :target_word),
      where: w.language_code == ^language_code,
      preload: [target_word: {w, :language}],
      select: t
    )
    |> Repo.one()
    |> case do
      nil -> {:error, "No translation found"}
      translation -> {:ok, translation}
    end
  end
end
