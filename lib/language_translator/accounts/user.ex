defmodule LanguageTranslator.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias LanguageTranslator.Models.Analysis
  alias LanguageTranslator.Repo

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :is_admin, :boolean, default: false

    has_many :analysis, Analysis, on_delete: :nilify_all

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, LanguageTranslator.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(
        %LanguageTranslator.Accounts.User{hashed_password: hashed_password},
        password
      )
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  def make_admin(user) do
    change(user, is_admin: true)
  end

  def get_all(%{order_by: order_by, filter_by: filter_by}, preloads \\ []) do
    from(u in __MODULE__)
    |> filter_by(filter_by)
    |> order_by(^resolve_order_by(order_by))
    |> Repo.preload(preloads)
    |> Repo.all()
  end

  def users_for_select() do
    __MODULE__
    |> Repo.all()
    |> Enum.map(&{&1.username, &1.id})
  end

  defp filter_by(query, nil) do
    query
  end

  defp filter_by(query, %{} = filters) when map_size(filters) == 0 do
    query
  end

  defp filter_by(query, %{} = filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      filter_by(acc, {key, value})
    end)
  end

  defp filter_by(query, {"id", id}) do
    where(query, [a], a.id == ^id)
  end

  defp filter_by(query, {"email", email}) do
    where(query, [a], ilike(a.email, ^"%#{email}%"))
  end

  defp filter_by(query, {"username", username}) do
    where(query, [a], ilike(a.username, ^"%#{username}%"))
  end

  defp filter_by(query, {"admin", nil}) do
    query
  end

  defp filter_by(query, {"admin", admin}) do
    where(query, [a], a.is_admin == ^admin)
  end

  def resolve_order_by("email_asc"), do: [asc: :email]
  def resolve_order_by("email_desc"), do: [desc: :email]
  def resolve_order_by("username_asc"), do: [asc: :username]
  def resolve_order_by("username_desc"), do: [desc: :username]
  def resolve_order_by("admin_asc"), do: [asc: :is_admin]
  def resolve_order_by("admin_desc"), do: [desc: :is_admin]
  def resolve_order_by("created_at_asc"), do: [asc: :inserted_at]
  def resolve_order_by("created_at_desc"), do: [desc: :inserted_at]
  def resolve_order_by("updated_at_asc"), do: [asc: :updated_at]
  def resolve_order_by("updated_at_desc"), do: [desc: :updated_at]
  def resolve_order_by(_), do: []
end
