defmodule LanguageTranslatorWeb.UserSettingsLive do
  alias LanguageTranslator.Repo
  alias LanguageTranslator.Models.Language
  use LanguageTranslatorWeb, :live_view
  import LiveSelect
  alias LanguageTranslator.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-screen-xl bg-white rounded-lg text-secondary-950 p-5">
      <.header class="text-center">
        Account Settings
        <:subtitle>Manage your account email address and password settings</:subtitle>
      </.header>
      <div class="grid grid-cols-3 divide-x justify-around mt-5">
        <div class="md:px-5">
          <.header class="text-center">Change Email</.header>
          <div class="-mt-8">
            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input field={@email_form[:email]} type="email" label="Email" required />
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label="Current password"
                value={@email_form_current_password}
                required
              />
              <:actions>
                <.button phx-disable-with="Changing...">Change Email</.button>
                <%= if @current_user.confirmed_at == nil do %>
                  <.button
                    phx-click="resend_confirmation_email"
                    phx-disable-with="Resending..."
                    class=""
                  >
                    Resend confirmation email
                  </.button>
                <% end %>
              </:actions>
            </.simple_form>
          </div>
        </div>
        <div class="md:px-5">
          <div class="">
            <.header class="text-center">Change Main Language</.header>
            <div class="-mt-8 ">
              <.simple_form
                for={@main_language_form}
                id="main_language_form"
                phx-submit="update_main_language"
              >
                <p class="text-sm text-gray-500 text-center">
                  The language you are most comfortable with
                </p>
                <.label>
                  Main Language
                  <.live_select
                    field={@main_language_form[:main_language_code]}
                    options={@languages}
                    mode={:single}
                    text_input_class={text_input_class()}
                    text_input_selected_class={text_input_class()}
                    tags_container_extra_class="order-last"
                    tag_class={tag_class()}
                    dropdown_extra_class="max-h-60 overflow-y-auto"
                  />
                </.label>
                <:actions>
                  <.button phx-disable-with="Changing...">Change Main Language</.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
          <div class="divide-y">
            <.header class="text-center mt-5">Change Username</.header>
            <div class="-mt-8">
              <.simple_form for={@username_form} id="username_form" phx-submit="update_username">
                <.input field={@username_form[:username]} type="text" label="Username" required />
                <:actions>
                  <.button phx-disable-with="Changing...">Change Username</.button>
                </:actions>
              </.simple_form>
            </div>
          </div>
        </div>
        <div class="md:px-5">
          <.header class="text-center">Change Password</.header>
          <div class="-mt-8">
            <.simple_form
              for={@password_form}
              id="password_form"
              action={~p"/users/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <.input
                field={@password_form[:username]}
                type="hidden"
                id="hidden_user_email"
                value={@current_user.username}
              />
              <.input field={@password_form[:password]} type="password" label="New password" required />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
              />
              <.input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                label="Current password"
                id="current_password_for_password"
                value={@current_password}
                required
              />
              <:actions>
                <.button phx-disable-with="Changing...">Change Password</.button>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    main_language_changeset = Accounts.change_user_main_language(user)
    languages = Language.languages_for_select()
    user_changeset = Accounts.change_user_username(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:main_language_form, to_form(main_language_changeset))
      |> assign(:username_form, to_form(user_changeset))
      |> assign(:languages, languages)
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_main_language", params, socket) do
    %{"user" => %{"main_language_code" => main_language_code}} = params
    user = socket.assigns.current_user

    case Accounts.update_user_main_language(user, main_language_code) do
      {:ok, _} ->
        main_language_changeset =
          Accounts.change_user_main_language(user, %{main_language_code: main_language_code})

        Repo.update!(main_language_changeset)

        main_language_form =
          to_form(main_language_changeset)

        {:noreply, assign(socket, main_language_form: main_language_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, main_language_form: to_form(changeset))}
    end
  end

  def handle_event("update_username", params, socket) do
    %{"user" => %{"username" => username}} = params
    user = socket.assigns.current_user

    case Accounts.update_user_username(user, username) do
      {:ok, _} ->
        username_changeset =
          Accounts.change_user_username(user, %{username: username})

        Repo.update!(username_changeset)

        username_form =
          to_form(username_changeset)

        {:noreply, assign(socket, username_form: username_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(changeset))}
    end
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options =
      case live_select_id do
        "user_main_language_code_live_select_component" -> Language.search_display_name(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  def handle_event(
        "live_select_blur",
        %{"id" => "user_main_language_code_live_select_component" = live_select_id},
        socket
      ) do
    options = Language.languages_for_select()

    send_update(LiveSelect.Component, id: live_select_id, options: options)
    {:noreply, socket}
  end

  def handle_event("resend_confirmation_email", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}")) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Confirmation email sent successfully.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Confirmation email could not be sent.")}
    end
  end

  defp text_input_class() do
    "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm text-gray-900"
  end

  defp tag_class() do
    "bg-primary-200 flex p-1 rounded-lg text-sm"
  end
end
