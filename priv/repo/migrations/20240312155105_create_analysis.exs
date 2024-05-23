defmodule LanguageTranslator.Repo.Migrations.CreateAnalysis do
  use Ecto.Migration

  def change do
    up = "CREATE TYPE analysis_status AS ENUM ('pending', 'processing', 'completed', 'failed')"
    down = "DROP TYPE analysis_status"

    execute up, down

    create table(:analysis) do
      add :description, :text
      add :status, :text, default: "pending", null: false
      add :type, :text, default: "manual", null: false

      add :source_language_code, references(:languages, column: :code, type: :text), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    execute """
    ALTER TABLE analysis
      ADD COLUMN id_text text 
      GENERATED ALWAYS AS (id::text) STORED;
    """

    execute """
    CREATE INDEX analysis_searchable_id_text_index
      ON analysis
      USING GIN(id_text gin_trgm_ops);
    """

    execute """
    CREATE INDEX analysis_searchable_description_index
      ON analysis
      USING GIN(description gin_trgm_ops);
    """

    execute """
    CREATE INDEX analysis_searchable_status_index
      ON analysis
      USING GIN(status gin_trgm_ops);
    """

    execute """
    CREATE INDEX analysis_searchable_source_language_code_index
      ON analysis
      USING GIN(source_language_code gin_trgm_ops);
    """
  end
end
