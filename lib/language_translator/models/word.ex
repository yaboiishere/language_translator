defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Word

  schema "words" do
    field :text, :string
    field :romanized_text, :string

    belongs_to :language, LanguageTranslator.Models.Language,
      foreign_key: :language_code,
      references: :code,
      type: :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:text, :language_code, :romanized_text])
    |> validate_required([:text, :language_code, :romanized_text])
    |> unique_constraint([:language_code, :text], name: :words_language_code_text_index)
  end

  def get!(text, language_code) do
    Repo.get_by!(Word, language_code: language_code, text: text)
  end

  def analysis_words(analysis_id) do
    from(at in AnalysisTranslation,
      where: at.analysis_id == ^analysis_id,
      join: t in Translation,
      on: t.id == at.translation_id,
      join: tw in Word,
      on: t.target_word_id == tw.id,
      join: tl in Language,
      on: tw.language_code == tl.code,
      order_by: [asc: tl.display_name],
      select: t
    )
    |> Repo.all()
    |> Repo.preload([:source_word, target_word: :language])
    |> Enum.group_by(& &1.source_word)
  end
end
