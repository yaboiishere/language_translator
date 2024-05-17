defmodule LanguageTranslatorWeb.WordLive.Index do
  use LanguageTranslatorWeb, :live_view

  import LanguageTranslatorWeb.FilterComponents

  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Language
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Changesets.PaginationChangeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias Ecto.Changeset

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, page_size: 10)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{page_size: page_size}} = socket) do
    default_show_cols = [
      "id",
      "text",
      "romanization",
      "language",
      "language_code",
      "created_at",
      "updated_at"
    ]

    order_and_filter =
      %OrderAndFilterChangeset{show_cols: default_show_cols, order_by: "id_desc"}
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    pagination =
      %PaginationChangeset{page: 1, page_size: page_size}
      |> PaginationChangeset.changeset(params)
      |> Changeset.apply_changes()

    %{
      entries: words,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      Word.paginate_all(order_and_filter, pagination)

    pagination =
      pagination
      |> PaginationChangeset.changeset(%{
        page: page_number,
        page_size: page_size,
        total_entries: total_entries,
        total_pages: total_pages
      })
      |> Changeset.apply_changes()

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:words, words)
      |> assign(:pagination, pagination)

    {:noreply, socket}
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
             Routes.word_index_path(
               socket,
               :index,
               Map.merge(params, %{page: page, page_size: page_size})
             )
         )}
    end
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        %{assigns: %{pagination: %{page_size: page_size}}} = socket
      ) do
    socket
    |> Util.update_order_by(field)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.word_index_path(socket, :index, Map.put(params, :page_size, page_size))
         )}
    end
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      case live_select_id do
        "source_language_filter" -> Language.search_display_name(text)
        "language_code_filter" -> Language.search_code(text)
        "id_filter" -> Word.search_id(text)
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
        "source_language_filter" -> Language.languages_for_select()
        "language_code_filter" -> Language.language_codes_for_select()
        "id_filter" -> []
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
      Util.clean_filter_params(params, [
        "_target",
        "source_language_text_input",
        "source_language_code_text_input"
      ])

    socket
    |> Util.update_filter_by(clean_params)
    |> case do
      nil ->
        {:noreply, socket}

      new_params ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.word_index_path(
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
         Routes.word_index_path(
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
         Routes.word_index_path(
           socket,
           :index,
           params
         )
     )}
  end
end
