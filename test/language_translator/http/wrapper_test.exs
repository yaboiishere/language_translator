defmodule LanguageTranslator.Http.WrapperTest do
  use LanguageTranslator.DataCase
  import Mock

  setup do
    Application.put_env(:language_translator, :http_adapter, Finch)
    :ok
  end

  test "get request - successful response" do
    url = "http://example.com"
    expected_body = %{"data" => "response"}

    with_mock(Finch, [:passthrough],
      request: fn _url, _options ->
        {:ok, %Finch.Response{status: 200, body: Jason.encode!(expected_body)}}
      end
    ) do
      response = LanguageTranslator.Http.Wrapper.get(url)

      assert response == {:ok, expected_body}
    end
  end

  test "get request - error response" do
    url = "http://example.com"

    with_mock(Finch, [:passthrough], request: fn _url, _options -> {:error, :timeout} end) do
      response = LanguageTranslator.Http.Wrapper.get(url)

      assert response == {:error, :timeout}
    end
  end

  test "post request - successful response" do
    url = "http://example.com"
    body = %{text: "data"}
    expected_body = %{"data" => "response"}

    with_mock(
      Finch,
      [:passthrough],
      request: fn _url, _body, _options ->
        {:ok, %Finch.Response{status: 201, body: Jason.encode!(expected_body)}}
      end
    ) do
      response = LanguageTranslator.Http.Wrapper.post(url, Jason.encode!(body))

      assert response == {:ok, expected_body}
    end
  end

  test "post request - error response" do
    url = "http://example.com"
    body = %{"text" => "data"}

    with_mock(Finch, [:passthrough], request: fn _url, _body, _options -> {:error, :timeout} end) do
      response = LanguageTranslator.Http.Wrapper.post(url, body)

      assert response == {:error, :timeout}
    end
  end

  test "parsing response body - successful JSON" do
    body = ~s({"key": "value"})

    parsed_body = LanguageTranslator.Http.Wrapper.parse_body(body)

    assert parsed_body == %{"key" => "value"}
  end

  test "parsing response body - invalid JSON" do
    body = "invalid json"

    parsed_body = LanguageTranslator.Http.Wrapper.parse_body(body)

    assert parsed_body == "invalid json"
  end
end

