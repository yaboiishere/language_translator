defmodule LanguageTranslator.Models.Language do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LanguageTranslator.Repo
  alias LanguageTranslatorWeb.Util

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
    from(l in __MODULE__, where: fragment("? <% ?", ^search, l.display_name))
    |> Repo.all()
    |> to_select_option()
  end

  def search_code(search) do
    from(l in __MODULE__, where: fragment("? <% ?", ^search, l.code))
    |> Repo.all()
    |> Enum.map(& &1.code)
  end

  def paginate_all(params, pagination) do
    %{entries: entries} =
      paginated_query =
      params
      |> all_query()
      |> Util.paginate(pagination, :code)

    entries = entries |> Repo.all()

    %{paginated_query | entries: entries}
  end

  defp all_query(%{order_by: order_by, filter_by: filter_by}) do
    from(l in __MODULE__)
    |> order_by(^resolve_order_by(order_by))
    |> filter_by(filter_by)
  end

  defp resolve_order_by("name_desc"), do: [desc: :display_name]
  defp resolve_order_by("name_asc"), do: [asc: :display_name]
  defp resolve_order_by("code_desc"), do: [desc: :code]
  defp resolve_order_by("code_asc"), do: [asc: :code]
  defp resolve_order_by(_), do: [asc: :display_name]

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

  defp filter_by(query, {"source_language", display_name}) do
    where(query, [a], ilike(a.display_name, ^"#{display_name}%"))
  end

  defp to_select_option(languages) do
    Enum.map(languages, &{&1.display_name, &1.code})
  end
end
