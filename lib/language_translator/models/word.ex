defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Word

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

  def words_ordered_by_language(analysis_id) do
    from(a in Analysis,
      where: a.id == ^analysis_id,
      join: at in AnalysisTranslation,
      on: at.analysis_id == a.id,
      join: t in Translation,
      on: t.id == at.translation_id,
      join: tw in Word,
      on: t.target_word_id == tw.id,
      join: tl in Language,
      on: tw.language_code == tl.code,
      join: sw in Word,
      on: t.source_word_id == sw.id,
      join: sl in Language,
      on: sw.language_code == sl.code,
      order_by: [desc: tl.display_name],
      select: %{
        target: %{language: tl, word: tw},
        source: %{language: sl, word: sw}
      }
    )
    |> Repo.all()
  end
end
