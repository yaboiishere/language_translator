defmodule LanguageTranslatorWeb.Changesets.PaginationChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pagination" do
    field :page, :integer
    field :page_size, :integer
    field :total_entries, :integer
    field :total_pages, :integer
  end

  def changeset(pagination, attrs \\ %{}) do
    pagination
    |> cast(attrs, [:page, :page_size, :total_entries, :total_pages])
  end

  def to_map(%__MODULE__{} = pagination) do
    pagination
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
  end

  def to_string_map(%__MODULE__{} = pagination) do
    pagination
    |> to_map()
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end
end
