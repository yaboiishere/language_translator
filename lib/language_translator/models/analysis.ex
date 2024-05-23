defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslator.Translator
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Accounts.User

  @default_preloads ~w(source_language user)a

  @required_fields ~w(source_language_code status user_id source_words)a
  @available_fields ~w(description is_public type)a ++ @required_fields
  schema "analysis" do
    field :description, :string
    field :status, Ecto.Enum, values: ~w(pending processing completed failed)a, default: :pending
    field :is_public, :boolean, default: false
    field :source_words, {:array, :string}
    field :type, Ecto.Enum, values: ~w(manual auto merged)a, default: :manual

    belongs_to :user, User

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

  def statuses_for_select() do
    [
      {"Pending", "pending"},
      {"Processing", "processing"},
      {"Completed", "completed"},
      {"Failed", "failed"}
    ]
  end

  def create_auto_analysis(word, user) do
    %__MODULE__{}
    |> changeset(%{
      source_language_code: word.language_code,
      source_words: [word.text],
      user_id: user.id,
      is_public: false,
      description: "Auto-generated analysis for #{word.text}",
      status: :pending,
      type: :auto
    })
    |> Repo.insert!()
    |> Repo.preload(@default_preloads)
    |> Translator.async_translate()
  end

  def create_analysis_for_merge(analysis, extra_ids, user) do
    analyses = [analysis | get_all(user, %{order_by: nil, filter_by: %{"id" => extra_ids}})]

    source_words =
      analyses
      |> Enum.flat_map(& &1.source_words)
      |> Enum.uniq()
      |> Enum.join(",")

    %AnalysisCreateChangeset{}
    |> AnalysisCreateChangeset.changeset(%{
      source_language_code: analysis.source_language_code,
      words: source_words,
      description: "Merged analysis (#{analysis.id}, #{Enum.join(extra_ids, ", ")})",
      type: "merged",
      separator: ",",
      is_file: false
    })
    |> apply_changes()
    |> Map.drop([:__meta__, :__struct__])
  end

  def get_all(_user_or_nil, _params, _preloads \\ @default_preloads)

  def get_all(nil, params, preloads) do
    nil
    |> all_query(params)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def get_all(%User{} = user, params, preloads) do
    user
    |> all_query(params)
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  defp user_owner_query(query, nil) do
    where(query, [a], a.is_public == true)
  end

  defp user_owner_query(query, user) do
    where(query, [a], a.is_public == true or a.user_id == ^user.id)
  end

  def get_by_source_language(user, %Analysis{source_language_code: source_language_code, id: id}) do
    from(a in __MODULE__,
      where:
        a.source_language_code == ^source_language_code and a.id != ^id and
          a.status == :completed and a.type != :merged,
      select: {a.id, a.description}
    )
    |> user_owner_query(user)
    |> Repo.all()
    |> Enum.map(fn {id, description} -> {"#{id} - #{description}", id} end)
  end

  def search_description(user, analysis, search) do
    from(a in __MODULE__,
      where:
        ilike(a.description, ^"#{search}%") and
          a.id != ^analysis.id and
          a.source_language_code == ^analysis.source_language_code and
          a.status == :completed and a.type != :merged,
      order_by: a.description
    )
    |> user_owner_query(user)
    |> Repo.all()
    |> Enum.map(fn %Analysis{description: description, id: id} ->
      {"#{id} - #{description}", id}
    end)
  end

  def paginate_all(user_or_nil, params, pagination, preloads \\ @default_preloads) do
    %{entries: query} =
      paginated_query =
      user_or_nil
      |> all_query(params)
      |> Util.paginate(pagination)

    entries =
      query
      |> Repo.all()
      |> Repo.preload(preloads)

    %{paginated_query | entries: entries}
  end

  defp all_query(user_or_nil, order_and_filter) do
    query =
      case user_or_nil do
        nil -> public_analysis_query()
        user -> public_analysis_query() |> or_where([a], a.user_id == ^user.id)
      end

    query
    |> filter_order_by(order_and_filter)
  end

  def get(analysis_id, preloads \\ [:source_language, :user]) do
    from(a in __MODULE__, where: a.id == ^analysis_id, preload: ^preloads) |> Repo.one()
  end

  def get!(analysis_id, preloads \\ [:source_language, :user]) do
    from(a in __MODULE__, where: a.id == ^analysis_id, preload: ^preloads) |> Repo.one!()
  end

  defp public_analysis_query do
    from a in __MODULE__, or_where: a.is_public == true
  end

  def update(%__MODULE__{} = analysis, attrs) do
    analysis
    |> changeset(attrs)
    |> Repo.update()
  end

  def update(analysis_id, attrs, preloads \\ []) when is_integer(analysis_id) do
    __MODULE__
    |> Repo.get(analysis_id)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, "Analysis not found"}
      analysis -> __MODULE__.update(analysis, attrs)
    end
  end

  def source_words(analysis_id) do
    %{source_words: source_words, source_language_code: source_language_code} =
      Repo.get!(__MODULE__, analysis_id)

    Enum.map(source_words, fn word ->
      Word.get!(word, source_language_code)
    end)
    |> Enum.map(& &1.text)
  end

  def search_id(search) do
    from(a in __MODULE__,
      where: fragment("? <% id_text", ^search),
      select: a.id,
      order_by: a.id
    )
    |> Repo.all()
  end

  def search_status(search) do
    statuses_for_select()
    |> Enum.filter(fn {_, value} ->
      value
      |> String.downcase()
      |> String.contains?(String.downcase(search))
    end)
  end

  defp filter_order_by(query, %{order_by: order_by, filter_by: filter_by}) do
    query
    |> filter_by(filter_by)
    |> resolve_order_by(order_by)
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

  defp filter_by(query, {"id", ids}) do
    where(query, [a], a.id in ^ids)
  end

  defp filter_by(query, {"description", description}) do
    where(query, [a], fragment("? <% ?", ^description, a.description))
  end

  defp filter_by(query, {"source_language", source_language}) do
    where(query, [a], a.source_language_code in ^source_language)
  end

  defp filter_by(query, {"status", status}) do
    where(query, [a], a.status in ^status)
  end

  defp filter_by(query, {"uploaded_by", uploaded_by}) do
    from(a in query, join: u in assoc(a, :user), where: u.username in ^uploaded_by)
  end

  defp filter_by(query, {"public", nil}) do
    query
  end

  defp filter_by(query, {"public", public}) do
    where(query, is_public: ^public)
  end

  defp resolve_order_by(query, nil) do
    resolve_order_by(query, "id_desc")
  end

  defp resolve_order_by(query, "id_asc") do
    order_by(query, [a], a.id)
  end

  defp resolve_order_by(query, "id_desc") do
    order_by(query, [a], desc: a.id)
  end

  defp resolve_order_by(query, "status_asc") do
    order_by(query, [a], a.status)
  end

  defp resolve_order_by(query, "status_desc") do
    order_by(query, [a], desc: a.status)
  end

  defp resolve_order_by(query, "created_at_asc") do
    order_by(query, [a], a.inserted_at)
  end

  defp resolve_order_by(query, "created_at_desc") do
    order_by(query, [a], desc: a.inserted_at)
  end

  defp resolve_order_by(query, "updated_at_asc") do
    order_by(query, [a], a.updated_at)
  end

  defp resolve_order_by(query, "updated_at_desc") do
    order_by(query, [a], desc: a.updated_at)
  end

  defp resolve_order_by(query, "source_language_asc") do
    from(a in query, join: l in assoc(a, :source_language), order_by: l.display_name)
  end

  defp resolve_order_by(query, "source_language_desc") do
    from(a in query, join: l in assoc(a, :source_language), order_by: [desc: l.display_name])
  end

  defp resolve_order_by(query, "uploaded_by_asc") do
    from(a in query, join: u in assoc(a, :user), order_by: u.username)
  end

  defp resolve_order_by(query, "uploaded_by_desc") do
    from(a in query, join: u in assoc(a, :user), order_by: [desc: u.username])
  end

  defp resolve_order_by(query, "public_asc") do
    order_by(query, [a], a.is_public)
  end

  defp resolve_order_by(query, "public_desc") do
    order_by(query, [a], desc: a.is_public)
  end

  defp resolve_order_by(query, "description_asc") do
    order_by(query, [a], a.description)
  end

  defp resolve_order_by(query, "description_desc") do
    order_by(query, [a], desc: a.description)
  end
end
