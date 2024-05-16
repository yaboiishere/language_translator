defmodule LanguageTranslatorWeb.PageSizeComponent do
  use Phoenix.LiveComponent

  import LiveSelect

  def mount(assigns) do
    assigns =
      assigns
      |> assign(expanded: false)
      |> assign(options: [10, 20, 50, 100])

    {:ok, assigns}
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
      <.form :let={f} for={%{}} phx-change="page_size">
        <.live_select
          field={f[:page_size]}
          options={@options}
          mode={:single}
          text_input_class="text-secondary-950 align-center flex rounded-lg hover:bg-primary-200 bg-primary-300 py-2 px-3 
          text-sm font-semibold leading-6 hover:text-text-medium w-20 border-none cursor-pointer"
          value={@pagination.page_size}
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

    # ~H"""
    # <div class="relative">
    #   <button
    #     phx-click={if @expanded, do: "close", else: "toggle"}
    #     phx-target={@myself}
    #     class="align-center flex rounded-lg hover:bg-primary-200 bg-primary-300 py-2 px-3
    #      text-sm font-semibold leading-6 text-text-light hover:text-text-medium"
    #   >
    #     <span><%= "Page size: #{@pagination.page_size}" %></span>
    #     <svg
    #       class="w-2.5 h-2.5 ms-3 my-auto"
    #       aria-hidden="true"
    #       xmlns="http://www.w3.org/2000/svg"
    #       fill="none"
    #       viewBox="0 0 10 6"
    #     >
    #       <path
    #         stroke="currentColor"
    #         stroke-linecap="round"
    #         stroke-linejoin="round"
    #         stroke-width="2"
    #         d="m1 1 4 4 4-4"
    #       />
    #     </svg>
    #   </button>
    #   <!-- Dropdown menu -->
    #   <%= if @expanded do %>
    #     <div class="z-50 absolute right-0 bg-white divide-y divide-gray-100 rounded-lg shadow w-10 border border-secondary-500 max-h-60 overflow-y-auto mt-2">
    #       <form phx-change="page_size">
    #         <ul class="m-2text-sm text-gray-700"></ul>
    #       </form>
    #     </div>
    #   <% end %>
    # </div>
    # """
  end
end
