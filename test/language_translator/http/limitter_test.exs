defmodule LanguageTranslator.Http.LimitterTest do
  use LanguageTranslator.DataCase
  import Kernel, except: [ref: 0]
  import Mock

  test "basic functionality" do
    assert Process.whereis(LanguageTranslator.Http.Limitter) != nil
  end

  test "request handling" do
    ref = make_ref()
    response_body = %{data: "response"}

    with_mock(LanguageTranslator.Http.Wrapper, get: fn _, _ -> {:ok, response_body} end) do
      LanguageTranslator.Http.Limitter.make_request(:get, "http://example.com", %{}, %{}, ref)

      assert_receive {:response, ^ref, _response_body}
    end
  end

  test "rate limiting" do
    ref1 = make_ref()
    ref2 = make_ref()
    response_body = %{data: "response"}

    with_mock(LanguageTranslator.Http.Wrapper, get: fn _, _ -> {:ok, response_body} end) do
      LanguageTranslator.Http.Limitter.make_request(:get, "http://example.com", %{}, %{}, ref1)

      LanguageTranslator.Http.Limitter.make_request(:get, "http://example.com", %{}, %{}, ref2)

      assert_receive {:response, ^ref1, _response_body}
      assert_receive {:response, ^ref2, _response_body}
    end
  end

  test "error handling" do
    ref = make_ref()

    with_mock(LanguageTranslator.Http.Wrapper, get: fn _, _ -> {:error, "Connection failed"} end) do
      LanguageTranslator.Http.Limitter.make_request(:get, "http://example.com", %{}, %{}, ref)

      assert_receive {:response, ^ref, {:error, "Connection failed"}}
    end
  end
end

