defmodule LanguageTranslator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LanguageTranslator.Repo,
      LanguageTranslator.Config,
      {Task.Supervisor, name: LanguageTranslator.TaskSupervisor},
      {DynamicSupervisor, name: LanguageTranslator.DynamicSupervisor, strategy: :one_for_one},
      LanguageTranslatorWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:language_translator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LanguageTranslator.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LanguageTranslator.Finch},
      # Start process groups
      %{id: :pg, start: {:pg, :start_link, []}},
      # Start translation aggregator process
      # LanguageTranslator.Translator.Aggregator,
      # Start the http services
      LanguageTranslator.Http.Supervisor,
      # Start a worker by calling: LanguageTranslator.Worker.start_link(arg)
      # {LanguageTranslator.Worker, arg},
      # Start to serve requests, typically the last entry
      # Start translators supervisor
      LanguageTranslator.Translator.Supervisor,
      LanguageTranslatorWeb.Endpoint
    ]

    children =
      if Application.get_env(:language_translator, :env) == :test do
        children
      else
        children ++
          [
            # Start the analysis monitor
            LanguageTranslator.Translator.AnalysisMonitor,
            # Start the analysis refresher
            {LanguageTranslator.Translator.Refresher, interval: 10_000 + :rand.uniform(10_000)}
          ]
      end

    children =
      case Application.get_env(:libcluster, :topologies) do
        nil ->
          children

        topologies ->
          [
            {Cluster.Supervisor, [topologies, [name: LanguageTranslator.ClusterSupervisor]]}
            | children
          ]
      end

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
