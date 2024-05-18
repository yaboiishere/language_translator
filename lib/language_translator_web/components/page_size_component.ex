defmodule LanguageTranslatorWeb.PageSizeComponent do
  alias LanguageTranslatorWeb.Changesets.PaginationChangeset
  alias LanguageTranslatorWeb.Util
  use Phoenix.LiveComponent

  import LiveSelect

  def mount(assigns) do
    assigns =
      assigns
      |> assign(expanded: false)
      |> assign(options: Util.page_size_options())

    {:ok, assigns}
  end

  def update(%{pagination: pagination} = assigns, socket) do
    pagination = PaginationChangeset.to_string_map(pagination)

    socket =
      socket
      |> assign(assigns)
      |> assign(pagination: pagination)

    {:ok, socket}
  end

  def handle_event("toggle", _params, %{assigns: %{expanded: expanded}} = socket) do
    {:noreply, assign(socket, expanded: !expanded)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, expanded: false)}
  end

  def render(assigns) do
    ~H"""
    <div class="relative">
      <.form :let={f} for={@pagination} phx-change="page_size">
        <.live_select
          field={f[:page_size]}
          options={@options}
          mode={:single}
          text_input_class="text-secondary-950 align-center flex rounded-lg hover:bg-primary-200 bg-primary-300 py-2 px-3 
          text-sm font-semibold leading-6 hover:text-text-medium w-20 border-none cursor-pointer"
        >
        </.live_select>
        <svg
          class="absolute inset-y-4 right-2.5 w-2.5 h-2.5 my-auto"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 10 6"
        >
          <path
            stroke="currentColor"
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="m1 1 4 4 4-4"
          />
        </svg>
      </.form>
    </div>
    """
  end
end
