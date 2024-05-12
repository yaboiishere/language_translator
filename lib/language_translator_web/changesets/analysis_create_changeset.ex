defmodule LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(source_language_code description)a
  @available_fields ~w(separator words)a ++ @required_fields
  schema "analysis_create" do
    field :description, :string
    field :words, :string
    field :source_language_code, :string
    field :separator, :string
    field :is_file, :boolean, default: true
  end

  @doc false
  def changeset(analysis, attrs) do
    analysis
    |> cast(attrs, @available_fields)
    |> validate_separator()
    |> validate_required(@required_fields)
    |> validate_format(:source_language_code, ~r/^[a-z]{2}$/)
  end

  defp validate_separator(changeset) do
    case get_field(changeset, :separator) do
      nil -> add_error(changeset, :separator, "Separator is required")
      separator when separator in [",", "space", "newline", ";"] -> changeset
      _ -> add_error(changeset, :separator, "Invalid separator")
    end
  end

  def resolve_separator("space"), do: " "
  def resolve_separator("newline"), do: "\n"
  def resolve_separator(separator), do: separator
end
