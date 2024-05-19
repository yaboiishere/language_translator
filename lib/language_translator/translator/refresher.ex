defmodule LanguageTranslator.Translator.Refresher do
  use GenServer
  require Logger
  import Ecto.Query, only: [from: 2]

  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslator.Translator
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator.AnalysisMonitor

  def start_link(interval: interval) do
    GenServer.start_link(__MODULE__, [interval: interval], name: __MODULE__)
  end

  def init(interval: interval) do
    Process.send_after(self(), :refresh, interval)
    from(a in Analysis, where: a.status == :processing)
    |> Repo.update_all(set: [status: :failed])
    |> case do 
      {0, _} -> Logger.info("No analyses to update")
      {_, analyses} -> 
        analyses
        |> Enum.each(fn analysis -> 
          ProcessGroups.Analysis.update_analysis(analysis)
        end)
      end
    {:ok, %{interval: interval}}
  end

  def refresh(analysis_id) do
    GenServer.cast(__MODULE__, {:refresh, analysis_id})
  end

  def handle_info(:refresh, %{interval: interval} = state) do
    refresh_analyses()
    Process.send_after(self(), :refresh, interval)
    {:noreply, state}
  end

  def handle_cast({:refresh, analysis_id}, state) do
    case Analysis.get(analysis_id) do
      nil ->
        Logger.error("Analysis not found: #{analysis_id}")

      analysis ->
        if AnalysisMonitor.is_analysis_running?(analysis) do
          Logger.info("Analysis is running: #{analysis_id}")
        else
          refresh_analysis(analysis)
        end
    end

    {:noreply, state}
  end

  defp refresh_analyses do
    from(a in Analysis, where: a.status == :failed, preload: [:source_language, :user])
    |> Repo.all()
    |> Enum.reject(&AnalysisMonitor.is_analysis_running?/1)
    |> Enum.each(fn analysis ->
      refresh_analysis(analysis)
    end)
  end

  defp refresh_analysis(analysis) do
    Logger.info("Refreshing analysis: #{inspect(analysis)}")

    {:ok, analysis} = Analysis.update(analysis, %{status: :processing})
    ProcessGroups.Analysis.update_analysis(analysis)

    Translator.async_translate(analysis)
  end
end
