defmodule LanguageTranslatorWeb.AnalysisLive.Index do
  alias ElixirSense.Core.Struct
  use LanguageTranslatorWeb, :live_view

  alias Ecto.Changeset
  alias LanguageTranslatorWeb.Router.Helpers, as: Routes
  alias LanguageTranslator.Accounts
  alias LanguageTranslator.Models
  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Translator.Refresher
  alias LanguageTranslatorWeb.Changesets.AnalysisCreateChangeset
  alias LanguageTranslatorWeb.Changesets.OrderAndFilterChangeset
  alias LanguageTranslator.ProcessGroups

  @impl true
  def mount(_params, session, socket) do
    ProcessGroups.Analysis.join(self())

    current_user =
      session
      |> Map.get("user_token")
      |> case do
        nil -> nil
        user_token -> Accounts.get_user_by_session_token(user_token)
      end

    socket =
      socket
      |> assign(:is_file, true)
      |> assign(:languages, [])
      |> assign_new(:current_user, fn -> current_user end)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{current_user: current_user}} = socket) do
    order_and_filter_changeset =
      OrderAndFilterChangeset.changeset(%OrderAndFilterChangeset{}, params)

    order_and_filter = Changeset.apply_changes(order_and_filter_changeset)

    socket =
      socket
      |> assign(:order_and_filter, order_and_filter)
      |> assign(:analysis_collection, Analysis.get_all(current_user, order_and_filter))

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Analysis")
    |> assign(:analysis, Analysis.get!(id))
  end

  defp apply_action(socket, :new, _params) do
    languages =
      Models.list_languages()
      |> Enum.map(&{&1.display_name, &1.code})

    socket
    |> assign(:page_title, "New Analysis")
    |> assign(:form_data, %AnalysisCreateChangeset{})
    |> assign(:analysis, %Analysis{})
    |> assign(:languages, languages)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Analysis")
    |> assign(:analysis, nil)
  end

  @impl true
  def handle_info(
        {LanguageTranslatorWeb.AnalysisLive.FormComponent, {:saved, _analysis}},
        %{assigns: %{current_user: current_user, order_and_filter: order_and_filter}} =
          socket
      ) do
    socket =
      socket
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:update_analysis, analysis},
        %{assigns: %{current_user: current_user, order_and_filter: order_and_filter}} = socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Analysis #{analysis.id} completed with status: #{analysis.status}")
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        %{"id" => id},
        %{assigns: %{order_and_filter: order_and_filter, current_user: current_user}} = socket
      ) do
    analysis = Models.get_analysis!(id)
    {:ok, _} = Models.delete_analysis(analysis)

    socket =
      socket
      |> assign(
        :analysis_collection,
        Analysis.get_all(current_user, order_and_filter)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("retry", %{"id" => id}, socket) do
    :ok = Refresher.refresh(id)

    socket =
      socket
      |> put_flash(:info, "Retrying analysis #{id}.")

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "sort",
        %{"col" => field},
        %{
          assigns: %{
            order_and_filter: %OrderAndFilterChangeset{order_by: order_by} = order_and_filter
          }
        } =
          socket
      ) do
    {old_field, old_direction} = OrderAndFilterChangeset.get_order_by(order_by)
    field = String.downcase(field)

    new_order_by =
      if old_field == field do
        new_direction =
          case old_direction do
            "asc" -> "desc"
            "desc" -> "asc"
          end

        "#{field}_#{new_direction}"
      else
        "#{field}_desc"
      end

    order_and_filter
    |> OrderAndFilterChangeset.changeset(%{order_by: new_order_by})
    |> case do
      %{valid?: true} = changeset ->
        params =
          changeset |> Changeset.apply_changes() |> Map.from_struct() |> Map.delete(:__meta__)

        {:noreply, push_patch(socket, to: Routes.analysis_index_path(socket, :index, params))}

      _ ->
        {:noreply, socket}
    end
  end
end
