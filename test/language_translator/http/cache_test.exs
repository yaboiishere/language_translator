defmodule LanguageTranslator.Http.CacheTest do
  use LanguageTranslator.DataCase

  alias LanguageTranslator.Http.Cache
  alias LanguageTranslator.Models.Language

  describe "fetch/3" do
    setup do
      {:ok, cache_pid} = Cache.start_link(%{size: 100})
      {:ok, cache_pid: cache_pid}
    end

    test "returns translation from cache if available" do
      source_language = %Language{code: "en"}
      target_language = %Language{code: "es"}
      Cache.store("hello", source_language, "hola", target_language)
      assert "hola" = Cache.fetch("hello", source_language, target_language)
    end

    test "returns nil if translation is not in cache", %{cache_pid: cache_pid} do
      source_language = %Language{code: "en"}
      target_language = %Language{code: "es"}
      Ecto.Adapters.SQL.Sandbox.allow(LanguageTranslator.Repo, self(), cache_pid)
      assert nil == Cache.fetch("hello", source_language, target_language)
    end
  end

  describe "store/4" do
    setup do
      {:ok, cache_pid} = Cache.start_link(%{size: 100})
      {:ok, cache_pid: cache_pid}
    end

    test "stores translation in cache" do
      source_language = %Language{code: "en"}
      target_language = %Language{code: "es"}
      Cache.store("hello", source_language, "hola", target_language)
      assert "hola" = Cache.fetch("hello", source_language, target_language)
    end

    test "overwrites existing translation in cache" do
      source_language = %Language{code: "en"}
      target_language = %Language{code: "es"}
      Cache.store("hello", source_language, "hola", target_language)
      Cache.store("hello", source_language, "bonjour", target_language)
      assert "bonjour" = Cache.fetch("hello", source_language, target_language)
    end
  end
end

