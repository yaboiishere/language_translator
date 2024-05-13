defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

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

  defp filter_order_by(query, %{order_by: order_by}) do
    order_by(query, ^filter_order_by(order_by))
  end

  defp filter_order_by("id_asc"), do: [asc: :id]
  defp filter_order_by("id_desc"), do: [desc: :id]
  defp filter_order_by("status_asc"), do: [asc: :status]
  defp filter_order_by("status_desc"), do: [desc: :status]
  defp filter_order_by("created_at_asc"), do: [asc: :inserted_at]
  defp filter_order_by("created_at_desc"), do: [desc: :inserted_at]
  defp filter_order_by("updated_at_asc"), do: [asc: :updated_at]
  defp filter_order_by("updated_at_desc"), do: [desc: :updated_at]
  defp filter_order_by("source_language_asc"), do: [asc: :source_language_code]
  defp filter_order_by("source_language_desc"), do: [desc: :source_language_code]
  defp filter_order_by("uploaded_by_asc"), do: [asc: :user_id]
  defp filter_order_by("uploaded_by_desc"), do: [desc: :user_id]
  defp filter_order_by("public_asc"), do: [asc: :is_public]
  defp filter_order_by("public_desc"), do: [desc: :is_public]
  defp filter_order_by("description_asc"), do: [asc: :description]
  defp filter_order_by("description_desc"), do: [desc: :description]

  defp filter_order_by(sorting) do
    Logger.warning("Invalid order_by value: #{sorting}, defaulting to id_desc")
    [desc: :id]
  end
end
