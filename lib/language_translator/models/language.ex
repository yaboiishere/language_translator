defmodule LanguageTranslator.Models.Language do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(display_name code)a

  schema "languages" do
    field :display_name, :string
    field :code, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(language, attrs) do
    language
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:code)
  end
end
