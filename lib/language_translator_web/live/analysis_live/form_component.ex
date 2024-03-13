defmodule LanguageTranslatorWeb.AnalysisLive.FormComponent do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage analysis records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="analysis-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />

        <%= if @action == :new do %>
         <label class="inline-flex items-center cursor-pointer">
           <input type="checkbox" value={@is_file} checked={@is_file} class="sr-only peer" phx-target={@myself} phx-click={:toggle_is_file}>
           <div class="relative w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
           <span class="ms-3  text-gray-300 dark:text-gray-900">
            <%= if @is_file do %>
              Upload File
            <% else %>
              Enter Text
            <% end %>
           </span>
         </label> 
         <%= if @is_file do %>
            <.input field={@form[:file]} type="file" label="File with words" />
         <% else %>
            <.input field={@form[:file]} type="textarea" label="Write words to be translated" />
         <% end %>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Analysis</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{analysis: analysis} = assigns, socket) do
    changeset = Models.change_analysis(analysis)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("toggle_is_file", _, socket) do
    {:noreply, assign(socket, :is_file, !socket.assigns.is_file)}
  end

  @impl true
  def handle_event("validate", %{"analysis" => analysis_params}, socket) do
    changeset =
      socket.assigns.analysis
      |> Models.change_analysis(analysis_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"analysis" => analysis_params}, socket) do
    save_analysis(socket, socket.assigns.action, analysis_params)
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
end
