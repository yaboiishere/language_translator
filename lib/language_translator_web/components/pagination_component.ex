defmodule LanguageTranslatorWeb.PaginationComponent do
  use Phoenix.LiveComponent

  attr :pagination, :map, required: true

  def pagination(%{pagination: pagination} = assigns) do
    %{
      page: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } =
      pagination

    pages_ahead =
      cond do
        page == 1 -> 8
        page == 2 -> 7
        true -> 6
      end

    pages_behind =
      cond do
        page == total_pages -> 8
        page == total_pages - 1 -> 7
        true -> 6
      end

    assigns =
      assign(assigns,
        page: page,
        page_size: page_size,
        total_entries: total_entries,
        total_pages: total_pages,
        pages_ahead: pages_ahead,
        pages_behind: pages_behind
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
      <div class="">
        <nav class="flex max-w-full" aria-label="Pagination">
          <div class="col-span-1"><.first page={@page} /></div>
          <div class="col-span-1"><.prev page={@page} total_pages={@total_pages} /></div>
          <%= for idx <- ( @page - @pages_behind)..(@page + @pages_ahead) do %>
            <div class="col-span-1">
              <%= if idx == @page do %>
                <.active_page idx={idx} />
              <% else %>
                <%= if idx > 0 && idx <= @total_pages do %>
                  <.inactive_page idx={idx} />
                <% end %>
              <% end %>
            </div>
          <% end %>
          <div class="col-span-1"><.next page={@page} total_pages={@total_pages} /></div>
          <div class="col-span-1"><.last page={@page} total_pages={@total_pages} /></div>
        </nav>
        <div class="flex justify-end border-t border-gray-200 bg-white pr-0 py-0">
          <div class="text-sm text-gray-700">
            Showing <span class="font-medium"><%= @page_size * (@page - 1) + 1 %></span>
            to <span class="font-medium"><%= clamp(@page_size * @page, 0, @total_entries) %></span>
            of <span class="font-medium"><%= @total_entries %></span>
            results
          </div>
        </div>
      </div>
      """
    end
  end

  defp clamp(value, min, max) do
    if value < min, do: min, else: if(value > max, do: max, else: value)
  end

  defp active_page(assigns) do
    ~H"""
    <a
      href="#"
      aria-current="page"
      class="block items-center bg-primary-300 px-4 py-2 text-sm font-semibold text-secondary-950 focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-secondary-900"
      phx-click="nav"
      phx-value-page={@idx}
    >
      <%= @idx %>
    </a>
    """
  end

  defp inactive_page(assigns) do
    ~H"""
    <a
      href="#"
      class="block text-center py-2 w-10 text-sm font-semibold text-secondary-900 ring-1 ring-inset ring-secondary-200 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
      phx-click="nav"
      phx-value-page={@idx}
    >
      <%= @idx %>
    </a>
    """
  end

  defp first(assigns) do
    ~H"""
    <a
      href="#"
      class={[
        button_classes(),
        "rounded-l-md",
        if(@page <= 1, do: "pointer-events-none text-gray-400")
      ]}
      phx-click="nav"
      phx-value-page={1}
    >
      <%= "<<" %>
    </a>
    """
  end

  defp prev(assigns) do
    ~H"""
    <a
      href="#"
      class={[
        button_classes(),
        if(@page <= 1, do: "pointer-events-none text-gray-400")
      ]}
      phx-click="nav"
      phx-value-page={@page - 1}
    >
      <div><%= "<" %></div>
    </a>
    """
  end

  defp next(assigns) do
    ~H"""
    <a
      href="#"
      class={[
        button_classes(),
        if(@page >= @total_pages, do: "pointer-events-none text-gray-400")
      ]}
      phx-click="nav"
      phx-value-page={@page + 1}
    >
      <%= ">" %>
    </a>
    """
  end

  defp last(assigns) do
    ~H"""
    <a
      href="#"
      class={[
        button_classes(),
        "rounded-r-md",
        if(@page >= @total_pages, do: "pointer-events-none text-gray-400")
      ]}
      phx-click="nav"
      phx-value-page={@total_pages}
    >
      <%= ">>" %>
    </a>
    """
  end

  defp button_classes() do
    "block px-auto text-center py-1 px-2 text-secondary-950 ring-1 ring-inset ring-secondary-200 hover:bg-gray-50 focus:z-20 focus:outline-offset-0 h-full"
  end
end
