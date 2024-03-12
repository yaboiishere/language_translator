defmodule LanguageTranslator.ModelsTest do
  use LanguageTranslator.DataCase

  alias LanguageTranslator.Models

  describe "languages" do
    alias LanguageTranslator.Models.Language

    import LanguageTranslator.ModelsFixtures

    @invalid_attrs %{name: nil}

    test "list_languages/0 returns all languages" do
      language = language_fixture()
      assert Models.list_languages() == [language]
    end

    test "get_language!/1 returns the language with given id" do
      language = language_fixture()
      assert Models.get_language!(language.id) == language
    end

    test "create_language/1 with valid data creates a language" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Language{} = language} = Models.create_language(valid_attrs)
      assert language.name == "some name"
    end

    test "create_language/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_language(@invalid_attrs)
    end

    test "update_language/2 with valid data updates the language" do
      language = language_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Language{} = language} = Models.update_language(language, update_attrs)
      assert language.name == "some updated name"
    end

    test "update_language/2 with invalid data returns error changeset" do
      language = language_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_language(language, @invalid_attrs)
      assert language == Models.get_language!(language.id)
    end

    test "delete_language/1 deletes the language" do
      language = language_fixture()
      assert {:ok, %Language{}} = Models.delete_language(language)
      assert_raise Ecto.NoResultsError, fn -> Models.get_language!(language.id) end
    end

    test "change_language/1 returns a language changeset" do
      language = language_fixture()
      assert %Ecto.Changeset{} = Models.change_language(language)
    end
  end

  describe "words" do
    alias LanguageTranslator.Models.Word

    import LanguageTranslator.ModelsFixtures

    @invalid_attrs %{text: nil}

    test "list_words/0 returns all words" do
      word = word_fixture()
      assert Models.list_words() == [word]
    end

    test "get_word!/1 returns the word with given id" do
      word = word_fixture()
      assert Models.get_word!(word.id) == word
    end

    test "create_word/1 with valid data creates a word" do
      valid_attrs = %{text: "some text"}

      assert {:ok, %Word{} = word} = Models.create_word(valid_attrs)
      assert word.text == "some text"
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_word(@invalid_attrs)
    end

    test "update_word/2 with valid data updates the word" do
      word = word_fixture()
      update_attrs = %{text: "some updated text"}

      assert {:ok, %Word{} = word} = Models.update_word(word, update_attrs)
      assert word.text == "some updated text"
    end

    test "update_word/2 with invalid data returns error changeset" do
      word = word_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_word(word, @invalid_attrs)
      assert word == Models.get_word!(word.id)
    end

    test "delete_word/1 deletes the word" do
      word = word_fixture()
      assert {:ok, %Word{}} = Models.delete_word(word)
      assert_raise Ecto.NoResultsError, fn -> Models.get_word!(word.id) end
    end

    test "change_word/1 returns a word changeset" do
      word = word_fixture()
      assert %Ecto.Changeset{} = Models.change_word(word)
    end
  end

  describe "translations" do
    alias LanguageTranslator.Models.Translation

    import LanguageTranslator.ModelsFixtures

    @invalid_attrs %{}

    test "list_translations/0 returns all translations" do
      translation = translation_fixture()
      assert Models.list_translations() == [translation]
    end

    test "get_translation!/1 returns the translation with given id" do
      translation = translation_fixture()
      assert Models.get_translation!(translation.id) == translation
    end

    test "create_translation/1 with valid data creates a translation" do
      valid_attrs = %{}

      assert {:ok, %Translation{} = translation} = Models.create_translation(valid_attrs)
    end

    test "create_translation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_translation(@invalid_attrs)
    end

    test "update_translation/2 with valid data updates the translation" do
      translation = translation_fixture()
      update_attrs = %{}

      assert {:ok, %Translation{} = translation} = Models.update_translation(translation, update_attrs)
    end

    test "update_translation/2 with invalid data returns error changeset" do
      translation = translation_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_translation(translation, @invalid_attrs)
      assert translation == Models.get_translation!(translation.id)
    end

    test "delete_translation/1 deletes the translation" do
      translation = translation_fixture()
      assert {:ok, %Translation{}} = Models.delete_translation(translation)
      assert_raise Ecto.NoResultsError, fn -> Models.get_translation!(translation.id) end
    end

    test "change_translation/1 returns a translation changeset" do
      translation = translation_fixture()
      assert %Ecto.Changeset{} = Models.change_translation(translation)
    end
  end

  describe "analysis" do
    alias LanguageTranslator.Models.Analysis

    import LanguageTranslator.ModelsFixtures

    @invalid_attrs %{name: nil}

    test "list_analysis/0 returns all analysis" do
      analysis = analysis_fixture()
      assert Models.list_analysis() == [analysis]
    end

    test "get_analysis!/1 returns the analysis with given id" do
      analysis = analysis_fixture()
      assert Models.get_analysis!(analysis.id) == analysis
    end

    test "create_analysis/1 with valid data creates a analysis" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Analysis{} = analysis} = Models.create_analysis(valid_attrs)
      assert analysis.name == "some name"
    end

    test "create_analysis/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_analysis(@invalid_attrs)
    end

    test "update_analysis/2 with valid data updates the analysis" do
      analysis = analysis_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Analysis{} = analysis} = Models.update_analysis(analysis, update_attrs)
      assert analysis.name == "some updated name"
    end

    test "update_analysis/2 with invalid data returns error changeset" do
      analysis = analysis_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_analysis(analysis, @invalid_attrs)
      assert analysis == Models.get_analysis!(analysis.id)
    end

    test "delete_analysis/1 deletes the analysis" do
      analysis = analysis_fixture()
      assert {:ok, %Analysis{}} = Models.delete_analysis(analysis)
      assert_raise Ecto.NoResultsError, fn -> Models.get_analysis!(analysis.id) end
    end

    test "change_analysis/1 returns a analysis changeset" do
      analysis = analysis_fixture()
      assert %Ecto.Changeset{} = Models.change_analysis(analysis)
    end
  end

  describe "analysis_translations" do
    alias LanguageTranslator.Models.AnalysisTranslation

    import LanguageTranslator.ModelsFixtures

    @invalid_attrs %{}

    test "list_analysis_translations/0 returns all analysis_translations" do
      analysis_translation = analysis_translation_fixture()
      assert Models.list_analysis_translations() == [analysis_translation]
    end

    test "get_analysis_translation!/1 returns the analysis_translation with given id" do
      analysis_translation = analysis_translation_fixture()
      assert Models.get_analysis_translation!(analysis_translation.id) == analysis_translation
    end

    test "create_analysis_translation/1 with valid data creates a analysis_translation" do
      valid_attrs = %{}

      assert {:ok, %AnalysisTranslation{} = analysis_translation} = Models.create_analysis_translation(valid_attrs)
    end

    test "create_analysis_translation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_analysis_translation(@invalid_attrs)
    end

    test "update_analysis_translation/2 with valid data updates the analysis_translation" do
      analysis_translation = analysis_translation_fixture()
      update_attrs = %{}

      assert {:ok, %AnalysisTranslation{} = analysis_translation} = Models.update_analysis_translation(analysis_translation, update_attrs)
    end

    test "update_analysis_translation/2 with invalid data returns error changeset" do
      analysis_translation = analysis_translation_fixture()
      assert {:error, %Ecto.Changeset{}} = Models.update_analysis_translation(analysis_translation, @invalid_attrs)
      assert analysis_translation == Models.get_analysis_translation!(analysis_translation.id)
    end

    test "delete_analysis_translation/1 deletes the analysis_translation" do
      analysis_translation = analysis_translation_fixture()
      assert {:ok, %AnalysisTranslation{}} = Models.delete_analysis_translation(analysis_translation)
      assert_raise Ecto.NoResultsError, fn -> Models.get_analysis_translation!(analysis_translation.id) end
    end

    test "change_analysis_translation/1 returns a analysis_translation changeset" do
      analysis_translation = analysis_translation_fixture()
      assert %Ecto.Changeset{} = Models.change_analysis_translation(analysis_translation)
    end
  end
end
