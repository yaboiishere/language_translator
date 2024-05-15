defmodule LanguageTranslatorWeb.AnalysisLive.Index do
  use LanguageTranslatorWeb, :live_view

  import LanguageTranslatorWeb.Filters

  alias Ecto.Changeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslator.Accounts
  alias LanguageTranslator.Models
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Accounts.User
  alias LanguageTranslator.Translator.Refresher
  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslatorWeb.Util

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

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{current_user: current_user}} = socket) do
    show_cols = [
      "id",
      "description",
      "source_language",
      "status",
      "uploaded_by",
      "public",
      "created_at",
      "updated_at"
    ]

    order_and_filter_changeset =
      OrderAndFilterChangeset.changeset(%OrderAndFilterChangeset{show_cols: show_cols}, params)

    order_and_filter = Changeset.apply_changes(order_and_filter_changeset)

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:analysis_collection, Analysis.get_all(current_user, order_and_filter))
      |> assign(:columns, show_cols)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Analysis")
    |> assign(:analysis, Analysis.get!(id))
  end

  defp apply_action(socket, :new, _params) do
    languages =
      Language.languages_for_select()

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
        {LanguageTranslatorWeb.AnalysisLive.FormComponent, {:saved, _analysis}},
        %{assigns: %{current_user: current_user, order_and_filter: order_and_filter}} =
          socket
      ) do
    socket =
      socket
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:update_analysis, analysis},
        %{assigns: %{current_user: current_user, order_and_filter: order_and_filter}} = socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Analysis #{analysis.id} completed with status: #{analysis.status}")
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        %{"id" => id},
        %{assigns: %{order_and_filter: order_and_filter, current_user: current_user}} = socket
      ) do
    analysis = Models.get_analysis!(id)
    {:ok, _} = Models.delete_analysis(analysis)

    socket =
      socket
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("retry", %{"id" => id}, socket) do
    :ok = Refresher.refresh(id)

    socket =
      socket
      |> put_flash(:info, "Retrying analysis #{id}.")

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        socket
      ) do
    socket
    |> Util.update_order_by(field)
    |> tap(&IO.inspect/1)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply, push_patch(socket, to: Routes.analysis_index_path(socket, :index, params))}
    end
  end

  @impl true
  def handle_event("show_cols", checked_cols, socket) do
    checked_cols = Util.format_show_cols(checked_cols)

    {:noreply,
     push_patch(socket,
       to: Routes.analysis_index_path(socket, :index, %{"show_cols" => checked_cols})
     )}
  end

  @impl true
  def handle_event("live_select_change", %{"id" => "status_filter"}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      case live_select_id do
        "source_language_filter" -> Language.search_display_name(text)
        "uploaded_by_filter" -> User.search_username(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change",
        %{"my_form" => %{"city_search_text_input" => city_name, "city_search" => city_coords}},
        socket
      ) do
    IO.puts("You selected city #{city_name} located at: #{city_coords}")

    {:noreply, socket}
  end

  def handle_event("filter", params, socket) do
    clean_params =
      params
      |> Map.drop([
        "_target",
        "source_language_text_input",
        "status_text_input",
        "uploaded_by_text_input"
      ])
      |> Enum.filter(fn {_k, v} -> v != "" end)

    {:noreply,
     push_patch(socket, to: Routes.analysis_index_path(socket, :index, filter_by: clean_params))}
  end
end
