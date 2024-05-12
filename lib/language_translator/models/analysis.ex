defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Accounts.User

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

  def get_all(_user_or_nil, _preloads \\ [])

  def get_all(nil, preloads) do
    query = public_analysis_query() |> preload(^preloads)
    Repo.all(query)
  end

  def get_all(%User{id: user_id}, preloads) do
    query = public_analysis_query() |> or_where([a], a.user_id == ^user_id) |> preload(^preloads)
    Repo.all(query)
  end

  def get(analysis_id, preloads \\ [:source_language, :user]) do
    from(a in __MODULE__, where: a.id == ^analysis_id, preload: ^preloads) |> Repo.one()
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
end
