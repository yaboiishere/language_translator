defmodule LanguageTranslatorWeb.ShowColumnsComponent do
  alias LanguageTranslatorWeb.CoreComponents
  use Phoenix.LiveComponent
  import CoreComponents

  def mount(socket) do
    socket =
      socket
      |> assign(expanded: false)
      |> assign(search_form: %{"query" => ""})

    {:ok, socket}
  end

  def update(
        %{columns: columns} = assigns,
        %{assigns: %{search_form: %{"query" => query}}} = socket
      ) do
    filtered_columns = filter_columns(columns, query)

    socket =
      socket
      |> assign(assigns)
      |> assign(columns: columns)
      |> assign(filtered_columns: filtered_columns)

    {:ok, socket}
  end

  def handle_event("toggle", _params, %{assigns: %{expanded: expanded}} = socket) do
    {:noreply, assign(socket, expanded: !expanded)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, expanded: false)}
  end

  def handle_event("search", %{"query" => query}, %{assigns: %{columns: columns}} = socket) do
    filtered_columns = filter_columns(columns, query)

    socket = assign(socket, search_form: %{"query" => query}, filtered_columns: filtered_columns)
    {:noreply, socket}
  end

  defp filter_columns([], _query), do: []
  defp filter_columns(columns, ""), do: columns

  defp filter_columns(columns, query) do
    lower_query = String.downcase(query)

    Enum.filter(columns, fn col ->
      lower_label = String.downcase(col[:label])
      String.contains?(lower_label, lower_query)
    end)
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
          class="z-50 absolute bg-white divide-y divide-gray-100 rounded-lg shadow w-42 border border-secondary-500 min-w-60 max-h-96 overflow-y-auto mt-2"
          phx-click-away="close"
          phx-target={@myself}
        >
          <div class="flex p-2 rounded">
            <label class="inline-flex items-center w-full">
              <.button phx-click="show_all" class="w-full">Show all</.button>
              <.button phx-click="hide_all" class="w-full">Hide all</.button>
            </label>
          </div>
          <.form :let={f} for={@search_form} phx-change="search" phx-target={@myself}>
            <.input
              type="text"
              field={f[:query]}
              class="w-full p-2 rounded"
              placeholder="Search columns"
            />
          </.form>
          <form phx-change="show_cols">
            <ul class="p-3 space-y-1 text-sm text-gray-700">
              <%= for col <- @filtered_columns do %>
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
