import Config

config :language_translator, env: :test
# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :language_translator, LanguageTranslator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "language_translator_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :language_translator, LanguageTranslatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "rH5BAHRDpE+uvdrGWDztTHE5j0pRqt681DlvKE1XxUy7+3bUOwsd32Q9SyGFVRJW",
  server: true

# In test we don't send emails.
config :language_translator, LanguageTranslator.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :debug, backends: []

config :language_translator, sql_sandbox: true

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
config :language_translator, :http_adapter, LanguageTranslator.TestHttpAdapter
