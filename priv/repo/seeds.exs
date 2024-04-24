# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LanguageTranslator.Repo.insert!(%LanguageTranslator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias LanguageTranslator.Repo
alias LanguageTranslator.Accounts.User
alias Ecto.Changeset

User.registration_changeset(%User{}, %{
  username: "admin",
  email: "admin@language.com",
  password: "ZdravaParola@123",
  is_admin: true
})
|> Changeset.change(%{is_admin: true})
|> Repo.insert!()

User.registration_changeset(%User{}, %{
  username: "misho",
  email: "mixaildobrev@gmail.com",
  password: "ZdravaParola@123"
})
|> Repo.insert!()

User.registration_changeset(%User{}, %{
  username: "anoniq",
  email: "anoniq@gmail.com",
  password: "ZdravaParola@123"
})
|> Repo.insert!()
