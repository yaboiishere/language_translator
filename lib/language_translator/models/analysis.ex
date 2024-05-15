defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  alias LanguageTranslator.Translator
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Accounts.User

  @default_preloads ~w(source_language user)a

  @required_fields ~w(source_language_code status user_id source_words)a
  @available_fields ~w(description is_public)a ++ @required_fields
  schema "analysis" do
    field :description, :string
    field :status, Ecto.Enum, values: ~w(pending processing completed failed)a, default: :pending
    field :is_public, :boolean, default: false
    field :source_words, {:array, :string}

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
      {"Pending", :pending},
      {"Processing", :processing},
      {"Completed", :completed},
      {"Failed", :failed}
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
      status: :pending
    })
    |> Repo.insert!()
    |> Repo.preload(@default_preloads)
    |> Translator.async_translate()
  end

  def get_all(_user_or_nil, _params, _preloads \\ @default_preloads)

  def get_all(nil, params, preloads) do
    query = public_analysis_query() |> filter_order_by(params) |> preload(^preloads)
    Repo.all(query)
  end

  def get_all(%User{id: user_id}, params, preloads) do
    query =
      public_analysis_query()
      |> or_where([a], a.user_id == ^user_id)
      |> filter_order_by(params)
      |> preload(^preloads)

    Repo.all(query)
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

  defp filter_order_by(query, %{order_by: order_by, filter_by: filter_by}) do
    query
    |> filter_by(filter_by)
    |> order_by(^resolve_order_by(order_by))
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
    where(query, [a], a.id == ^id)
  end

  defp filter_by(query, {"description", description}) do
    where(query, [a], ilike(a.description, ^"%#{description}%"))
  end

  defp filter_by(query, {"source_language", source_language}) do
    where(query, [a], a.source_language_code in ^source_language)
  end

  defp filter_by(query, {"status", status}) do
    where(query, [a], a.status in ^status)
  end

  defp filter_by(query, {"uploaded_by", uploaded_by}) do
    where(query, [a], a.user_id in ^uploaded_by)
  end

  defp filter_by(query, {"public", nil}) do
    query
  end

  defp filter_by(query, {"public", public}) do
    where(query, is_public: ^public)
  end

  defp resolve_order_by("id_asc"), do: [asc: :id]
  defp resolve_order_by("id_desc"), do: [desc: :id]
  defp resolve_order_by("status_asc"), do: [asc: :status]
  defp resolve_order_by("status_desc"), do: [desc: :status]
  defp resolve_order_by("created_at_asc"), do: [asc: :inserted_at]
  defp resolve_order_by("created_at_desc"), do: [desc: :inserted_at]
  defp resolve_order_by("updated_at_asc"), do: [asc: :updated_at]
  defp resolve_order_by("updated_at_desc"), do: [desc: :updated_at]
  defp resolve_order_by("source_language_asc"), do: [asc: :source_language_code]
  defp resolve_order_by("source_language_desc"), do: [desc: :source_language_code]
  defp resolve_order_by("uploaded_by_asc"), do: [asc: :user_id]
  defp resolve_order_by("uploaded_by_desc"), do: [desc: :user_id]
  defp resolve_order_by("public_asc"), do: [asc: :is_public]
  defp resolve_order_by("public_desc"), do: [desc: :is_public]
  defp resolve_order_by("description_asc"), do: [asc: :description]
  defp resolve_order_by("description_desc"), do: [desc: :description]

  defp resolve_order_by(sorting) do
    Logger.warning("Invalid order_by value: #{sorting}, defaulting to id_desc")
    [desc: :id]
  end
end
