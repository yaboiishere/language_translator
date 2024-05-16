defmodule LanguageTranslatorWeb.PaginationComponent do
  use Phoenix.LiveComponent

  # attr :page, :integer, required: true
  # attr :total_entries, :integer, required: true
  # attr :page_size, :integer, required: true
  # attr :total_pages, :integer, required: false
  attr :pagination, :map, required: true

  def pagination(%{pagination: pagination} = assigns) do
    %{
      page: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      pagination

    assigns =
      assign(assigns,
        page: page,
        page_size: page_size,
        total_entries: total_entries,
        total_pages: total_pages
      )

    if total_pages == nil do
      ~H"""
      <nav class="border-t border-gray-200">
        <ul class="flex my-2">
          <li class="">
            <a class="px-2 py-2 pointer-events-none text-gray-600" href="#">
              Previous
            </a>
          </li>
          <li class="">
            <a class="px-2 py-2 pointer-events-none text-gray-600" href="#">
              1
            </a>
          </li>
          <li class="">
            <a class="px-2 py-2 pointer-events-none text-gray-600" href="#">
              Next
            </a>
          </li>
        </ul>
      </nav>
      """
    else
      ~H"""
      <nav class="border-t border-gray-200">
        <ul class="flex my-2">
          <li class="">
            <a
              class={["px-2 py-2", if(@page <= 1, do: "pointer-events-none text-gray-600")]}
              href="#"
              phx-click="nav"
              phx-value-page={@page + 1}
            >
              Previous
            </a>
          </li>
          <%= for idx <-  Enum.to_list(1..@total_pages) do %>
            <li class="">
              <a
                class={["px-2 py-2", if(@page == idx, do: "pointer-events-none text-gray-600")]}
                href="#"
                phx-click="nav"
                phx-value-page={idx}
              >
                <%= idx %>
              </a>
            </li>
          <% end %>
          <li class="">
            <a
              class={[
                "px-2 py-2",
                if(@page >= @total_pages, do: "pointer-events-none text-gray-600")
              ]}
              href="#"
              phx-click="nav"
              phx-value-page={@page + 1}
            >
              Next
            </a>
          </li>
        </ul>
      </nav>
      """
    end
  end
end
