defmodule LanguageTranslatorWeb.UserRegistrationLive do
  alias LanguageTranslator.Models.Language
  use LanguageTranslatorWeb, :live_view

  alias LanguageTranslator.Accounts
  alias LanguageTranslator.Accounts.User

  import LiveSelect

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg bg-white p-5 rounded-lg text-secondary-950">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.label>
          Main language
          <p class="text-sm text-gray-500">The language you are most comfortable with</p>
          <.live_select
            field={@form[:main_language_code]}
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
          <.button id="register" phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign(languages: Language.languages_for_select())
      |> assign(page_title: "Register")
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp text_input_class() do
    "mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm text-gray-900"
  end

  defp tag_class() do
    "bg-primary-200 flex p-1 rounded-lg text-sm"
  end
end
