defmodule LanguageTranslatorWeb.AnalysisLive.FormComponent do
  alias LanguageTranslator.ProcessGroups
  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Translator
  alias Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-98 text-secondary-950 bg-white">
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage analysis records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="analysis-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit={if @action == :new, do: "save", else: "update"}
        multipart={true}
      >
        <div class="grid grid-cols-6 gap-1">
          <div class="col-span-5">
            <.input field={@form[:description]} type="text" label="Description" />
          </div>
          <div class="ml-6">
            <div class="ml-2 flex  items-center mx-auto">
              <.label>
                Public
              </.label>
            </div>
            <label class="flex items-center cursor-pointer mb-8">
              <div class="mt-4 ml-2">
                <input
                  type="checkbox"
                  value={@form_data.is_public}
                  checked={@form_data.is_public}
                  class="sr-only peer"
                  name="is_public"
                />
                <.toggle />
              </div>
            </label>
          </div>
        </div>

        <%= if @action == :new do %>
          <div class="grid grid-cols-6 min-w-full justify-between gap-8">
            <div class="col-span-3">
              <.input
                field={@form[:source_language_code]}
                type="select"
                label="Source Language"
                options={@languages}
              />
            </div>
            <div class="col-span-2">
              <.input
                type="select"
                label="Separator"
                options={@separators}
                value={@separator}
                field={@form[:separator]}
              />
            </div>
            <div class="flex min-w-full justify-between">
              <div class="block">
                <div class="">
                  <.label>
                    <%= if @is_file do %>
                      Upload File
                    <% else %>
                      Enter Text
                    <% end %>
                  </.label>
                </div>
                <label class="flex mx-auto items-center cursor-pointer mb-8">
                  <div class="mt-4 ml-2">
                    <input
                      type="checkbox"
                      value={@is_file}
                      checked={@is_file}
                      class="sr-only peer"
                      phx-target={@myself}
                      phx-click={:toggle_is_file}
                    />
                    <.toggle />
                  </div>
                </label>
              </div>
            </div>
            <div class="col-span-full">
              <%= if @is_file do %>
                <label class="text-md font-semibold leading-6">
                  Upload a file with words to be analyzed
                  <.live_file_input upload={@uploads[:words]} accept="text/plain" />
                  <.input type="hidden" field={@form[:words]} />
                </label>
              <% else %>
                <label class="text-start text-sm font-semibold leading-6">
                  Enter the words to be analyzed
                  <.input
                    type="textarea"
                    class="w-full h-40 px-3 py-2 text-gray-700 border rounded-lg focus:outline-none text-md"
                    field={@form[:words]}
                  >
                  </.input>
                </label>
              <% end %>
            </div>
          </div>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Analysis</.button>
        </:actions>
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
      |> assign(:words, "")
      |> assign(:separator, ",")
      |> assign(:uploaded_files, [])
      |> assign(:is_public, false)
      |> assign(:form_data, %AnalysisCreateChangeset{})

    {:ok, socket}
  end

  @impl true
  def update(%{form_data: form_data} = assigns, socket) do
    changeset = AnalysisCreateChangeset.changeset(%AnalysisCreateChangeset{}, form_data)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("toggle_is_file", _, socket) do
    is_file = !socket.assigns.is_file

    socket =
      if is_file do
        socket
        |> assign(:is_file, true)
      else
        socket
        |> assign(:is_file, false)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"analysis_create_changeset" => analysis_params} = params,
        socket
      ) do
    is_public = params["is_public"]

    changeset =
      %AnalysisCreateChangeset{}
      |> AnalysisCreateChangeset.changeset(analysis_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign_form(changeset)
      |> assign(:is_public, is_public)

    {:noreply, socket}
  end

  def handle_event(
        "update",
        %{"analysis_create_changeset" => analysis_params} = params,
        %{assigns: %{analysis: analysis}} = socket
      ) do
    is_public =
      params
      |> Map.get("is_public", "off")
      |> case do
        "on" -> true
        _ -> false
      end

    analysis_params = Map.put(analysis_params, "is_public", is_public)

    case Models.update_analysis(analysis, analysis_params) do
      {:ok, analysis} ->
        ProcessGroups.Analysis.edit_analysis(analysis)
        notify_parent({:saved, analysis})

        {:noreply,
         socket
         |> assign(:analysis, analysis)
         |> put_flash(:info, "Analysis updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event(
        "save",
        %{"analysis_create_changeset" => analysis_params} = params,
        %{
          assigns: %{current_user: current_user} = assigns
        } = socket
      ) do
    is_file = Map.get(assigns, :is_file)

    %AnalysisCreateChangeset{}
    |> AnalysisCreateChangeset.changeset(analysis_params)
    |> Map.put(:action, :validate)
    |> case do
      %{valid?: true} = changeset ->
        separator =
          analysis_params
          |> Map.get("separator")
          |> AnalysisCreateChangeset.resolve_separator()

        is_public =
          params
          |> Map.get("is_public", "off")
          |> case do
            "on" -> true
            _ -> false
          end

        extra_fields = %{"user_id" => current_user.id, "is_public" => is_public}
        analysis = Map.merge(analysis_params, extra_fields)

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
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

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
