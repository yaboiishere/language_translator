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
          order_and_filter: order_and_filter,
          source_language: source_language
        },
        socket
      ) do
    socket =
      assign(socket,
        entries: entries,
        columns: columns,
        order_and_filter: order_and_filter,
        source_language: source_language
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
          <table class="w-full whitespace-nowrap text-md text-left rtl:text-right text-secondary-950 border border-2">
            <thead class="text-sm w-full">
              <tr class="sticky top-0 z-40 border-b">
                <th
                  scope="col"
                  class="relative sticky top-0 -left-1 px-6 py-3 text-secondary-950 uppercase bg-primary-300"
                >
                  <div class="mx-auto">
                    <%= "#{@source_language.display_name} - #{@source_language.code}" %>
                  </div>
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
                    class="sticky -left-1 px-6 py-4 font-medium whitespace-nowrap bg-primary-300  max-w-80"
                    phx-click="show_word"
                    phx-value-text={source.text}
                    phx-value-language_code={source.language_code}
                  >
                    <div class="text-center">
                      <%= source.text %>
                      <div class="text-gray-500">
                        <%= source.romanized_text %>
                      </div>
                    </div>
                  </td>
                  <%= for {column, i} <- Enum.with_index(@columns) do %>
                    <%= if column[:id] in @order_and_filter.show_cols do %>
                      <% word = Enum.at(translations, i) %>
                      <.word word={word} index={i} />
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

  defp word(
         assigns = %{
           word: %Table{
             text: text,
             romanized_text: romanized_text,
             lavenshtein: lavenshtein,
             language_code: language_code
           },
           index: index
         }
       ) do
    extra_classes =
      if rem(index, 2) == 0,
        do: "bg-primary-100 group-hover:bg-primary-200",
        else: "bg-white  group-hover:bg-primary-100"

    assigns =
      assign(assigns,
        extra_classes: extra_classes,
        text: text,
        romanized_text: romanized_text,
        lavenshtein: lavenshtein,
        language_code: language_code
      )

    ~H"""
    <td
      class={["min-w-52 px-5 font-medium cursor-pointer", @extra_classes]}
      phx-click="show_word"
      phx-value-text={@text}
      phx-value-language_code={@language_code}
    >
      <div class="flex justify-between gap-4 w-full ">
        <div class="text-center">
          <div class="font-medium ">
            <%= @text %>
          </div>
          <div class="text-gray-500">
            <%= @romanized_text %>
          </div>
        </div>
        <div class="my-auto font-semibold text-gray-900 group-hover:text-secondary-800 text-center">
          <%= "#{@lavenshtein}" %>
        </div>
      </div>
    </td>
    """
  end
end
