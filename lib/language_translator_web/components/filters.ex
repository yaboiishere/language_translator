defmodule LanguageTranslatorWeb.Filters do
  use Phoenix.Component

  import LanguageTranslatorWeb.CoreComponents
  import LiveSelect

  alias LanguageTranslator.Accounts.User
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.Analysis

  attr :filter_by, :map, required: true

  def analysis_filters_form(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@filter_by} phx-change="filter">
        <div class="grid grid-rows-1 space-x-4 align-top">
          <div class="grid grid-cols-11 gap-4">
            <div class="col-span-1"></div>
            <.render_id_filter filter_by={@filter_by} form={f} />
            <div class="col-span-2">
              <.render_description_filter filter_by={@filter_by} form={f} />
            </div>
            <div class="col-span-2">
              <.render_source_language_filter filter_by={@filter_by} form={f} />
            </div>
            <.render_status_filter filter_by={@filter_by} form={f} />
            <.render_uploaded_by_filter filter_by={@filter_by} form={f} />
            <div class="max-w-40">
              <.render_public_filter filter_by={@filter_by} form={f} />
            </div>
            <.clear_button />
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def users_filters_form(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@filter_by} phx-change="filter">
        <div class="grid grid-rows-1 space-x-4 align-top">
          <div class="grid grid-cols-11 gap-4">
            <div class="col-span-2"></div>
            <.render_id_filter filter_by={@filter_by} form={f} />
            <div class="col-span-2">
              <.render_email_filter filter_by={@filter_by} form={f} />
            </div>
            <div class="col-span-2">
              <.render_username_filter filter_by={@filter_by} form={f} />
            </div>
            <.render_admin_filter filter_by={@filter_by} form={f} />
            <.clear_button />
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def render_id_filter(assigns) do
    value = get_in(assigns, [:filter_by, "id"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          name="id"
          value={@value}
          field={@form[:id]}
          type="text"
          label="ID"
          class="pr-0 py-0 h-[22px]"
        />
      </div>
    </div>
    """
  end

  def render_email_filter(assigns) do
    value = get_in(assigns, [:filter_by, "email"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input value={@value} field={@form[:email]} type="text" label="Email" class="pr-0 py-0" />
      </div>
    </div>
    """
  end

  def render_username_filter(assigns) do
    value = get_in(assigns, [:filter_by, "username"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          value={@value}
          field={@form[:username]}
          type="text"
          label="Username"
          class="pr-0 py-0"
        />
      </div>
    </div>
    """
  end

  def render_admin_filter(assigns) do
    id = "admin_filter"
    value = get_in(assigns, [:filter_by, "admin"])
    assigns = assigns |> assign(value: value, id: id)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.label for={@id}>User Type</.label>
        <.input
          id={@id}
          value={@value}
          field={@form[:is_admin]}
          type="select"
          options={[{"All", nil}, {"Admin", "true"}, {"User", "false"}]}
          class="pr-0 py-0"
        />
      </div>
    </div>
    """
  end

  def render_description_filter(assigns) do
    value = get_in(assigns, [:filter_by, "description"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          name="description"
          value={@value}
          field={@form[:description]}
          type="text"
          label="Description"
          class="pr-0 py-0 h-[22px]"
        />
      </div>
    </div>
    """
  end

  def render_source_language_filter(assigns) do
    value = get_in(assigns, [:filter_by, "source_language"])
    languages = Language.languages_for_select()
    id = "source_language_filter"
    assigns = assigns |> assign(value: value, languages: languages, id: id)

    ~H"""
    <div class="flex flex-col text-sm justify-center max-w-60">
      <.label for={@id}>Source Language</.label>
      <.custom_live_select field={@form[:source_language]} options={@languages} id={@id} />
    </div>
    """
  end

  def render_status_filter(assigns) do
    value = get_in(assigns, [:filter_by, "status"])
    statuses = Analysis.statuses_for_select()
    id = "status_filter"
    assigns = assigns |> assign(value: value, statuses: statuses, id: id)

    ~H"""
    <div class="flex flex-col text-sm justify-center max-w-60">
      <.label for={@id}>Status</.label>
      <.custom_live_select field={@form[:status]} options={@statuses} id={@id} />
    </div>
    """
  end

  def render_uploaded_by_filter(assigns) do
    value = get_in(assigns, [:filter_by, "uploaded_by"])
    users = User.users_for_select()
    id = "uploaded_by_filter"
    assigns = assigns |> assign(value: value, users: users, id: id)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.label for={@id}>Uploaded By</.label>
        <.custom_live_select field={@form[:uploaded_by]} options={@users} id={@id} />
      </div>
    </div>
    """
  end

  def render_public_filter(assigns) do
    value = get_in(assigns, [:filter_by, "public"])
    id = "public_filter"
    assigns = assigns |> assign(value: value, id: id)

    ~H"""
    <div class="flex flex-col text-sm justify-center">
      <.label for={@id}>Visibility</.label>
      <.input
        type="select"
        value={@value}
        field={@form[:public]}
        options={[{"All", nil}, {"Public", "true"}, {"Private", "false"}]}
        class="pr-0 py-0"
      />
    </div>
    """
  end

  def render_column(assigns) do
    ~H"""

    """
  end

  def clear_button(assigns) do
    ~H"""
    <div class="mt-3">
      <.button type="clear" class="bg-red-600 hover:bg-red-400 max-h-10 p-0">
        Clear
      </.button>
    </div>
    """
  end

  defp text_input_class() do
    "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm text-gray-900 pr-0 py-0"
  end

  defp tag_class() do
    "bg-primary-200 flex p-1 rounded-lg text-sm"
  end

  attr :id, :string, required: true
  attr :field, :map, required: true
  attr :options, :list, required: true

  defp custom_live_select(assigns) do
    ~H"""
    <.live_select
      id={@id}
      field={@field}
      options={@options}
      mode={:tags}
      container_extra_class="flex flex-col"
      dropdown_extra_class="max-h-60 overflow-y-auto"
      text_input_class={text_input_class()}
      text_input_selected_class={text_input_class()}
      tags_container_extra_class="order-last"
      tag_class={tag_class()}
    />
    """
  end
end
