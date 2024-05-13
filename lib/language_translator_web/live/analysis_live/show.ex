defmodule LanguageTranslatorWeb.AnalysisLive.Show do
  alias LanguageTranslatorWeb.AnalysisLive.FormComponent
  use LanguageTranslatorWeb, :live_view

  alias Ecto.Changeset
  alias LanguageTranslator.Models
  alias LanguageTranslatorWeb.TranslationsTable
  alias LanguageTranslator.Accounts
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset

  @analysis_preloads [:source_language, :user]

  @impl true
  def mount(_params, session, socket) do
    current_user =
      session
      |> Map.get("user_token")
      |> case do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end

    socket =
      socket
      |> assign(:current_user, current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    order_and_filter_changeset =
      OrderAndFilterChangeset.changeset(%OrderAndFilterChangeset{}, params)

    order_and_filter = Changeset.apply_changes(order_and_filter_changeset)

    analysis = Models.get_analysis!(id, @analysis_preloads)

    {:noreply,
     socket
     |> assign(:order_and_filter, order_and_filter)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:analysis, analysis)}
  end

  @impl true
  def handle_info({FormComponent, {:saved, analysis}}, socket) do
    {:noreply,
     socket
     |> assign(:analysis, analysis)
     |> put_flash(:info, "Analysis updated successfully")}
  end

  defp page_title(:show), do: "Show Analysis"
  defp page_title(:edit), do: "Edit Analysis"
end
