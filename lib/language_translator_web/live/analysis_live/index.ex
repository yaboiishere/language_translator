defmodule LanguageTranslatorWeb.AnalysisLive.Index do
  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset
  alias LanguageTranslator.ProcessGroups
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Accounts
  alias LanguageTranslator.Models
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Repo

  @analysis_preloads [:source_language, :user]

  @impl true
  def mount(_params, session, socket) do
    ProcessGroups.Analysis.join(self())

    current_user =
      session
      |> Map.get("user_token")
      |> case do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end

    socket =
      socket
      |> assign(:is_file, true)
      |> assign(:languages, [])
      |> assign_new(:current_user, fn -> current_user end)

    {:ok,
     stream(
       socket,
       :analysis_collection,
       Analysis.get_all(current_user, @analysis_preloads)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Analysis")
    |> assign(:analysis, Models.get_analysis!(id, @analysis_preloads))
  end

  defp apply_action(socket, :new, _params) do
    languages =
      Models.list_languages()
      |> Enum.map(&{&1.display_name, &1.code})

    socket
    |> assign(:page_title, "New Analysis")
    |> assign(:form_data, %AnalysisCreateChangeset{})
    |> assign(:analysis, %Analysis{})
    |> assign(:languages, languages)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Analysis")
    |> assign(:analysis, nil)
  end

  @impl true
  def handle_info(
        {LanguageTranslatorWeb.AnalysisLive.FormComponent, {:saved, analysis}},
        socket
      ) do
    analysis =
      Repo.preload(analysis, @analysis_preloads)

    {:noreply, stream_insert(socket, :analysis_collection, analysis)}
  end

  @impl true
  def handle_info({:update_analysis, analysis}, socket) do
    socket =
      socket
      |> put_flash(:info, "Analysis #{analysis.id} completed with status: #{analysis.status}")
      |> stream_insert(:analysis_collection, analysis)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    analysis = Models.get_analysis!(id)
    {:ok, _} = Models.delete_analysis(analysis)

    {:noreply, stream_delete(socket, :analysis_collection, analysis)}
  end
end
