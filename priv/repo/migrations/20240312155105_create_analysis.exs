defmodule LanguageTranslator.Repo.Migrations.CreateAnalysis do
  use Ecto.Migration

  def change do
    create table(:analysis) do
      add :name, :text

      timestamps(type: :utc_datetime)
    end

    create index(:analysis, [:name], unique: true)
  end
end
