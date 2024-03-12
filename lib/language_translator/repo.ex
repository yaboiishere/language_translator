defmodule LanguageTranslator.Repo do
  use Ecto.Repo,
    otp_app: :language_translator,
    adapter: Ecto.Adapters.Postgres
end
