defmodule LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(source_language_code description)a
  @available_fields ~w(words separator)a ++ @required_fields
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
    |> validate_length(:description, max: 160)
  end

  def validate_words_changeset(analysis, attrs) do
    analysis
    |> changeset(attrs)
    |> validate_words(attrs)
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

  def validate_words(changeset, %{words: words, separator: separator}) do
    words
    |> String.split(separator)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] ->
        add_error(changeset, :words, "At least one word is required")

      words ->
        words
        |> Enum.any?(&(String.length(&1) > 64))
        |> case do
          true ->
            add_error(
              changeset,
              :words,
              "Invalid word detected. Each word must be less than 64 characters"
            )

          false ->
            changeset
        end
    end
  end

  def validate_words(changeset, _attrs) do
    add_error(changeset, :words, "Words are required")
  end
end
