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
alias LanguageTranslator.Models.Analysis
alias Ecto.Changeset

if Application.get_env(:language_translator, :env) == :dev do
  User.registration_changeset(%User{}, %{
    username: "admin",
    email: "admin@language.com",
    password: "ZdravaParola@123",
    is_admin: true,
    main_language_code: "bg",
    confirmed_at: DateTime.utc_now()
  })
  |> Changeset.change(%{is_admin: true})
  |> Repo.insert!()

  User.registration_changeset(%User{}, %{
    username: "misho",
    email: "mixaildobrev@gmail.com",
    password: "ZdravaParola@123",
    main_language_code: "en",
    confirmed_at: DateTime.utc_now()
  })
  |> Repo.insert!()

  User.registration_changeset(%User{}, %{
    username: "anoniq",
    email: "anoniq@gmail.com",
    password: "ZdravaParola@123",
    main_language_code: "bg",
    confirmed_at: DateTime.utc_now()
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

  # |> Translator.async_translate()

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

  # |> Translator.async_translate()

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

  # |> Translator.async_translate()

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

  # |> Translator.async_translate()

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

  # |> Translator.async_translate()

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

  # |> Translator.async_translate()

  portuguese_words = %{
    "GreetingsAndPoliteness" => [
      # Hello
      "Olá",
      # Good morning
      "Bom dia",
      # Good afternoon
      "Boa tarde",
      # Good night
      "Boa noite",
      # Goodbye
      "Tchau",
      # Please
      "Por favor",
      # Thank you
      "Obrigado (m)/Obrigada (f)",
      # Sorry
      "Desculpe",
      # Excuse me
      "Com licença",
      # See you later
      "Até logo",
      # Greetings
      "Saudações",
      # Welcome
      "Bem-vindo (m)/Bem-vinda (f)"
    ],
    "AffirmationAndNegation" => [
      # Yes
      "Sim",
      # No
      "Não",
      # Of course
      "Claro",
      # Maybe
      "Talvez",
      # Certainly
      "Certamente",
      # Never
      "Nunca",
      # Always
      "Sempre",
      # Possibly
      "Possivelmente",
      # Definitely
      "Definitivamente",
      # No way
      "De jeito nenhum"
    ],
    "Relationships" => [
      # Love
      "Amor",
      # Friend
      "Amigo (m)/Amiga (f)",
      # Family
      "Família",
      # Child
      "Criança",
      # Man
      "Homem",
      # Woman
      "Mulher",
      # Parents
      "Pais",
      # Son
      "Filho",
      # Daughter
      "Filha",
      # Husband
      "Marido",
      # Wife
      "Esposa",
      # Grandfather
      "Avô",
      # Grandmother
      "Avó"
    ],
    "DailyLife" => [
      # House
      "Casa",
      # Work
      "Trabalho",
      # School
      "Escola",
      # Food
      "Comida",
      # Water
      "Água",
      # Car
      "Carro",
      # Book
      "Livro",
      # Telephone
      "Telefone",
      # Computer
      "Computador",
      # Watch
      "Relógio",
      # Clothes
      "Roupa",
      # Money
      "Dinheiro",
      # Furniture
      "Móvel"
    ],
    "NatureAndPlaces" => [
      # Sun
      "Sol",
      # Sea
      "Mar",
      # Beach
      "Praia",
      # Mountain
      "Montanha",
      # City
      "Cidade",
      # Country
      "País",
      # Forest
      "Floresta",
      # River
      "Rio",
      # Lake
      "Lago",
      # Field
      "Campo",
      # Island
      "Ilha",
      # Desert
      "Deserto",
      # Park
      "Parque"
    ],
    "Travel" => [
      # Car
      "Carro",
      # Airplane
      "Avião",
      # Bus
      "Ônibus",
      # Train
      "Trem",
      # Bicycle
      "Bicicleta",
      # Motorcycle
      "Moto",
      # Boat
      "Barco",
      # Taxi
      "Táxi",
      # Truck
      "Caminhão",
      # Station
      "Estação",
      # Airport
      "Aeroporto",
      # Port
      "Porto",
      # Bus station
      "Rodoviária"
    ]
  }

  {first_first_portugese_words_description, first_portugese_words} = Enum.at(portuguese_words, 0)

  Analysis.changeset(%Analysis{}, %{
    description: first_first_portugese_words_description,
    user_id: 1,
    source_language_code: "pt",
    status: "processing",
    is_public: true,
    source_words: first_portugese_words
  })
  |> Repo.insert!()

  {second_first_portugese_words_description, second_portugese_words} =
    Enum.at(portuguese_words, 1)

  Analysis.changeset(%Analysis{}, %{
    description: second_first_portugese_words_description,
    user_id: 2,
    source_language_code: "pt",
    status: "processing",
    is_public: true,
    source_words: second_portugese_words
  })
  |> Repo.insert!()

  {third_first_portugese_words_description, third_portugese_words} = Enum.at(portuguese_words, 2)

  Analysis.changeset(%Analysis{}, %{
    description: third_first_portugese_words_description,
    user_id: 2,
    source_language_code: "pt",
    status: "processing",
    is_public: false,
    source_words: third_portugese_words
  })
  |> Repo.insert!()

  {fourth_first_portugese_words_description, fourth_portugese_words} =
    Enum.at(portuguese_words, 3)

  Analysis.changeset(%Analysis{}, %{
    description: fourth_first_portugese_words_description,
    user_id: 3,
    source_language_code: "pt",
    status: "processing",
    is_public: false,
    source_words: fourth_portugese_words
  })
  |> Repo.insert!()

  {fifth_first_portugese_words_description, fifth_portugese_words} = Enum.at(portuguese_words, 4)

  Analysis.changeset(%Analysis{}, %{
    description: fifth_first_portugese_words_description,
    user_id: 3,
    source_language_code: "pt",
    status: "processing",
    is_public: false,
    source_words: fifth_portugese_words
  })
  |> Repo.insert!()

  {sixth_first_portugese_words_description, sixth_portugese_words} = Enum.at(portuguese_words, 5)

  Analysis.changeset(%Analysis{}, %{
    description: sixth_first_portugese_words_description,
    user_id: 3,
    source_language_code: "pt",
    status: "processing",
    is_public: false,
    source_words: sixth_portugese_words
  })
  |> Repo.insert!()

  Analysis.changeset(%Analysis{}, %{
    description: "#{first_first_portugese_words_description} repeated",
    user_id: 1,
    source_language_code: "pt",
    status: "processing",
    is_public: true,
    source_words: first_portugese_words
  })
  |> Repo.insert!()
end
