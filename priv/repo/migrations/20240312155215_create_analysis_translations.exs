defmodule LanguageTranslator.Repo.Migrations.CreateAnalysisTranslations do
  use Ecto.Migration

  def change do
    create table(:analysis_translations) do
      add :analysis_id, references(:analysis)
      add :translation_id, references(:translations)

      timestamps(type: :utc_datetime)
    end

    create index(:analysis_translations, [:analysis_id, :translation_id], unique: true)
  end
end
