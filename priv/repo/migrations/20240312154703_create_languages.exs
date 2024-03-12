defmodule LanguageTranslator.Repo.Migrations.CreateLanguages do
  use Ecto.Migration

  def change do
    create table(:languages) do
      add :name, :text

      timestamps(type: :utc_datetime)
    end

    create index(:languages, [:name], unique: true)
  end
end
