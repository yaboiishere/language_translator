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
  alias LanguageTranslatorWeb.Util

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

  def get_all!(%{order_by: order_by}, preloads \\ []) do
    from(w in Word,
      join: l in assoc(w, :language),
      preload: [language: l]
    )
    |> resolve_order_by(order_by)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def paginate_all(params, pagination) do
    %{entries: query} =
      paginated_query =
      params
      |> all_query()
      |> Util.paginate(pagination)

    entries =
      query
      |> Repo.all()

    %{paginated_query | entries: entries}
  end

  def all_query(%{order_by: order_by, filter_by: filter_by}) do
    query =
      from(w in Word,
        join: l in assoc(w, :language),
        preload: [language: l]
      )

    query
    |> resolve_order_by(order_by)
    |> filter_by(filter_by)
  end

  def search_id(search) do
    from(w in __MODULE__,
      where: fragment("? <% id_text", ^search),
      select: w.id,
      order_by: w.id
    )
    |> Repo.all()
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

  defp filter_by(query, nil) do
    query
  end

  defp filter_by(query, %{} = filters) when map_size(filters) == 0 do
    query
  end

  defp filter_by(query, %{} = filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter_by(acc, {key, value})
    end)
  end

  defp filter_by(query, {"id", id}) do
    where(query, [a], a.id in ^id)
  end

  defp filter_by(query, {"text", text}) do
    where(query, [a], fragment("? <% ?", ^text, a.text))
  end

  defp filter_by(query, {"romanized_text", romanized_text}) do
    where(query, [a], fragment("? <% ?", ^romanized_text, a.romanized_text))
  end

  defp filter_by(query, {"language_code", language_code}) do
    where(query, [a], a.language_code in ^language_code)
  end

  defp filter_by(query, {"source_language", language}) do
    from(a in query, where: a.language_code in ^language)
  end

  defp filter_by(query, search) do
    Logger.error("Unknown filter: #{inspect(search)}")
    query
  end

  defp resolve_order_by(query, nil) do
    resolve_order_by(query, "id_desc")
  end

  defp resolve_order_by(query, "id_asc") do
    order_by(query, [w], w.id)
  end

  defp resolve_order_by(query, "id_desc") do
    order_by(query, [w], desc: w.id)
  end

  defp resolve_order_by(query, "language_code_asc") do
    order_by(query, [w], w.language_code)
  end

  defp resolve_order_by(query, "language_code_desc") do
    order_by(query, [w], desc: w.language_code)
  end

  defp resolve_order_by(query, "language_asc") do
    from(w in query, join: l in assoc(w, :language), order_by: l.display_name)
  end

  defp resolve_order_by(query, "language_desc") do
    from(w in query, join: l in assoc(w, :language), order_by: [desc: l.display_name])
  end

  defp resolve_order_by(query, "text_asc") do
    order_by(query, [w], w.text)
  end

  defp resolve_order_by(query, "text_desc") do
    order_by(query, [w], desc: w.text)
  end

  defp resolve_order_by(query, "romanization_asc") do
    order_by(query, [w], w.romanized_text)
  end

  defp resolve_order_by(query, "romanization_desc") do
    order_by(query, [w], desc: w.romanized_text)
  end

  defp resolve_order_by(query, "inserted_at_asc") do
    order_by(query, [w], w.inserted_at)
  end

  defp resolve_order_by(query, "inserted_at_desc") do
    order_by(query, [w], desc: w.inserted_at)
  end

  defp resolve_order_by(query, "updated_at_asc") do
    order_by(query, [w], w.updated_at)
  end

  defp resolve_order_by(query, "updated_at_desc") do
    order_by(query, [w], desc: w.updated_at)
  end
end
