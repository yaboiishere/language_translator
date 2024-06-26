defmodule LanguageTranslatorWeb.LanguageLive.Index do
  alias LanguageTranslator.Models.Language
  use LanguageTranslatorWeb, :live_view
  import LanguageTranslatorWeb.FilterComponents

  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Changesets.PaginationChangeset
  alias Ecto.Changeset

  @default_show_cols [
    "code",
    "display_name",
    "created_at",
    "updated_at"
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_size: 100)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{page_size: page_size}} = socket) do
    pagination =
      %PaginationChangeset{page: 1, page_size: page_size}
      |> PaginationChangeset.changeset(params)
      |> Changeset.apply_changes()

    order_and_filter =
      %OrderAndFilterChangeset{
        show_cols: @default_show_cols,
        order_by: "display_name_asc"
      }
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    pagination_params =
      %{
        entries: languages
      } =
      Language.paginate_all(order_and_filter, pagination)

    pagination =
      pagination
      |> PaginationChangeset.changeset(pagination_params)
      |> Changeset.apply_changes()

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:languages, languages)
      |> assign(:pagination, pagination)

    {:noreply, socket}
  end

  def handle_event(
        "show_all",
        _params,
        %{assigns: %{pagination: %{page: page, page_size: page_size}}} = socket
      ) do
    socket
    |> Util.update_show_cols(@default_show_cols)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        params = Map.merge(params, %{page: page, page_size: page_size})

        {:noreply,
         push_patch(socket,
           to:
             Routes.language_index_path(
               socket,
               :index,
               params
             )
         )}
    end
  end

  def handle_event(
        "hide_all",
        _params,
        %{
          assigns: %{
            pagination: %{page: page, page_size: page_size}
          }
        } = socket
      ) do
    socket
    |> Util.update_show_cols(["none"])
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        params = Map.merge(params, %{page: page, page_size: page_size})

        {:noreply,
         push_patch(socket,
           to:
             Routes.language_index_path(
               socket,
               :index,
               params
             )
         )}
    end
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        %{assigns: %{pagination: %{page_size: page_size}}} =
          socket
      ) do
    Util.update_order_by(socket, field)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.language_index_path(socket, :index, Map.put(params, :page_size, page_size))
         )}
    end
  end

  @impl true
  def handle_event(
        "show_cols",
        checked_cols,
        %{assigns: %{pagination: %{page: page, page_size: page_size}}} = socket
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
             Routes.language_index_path(
               socket,
               :index,
               Map.merge(params, %{page: page, page_size: page_size})
             )
         )}
    end
  end

  def handle_event("filter", params, %{assigns: %{pagination: %{page_size: page_size}}} = socket) do
    clean_params =
      Util.clean_filter_params(params, [
        "_target",
        "_page_size_live_select_component",
        "language_code_filter"
      ])

    socket
    |> Util.update_filter_by(clean_params)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.language_index_path(
               socket,
               :index,
               Map.merge(params, %{page_size: page_size})
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
         Routes.language_index_path(
           socket,
           :index,
           Map.merge(OrderAndFilterChangeset.to_map(order_and_filter), %{
             page: page,
             page_size: page_size
           })
         )
     )}
  end

  @impl true
  def handle_event(
        "page_size",
        %{"page_size" => page_size},
        %{assigns: %{order_and_filter: order_and_filter}} = socket
      ) do
    params =
      order_and_filter |> OrderAndFilterChangeset.to_map() |> Map.put(:page_size, page_size)

    {:noreply,
     push_patch(socket,
       to:
         Routes.language_index_path(
           socket,
           :index,
           params
         )
     )}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      case live_select_id do
        "language_code_filter" ->
          Language.search_code(text)

        "_page_size_live_select_component" ->
          Util.page_size_options()
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "live_select_blur",
        %{"id" => live_select_id},
        socket
      ) do
    options =
      case live_select_id do
        "language_code_filter" -> Language.language_codes_for_select()
        "_page_size_live_select_component" -> Util.page_size_options()
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end
end
