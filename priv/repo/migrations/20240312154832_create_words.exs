defmodule LanguageTranslator.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :text, :text
      add :language_id, references(:languages)

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:words, [:text, :language_id], unique: true)
  end
end
