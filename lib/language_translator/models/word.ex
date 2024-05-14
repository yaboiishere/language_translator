defmodule LanguageTranslator.Models.Word do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  require Logger

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

  def get!(id) do
    Repo.get!(Word, id)
    |> Repo.preload(:language)
  end

  def get!(text, language_code, preloads \\ []) do
    Word
    |> Repo.get_by!(language_code: language_code, text: text)
    |> Repo.preload(preloads)
  end

  def get_all!(params, preloads \\ []) do
    from(w in Word,
      join: l in assoc(w, :language),
      preload: [language: l],
      order_by: ^filter_order_by(params.order_by)
    )
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def get_translations(%__MODULE__{id: id}) do
    from(t in Translation,
      where: t.source_word_id == ^id,
      join: tw in assoc(t, :target_word),
      on: t.target_word_id == tw.id,
      join: tl in assoc(tw, :language),
      on: tw.language_code == tl.code,
      where: t.source_word_id != t.target_word_id,
      order_by: [desc: t.similarity],
      preload: [target_word: {tw, [language: tl]}]
    )
    |> Repo.all()
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

  defp filter_order_by("id_asc"), do: [asc: :id]
  defp filter_order_by("id_desc"), do: [desc: :id]
  defp filter_order_by("language_code_asc"), do: [asc: :language_code]
  defp filter_order_by("language_code_desc"), do: [desc: :language_code]
  defp filter_order_by("language_asc"), do: [asc: [language: :display_name]]
  defp filter_order_by("language_desc"), do: [desc: [language: :display_name]]
  defp filter_order_by("text_asc"), do: [asc: :text]
  defp filter_order_by("text_desc"), do: [desc: :text]
  defp filter_order_by("romanization_asc"), do: [asc: :romanized_text]
  defp filter_order_by("romanization_desc"), do: [desc: :romanized_text]
  defp filter_order_by("inserted_at_asc"), do: [asc: :inserted_at]
  defp filter_order_by("inserted_at_desc"), do: [desc: :inserted_at]
  defp filter_order_by("updated_at_asc"), do: [asc: :updated_at]
  defp filter_order_by("updated_at_desc"), do: [desc: :updated_at]

  defp filter_order_by(order_by) do
    Logger.warning(" Invalid order_by value: #{order_by}, defaulting to id_desc")
    [desc: :id]
  end
end
