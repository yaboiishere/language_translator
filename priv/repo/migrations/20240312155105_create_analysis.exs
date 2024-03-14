defmodule LanguageTranslator.Repo.Migrations.CreateAnalysis do
  use Ecto.Migration

  def change do
    up = "CREATE TYPE analysis_status AS ENUM ('pending', 'processing', 'completed', 'failed')"
    down = "DROP TYPE analysis_status"

    execute up, down

    create table(:analysis) do
      add :description, :text
      add :status, :analysis_status, default: "pending", null: false

      add :source_language_code, references(:languages, column: :code, type: :text), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end
  end
end
