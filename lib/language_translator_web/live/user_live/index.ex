defmodule LanguageTranslatorWeb.UserLive.Index do
  use LanguageTranslatorWeb, :live_view
  import LanguageTranslatorWeb.FilterComponents

  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslator.Accounts.User
  alias LanguageTranslator.Accounts
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Changesets.PaginationChangeset
  alias Ecto.Changeset

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
      |> assign_new(:current_user, fn -> current_user end)
      |> assign(page_size: 1)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{page_size: page_size}} = socket) do
    default_show_cols = [
      "id",
      "email",
      "username",
      "admin",
      "created_at",
      "updated_at"
    ]

    pagination =
      %PaginationChangeset{page: 1, page_size: page_size}
      |> PaginationChangeset.changeset(params)
      |> Changeset.apply_changes()

    order_and_filter =
      %OrderAndFilterChangeset{
        show_cols: default_show_cols,
        order_by: "id_desc"
      }
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    pagination_params =
      %{
        entries: users
      } =
      User.paginate_all(order_and_filter, pagination)

    pagination =
      pagination
      |> PaginationChangeset.changeset(pagination_params)
      |> Changeset.apply_changes()

    # Analysis.paginate_all(current_user, order_and_filter, pagination)

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:users, users)
      |> assign(:pagination, pagination)

    {:noreply, socket}
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
           to: Routes.user_index_path(socket, :index, Map.put(params, :page_size, page_size))
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
             Routes.user_index_path(
               socket,
               :index,
               Map.merge(params, %{page: page, page_size: page_size})
             )
         )}
    end
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      case live_select_id do
        "id_filter" -> User.search_id(text)
        "username_filter" -> User.search_username(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_blur", %{"id" => "admin_filter"}, socket) do
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
        "id_filter" -> []
        "username_filter" -> User.users_for_select()
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  def handle_event("filter", params, %{assigns: %{pagination: %{page_size: page_size}}} = socket) do
    clean_params =
      Util.clean_filter_params(params, ["_target", "id_text_input", "username_text_input"])

    socket
    |> Util.update_filter_by(clean_params)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.user_index_path(socket, :index, Map.merge(params, %{page_size: page_size}))
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
         Routes.user_index_path(
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
         Routes.user_index_path(
           socket,
           :index,
           params
         )
     )}
  end
end
