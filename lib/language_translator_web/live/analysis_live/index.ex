defmodule LanguageTranslatorWeb.AnalysisLive.Index do
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Models
  alias LanguageTranslator.Models.Analysis

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :analysis_collection, Models.list_analysis())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Analysis")
    |> assign(:analysis, Models.get_analysis!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Analysis")
    |> assign(:analysis, %Analysis{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Analysis")
    |> assign(:analysis, nil)
  end

  @impl true
  def handle_info({LanguageTranslatorWeb.AnalysisLive.FormComponent, {:saved, analysis}}, socket) do
    {:noreply, stream_insert(socket, :analysis_collection, analysis)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    analysis = Models.get_analysis!(id)
    {:ok, _} = Models.delete_analysis(analysis)

    {:noreply, stream_delete(socket, :analysis_collection, analysis)}
  end
end
