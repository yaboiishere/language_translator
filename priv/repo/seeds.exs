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
alias LanguageTranslator.Translator
alias LanguageTranslator.Accounts.User
alias LanguageTranslator.Models.Language
alias LanguageTranslator.Models.Analysis
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

# Language.changeset(%Language{}, %{
#   display_name: "German",
#   code: "de"
# })
# |> Repo.insert()

colors_in_german = [
  "rot",
  "blau",
  "gelb",
  "grün",
  "schwarz",
  "weiß",
  "braun",
  "orange",
  "rosa",
  "lila"
]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in German",
  user_id: 1,
  source_language_code: "de",
  status: "processing",
  is_public: true,
  source_words: colors_in_german
})
|> Repo.insert!()

# Language.changeset(%Language{}, %{
#   display_name: "English",
#   code: "en"
# })
# |> Repo.insert()

colors_in_english = [
  "red",
  "blue",
  "yellow",
  "green",
  "black",
  "white",
  "brown",
  "orange",
  "pink",
  "purple"
]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in English",
  user_id: 1,
  source_language_code: "en",
  status: "processing",
  is_public: true,
  source_words: colors_in_english
})
|> Repo.insert!()
|> Translator.async_translate()

# Language.changeset(%Language{}, %{
#   display_name: "Spanish",
#   code: "es"
# })
# |> Repo.insert()

colors_in_spanish = [
  "Rojo",
  "Verde",
  "Negro",
  "Azul",
  "Rosa",
  "Marrón",
  "Laranja",
  "Amarillo",
  "Morado",
  "Blanco"
]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in Spanish",
  user_id: 1,
  source_language_code: "es",
  status: "processing",
  is_public: true,
  source_words: colors_in_spanish
})
|> Repo.insert!()
|> Translator.async_translate()

# Language.changeset(%Language{}, %{
#   display_name: "Armenian",
#   code: "hy"
# })
# |> Repo.insert()

colors_in_armenian =
  [
    "կարմիր",
    "կանաչ",
    "կապույտ",
    "դեղին",
    "մանուշակագույն",
    "շագանակագույն",
    "սպիտակ",
    "սև",
    "նարնջագույն",
    "վարդագույն",
    "մոխրագույն",
    "մանուշակագույն",
    "փիրուզագույն",
    "մուգ մանուշակագույն",
    "դեղնավարդագույն",
    "երկնագույն",
    "դեղնականաչ",
    "թուխ",
    "ոսկեգույն",
    "դարչնագույն"
  ]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in Armenian",
  user_id: 1,
  source_language_code: "hy",
  status: "processing",
  is_public: true,
  source_words: colors_in_armenian
})
|> Repo.insert!()
|> Translator.async_translate()

# Language.changeset(%Language{}, %{
#   display_name: "Bulgarian",
#   code: "bg"
# })
# |> Repo.insert()

colors_in_bulgarian =
  [
    "червен",
    "зелен",
    "син",
    "жълт",
    "лилав",
    "кафяв",
    "бял",
    "черен",
    "оранжев",
    "розов",
    "сив",
    "лилав",
    "тюркоаз",
    "кафяв"
  ]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in Bulgarian",
  user_id: 1,
  source_language_code: "bg",
  status: "processing",
  is_public: true,
  source_words: colors_in_bulgarian
})
|> Repo.insert!()
|> Translator.async_translate()

# Language.changeset(%Language{}, %{
#   display_name: "Italian",
#   code: "it"
# })
# |> Repo.insert()

colors_in_italian = [
  "Rosso",
  "Verde",
  "Nero",
  "Azzurro",
  "Rosa",
  "Marrone",
  "Arancio",
  "Giallo",
  "Viola",
  "Bianco"
]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in Italian",
  user_id: 1,
  source_language_code: "it",
  status: "processing",
  is_public: true,
  source_words: colors_in_italian
})
|> Repo.insert!()
|> Translator.async_translate()

# Language.changeset(%Language{}, %{
#   display_name: "Portuguese",
#   code: "pt"
# })
# |> Repo.insert()

colors_in_portugese =
  [
    "Vermelho",
    "Verde",
    "Preto",
    "Azul",
    "Rosa",
    "Marrom",
    "Laranja",
    "Amarelo",
    "Roxo",
    "Branco"
  ]

Analysis.changeset(%Analysis{}, %{
  description: "Colors in Portuguese",
  user_id: 1,
  source_language_code: "pt",
  status: "processing",
  is_public: true,
  source_words: colors_in_portugese
})
|> Repo.insert!()
|> Translator.async_translate()
