defmodule LanguageTranslator.TranslateTest do
  use ExUnit.Case, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias LanguageTranslator.GoogleApi.Translate
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  setup do
    :ok = Sandbox.checkout(Repo)
    :ok
  end

  @tag :integration
  test "translates a word" do
    english = %Language{code: "en", display_name: "English"}
    bulgarian = %Language{code: "bg", display_name: "Bulgarian"}
    spanish = %Language{code: "es", display_name: "Spanish"}

    assert Translate.translate(english, spanish, "hello") == {:ok, "Hola"}
    assert Translate.translate(bulgarian, english, "Здравей") == {:ok, "Hello"}
  end

  @tag :integration
  test "translates a word to all languages" do
    {:ok, available_languages} = Translate.get_languages()

    translations = LanguageTranslator.Translator.Aggregator.translate("bg", "hello")
    assert Enum.count(translations) == Enum.count(available_languages)
    assert Enum.uniq(translations) == translations
  end

  @tag :integration
  test "translates a word to all languages with n concurrent analyses" do
    {:ok, available_languages} = Translate.get_languages()

    words = [
      {"bg", "Здравей"},
      {"en", "Hello"},
      {"es", "Hola"},
      {"fr", "Bonjour"},
      {"de", "Hallo"},
      {"it", "Ciao"},
      {"ru", "Привет"},
      {"tr", "Merhaba"},
      {"ar", "مرحبا"},
      {"ja", "こんにちは"}
    ]

    Enum.each(words, fn {lang, word} ->
      spawn(fn ->
        Sandbox.checkout(Repo)
        translations = LanguageTranslator.Translator.Aggregator.translate(lang, word)
        assert Enum.count(translations) == Enum.count(available_languages)
        assert Enum.uniq(translations) == translations
      end)
    end)
  end
end
