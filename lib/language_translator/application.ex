defmodule LanguageTranslator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LanguageTranslator.Config,
      {Task.Supervisor, name: LanguageTranslator.TaskSupervisor},
      LanguageTranslatorWeb.Telemetry,
      LanguageTranslator.Repo,
      {DNSCluster,
       query: Application.get_env(:language_translator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LanguageTranslator.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LanguageTranslator.Finch},
      # Start process groups
      %{id: :pg, start: {:pg, :start_link, []}},
      # Start translators supervisor
      LanguageTranslator.Translator.Supervisor,
      # Start translation aggregator process
      LanguageTranslator.Translator.Aggregator,
      # Start the cache with size 2000
      {LanguageTranslator.Http.Cache, %{size: 2000}},
      # Start the limitter
      {LanguageTranslator.Http.Limitter, %{requests_per_second: 100}},
      # Start a worker by calling: LanguageTranslator.Worker.start_link(arg)
      # {LanguageTranslator.Worker, arg},
      # Start to serve requests, typically the last entry
      LanguageTranslatorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LanguageTranslator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LanguageTranslatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
