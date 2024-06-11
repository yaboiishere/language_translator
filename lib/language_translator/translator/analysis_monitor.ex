defmodule LanguageTranslator.Translator.AnalysisMonitor do
  use GenServer

  require Logger

  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.ProcessGroups

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def add_analysis(%Analysis{id: id}) do
    if Application.get_env(:language_translator, :env) == :test do
      :ok
    else
      caller = self()
      GenServer.call(__MODULE__, {:add_analysis, id, caller})
    end
  end

  def running_analyses do
    GenServer.call(__MODULE__, :running_analyses)
  end

  def is_analysis_running?(%Analysis{id: id}) do
    GenServer.call(__MODULE__, {:is_analysis_running?, id})
  end

  def handle_call({:add_analysis, analysis_id, caller}, _from, state) do
    task_ref =
      Process.monitor(caller)

    {:reply, :ok, Map.put(state, task_ref, analysis_id)}
  end

  def handle_call(:running_analyses, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:is_analysis_running?, analysis_id}, _from, state) do
    resp =
      Enum.any?(state, fn {_task_ref, id} -> analysis_id == id end)

    {:reply, resp, state}
  end

  def handle_info({:DOWN, task_ref, :process, _caller, :normal}, state) do
    Process.demonitor(task_ref)
    {:noreply, Map.delete(state, task_ref)}
  end

  def handle_info({:DOWN, task_ref, :process, _caller, _reason}, state) do
    Process.demonitor(task_ref)
    analysis_id = Map.get(state, task_ref)

    Analysis.update(analysis_id, %{status: :failed}, [:source_language, :user])
    |> case do
      {:ok, analysis} ->
        ProcessGroups.Analysis.update_analysis(analysis)

        Logger.error("Analysis failed: #{analysis_id}. Will be retried.")

      _ ->
        Logger.error("Analysis failed: #{analysis_id}. Could not be retried.")
    end

    {:noreply, Map.delete(state, task_ref)}
  end
end
