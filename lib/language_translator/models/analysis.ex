defmodule LanguageTranslator.Models.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Accounts.User

  @required_fields ~w(source_language_code status user_id)a
  @available_fields ~w(description is_public)a ++ @required_fields
  schema "analysis" do
    field :description, :string
    field :status, Ecto.Enum, values: ~w(pending processing completed failed)a, default: :pending
    field :is_public, :boolean, default: false

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

  defp public_analysis_query do
    from a in __MODULE__, or_where: a.is_public == true
  end
end
