defmodule LanguageTranslator.GoogleApi.AuthTest do
  use LanguageTranslator.DataCase
  import Mock

  alias LanguageTranslator.GoogleApi.Auth
  alias LanguageTranslator.Config

  test "headers/0 returns the correct headers" do
    with_mock Config,
      google_translate_access_key: fn -> "test-access-key" end,
      google_translate_project_id: fn -> "test-project-id" end do
      expected_headers = [
        {"Content-Type", "application/json; charset=utf-8"},
        {"Authorization", "Bearer test-access-key"},
        {"X-Goog-User-Project", "test-project-id"}
      ]

      assert Auth.headers() == expected_headers
    end
  end
end
