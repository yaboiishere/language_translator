defmodule LanguageTranslator.Http.Wrapper do
  @moduledoc """
  Wrapper module for HTTP clients, abstracts over whether we use a real HTTP client or a mocked
  one for tests.
  """
  require Logger

  @behaviour LanguageTranslator.Http.Behaviour

  def impl(), do: Application.get_env(:language_translator, :http_adapter)

  def get(url, headers \\ [], options \\ []) do
    url
    |> get_url(headers, options)
    |> process_response_body(url)
  end

  def post(url, body, headers \\ [], options \\ []) do
    url
    |> post_url(body, headers, options)
    |> process_response_body(url)
  end

  defp get_url(url, headers, options) do
    if impl() == Finch do
      :get
      |> Finch.build(url, headers, nil, options)
      |> Finch.request(LanguageTranslator.Finch)
    else
      impl().get(url, headers, options)
    end
  end

  defp post_url(url, body, headers, options) do
    if impl() == Finch do
      :post
      |> Finch.build(url, headers, body, options)
      |> Finch.request(LanguageTranslator.Finch, options)
    else
      impl().post(url, body, headers, options)
    end
  end

  # defp process_response_body(
  #        {:ok, %HTTPoison.Response{status_code: status_code, body: body}},
  #        _url
  #      )
  #      when status_code in [200, 201, 204] do
  #   {:ok, parse_body(body)}
  # end
  #
  # defp process_response_body(
  #        {:ok, %HTTPoison.Response{status_code: status_code, body: body, headers: _headers}},
  #        url
  #      ) do
  #   {
  #     :error,
  #     %{
  #       status_code: status_code,
  #       body: parse_body(body),
  #       url: url
  #     }
  #   }
  # end

  def process_response_body({:ok, %Finch.Response{status: status, body: body}}, _url)
      when status in [200, 201, 204] do
    {:ok, parse_body(body)}
  end

  def process_response_body(
        {:ok, %Finch.Response{status: status, body: body, headers: _headers}},
        url
      ) do
    {
      :error,
      %{
        status_code: status,
        body: parse_body(body),
        url: url
      }
    }
  end

  # defp process_response_body({:error, %HTTPoison.Error{reason: {_, reason}}}, _url) do
  #   {:error, reason}
  # end
  #
  # defp process_response_body({:error, %HTTPoison.Error{reason: reason}}, _url) do
  #   {:error, reason}
  # end

  def process_response_body({:error, reason}, _url) do
    {:error, reason}
  end

  def parse_body(body) do
    body
    |> Jason.decode()
    |> case do
      {:ok, json} -> json
      {:error, _} -> body
    end
  end
end
