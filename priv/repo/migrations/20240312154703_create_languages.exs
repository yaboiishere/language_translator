defmodule LanguageTranslator.Repo.Migrations.CreateLanguages do
  use Ecto.Migration

  def change do
    create table(:languages, primary_key: false) do
      add :code, :text, primary_key: true
      add :display_name, :text

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:languages, [:code], unique: true)

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "SET pg_trgm.similarity_threshold = 0.0;"

    execute """
    CREATE INDEX languages_searchable_display_name_index
      ON languages
      USING GIN(display_name gin_trgm_ops);
    """

    execute """
    CREATE INDEX languages_searchable_code_index
      ON languages
      USING GIN(code gin_trgm_ops);
    """
  end
end
