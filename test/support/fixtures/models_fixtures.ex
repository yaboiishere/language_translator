defmodule LanguageTranslator.ModelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LanguageTranslator.Models` context.
  """

  @doc """
  Generate a language.
  """
  def language_fixture(attrs \\ %{}) do
    {:ok, language} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> LanguageTranslator.Models.create_language()

    language
  end

  @doc """
  Generate a word.
  """
  def word_fixture(attrs \\ %{}) do
    {:ok, word} =
      attrs
      |> Enum.into(%{
        text: "some text"
      })
      |> LanguageTranslator.Models.create_word()

    word
  end

  @doc """
  Generate a translation.
  """
  def translation_fixture(attrs \\ %{}) do
    {:ok, translation} =
      attrs
      |> Enum.into(%{})
      |> LanguageTranslator.Models.create_translation()

    translation
  end

  @doc """
  Generate a analysis.
  """
  def analysis_fixture(attrs \\ %{}) do
    {:ok, analysis} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> LanguageTranslator.Models.create_analysis()

    analysis
  end

  @doc """
  Generate a analysis_translation.
  """
  def analysis_translation_fixture(attrs \\ %{}) do
    {:ok, analysis_translation} =
      attrs
      |> Enum.into(%{})
      |> LanguageTranslator.Models.create_analysis_translation()

    analysis_translation
  end
end
