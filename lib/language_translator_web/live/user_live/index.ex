defmodule LanguageTranslatorWeb.UserLive.Index do
  use LanguageTranslatorWeb, :live_view
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslator.Accounts.User
  alias LanguageTranslator.Accounts
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
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

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    default_show_cols = [
      "id",
      "email",
      "username",
      "admin",
      "created_at",
      "updated_at"
    ]

    order_and_filter =
      %OrderAndFilterChangeset{show_cols: default_show_cols}
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:users, User.get_all(order_and_filter))

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        socket
      ) do
    Util.update_order_by(socket, field)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply, push_patch(socket, to: Routes.user_index_path(socket, :index, params))}
    end
  end

  @impl true
  def handle_event("show_cols", checked_cols, socket) do
    checked_cols = Util.format_show_cols(checked_cols)

    {:noreply,
     push_patch(socket,
       to: Routes.user_index_path(socket, :index, %{"show_cols" => checked_cols})
     )}
  end
end
