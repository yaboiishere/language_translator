defmodule LanguageTranslator.Repo.Migrations.AddUserFieldsToAnalysis do
  use Ecto.Migration

  def change do
    alter table(:analysis) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :is_public, :boolean, default: false, null: false
      add :source_words, {:array, :string}, null: false
    end
  end
end
