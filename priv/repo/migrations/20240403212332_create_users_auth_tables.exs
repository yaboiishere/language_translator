defmodule LanguageTranslator.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :username, :text, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :is_admin, :boolean, default: false

      add(
        :main_language_code,
        references(:languages, column: "code", type: :text, on_delete: :nilify_all),
        null: false
      )

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    execute """
    ALTER TABLE users
      ADD COLUMN id_text text
      GENERATED ALWAYS AS (id::text) STORED;
    """

    execute """
    CREATE INDEX users_searchable_id_text_index
      ON users
      USING GIN(id_text gin_trgm_ops);
    """

    execute """
    CREATE INDEX users_searchable_email_index
      ON users
      USING GIN(email gin_trgm_ops);
    """

    execute """
    CREATE INDEX users_searchable_username_index
      ON users
      USING GIN(username gin_trgm_ops);
    """
  end
end
