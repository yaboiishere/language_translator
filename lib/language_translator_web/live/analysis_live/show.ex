defmodule LanguageTranslatorWeb.AnalysisLive.Show do
  use LanguageTranslatorWeb, :live_view

  import LiveSelect
  alias Ecto.Changeset
  alias LanguageTranslator.Models.Word
  alias LanguageTranslatorWeb.AnalysisLive.FormComponent
  alias LanguageTranslator.Models
  alias LanguageTranslatorWeb.TranslationsTable
  alias LanguageTranslator.Accounts
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslatorWeb.ShowColumnsComponent
  alias LanguageTranslatorWeb.Util
  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Analysis
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
      |> assign(:extra_ids_form, %{})

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, %{assigns: %{current_user: current_user}} = socket) do
    analysis = Models.get_analysis!(id, @analysis_preloads)

    extra_ids = Map.get(params, "extra_ids", [])

    valid_extra_description_to_ids =
      Analysis.get_by_source_language(current_user, analysis)

    words = Word.analysis_words(id, extra_ids)

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
        %{label: language_display_name, id: language_code}
      end)

    order_and_filter =
      %OrderAndFilterChangeset{show_cols: columns |> Enum.map(&Map.get(&1, :id))}
      |> OrderAndFilterChangeset.changeset(params)
      |> Changeset.apply_changes()

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:analysis, analysis)
      |> assign(:entries, entries)
      |> assign(:columns, columns)
      |> assign(:extra_ids, extra_ids)
      |> assign(:valid_extra_ids, valid_extra_description_to_ids)

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

    socket
    |> Util.update_show_cols(checked_cols)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.analysis_show_path(socket, :show, id, params)
         )}
    end
  end

  def handle_event(
        "show_all",
        _params,
        %{assigns: %{analysis: %{id: id}, columns: columns}} = socket
      ) do
    checked_cols = columns |> Enum.map(&Map.get(&1, :id))

    socket
    |> Util.update_show_cols(checked_cols)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.analysis_show_path(socket, :show, id, params)
         )}
    end
  end

  def handle_event("hide_all", _params, %{assigns: %{analysis: %{id: id}}} = socket) do
    socket
    |> Util.update_show_cols(["none"])
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.analysis_show_path(socket, :show, id, params)
         )}
    end
  end

  def handle_event(
        "add_extra_ids",
        %{"extra_ids" => extra_ids},
        %{
          assigns: %{
            analysis: %{id: id},
            extra_ids: old_extra_ids
          }
        } = socket
      ) do
    new_extra_ids = old_extra_ids ++ extra_ids

    socket
    |> Util.update_extra_ids(new_extra_ids)
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.analysis_show_path(socket, :show, id, params)
         )}
    end
  end

  def handle_event(
        "add_extra_ids",
        _params,
        %{
          assigns: %{
            analysis: %{id: id}
          }
        } = socket
      ) do
    socket
    |> Util.update_extra_ids([])
    |> case do
      nil ->
        {:noreply, socket}

      params ->
        {:noreply,
         push_patch(socket,
           to: Routes.analysis_show_path(socket, :show, id, params)
         )}
    end
  end

  def handle_event(
        "live_select_blur",
        %{"id" => live_select_id},
        %{assigns: %{analysis: analysis, current_user: current_user}} = socket
      ) do
    options =
      case live_select_id do
        "extra_analysis" -> Analysis.get_by_source_language(current_user, analysis)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => live_select_id},
        %{assigns: %{current_user: current_user, analysis: analysis}} = socket
      ) do
    options =
      case live_select_id do
        "extra_analysis" -> Analysis.search_description(current_user, analysis, text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Analysis"
  defp page_title(:edit), do: "Edit Analysis"

  defp text_input_class() do
    "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm text-gray-900 pr-0 py-0"
  end

  defp tag_class() do
    "bg-primary-200 flex p-1 rounded-lg text-sm"
  end
end
