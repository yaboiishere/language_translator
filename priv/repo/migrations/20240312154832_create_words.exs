defmodule LanguageTranslator.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
      add :text, :text, null: false
      add :romanized_text, :text, null: false
      add :language_code, references(:languages, column: :code, type: :text), null: false

      add :inserted_at, :utc_datetime_usec, default: fragment("NOW()")
      add :updated_at, :utc_datetime_usec, default: fragment("NOW()")
    end

    create index(:words, [:language_code, :text], unique: true)

    execute """
    ALTER TABLE words
    ADD COLUMN id_text text 
      GENERATED ALWAYS AS (id::text) STORED;
    """

    execute """
    CREATE INDEX words_searchable_id_text_index
      ON words
      USING GIN(id_text gin_trgm_ops);
    """

    execute """
    CREATE INDEX words_searchable_text_index
      ON words
      USING GIN(text gin_trgm_ops);
    """

    execute """
    CREATE INDEX words_searchable_romanized_text_index
      ON words
      USING GIN(romanized_text gin_trgm_ops);
    """

    execute """
    CREATE INDEX words_searchable_language_code_index
      ON words
      USING GIN(language_code gin_trgm_ops);
    """
  end
end
