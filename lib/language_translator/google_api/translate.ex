defmodule LanguageTranslator.GoogleApi.Translate do
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Config
  alias LanguageTranslator.GoogleApi.Auth
  alias LanguageTranslator.Http.Wrapper
  require Logger

  @spec get_languages() :: {:ok, map()} | {:error, map()}
  def get_languages() do
    "#{Config.google_translate_url()}/supportedLanguages?displayLanguageCode=en"
    |> Wrapper.get(Auth.headers())
    |> parse_response()
  end

  def translate(%Language{code: source_code}, %Language{code: target_code}, text) do
    url = "#{Config.google_translate_url()}:translateText"

    body =
      %{
        sourceLanguageCode: source_code,
        targetLanguageCode: target_code,
        contents: text,
        mimeType: "text/plain"
      }
      |> Jason.encode!()

    url
    |> Wrapper.post(body, Auth.headers())
    |> parse_response()
  end

  defp parse_response({:ok, response}) do
    {:ok, parse_response(response)}
  end

  defp parse_response(%{"languages" => languages}) do
    Enum.flat_map(languages, fn %{
                                  "displayName" => display_name,
                                  "languageCode" => code,
                                  "supportTarget" => supportTarget,
                                  "supportSource" => supportSource
                                } ->
      if supportTarget && supportSource do
        [%Language{display_name: display_name, code: code}]
      else
        []
      end
    end)
  end

  defp parse_response(%{"translations" => [translation | _]}) do
    Map.get(translation, "translatedText")
  end

  defp parse_response({:error, _response} = response) do
    response
  end

  defp parse_response(response) do
    Logger.error("Unexpected response: #{inspect(response)}")
    {:error, %{message: "Unexpected response", response: response}}
  end
end
