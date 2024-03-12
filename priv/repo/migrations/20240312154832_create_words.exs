defmodule LanguageTranslator.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :text, :text
      add :language_id, references(:languages)

      timestamps(type: :utc_datetime)
    end

    create index(:words, [:text, :language_id], unique: true)
  end
end
