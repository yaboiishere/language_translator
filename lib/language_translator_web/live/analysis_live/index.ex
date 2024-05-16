defmodule LanguageTranslatorWeb.AnalysisLive.Index do
  alias LanguageTranslatorWeb.Changesets.PaginationChangeset
  use LanguageTranslatorWeb, :live_view

  import LanguageTranslatorWeb.FilterComponents
  import LanguageTranslatorWeb.PaginationComponent

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
      |> assign(page_size: 10)

    {:ok, socket}
  end

  @impl true
  def handle_params(
        params,
        _url,
        %{assigns: %{current_user: current_user, page_size: page_size}} = socket
      ) do
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

    pagination =
      %PaginationChangeset{page: 1, page_size: page_size}
      |> PaginationChangeset.changeset(params)
      |> Changeset.apply_changes()

    order_and_filter_changeset =
      OrderAndFilterChangeset.changeset(
        %OrderAndFilterChangeset{show_cols: show_cols, order_by: "id_desc"},
        params
      )

    order_and_filter = Changeset.apply_changes(order_and_filter_changeset)

    %{
      entries: analyses,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      Analysis.paginate_all(current_user, order_and_filter, pagination)

    pagination =
      pagination
      |> PaginationChangeset.changeset(%{
        page: page_number,
        page_size: page_size,
        total_entries: total_entries,
        total_pages: total_pages
      })
      |> Changeset.apply_changes()

    IO.inspect(pagination)

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:analysis_collection, analyses)
      |> assign(:columns, show_cols)
      |> assign(:pagination, pagination)

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
    |> tap(&IO.inspect(&1, label: "update_order_by"))
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply, push_patch(socket, to: Routes.analysis_index_path(socket, :index, params))}
    end
  end

  @impl true
  def handle_event(
        "show_cols",
        checked_cols,
        %{
          assigns: %{
            pagination: %{page: page, page_size: page_size}
          }
        } = socket
      ) do
    checked_cols = Util.format_show_cols(checked_cols)

    socket
    |> Util.update_show_cols(checked_cols)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.analysis_index_path(
               socket,
               :index,
               Map.merge(params, %{page: page, page_size: page_size})
             )
         )}
    end
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
        "id_filter" -> Analysis.search_id(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "filter",
        params,
        %{assigns: %{pagination: %{page_size: page_size}}} = socket
      ) do
    clean_params =
      params
      |> Map.drop([
        "_target",
        "source_language_text_input",
        "status_text_input",
        "uploaded_by_text_input",
        "id_text_input"
      ])
      |> Enum.filter(fn {_k, v} -> v != "" end)
      |> Enum.into(%{})

    socket
    |> Util.update_filter_by(clean_params)
    |> case do
      nil ->
        {:noreply, socket}

      new_params ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.analysis_index_path(
               socket,
               :index,
               Map.put(new_params, :page_size, page_size)
             )
         )}
    end
  end

  @impl true
  def handle_event(
        "nav",
        %{"page" => page},
        %{
          assigns: %{
            order_and_filter: order_and_filter,
            pagination: %{page_size: page_size}
          }
        } = socket
      ) do
    {:noreply,
     push_patch(socket,
       to:
         Routes.analysis_index_path(
           socket,
           :index,
           Map.merge(OrderAndFilterChangeset.to_map(order_and_filter), %{
             page: page,
             page_size: page_size
           })
           |> tap(&IO.inspect(&1, label: "nav"))
         )
     )}
  end
end
