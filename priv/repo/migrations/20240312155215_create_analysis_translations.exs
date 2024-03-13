defmodule LanguageTranslator.Repo.Migrations.CreateAnalysisTranslations do
  use Ecto.Migration

  def change do
    create table(:analysis_translations) do
      add :analysis_id, references(:analysis), null: false
      add :translation_id, references(:translations), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:analysis_translations, [:analysis_id, :translation_id], unique: true)
  end
end
