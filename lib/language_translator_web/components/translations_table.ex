defmodule LanguageTranslatorWeb.TranslationsTable do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{analysis_id: analysis_id}, socket) do
    words = Models.words_ordered_by_language(analysis_id)

    columns =
      Enum.reduce(words, [], fn %{target: %{language: %{code: code, display_name: language}}},
                                acc ->
        if Enum.member?(acc, "#{language} - #{code}") do
          acc
        else
          ["#{language} - #{code}" | acc]
        end
      end)

    rows =
      Enum.reduce(words, %{}, fn %{
                                   source: %{word: %{text: source}},
                                   target: %{word: %{text: text}}
                                 },
                                 acc ->
        Map.update(acc, source, [text], &[text | &1])
      end)

    socket = assign(socket, rows: rows, columns: columns)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full">
      <%= if Kernel.map_size(@rows) == 0 do %>
        <div class="text-center text-gray-300 dark:text-gray-900">
          No translations available
        </div>
      <% else %>
        <div class="relative overflow-auto shadow-md rounded-lg scrollbar-top">
          <table class="auto w-full whitespace-nowrap text-sm text-left rtl:text-right text-gray-500 scrollbar-top-content">
            <thead class="sticky top-0 text-xs text-gray-700 uppercase bg-gray-100">
              <tr>
                <th scope="col" class="sticky left-0 px-6 py-3 bg-gray-100">Source</th>
                <%= for column <- @columns do %>
                  <th scope="col" class="px-6 py-3"><%= column %></th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for {source, translations} <- @rows do %>
                <tr class="group bg-white border-b hover:bg-background-secondary hover:text-gray-100">
                  <th class="sticky left-0 px-6 py-4 font-medium text-gray-900 whitespace-nowrap bg-gray-100 group-hover:bg-background-secondary">
                    <%= source %>
                  </th>
                  <%= for {translation, i} <- Enum.with_index(translations) do %>
                    <%= if rem(i, 2) == 1 do %>
                      <td class="px-6 py-4 font-medium bg-gray-50 group-hover:bg-background-secondary">
                        <%= translation %>
                      </td>
                    <% else %>
                      <td class="px-6 py-4 font-medium ">
                        <%= translation %>
                      </td>
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
end
