defmodule LanguageTranslatorWeb.WordLive.Index do
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Models.Word
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias Ecto.Changeset

  @impl true
  def handle_params(params, _url, socket) do
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
      %OrderAndFilterChangeset{show_cols: default_show_cols}
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    words = Word.get_all!(order_and_filter)

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:words, words)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_cols", checked_cols, socket) do
    checked_cols = Util.format_show_cols(checked_cols)

    {:noreply,
     push_patch(socket,
       to: Routes.word_index_path(socket, :index, %{"show_cols" => checked_cols})
     )}
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        socket
      ) do
    socket
    |> Util.update_order_by(field)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply, push_patch(socket, to: Routes.word_index_path(socket, :index, params))}
    end
  end
end
