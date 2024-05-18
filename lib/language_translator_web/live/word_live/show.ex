defmodule LanguageTranslatorWeb.WordLive.Show do
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Accounts
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes

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
  def handle_params(%{"word_id" => word_id}, _url, socket) do
    ProcessGroups.Analysis.join(self())
    word = Word.get!(word_id)

    translations =
      Word.get_translations(word)

    {:noreply, assign(socket, word: word, translations: translations)}
  end

  @impl true
  def handle_event("show_word", %{"word_id" => word_id}, socket) do
    {:noreply, push_patch(socket, to: Routes.word_show_path(socket, :show, word_id))}
  end

  @impl true
  def handle_event(
        "fetch_translations",
        _params,
        %{assigns: %{word: word, current_user: current_user}} = socket
      ) do
    Analysis.create_auto_analysis(word, current_user)

    socket =
      put_flash(socket, :info, "Analysis started!")

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:update_analysis, %Analysis{source_words: [text]}},
        %{assigns: %{word: %{id: id, text: text}}} = socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Analysis done!")
      |> push_patch(to: Routes.word_show_path(socket, :show, id))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_analysis, _analysis}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:edit_analysis, _analysis}, socket) do
    {:noreply, socket}
  end
end
