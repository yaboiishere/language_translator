defmodule LanguageTranslatorWeb.TranslationsTable do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslatorWeb.AnalysisLive.Show.Table

  def mount(socket) do
    socket =
      socket
      |> assign(rows: [], columns: [], expanded: false)

    {:ok, socket}
  end

  def update(
        %{
          entries: entries,
          columns: columns,
          order_and_filter: order_and_filter
        },
        socket
      ) do
    socket =
      assign(socket,
        entries: entries,
        columns: columns,
        order_and_filter: order_and_filter
      )

    {:ok, socket}
  end

  def handle_event("toggle", _, %{assigns: %{expanded: expanded}} = socket) do
    socket = assign(socket, expanded: !expanded)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full">
      <%= if length(@entries) == 0 do %>
        <div class="text-center text-secondary-950">
          No translations available
        </div>
      <% else %>
        <div class="relative overflow-x-auto shadow-md rounded-lg max-h-screen">
          <table class="auto w-full whitespace-nowrap text-md text-left rtl:text-right text-secondary-950">
            <thead class="text-sm">
              <tr class="sticky top-0 z-40 border-b">
                <th scope="col" class="relative px-6 py-3 text-secondary-950 uppercase bg-white">
                  Source
                </th>
                <%= for {column, i} <- Enum.with_index(@columns) do %>
                  <%= if column[:id] in @order_and_filter.show_cols do %>
                    <%= if rem(i, 2) == 1 do %>
                      <th scope="col" class="px-6 py-3 text-secondary-950 uppercase bg-white">
                        <%= "#{column[:label]} - #{column[:id]}" %>
                      </th>
                    <% else %>
                      <th scope="col" class="px-6 py-3 text-secondary-950 uppercase bg-primary-100">
                        <%= "#{column[:label]} - #{column[:id]}" %>
                      </th>
                    <% end %>
                  <% end %>
                <% end %>
              </tr>
            </thead>
            <tbody class="text-sm">
              <%= for {source, translations} <- @entries do %>
                <tr class="group bg-white border-b hover:bg-primary-100 hover:text-secondary-800 overflow-y-auto">
                  <td
                    class="sticky left-0 px-6 py-4 font-medium whitespace-nowrap bg-white group-hover:bg-primary-100 max-w-80"
                    phx-click="show_word"
                    phx-value-text={source.text}
                    phx-value-language_code={source.language_code}
                  >
                    <%= "#{source.text} - #{source.romanized_text}" %>
                  </td>
                  <%= for {column, i} <- Enum.with_index(@columns) do %>
                    <%= if column[:id] in @order_and_filter.show_cols do %>
                      <% %Table{
                        text: text,
                        romanized_text: romanized_text,
                        lavenshtein: lavenshtein,
                        language_code: language_code
                      } =
                        Enum.at(translations, i) %>

                      <%= if rem(i, 2) == 1 do %>
                        <td
                          class="px-10 py-4 font-medium cursor-pointer"
                          phx-click="show_word"
                          phx-value-text={text}
                          phx-value-language_code={language_code}
                        >
                          <%= "#{text} (#{romanized_text}) - #{lavenshtein}" %>
                        </td>
                      <% else %>
                        <td
                          class="px-10 py-4 font-medium bg-primary-100 group-hover:bg-primary-200 cursor-pointer"
                          phx-click="show_word"
                          phx-value-text={text}
                          phx-value-language_code={language_code}
                        >
                          <%= "#{text} (#{romanized_text}) - #{lavenshtein}" %>
                        </td>
                      <% end %>
                    <% end %>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp format_cols(columns) do
    Enum.map(columns, fn column ->
      [label | id_parts] =
        column
        |> String.split("-")
        |> Enum.map(&String.trim/1)

      id = Enum.join(id_parts, "-")

      %{label: label, id: id}
    end)
  end
end
