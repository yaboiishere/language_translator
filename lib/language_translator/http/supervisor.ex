defmodule LanguageTranslator.Http.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      # Start the limitter
      {LanguageTranslator.Http.Limitter, %{requests_per_second: 100}}
    ]

    if Application.get_env(:language_translator, :env) == :test do
      children
    else
      [
        # Start the cache with size 2000
        {LanguageTranslator.Http.Cache, %{size: 2000}}
        | children
      ]
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
