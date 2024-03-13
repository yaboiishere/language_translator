defmodule LanguageTranslator.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :text, :text, null: false
      add :language, references(:languages, column: :code, type: :text), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:words, [:language, :text], unique: true)
  end
end
