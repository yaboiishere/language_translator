defmodule LanguageTranslatorWeb.TranslationsTable do
  use LanguageTranslatorWeb, :live_component

  alias LanguageTranslator.Models.Word

  defmodule Translation do
    defstruct lavenshtein: "0%", romanized_text: "", text: ""
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{analysis_id: analysis_id}, socket) do
    words = Word.words_ordered_by_language(analysis_id)

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
      words
      |> Enum.reduce(%{}, fn %{
                               source: %{word: %{text: source}},
                               target: %{word: %{text: text}}
                             },
                             acc ->
        Map.update(acc, source, [text], &[text | &1])
      end)
      |> Enum.into(%{}, fn {source, translations} ->
        romanized_source = source |> AnyAscii.transliterate() |> IO.iodata_to_binary()

        Enum.map(translations, fn translation ->
          romanized = translation |> AnyAscii.transliterate() |> IO.iodata_to_binary()
          lavenshtein = Akin.Levenshtein.compare(romanized_source, romanized) * 100.0

          lavenshtein_string =
            lavenshtein |> Float.round(2) |> Float.to_string() |> then(fn x -> "#{x}%" end)

          %Translation{
            lavenshtein: lavenshtein_string,
            romanized_text: romanized,
            text: translation
          }
        end)
        |> then(fn x -> {source, x} end)
      end)

    socket = assign(socket, rows: rows, columns: columns)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full">
      <%= if Kernel.map_size(@rows) == 0 do %>
        <div class="text-center text-secondary-950">
          No translations available
        </div>
      <% else %>
        <div class="relative flex flex-grow overflow-x-auto shadow-md rounded-lg h-screen">
          <table class="auto w-full whitespace-nowrap text-md text-left rtl:text-right text-secondary-950">
            <thead class="text-sm">
              <tr class="sticky top-0 z-40 border-b">
                <th scope="col" class="relative px-6 py-3 text-secondary-950 uppercase bg-white">
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
            <tbody class="text-xs">
              <%= for {source, translations} <- @rows do %>
                <tr class="group bg-white border-b hover:bg-primary-100 hover:text-secondary-800 overflow-y-auto">
                  <td class="sticky left-0 px-6 py-4 font-medium whitespace-nowrap bg-white group-hover:bg-primary-100 max-w-80">
                    <%= "#{source} (#{source |> AnyAscii.transliterate() |> IO.iodata_to_binary()})" %>
                  </td>
                  <%= for {%Translation{text: text, romanized_text: romanized_text, lavenshtein: lavenshtein}, i} <- Enum.with_index(translations) do %>
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
