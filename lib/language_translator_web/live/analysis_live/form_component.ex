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
