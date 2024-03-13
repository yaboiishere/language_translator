defmodule LanguageTranslator.Repo.Migrations.CreateAnalysis do
  use Ecto.Migration

  def change do
    create table(:analysis) do
      add :name, :text
      add :description, :text

      add :source_language_code, references(:languages, column: :code, type: :text), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:analysis, [:name], unique: true)
  end
end
