defmodule LanguageTranslatorWeb.TranslationsTable do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models.Word
  alias LanguageTranslator.Models.Translation
  alias LanguageTranslator.Models.Language

  defmodule Table do
    defstruct lavenshtein: "0%",
              romanized_text: "",
              text: "",
              language_display_name: "",
              language_code: ""
  end

  def mount(socket) do
    socket =
      socket
      |> assign(rows: [], columns: [])

    {:ok, socket}
  end

  def update(%{analysis_id: analysis_id, order_and_filter: _order_and_filter}, socket) do
    words = Word.analysis_words(analysis_id)

    entries =
      words
      |> Enum.map(fn {%Word{text: text, romanized_text: romanized_text}, translations} ->
        {
          "#{text} - #{romanized_text}",
          translations
          |> Enum.map(fn
            %Translation{
              target_word: %Word{
                text: text,
                romanized_text: romanized_text,
                language: %Language{display_name: language, code: code}
              },
              similarity: similarity
            } ->
              %Table{
                lavenshtein:
                  similarity |> Float.round(2) |> Float.to_string() |> then(fn x -> "#{x}%" end),
                romanized_text: romanized_text,
                text: text,
                language_display_name: language,
                language_code: code
              }
          end)
        }
      end)

    columns =
      entries
      |> List.first()
      |> elem(1)
      |> Enum.map(fn %Table{
                       language_display_name: language_display_name,
                       language_code: language_code
                     } ->
        "#{language_display_name} - #{language_code}"
      end)

    socket = assign(socket, entries: entries, columns: columns)

    {:ok, socket}
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
                <th
                  scope="col"
                  phx-click="sort"
                  phx-value-sort_by="language"
                  class="relative px-6 py-3 text-secondary-950 uppercase bg-white"
                >
                  Source
                </th>
                <%= for {column, i} <- Enum.with_index(@columns) do %>
                  <%= if rem(i, 2) == 1 do %>
                    <th scope="col" class="px-6 py-3 text-secondary-950 uppercase bg-white">
                      <%= column %>
                    </th>
                  <% else %>
                    <th scope="col" class="px-6 py-3 text-secondary-950 uppercase bg-primary-100">
                      <%= column %>
                    </th>
                  <% end %>
                <% end %>
              </tr>
            </thead>
            <tbody class="text-sm">
              <%= for {source, translations} <- @entries do %>
                <tr class="group bg-white border-b hover:bg-primary-100 hover:text-secondary-800 overflow-y-auto">
                  <td
                    class="sticky left-0 px-6 py-4 font-medium whitespace-nowrap bg-white group-hover:bg-primary-100 max-w-80"
                    phx-click="sort"
                    phx-value-sort_by={source}
                  >
                    <%= source %>
                  </td>
                  <%= for {%Table{text: text, romanized_text: romanized_text, lavenshtein: lavenshtein}, i} <- Enum.with_index(translations) do %>
                    <%= if rem(i, 2) == 1 do %>
                      <td class="px-10 py-4 font-medium ">
                        <%= "#{text} (#{romanized_text}) - #{lavenshtein}" %>
                      </td>
                    <% else %>
                      <td class="px-10 py-4 font-medium bg-primary-100 group-hover:bg-primary-200">
                        <%= "#{text} (#{romanized_text}) - #{lavenshtein}" %>
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
