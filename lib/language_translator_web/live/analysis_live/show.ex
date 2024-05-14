defmodule LanguageTranslatorWeb.AnalysisLive.Show do
  use LanguageTranslatorWeb, :live_view

  alias Ecto.Changeset
  alias LanguageTranslator.Models.Word
  alias LanguageTranslatorWeb.AnalysisLive.FormComponent
  alias LanguageTranslator.Models
  alias LanguageTranslatorWeb.TranslationsTable
  alias LanguageTranslator.Accounts
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias Ecto.Changeset

  defmodule Table do
    defstruct lavenshtein: "0%",
              romanized_text: "",
              text: "",
              language_display_name: "",
              language_code: ""
  end

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
    analysis = Models.get_analysis!(id, @analysis_preloads)

    words = Word.analysis_words(id)

    entries =
      words
      |> Enum.map(fn {%Word{text: _text, romanized_text: _romanized_text} = word, translations} ->
        {
          word,
          translations
          |> Enum.map(fn
            %Translation{
              target_word: %Word{
                text: text,
                romanized_text: romanized_text,
                language: %Language{display_name: language, code: code}
              },
              similarity: similarity
            } ->
              %Table{
                lavenshtein:
                  similarity |> Float.round(2) |> Float.to_string() |> then(fn x -> "#{x}%" end),
                romanized_text: romanized_text,
                text: text,
                language_display_name: language,
                language_code: code
              }
          end)
        }
      end)

    columns =
      entries
      |> List.first()
      |> elem(1)
      |> Enum.map(fn %Table{
                       language_display_name: language_display_name,
                       language_code: language_code
                     } ->
        "#{language_display_name} - #{language_code}"
      end)

    order_and_filter =
      %OrderAndFilterChangeset{show_cols: columns}
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:analysis, analysis)
      |> assign(:entries, entries)
      |> assign(:columns, columns)

    {:noreply, socket}
  end

  @impl true
  def handle_info({FormComponent, {:saved, analysis}}, socket) do
    {:noreply,
     socket
     |> assign(:analysis, analysis)
     |> put_flash(:info, "Analysis updated successfully")}
  end

  @impl true
  def handle_event("show_word", %{"text" => text, "language_code" => language_code}, socket) do
    %{id: id} = Word.get!(text, language_code)

    {:noreply, push_navigate(socket, to: Routes.word_show_path(socket, :show, id))}
  end

  @impl true
  def handle_event("show_cols", checked_cols, %{assigns: %{analysis: %{id: id}}} = socket) do
    checked_cols = Util.format_show_cols(checked_cols)

    {:noreply,
     push_patch(socket,
       to: Routes.analysis_show_path(socket, :show, id, show_cols: checked_cols)
     )}
  end

  defp page_title(:show), do: "Show Analysis"
  defp page_title(:edit), do: "Edit Analysis"
end
