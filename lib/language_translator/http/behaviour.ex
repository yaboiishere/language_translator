defmodule LanguageTranslator.Http.Behaviour do
  @moduledoc """
  Determines what a HTTP client should have; used for abstracting over HTTP clients so we can mock
  them for testing purposes and use the same interface in production code.
  """

  @typep url :: binary()
  @typep body :: {:form, [{atom(), any()}]}
  @typep headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @typep options :: Keyword.t()

  @callback post(url, body, headers, options) :: {:ok, map()} | {:error, binary() | map()}

  @callback get(url, headers, options) :: {:ok, map()} | {:error, binary() | map()}
end
