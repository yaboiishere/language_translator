defmodule LanguageTranslator.Models.Language do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
    |> to_select_option()
  end

  def language_codes_for_select() do
    __MODULE__
    |> Repo.all()
    |> Enum.map(& &1.code)
  end

  def search_display_name(search) do
    from(l in __MODULE__, where: ilike(l.display_name, ^"#{search}%"))
    |> Repo.all()
    |> to_select_option()
  end

  def search_code(search) do
    from(l in __MODULE__, where: ilike(l.code, ^"#{search}%"))
    |> Repo.all()
    |> Enum.map(& &1.code)
  end

  defp to_select_option(languages) do
    Enum.map(languages, &{&1.display_name, &1.code})
  end
end
