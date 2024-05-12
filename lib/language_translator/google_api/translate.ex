defmodule LanguageTranslator.GoogleApi.Translate do
  alias LanguageTranslator.Http.Cache
  alias LanguageTranslator.Http.Limitter
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

  def translate(
        %Language{code: source_code} = source_language,
        %Language{code: target_code} = target_language,
        text
      ) do
    text
    |> Cache.fetch(source_language, target_language)
    |> case do
      nil ->
        Logger.info("Cache miss for #{text}")
        url = "#{Config.google_translate_url()}:translateText"

        body =
          %{
            sourceLanguageCode: source_code,
            targetLanguageCode: target_code,
            contents: text,
            mimeType: "text/plain"
          }
          |> Jason.encode!()

        translated_word =
          :post
          |> Limitter.make_request(url, Auth.headers(), body)
          |> parse_response()

        case translated_word do
          {:ok, translated_word} ->
            Cache.store(text, source_language, translated_word, target_language)
            {:ok, translated_word}

          {:error, _} ->
            {:ok, translated_word}
        end

      word when is_binary(word) ->
        {:ok, word}
    end
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
    translation
    |> Map.get("translatedText")
    |> String.downcase()
  end

  defp parse_response({:error, _response} = response) do
    response
  end

  defp parse_response(response) do
    Logger.error("Unexpected response: #{inspect(response)}")
    {:error, %{message: "Unexpected response", response: response}}
  end
end
