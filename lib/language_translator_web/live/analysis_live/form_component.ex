defmodule LanguageTranslatorWeb.AnalysisLive.FormComponent do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-98 text-secondary-950 bg-white">
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage analysis records in your database.</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@form_data}
        id="analysis-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit={if @action == :new, do: "save", else: "update"}
        multipart={true}
      >
        <div class="grid grid-cols-6 gap-1">
          <div class="col-span-5">
            <.input id="form_description" field={f[:description]} type="text" label="Description" />
          </div>
          <div class="ml-6">
            <div class="ml-2 flex  items-center mx-auto">
              <.label>
                Public
              </.label>
            </div>
            <label class="flex items-center cursor-pointer mb-8">
              <div class="mt-4 ml-2">
                <.input
                  id="is_public"
                  type="toggle"
                  field={f[:is_public]}
                  value={@is_public}
                  class="sr-only peer"
                />
              </div>
            </label>
          </div>
        </div>

        <%= if @action == :new do %>
          <div class="grid grid-cols-6 min-w-full justify-between gap-8">
            <div class="col-span-3">
              <.input
                field={f[:source_language_code]}
                type="select"
                label="Source Language"
                options={Enum.sort_by(@languages, &elem(&1, 0))}
                disabled={@merge}
              />
              <%= if @merge do %>
                <.input type="hidden" field={f[:source_language_code]} />
              <% end %>
            </div>
            <div class="col-span-2">
              <.input
                type="select"
                label="Separator"
                options={@separators}
                field={f[:separator]}
                disabled={@merge}
              />
              <%= if @merge do %>
                <.input type="hidden" field={f[:separator]} />
              <% end %>
            </div>
            <div class="flex min-w-full justify-between">
              <div class="block">
                <div class="">
                  <%= if !@merge do %>
                    <.label>
                      <%= if @is_file do %>
                        Upload File
                      <% else %>
                        Enter Text
                      <% end %>
                    </.label>
                  <% end %>
                </div>
                <label class="flex mx-auto items-center cursor-pointer mb-8">
                  <div class="mt-4 ml-2">
                    <%= if !@merge do %>
                      <.input
                        id="is_file"
                        type="toggle"
                        class="sr-only peer"
                        field={f[:is_file]}
                        value={@is_file}
                      />
                    <% end %>
                  </div>
                </label>
              </div>
            </div>
            <div class="col-span-full">
              <%= if @is_file && !@merge do %>
                <label class="text-md font-semibold leading-6">
                  Upload a file with words to be analyzed
                  <.live_file_input upload={@uploads[:words]} accept="text/plain" />
                  <.input type="hidden" field={f[:words]} />
                </label>
              <% else %>
                <label class="text-start text-sm font-semibold leading-6">
                  Enter the words to be analyzed
                  <.input
                    id="words_area"
                    type="textarea"
                    class="w-full h-40 px-3 py-2 text-gray-700 border rounded-lg focus:outline-none text-md"
                    field={f[:words]}
                  >
                  </.input>
                </label>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class={["flex justify-end", if(@is_file, do: "-mt-10", else: "mt-4")]}>
          <.button id="form_save" phx-disable-with="Saving...">Save Analysis</.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:separators, [
        {"Comma", ","},
        {"Semicolon", ";"},
        {"Space", "space"},
        {"Newline", "newline"}
      ])
      |> allow_upload(:words, accept: ["text/plain"], max_entries: 1, max_file_size: 500_000)
      |> assign(:uploaded_files, [])
      |> assign(:is_file, true)
      |> assign(:is_public, false)

    {:ok, socket}
  end

  @impl true
  def update(%{form_data: form_data} = assigns, socket) do
    is_public =
      form_data.changes[:is_public]
      |> case do
        true -> true
        _ -> false
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(form_data)
     |> assign(:is_public, is_public)}
  end

  @impl true
  def handle_event(
        "validate",
        analysis_params,
        socket
      ) do
    changeset =
      %AnalysisCreateChangeset{}
      |> AnalysisCreateChangeset.changeset(analysis_params)
      |> Map.put(:action, :validate)

    is_file =
      case analysis_params["is_file"] do
        "true" -> true
        _ -> false
      end

    is_public =
      case analysis_params["is_public"] do
        "true" -> true
        _ -> false
      end

    socket =
      socket
      |> assign_form(changeset)
      |> assign(:is_file, is_file)
      |> assign(:is_public, is_public)

    {:noreply, socket}
  end

  def handle_event(
        "update",
        analysis_params,
        %{assigns: %{analysis: analysis}} = socket
      ) do
    analysis
    |> Analysis.changeset(analysis_params)
    |> case do
      %{valid?: true} = changeset ->
        Repo.update(changeset)
        |> case do
          {:ok, analysis} ->
            ProcessGroups.Analysis.edit_analysis(analysis)
            notify_parent({:saved, analysis})

            {:noreply,
             socket
             |> assign(:analysis, analysis)
             |> put_flash(:info, "Analysis updated successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      changeset ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event(
        "save",
        analysis_params,
        %{
          assigns: %{current_user: current_user}
        } = socket
      ) do
    %AnalysisCreateChangeset{}
    |> AnalysisCreateChangeset.changeset(analysis_params)
    |> Map.put(:action, :validate)
    |> case do
      %{valid?: true} = changeset ->
        separator =
          analysis_params
          |> Map.get("separator")
          |> AnalysisCreateChangeset.resolve_separator()

        extra_fields = %{"user_id" => current_user.id}
        analysis = Map.merge(analysis_params, extra_fields)

        is_file =
          case analysis_params["is_file"] do
            "true" -> true
            _ -> false
          end

        words =
          if is_file do
            consume_uploaded_entries(socket, :words, fn %{path: path}, _entry ->
              File.read!(path)
              |> clean_words(separator)
              |> then(&{:ok, &1})
            end)
            |> List.flatten()
          else
            analysis_params
            |> Map.get("words")
            |> clean_words(separator)
          end

        AnalysisCreateChangeset.validate_words_changeset(changeset, %{
          words: Enum.join(words, separator),
          separator: separator
        })
        |> Map.put(:action, :validate)
        |> case do
          %{valid?: true} ->
            analysis = Map.put(analysis, "source_words", words)
            save_analysis(socket, socket.assigns.action, analysis)

          changeset ->
            {:noreply, assign_form(socket, changeset)}
        end

      analysis_params_changeset ->
        {:noreply, assign_form(socket, analysis_params_changeset)}
    end
  end

  defp save_analysis(socket, :edit, analysis_params) do
    case Models.update_analysis(socket.assigns.analysis, analysis_params) do
      {:ok, analysis} ->
        notify_parent({:saved, analysis})

        {:noreply,
         socket
         |> put_flash(:info, "Analysis updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_analysis(socket, :new, analysis_params) do
    case Models.create_analysis(analysis_params) do
      {:ok, analysis} ->
        analysis = Repo.preload(analysis, :source_language)

        {:ok, _pid} =
          Translator.async_translate(analysis)

        notify_parent({:saved, analysis})

        {:noreply,
         socket
         |> put_flash(:info, "Analysis created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form_data, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp clean_words(nil, _separator), do: []

  defp clean_words(words, separator) do
    words
    |> String.split(separator)
    |> Enum.map(fn word ->
      word
      |> String.replace(~r/[,.!?]/, " ")
      |> String.replace(~r/\s+/, "\n")
      |> String.trim()
    end)
    |> Enum.filter(&(&1 != ""))
  end
end
