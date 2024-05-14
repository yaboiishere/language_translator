defmodule LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  @doc false
  schema "order_and_filter" do
    field :order_by, :string
    field :show_cols, {:array, :string}
  end

  def changeset(order_and_filter, attrs \\ %{}) do
    order_and_filter
    |> cast(attrs, [:order_by, :show_cols])
  end

  def get_order_by(%{order_by: order_by}) do
    get_order_by(order_by)
  end

  def get_order_by(order_by) when is_binary(order_by) do
    splits =
      order_by
      |> String.split("_")

    dir = List.last(splits)
    label = splits |> List.delete_at(-1) |> Enum.join("_")

    {label, dir}
  end

  def get_order_by(_), do: {nil, nil}

  def get_order_label(order_by) when is_binary(order_by) do
    case order_by do
      <<label, "_desc">> -> label
      <<label, "_asc">> -> label
    end
  end
end
