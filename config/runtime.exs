import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/language_translator start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :language_translator, LanguageTranslatorWeb.Endpoint, server: true
end

google_project_id = System.get_env("GOOGLE_PROJECT_ID") || raise "GOOGLE_PROJECT_ID is not set"

config :language_translator, :google_translate,
  base_url: "https://translation.googleapis.com/v3/projects/",
  project_id: google_project_id

username = System.get_env("POSTGRES_USER") || raise "PGUSER is not set"
password = System.get_env("POSTGRES_PASSWORD") || raise "PGPASSWORD is not set"
db_host = System.get_env("POSTGRES_HOST") || raise "PGHOST is not set"
db_port = System.get_env("POSTGRES_PORT") || raise "PGPORT is not set"
db = System.get_env("POSTGRES_DB") || raise "PGDATABASE is not set"

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

config :language_translator, LanguageTranslator.Repo,
  username: username,
  password: password,
  database: db,
  port: String.to_integer(db_port),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  socket_options: maybe_ipv6,
  queue_target: 60_000,
  queue_interval: 160_000,
  timeout: 160_000

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :language_translator, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :language_translator, LanguageTranslatorWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true,
    check_origin: [
      "http://localhost:443",
      "https://language-translator.info"
    ]

  config :logger,
    backends: [:console, LokiLogger]

  loki_host = System.get_env("LOKI_HOST") || "http://localhost:3100"

  config :logger, :loki_logger,
    level: :debug,
    format: "$metadata level=$level $message",
    metadata: :all,
    max_buffer: 300,
    loki_labels: %{application: "language_translator", elixir_node: node()},
    loki_host: loki_host

  email_host = System.get_env("EMAIL_HOST") || throw("EMAIL_HOST is not set")
  email_port = String.to_integer(System.get_env("EMAIL_PORT") || throw("EMAIL_PORT is not set"))
  email_username = System.get_env("EMAIL_USER") || throw("EMAIL_USER is not set")
  email_password = System.get_env("EMAIL_PASSWORD") || throw("EMAIL_PASSWORD is not set")

  config :language_translator, LanguageTranslator.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: email_host,
    port: email_port,
    username: email_username,
    password: email_password,
    tls: :if_available,
    ssl: false,
    auth: :if_available,
    retries: 2,
    no_mx_lookups: false,
    ssl_opts: [
      verify: :verify_none,
      depth: 0
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :language_translator, LanguageTranslatorWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :language_translator, LanguageTranslatorWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :language_translator, LanguageTranslator.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
