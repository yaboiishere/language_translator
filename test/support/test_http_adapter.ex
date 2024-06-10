defmodule LanguageTranslator.TestHttpAdapter do
  def get(_url, _headers \\ [], _options \\ []) do
    raise "Not implemented for test"
  end

  def post(_url, _body, _headers \\ [], _options \\ []) do
    raise "Not implemented for test"
  end
end
