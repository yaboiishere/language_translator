defmodule LanguageTranslator.Models.Language do
  use Ecto.Schema
  import Ecto.Changeset

  alias LanguageTranslator.Repo

  @required_fields ~w(display_name code)a

  @primary_key {:code, :string, []}

  schema "languages" do
    field :display_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(language, attrs) do
    language
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def get_all() do
    Repo.all(__MODULE__)
  end

  def languages_for_select() do
    __MODULE__
    |> Repo.all()
    |> Enum.map(&{&1.display_name, &1.code})
  end
end
