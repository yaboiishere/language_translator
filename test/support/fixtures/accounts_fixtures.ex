defmodule LanguageTranslator.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LanguageTranslator.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "MnogoSlojnaParola@123"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      username: "user#{System.unique_integer()}",
      main_language_code: random_language_code()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> LanguageTranslator.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  defp random_language_code() do
    ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "zh", "ru"]
    |> Enum.random()
  end
end
