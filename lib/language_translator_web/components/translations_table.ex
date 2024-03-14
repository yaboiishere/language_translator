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
        <div class="overflow-x-auto">
          <table class="auto w-full whitespace-nowrap">
            <thead>
              <tr>
                <th class="border border-slate-600 px-3">Source</th>
                <%= for column <- @columns do %>
                  <th class="border border-slate-600 px-5"><%= column %></th>
                <% end %>
              </tr>
            </thead>
            <tbody>
              <%= for {source, translations} <- @rows do %>
                <tr>
                  <td class="border border-slate-600"><%= source %></td>
                  <%= for translation <- translations do %>
                    <td class="border border-slate-600"><%= translation %></td>
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
