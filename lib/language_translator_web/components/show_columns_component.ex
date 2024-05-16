defmodule LanguageTranslatorWeb.ShowColumnsComponent do
  use Phoenix.LiveComponent

  def mount(assigns) do
    assigns =
      assigns
      |> assign(expanded: false)

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
    <div>
      <button
        phx-click={if @expanded, do: "close", else: "toggle"}
        phx-target={@myself}
        class="align-center flex rounded-lg hover:bg-primary-200 bg-primary-300 py-2 px-3
         text-sm font-semibold leading-6 text-text-light hover:text-text-medium text-secondary-950"
      >
        Hide columns
        <svg
          class="w-2.5 h-2.5 ms-3 my-auto"
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
      </button>
      <!-- Dropdown menu -->
      <%= if @expanded do %>
        <div
          class="z-50 absolute bg-white divide-y divide-gray-100 rounded-lg shadow w-42 border border-secondary-500 max-h-60 overflow-y-auto mt-2"
          phx-click-away="close"
          phx-target={@myself}
        >
          <form phx-change="show_cols">
            <ul class="p-3 space-y-1 text-sm text-gray-700">
              <%= for col <- @columns do %>
                <li>
                  <div class="flex p-2 rounded hover:bg-gray-100">
                    <label class="inline-flex items-center w-full cursor-pointer">
                      <input type="hidden" name={col[:id]} value="false" />
                      <input
                        type="checkbox"
                        name={col[:id]}
                        value="true"
                        checked={col[:id] in @show_cols}
                        class="sr-only peer"
                      />
                      <div class="relative w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-gray-100 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-primary-300">
                      </div>
                      <span class="ms-3 text-sm font-medium text-secondary-900">
                        <%= col[:label] %>
                      </span>
                    </label>
                  </div>
                </li>
              <% end %>
            </ul>
          </form>
        </div>
      <% end %>
    </div>
    """
  end
end
