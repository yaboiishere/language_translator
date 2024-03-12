defmodule LanguageTranslator.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :source_word_id, references(:words)
      add :target_word_id, references(:words)

      timestamps(type: :utc_datetime)
    end

    create index(:translations, [:source_word_id, :target_word_id], unique: true)
  end
end
