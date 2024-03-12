defmodule LanguageTranslator.Config do
  def google_translate() do
    Application.get_env(:language_translator, :google_translate)
  end

  def google_translate_access_key do
    google_translate()[:access_token]
  end

  def google_translate_project_id do
    google_translate()[:project_id]
  end

  def google_translate_url do
    "#{google_translate_base_url()}#{google_translate_project_id()}/locations/global"
  end

  defp google_translate_base_url do
    google_translate()[:base_url]
  end
end
