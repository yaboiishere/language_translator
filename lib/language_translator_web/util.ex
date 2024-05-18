defmodule LanguageTranslatorWeb.Util do
  import Ecto.Query
  alias Ecto.Changeset
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslator.Repo

  def create_order_by(params) do
    %OrderAndFilterChangeset{}
    |> OrderAndFilterChangeset.changeset(params)
    |> Changeset.apply_changes()
  end

  def update_order_by(
        %{
          assigns: %{
            order_and_filter: %OrderAndFilterChangeset{order_by: order_by} = order_and_filter
          }
        },
        field
      ) do
    {old_field, old_direction} = OrderAndFilterChangeset.get_order_by(order_by)
    field = String.downcase(field)

    new_order_by =
      if old_field == field do
        new_direction =
          case old_direction do
            "asc" -> "desc"
            "desc" -> "asc"
          end

        "#{field}_#{new_direction}"
      else
        "#{field}_desc"
      end

    order_and_filter
    |> OrderAndFilterChangeset.changeset(%{order_by: new_order_by})
    |> case do
      %{valid?: true} = changeset ->
        changeset |> Changeset.apply_changes() |> Map.from_struct() |> Map.delete(:__meta__)

      _ ->
        nil
    end
  end

  def update_show_cols(%{assigns: %{order_and_filter: order_and_filter}}, new_show_cols) do
    order_and_filter
    |> OrderAndFilterChangeset.changeset(%{"show_cols" => new_show_cols})
    |> case do
      %{valid?: true} = changeset ->
        changeset |> Changeset.apply_changes() |> OrderAndFilterChangeset.to_map()

      error ->
        require Logger
        Logger.error("Error updating show cols: #{inspect(error)}")

        nil
    end
  end

  def update_filter_by(%{assigns: %{order_and_filter: order_and_filter}}, filters) do
    order_and_filter
    |> OrderAndFilterChangeset.changeset(%{filter_by: filters})
    |> case do
      %{valid?: true} = changeset ->
        changeset |> Changeset.apply_changes() |> OrderAndFilterChangeset.to_map()

      _ ->
        nil
    end
  end

  def format_show_cols(checked_cols) do
    checked_cols
    |> Enum.filter(fn {_, value} -> value == "true" end)
    |> Enum.into([], fn {key, _} -> key end)
    |> case do
      [] -> ["none"]
      cols -> cols
    end
  end

  def clean_filter_params(params, to_drop) do
    params
    |> Map.drop(to_drop)
    |> Enum.filter(fn
      {_k, v} when is_binary(v) -> String.length(v) > 1
      {_k, v} -> v != []
    end)
    |> Enum.into(%{})
  end

  def paginate(query, %{
        page: page_number,
        page_size: page_size
      }) do
    entries = from(q in query, limit: ^page_size, offset: ^((page_number - 1) * page_size))

    total_entries =
      from(q in query) |> Repo.aggregate(:count, :id)

    %{
      entries: entries,
      total_entries: total_entries,
      page_number: page_number,
      page_size: page_size,
      total_pages: ceil(total_entries / page_size)
    }
  end

  def page_size_options() do
    [10, 25, 50, 100]
  end
end
