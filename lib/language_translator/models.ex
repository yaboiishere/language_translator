defmodule LanguageTranslator.Models do
  @moduledoc """
  The Models context.
  """

  import Ecto.Query, warn: false
  alias LanguageTranslator.Repo

  alias LanguageTranslator.Models.Language
  alias LanguageTranslator.Models.AnalysisTranslation
  alias LanguageTranslator.Models.Word

  @doc """
  Returns the list of languages.

  ## Examples

      iex> list_languages()
      [%Language{}, ...]

  """
  def list_languages do
    Repo.all(Language)
  end

  @doc """
  Gets a single language.

  Raises `Ecto.NoResultsError` if the Language does not exist.

  ## Examples

      iex> get_language!(123)
      %Language{}

      iex> get_language!(456)
      ** (Ecto.NoResultsError)

  """
  def get_language!(id), do: Repo.get!(Language, id)

  @doc """
  Creates a language.

  ## Examples

      iex> create_language(%{field: value})
      {:ok, %Language{}}

      iex> create_language(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_language(attrs \\ %{}) do
    %Language{}
    |> Language.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a language.

  ## Examples

      iex> update_language(language, %{field: new_value})
      {:ok, %Language{}}

      iex> update_language(language, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_language(%Language{} = language, attrs) do
    language
    |> Language.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a language.

  ## Examples

      iex> delete_language(language)
      {:ok, %Language{}}

      iex> delete_language(language)
      {:error, %Ecto.Changeset{}}

  """
  def delete_language(%Language{} = language) do
    Repo.delete(language)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking language changes.

  ## Examples

      iex> change_language(language)
      %Ecto.Changeset{data: %Language{}}

  """
  def change_language(%Language{} = language, attrs \\ %{}) do
    Language.changeset(language, attrs)
  end

  alias LanguageTranslator.Models.Word

  @doc """
  Returns the list of words.

  ## Examples

      iex> list_words()
      [%Word{}, ...]

  """
  def list_words do
    Repo.all(Word)
  end

  @doc """
  Gets a single word.

  Raises `Ecto.NoResultsError` if the Word does not exist.

  ## Examples

      iex> get_word!(123)
      %Word{}

      iex> get_word!(456)
      ** (Ecto.NoResultsError)

  """
  def get_word!(id), do: Repo.get!(Word, id)

  @doc """
  Creates a word.

  ## Examples

      iex> create_word(%{field: value})
      {:ok, %Word{}}

      iex> create_word(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_word(attrs \\ %{}) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a word.

  ## Examples

      iex> update_word(word, %{field: new_value})
      {:ok, %Word{}}

      iex> update_word(word, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_word(%Word{} = word, attrs) do
    word
    |> Word.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a word.

  ## Examples

      iex> delete_word(word)
      {:ok, %Word{}}

      iex> delete_word(word)
      {:error, %Ecto.Changeset{}}

  """
  def delete_word(%Word{} = word) do
    Repo.delete(word)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking word changes.

  ## Examples

      iex> change_word(word)
      %Ecto.Changeset{data: %Word{}}

  """
  def change_word(%Word{} = word, attrs \\ %{}) do
    Word.changeset(word, attrs)
  end

  alias LanguageTranslator.Models.Translation

  @doc """
  Returns the list of translations.

  ## Examples

      iex> list_translations()
      [%Translation{}, ...]

  """
  def list_translations do
    Repo.all(Translation)
  end

  @doc """
  Gets a single translation.

  Raises `Ecto.NoResultsError` if the Translation does not exist.

  ## Examples

      iex> get_translation!(123)
      %Translation{}

      iex> get_translation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_translation!(id), do: Repo.get!(Translation, id)

  @doc """
  Creates a translation.

  ## Examples

      iex> create_translation(%{field: value})
      {:ok, %Translation{}}

      iex> create_translation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_translation(attrs \\ %{}) do
    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a translation.

  ## Examples

      iex> update_translation(translation, %{field: new_value})
      {:ok, %Translation{}}

      iex> update_translation(translation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_translation(%Translation{} = translation, attrs) do
    translation
    |> Translation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a translation.

  ## Examples

      iex> delete_translation(translation)
      {:ok, %Translation{}}

      iex> delete_translation(translation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_translation(%Translation{} = translation) do
    Repo.delete(translation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking translation changes.

  ## Examples

      iex> change_translation(translation)
      %Ecto.Changeset{data: %Translation{}}

  """
  def change_translation(%Translation{} = translation, attrs \\ %{}) do
    Translation.changeset(translation, attrs)
  end

  alias LanguageTranslator.Models.Analysis

  @doc """
  Gets a single analysis.

  Raises `Ecto.NoResultsError` if the Analysis does not exist.

  ## Examples

      iex> get_analysis!(123)
      %Analysis{}

      iex> get_analysis!(456)
      ** (Ecto.NoResultsError)

  """
  def get_analysis!(id, preloads \\ []) do
    Analysis
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a analysis.

  ## Examples

      iex> create_analysis(%{field: value})
      {:ok, %Analysis{}}

      iex> create_analysis(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_analysis(attrs \\ %{}) do
    %Analysis{}
    |> Analysis.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a analysis.

  ## Examples

      iex> update_analysis(analysis, %{field: new_value})
      {:ok, %Analysis{}}

      iex> update_analysis(analysis, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_analysis(%Analysis{} = analysis, attrs) do
    analysis
    |> Analysis.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a analysis.

  ## Examples

      iex> delete_analysis(analysis)
      {:ok, %Analysis{}}

      iex> delete_analysis(analysis)
      {:error, %Ecto.Changeset{}}

  """
  def delete_analysis(%Analysis{} = analysis) do
    Repo.delete(analysis)
  end

  alias LanguageTranslator.Models.AnalysisTranslation

  @doc """
  Returns the list of analysis_translations.

  ## Examples

      iex> list_analysis_translations()
      [%AnalysisTranslation{}, ...]

  """
  def list_analysis_translations do
    Repo.all(AnalysisTranslation)
  end

  @doc """
  Gets a single analysis_translation.

  Raises `Ecto.NoResultsError` if the Analysis translation does not exist.

  ## Examples

      iex> get_analysis_translation!(123)
      %AnalysisTranslation{}

      iex> get_analysis_translation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_analysis_translation!(id), do: Repo.get!(AnalysisTranslation, id)

  @doc """
  Creates a analysis_translation.

  ## Examples

      iex> create_analysis_translation(%{field: value})
      {:ok, %AnalysisTranslation{}}

      iex> create_analysis_translation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_analysis_translation(attrs \\ %{}) do
    %AnalysisTranslation{}
    |> AnalysisTranslation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a analysis_translation.

  ## Examples

      iex> update_analysis_translation(analysis_translation, %{field: new_value})
      {:ok, %AnalysisTranslation{}}

      iex> update_analysis_translation(analysis_translation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_analysis_translation(%AnalysisTranslation{} = analysis_translation, attrs) do
    analysis_translation
    |> AnalysisTranslation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a analysis_translation.

  ## Examples

      iex> delete_analysis_translation(analysis_translation)
      {:ok, %AnalysisTranslation{}}

      iex> delete_analysis_translation(analysis_translation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_analysis_translation(%AnalysisTranslation{} = analysis_translation) do
    Repo.delete(analysis_translation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking analysis_translation changes.

  ## Examples

      iex> change_analysis_translation(analysis_translation)
      %Ecto.Changeset{data: %AnalysisTranslation{}}

  """
  def change_analysis_translation(%AnalysisTranslation{} = analysis_translation, attrs \\ %{}) do
    AnalysisTranslation.changeset(analysis_translation, attrs)
  end
end
