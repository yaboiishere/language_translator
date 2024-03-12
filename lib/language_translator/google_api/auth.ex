defmodule LanguageTranslator.GoogleApi.Auth do
  @moduledoc """
  This module is responsible for handling the authentication with Google Cloud.
  """

  alias LanguageTranslator.Config

  def headers do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Authorization", "Bearer #{Config.google_translate_access_key()}"},
      {"X-Goog-User-Project", Config.google_translate_project_id()}
    ]
  end
end
