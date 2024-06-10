defmodule LanguageTranslator.Translator.Supervisor do
  use Supervisor

  alias LanguageTranslator.Translator
  alias LanguageTranslator.GoogleApi.Translate
  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Repo

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children =
      children()

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp children do
    {:ok, languages} =
      if Application.get_env(:language_translator, :use_mock) do
        {:ok, all_languages()}
      else
        Translate.get_languages()
      end

    cleaned_languages = languages |> Enum.map(&Map.take(&1, [:code, :display_name]))

    {137, inserted_languages} =
      Repo.insert_all(Language, cleaned_languages,
        conflict_target: [:code],
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        returning: true
      )

    Enum.flat_map(inserted_languages, &create_worker/1)
  end

  defp create_worker(%Language{code: code} = language) do
    translator_id = String.to_atom(code <> "_translator")
    aggregator_id = String.to_atom(code <> "_aggregator")

    [
      %{id: translator_id, start: {Translator.GenServer, :start_link, [language]}},
      %{id: aggregator_id, start: {Translator.Aggregator, :start_link, [language]}}
    ]
  end

  defp all_languages do
    [
      %{code: "af", display_name: "Afrikaans"},
      %{code: "sq", display_name: "Albanian"},
      %{code: "am", display_name: "Amharic"},
      %{code: "ar", display_name: "Arabic"},
      %{code: "hy", display_name: "Armenian"},
      %{code: "as", display_name: "Assamese"},
      %{code: "ay", display_name: "Aymara"},
      %{code: "az", display_name: "Azerbaijani"},
      %{code: "bm", display_name: "Bambara"},
      %{code: "eu", display_name: "Basque"},
      %{code: "be", display_name: "Belarusian"},
      %{code: "bn", display_name: "Bengali"},
      %{code: "bho", display_name: "Bhojpuri"},
      %{code: "bs", display_name: "Bosnian"},
      %{code: "bg", display_name: "Bulgarian"},
      %{code: "ca", display_name: "Catalan"},
      %{code: "ceb", display_name: "Cebuano"},
      %{code: "ny", display_name: "Chichewa"},
      %{code: "zh", display_name: "Chinese (Simplified)"},
      %{code: "zh-CN", display_name: "Chinese (Simplified)"},
      %{code: "zh-TW", display_name: "Chinese (Traditional)"},
      %{code: "co", display_name: "Corsican"},
      %{code: "hr", display_name: "Croatian"},
      %{code: "cs", display_name: "Czech"},
      %{code: "da", display_name: "Danish"},
      %{code: "dv", display_name: "Divehi"},
      %{code: "doi", display_name: "Dogri"},
      %{code: "nl", display_name: "Dutch"},
      %{code: "en", display_name: "English"},
      %{code: "eo", display_name: "Esperanto"},
      %{code: "et", display_name: "Estonian"},
      %{code: "ee", display_name: "Ewe"},
      %{code: "tl", display_name: "Filipino"},
      %{code: "fil", display_name: "Filipino"},
      %{code: "fi", display_name: "Finnish"},
      %{code: "fr", display_name: "French"},
      %{code: "fy", display_name: "Frisian"},
      %{code: "gl", display_name: "Galician"},
      %{code: "lg", display_name: "Ganda"},
      %{code: "ka", display_name: "Georgian"},
      %{code: "de", display_name: "German"},
      %{code: "el", display_name: "Greek"},
      %{code: "gn", display_name: "Guarani"},
      %{code: "gu", display_name: "Gujarati"},
      %{code: "ht", display_name: "Haitian Creole"},
      %{code: "ha", display_name: "Hausa"},
      %{code: "haw", display_name: "Hawaiian"},
      %{code: "iw", display_name: "Hebrew"},
      %{code: "he", display_name: "Hebrew"},
      %{code: "hi", display_name: "Hindi"},
      %{code: "hmn", display_name: "Hmong"},
      %{code: "hu", display_name: "Hungarian"},
      %{code: "is", display_name: "Icelandic"},
      %{code: "ig", display_name: "Igbo"},
      %{code: "ilo", display_name: "Iloko"},
      %{code: "id", display_name: "Indonesian"},
      %{code: "ga", display_name: "Irish Gaelic"},
      %{code: "it", display_name: "Italian"},
      %{code: "ja", display_name: "Japanese"},
      %{code: "jw", display_name: "Javanese"},
      %{code: "jv", display_name: "Javanese"},
      %{code: "kn", display_name: "Kannada"},
      %{code: "kk", display_name: "Kazakh"},
      %{code: "km", display_name: "Khmer"},
      %{code: "rw", display_name: "Kinyarwanda"},
      %{code: "gom", display_name: "Konkani"},
      %{code: "ko", display_name: "Korean"},
      %{code: "kri", display_name: "Krio"},
      %{code: "ku", display_name: "Kurdish (Kurmanji)"},
      %{code: "ckb", display_name: "Kurdish (Sorani)"},
      %{code: "ky", display_name: "Kyrgyz"},
      %{code: "lo", display_name: "Lao"},
      %{code: "la", display_name: "Latin"},
      %{code: "lv", display_name: "Latvian"},
      %{code: "ln", display_name: "Lingala"},
      %{code: "lt", display_name: "Lithuanian"},
      %{code: "lb", display_name: "Luxembourgish"},
      %{code: "mk", display_name: "Macedonian"},
      %{code: "mai", display_name: "Maithili"},
      %{code: "mg", display_name: "Malagasy"},
      %{code: "ms", display_name: "Malay"},
      %{code: "ml", display_name: "Malayalam"},
      %{code: "mt", display_name: "Maltese"},
      %{code: "mi", display_name: "Maori"},
      %{code: "mr", display_name: "Marathi"},
      %{code: "mni-Mtei", display_name: "Meiteilon (Manipuri)"},
      %{code: "lus", display_name: "Mizo"},
      %{code: "mn", display_name: "Mongolian"},
      %{code: "my", display_name: "Myanmar (Burmese)"},
      %{code: "ne", display_name: "Nepali"},
      %{code: "nso", display_name: "Northern Sotho"},
      %{code: "no", display_name: "Norwegian"},
      %{code: "or", display_name: "Odia (Oriya)"},
      %{code: "om", display_name: "Oromo"},
      %{code: "ps", display_name: "Pashto"},
      %{code: "fa", display_name: "Persian"},
      %{code: "pl", display_name: "Polish"},
      %{code: "pt", display_name: "Portuguese"},
      %{code: "pa", display_name: "Punjabi"},
      %{code: "qu", display_name: "Quechua"},
      %{code: "ro", display_name: "Romanian"},
      %{code: "ru", display_name: "Russian"},
      %{code: "sm", display_name: "Samoan"},
      %{code: "sa", display_name: "Sanskrit"},
      %{code: "gd", display_name: "Scots Gaelic"},
      %{code: "sr", display_name: "Serbian"},
      %{code: "st", display_name: "Sesotho"},
      %{code: "sn", display_name: "Shona"},
      %{code: "sd", display_name: "Sindhi"},
      %{code: "si", display_name: "Sinhala"},
      %{code: "sk", display_name: "Slovak"},
      %{code: "sl", display_name: "Slovenian"},
      %{code: "so", display_name: "Somali"},
      %{code: "es", display_name: "Spanish"},
      %{code: "su", display_name: "Sundanese"},
      %{code: "sw", display_name: "Swahili"},
      %{code: "sv", display_name: "Swedish"},
      %{code: "tg", display_name: "Tajik"},
      %{code: "ta", display_name: "Tamil"},
      %{code: "tt", display_name: "Tatar"},
      %{code: "te", display_name: "Telugu"},
      %{code: "th", display_name: "Thai"},
      %{code: "ti", display_name: "Tigrinya"},
      %{code: "ts", display_name: "Tsonga"},
      %{code: "tr", display_name: "Turkish"},
      %{code: "tk", display_name: "Turkmen"},
      %{code: "ak", display_name: "Twi"},
      %{code: "uk", display_name: "Ukrainian"},
      %{code: "ur", display_name: "Urdu"},
      %{code: "ug", display_name: "Uyghur"},
      %{code: "uz", display_name: "Uzbek"},
      %{code: "vi", display_name: "Vietnamese"},
      %{code: "cy", display_name: "Welsh"},
      %{code: "xh", display_name: "Xhosa"},
      %{code: "yi", display_name: "Yiddish"},
      %{code: "yo", display_name: "Yoruba"},
      %{code: "zu", display_name: "Zulu"}
    ]
  end
end
