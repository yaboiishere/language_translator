defmodule LanguageTranslatorWeb.Util do
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias Ecto.Changeset

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
end
