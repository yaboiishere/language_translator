defmodule LanguageTranslatorWeb.AnalysisLive.Show do
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Models
  alias LanguageTranslatorWeb.TranslationsTable

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:analysis, Models.get_analysis!(id, [:source_language]))}
  end

  defp page_title(:show), do: "Show Analysis"
  defp page_title(:edit), do: "Edit Analysis"
end
