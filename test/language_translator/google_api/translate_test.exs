defmodule LanguageTranslator.GoogleApi.TranslateTest do
  use LanguageTranslator.DataCase
  import Mock

  alias LanguageTranslator.GoogleApi.Translate
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Http.Wrapper
  alias LanguageTranslator.Http.Cache
  alias LanguageTranslator.Config

  describe "get_languages/0" do
    test "returns the list of supported languages" do
      with_mocks([
        {Wrapper, [:passthrough],
         [
           get: fn _, _ ->
             {:ok,
              %{
                "languages" => [
                  %{
                    "displayName" => "English",
                    "languageCode" => "en",
                    "supportTarget" => true,
                    "supportSource" => true
                  }
                ]
              }}
           end
         ]},
        {Config, [:passthrough],
         [
           google_translate_url: fn ->
             "https://fake.translation.googleapis.com/language/translate/v2"
           end
         ]}
      ]) do
        assert {:ok, [%Language{display_name: "English", code: "en"}]} = Translate.get_languages()
      end
    end
  end

  describe "translate/3" do
    setup do
      {:ok,
       source_language: %Language{code: "en", display_name: "English"},
       target_language: %Language{code: "es", display_name: "Spanish"}}
    end

    test "returns translation from cache if available", %{
      source_language: source_language,
      target_language: target_language
    } do
      {:ok, cache_pid} =
        LanguageTranslator.Http.Cache.start_link(%{size: 100, name: LanguageTranslator.Http.Cache})

      Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)

      Cache.store("hello", source_language, "hola", target_language)
      assert {:ok, "hola"} = Translate.translate(source_language, target_language, "hello")
    end

    test "fetches translation from API if not in cache", %{
      source_language: source_language,
      target_language: target_language
    } do
      {:ok, cache_pid} =
        LanguageTranslator.Http.Cache.start_link(%{size: 100, name: LanguageTranslator.Http.Cache})

      Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)

      with_mocks([
        {Wrapper, [:passthrough],
         [
           post: fn _, _, _ -> {:ok, %{"translations" => [%{"translatedText" => "hola"}]}} end
         ]},
        {Config, [:passthrough],
         [
           google_translate_url: fn ->
             "https://fake.translation.googleapis.com/language/translate/v2"
           end
         ]}
      ]) do
        assert {:ok, "hola"} = Translate.translate(source_language, target_language, "hello")
      end
    end

    test "stores translation in cache after fetching from API", %{
      source_language: source_language,
      target_language: target_language
    } do
      {:ok, cache_pid} =
        LanguageTranslator.Http.Cache.start_link(%{size: 100, name: LanguageTranslator.Http.Cache})

      Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)

      with_mocks([
        {Wrapper, [:passthrough],
         [
           post: fn _, _, _ -> {:ok, %{"translations" => [%{"translatedText" => "hola"}]}} end
         ]},
        {Config, [:passthrough],
         [
           google_translate_url: fn ->
             "https://fake.translation.googleapis.com/language/translate/v2"
           end
         ]}
      ]) do
        assert {:ok, "hola"} = Translate.translate(source_language, target_language, "hello")
        assert Cache.fetch("hello", source_language, target_language) == "hola"
      end
    end

    test "returns error if API call fails", %{
      source_language: source_language,
      target_language: target_language
    } do
      {:ok, cache_pid} =
        LanguageTranslator.Http.Cache.start_link(%{size: 100, name: LanguageTranslator.Http.Cache})

      Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)

      with_mocks([
        {Wrapper, [:passthrough],
         [
           post: fn _, _, _ -> {:error, %{"error" => "some error"}} end
         ]},
        {Config, [:passthrough],
         [
           google_translate_url: fn ->
             "https://fake.translation.googleapis.com/language/translate/v2"
           end
         ]}
      ]) do
        assert {:error, %{"error" => "some error"}} =
                 Translate.translate(source_language, target_language, "hello")
      end
    end
  end
end

