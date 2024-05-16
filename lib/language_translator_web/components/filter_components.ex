defmodule LanguageTranslatorWeb.FilterComponents do
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

  attr :filter_by, :map, required: true

  def user_filters_form(assigns) do
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

  attr :filter_by, :map, required: true

  def word_filters_form(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={@filter_by} phx-change="filter">
        <div class="grid grid-rows-1 space-x-4 align-top">
          <div class="grid grid-cols-11 gap-4">
            <div class="col-span-2"></div>
            <.render_id_filter filter_by={@filter_by} form={f} />
            <div class="col-span-2">
              <.render_source_language_filter filter_by={@filter_by} form={f} />
            </div>
            <.render_text_filter filter_by={@filter_by} form={f} />
            <.render_romanized_text_filter filter_by={@filter_by} form={f} />
            <.render_language_code_filter filter_by={@filter_by} form={f} />
            <.clear_button />
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def render_id_filter(assigns) do
    value = get_in(assigns, [:filter_by, "id"])
    id = "id_filter"
    assigns = assigns |> assign(value: value, id: id)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.label for={@id}>ID</.label>
        <.custom_live_select field={@form[:id]} options={[]} id={@id} />
      </div>
    </div>
    """
  end

  def render_text_filter(assigns) do
    value = get_in(assigns, [:filter_by, "text"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          name="text"
          value={@value}
          field={@form[:text]}
          type="text"
          label="Text"
          class="pr-0 py-0 h-[22px]"
        />
      </div>
    </div>
    """
  end

  def render_romanized_text_filter(assigns) do
    value = get_in(assigns, [:filter_by, "romanized_text"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          name="romanized_text"
          value={@value}
          field={@form[:romanized_text]}
          type="text"
          label="Romanized Text"
          class="pr-0 py-0 h-[22px]"
        />
      </div>
    </div>
    """
  end

  def render_language_code_filter(assigns) do
    value = get_in(assigns, [:filter_by, "language_code"])
    languages = Language.language_codes_for_select()
    id = "language_code_filter"
    assigns = assigns |> assign(value: value, languages: languages, id: id)

    ~H"""
    <div class="flex flex-col text-sm justify-center max-w-60">
      <.label for={@id}>Language Code</.label>
      <.custom_live_select field={@form[:language_code]} options={@languages} id={@id} />
    </div>
    """
  end

  def render_email_filter(assigns) do
    value = get_in(assigns, [:filter_by, "email"])
    assigns = assigns |> assign(value: value)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.input
          value={@value}
          field={@form[:email]}
          type="text"
          label="Email"
          class="pr-0 py-0 h-[22px]"
        />
      </div>
    </div>
    """
  end

  def render_username_filter(assigns) do
    value = get_in(assigns, [:filter_by, "username"])
    id = "username_filter"
    users = User.users_for_select()
    assigns = assigns |> assign(value: value, users: users, id: id)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.label for={@id}>Username</.label>
        <.custom_live_select field={@form[:username]} options={@users} id={@id} />
      </div>
    </div>
    """
  end

  def render_admin_filter(assigns) do
    id = "admin_filter"
    value = get_in(assigns, [:filter_by, "admin"])
    options = [{"All", nil}, {"Admin", "true"}, {"User", "false"}]
    assigns = assigns |> assign(value: value, id: id, options: options)

    ~H"""
    <div>
      <div class="flex flex-col text-sm justify-center">
        <.label for={@id}>User Type</.label>
        <.single_live_select field={@form[:admin]} options={@options} id={@id} placeholder="All" />
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
      phx-blur="live_select_blur"
    />
    """
  end

  attr :id, :string, required: true
  attr :field, :map, required: true
  attr :options, :list, required: true
  attr :placeholder, :string

  defp single_live_select(assigns) do
    ~H"""
    <.live_select
      id={@id}
      field={@field}
      options={@options}
      mode={:single}
      container_extra_class="flex flex-col"
      dropdown_extra_class="max-h-60 overflow-y-auto"
      text_input_class={text_input_class()}
      text_input_selected_class={text_input_class()}
      tags_container_extra_class="order-last"
      tag_class={tag_class()}
      phx-blur="live_select_blur"
      placeholder={@placeholder}
    />
    """
  end
end
