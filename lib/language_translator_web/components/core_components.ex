defmodule LanguageTranslatorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LanguageTranslatorWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="bg-primary-100/90 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        <%= gettext("Hang in there while we get back on track") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg hover:bg-primary-200 bg-primary-300 py-2 px-3",
        "text-sm font-semibold leading-6 text-text-light hover:text-text-medium",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-secondary-950">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-secondary-200 text-secondary-950 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm text-gray-900"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-primary-950 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-secondary-950">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-secondary-950">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-secondary-950">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 lg:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-secondary-950">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-secondary-200 border-t border-secondary-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-primary-200 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-secondary-950"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="flex text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-primary-200 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-secondary-950 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-x divide-secondary-200 flex justify-between">
        <div
          :for={item <- @item}
          class="gap-4 py-4 text-md leading-6 sm:gap-8 w-full mx-auto text-center"
        >
          <dt class="text-secondary-950 font-bold"><%= item.title %></dt>
          <dd class="text-secondary-950"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  attr(:id, :string, required: true)

  slot(:button, required: true)
  slot(:content, required: true)

  def dropdown(assigns) do
    ~H"""
    <div class="relative" data-component="dropdown">
      <button
        type="button"
        class="inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
        id={"#{@id}-button"}
        aria-expanded="false"
        phx-click={JS.dispatch("toggle", to: "##{@id}-menu")}
        phx-click-away={JS.dispatch("close", to: "##{@id}-menu")}
      >
        <%= render_slot(@button) %>
      </button>

      <nav
        hidden="true"
        class="absolute right-0 z-10 mt-2 w-56 origin-top-right divide-y divide-gray-100 rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5"
        id={"#{@id}-menu"}
      >
        > <%= render_slot(@content) %>
      </nav>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(LanguageTranslatorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(LanguageTranslatorWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def toggle(assigns) do
    ~H"""
    <div class="relative w-11 h-6 bg-gray-600 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-gray-100 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-primary-300">
    </div>
    """
  end

  def logo(assigns) do
    ~H"""
    <svg viewBox="0 0 480.002 480.002" xml:space="preserve">
      <path d="M469.877,170.658c0.066-0.297,0.138-0.584,0.199-0.89l-0.497-0.099c-11.323-37.129-31.648-71.148-59.873-99.374
    C364.376,24.965,304.106,0,240,0S115.624,24.965,70.294,70.296c-45.33,45.33-70.293,105.6-70.293,169.706
    s24.964,124.376,70.293,169.706S175.893,480.002,240,480.002c64.107,0,124.376-24.964,169.707-70.294
    c45.331-45.33,70.295-105.6,70.295-169.706C480.001,216.166,476.543,192.862,469.877,170.658z M345.198,46.682
    c16.934,9.246,32.733,20.785,47,34.471c-1.331,3.705-3.593,7.78-7.105,7.78c-0.055,0-0.11-0.001-0.166-0.003
    c-3.015-0.109-6.51-1.256-10.21-2.469c-5.606-1.838-11.961-3.924-19.181-3.341c-7.066,0.567-13.123,3.55-18.466,6.181
    c-5.009,2.466-9.334,4.599-12.433,3.824c-2.947-0.734-6.03-4.443-9.193-8.507c-1.406-1.806-2.276-3.101-2.596-3.861
    c0.377-0.629,1.144-1.622,1.552-2.15c3.982-5.154,10.708-11.751,17.213-18.131C336.306,55.872,341.09,51.169,345.198,46.682z
    M274.868,22.747c-1.166,7.447-4.387,17.263-7.303,20.87c-3.223,3.985-8.92,5.825-12.7,4.104c-3.813-1.738-6.832-7.169-8.074-14.528
    c-0.814-4.824-2.419-9.183-4.113-13.159C253.557,20.162,264.308,21.075,274.868,22.747z M84.437,84.438
    c26.093-26.093,57.588-44.82,91.961-55.146c4.151,13.648,9.206,26.434,14.136,38.517c3.774,9.253,8.053,19.739,7.087,29.229
    c-0.37,3.634-1.293,8.281-3.594,9.786c-2.001,1.31-6.018,1.645-10.269,2c-7.008,0.585-15.729,1.313-23.673,6.891
    c-1.697,1.191-3.273,2.423-4.796,3.612c-3.273,2.557-6.365,4.971-9.248,5.779c-2.85,0.8-6.522,0.381-10.776-0.104
    c-2.443-0.278-4.97-0.565-7.644-0.653c-8.488-0.312-27.836,3.766-36.26,14.768c-4.163,5.437-5.362,12.009-3.376,18.506
    c1.471,4.815,4.623,8.174,7.514,10.826c13.503,12.38,32.035,21.148,50.842,24.058c2.69,0.416,5.294,0.734,7.813,1.043
    c13.791,1.688,20.652,2.915,25.868,12.314c1.299,2.341,2.345,5.112,3.453,8.046c1.275,3.379,2.594,6.873,4.515,10.395
    c5.704,10.463,15.32,16.592,25.086,16.048c7.29-0.42,12.674-4.225,17-7.281c1.996-1.41,3.881-2.742,5.494-3.414
    c4.335-1.81,10.953-0.203,17.695,4.291c4.624,3.083,10.606,8.183,12.845,14.97c1.685,5.106,0.519,11.017-2.75,13.78L233.97,287.8
    c-9.464,8.084-19.59,17.9-19.931,32.135c-0.108,4.502,0.821,8.825,1.64,12.64c0.574,2.669,1.533,7.137,1.018,8.304
    c-0.539,0.479-3.059,1.097-4.564,1.466c-2.652,0.649-5.657,1.385-8.711,2.928c-14.806,7.476-16.189,25.188-17.105,36.91
    c-0.664,8.503-3.818,15.659-7.033,15.953c-2.615,0.251-6.308-4.27-7.591-9.281c-0.796-3.109-1.17-6.575-1.566-10.245
    c-0.57-5.287-1.217-11.28-3.34-17.165c-2.736-7.583-7.499-13.834-11.701-19.349c-4.127-5.418-8.026-10.535-9.285-15.858
    c-0.943-3.987-0.563-8.778-0.159-13.852c0.514-6.46,1.096-13.782-0.953-21.235c-2.912-10.594-10.128-18.164-16.495-24.845
    c-4.181-4.386-8.13-8.529-10.476-13.005c-2.828-5.396-2.477-11.052-2.07-17.601c0.385-6.207,0.822-13.243-1.649-20.482
    c-2.468-7.229-8.302-11.405-12.623-14.499c-12.668-9.069-24.534-19.397-35.267-30.698c-5.738-6.041-11.347-12.639-13.52-19.942
    c-0.568-1.909-0.961-3.351-1.27-4.479c-1.373-5.028-2.182-6.824-5.067-10.017C56.295,117.009,69.088,99.787,84.437,84.438z
    M240,460.002c-58.764,0-114.011-22.884-155.563-64.437c-41.552-41.552-64.436-96.799-64.436-155.563
    c0-27.796,5.127-54.803,14.921-79.949c3.779,9.331,10.196,16.907,16.686,23.74c11.604,12.217,24.432,23.383,38.187,33.229
    c1.943,1.392,4.881,3.495,5.277,4.656c1.191,3.49,0.924,7.797,0.615,12.782c-0.492,7.922-1.103,17.779,4.317,28.122
    c3.648,6.961,8.765,12.329,13.713,17.521c5.425,5.691,10.11,10.607,11.687,16.347c1.118,4.067,0.721,9.063,0.301,14.35
    c-0.484,6.092-1.033,12.996,0.633,20.04c2.237,9.46,7.87,16.853,12.839,23.375c3.653,4.795,7.103,9.323,8.796,14.016
    c1.309,3.628,1.775,7.949,2.268,12.523c0.454,4.209,0.924,8.561,2.076,13.06c3.176,12.408,13.243,24.335,26.682,24.334
    c0.691,0,1.393-0.031,2.102-0.096c13.963-1.274,23.601-14.423,25.154-34.313c0.6-7.686,1.422-18.212,6.18-20.613
    c1.016-0.514,2.686-0.923,4.454-1.355c4.083-1,9.673-2.369,14.111-6.914c8.131-8.327,5.878-18.82,4.232-26.48
    c-0.643-2.996-1.251-5.825-1.2-7.961c0.144-5.997,6.748-12.13,12.926-17.407l29.353-25.072c9.555-8.08,13.088-22.26,8.791-35.285
    c-3.186-9.657-10.359-18.421-20.746-25.346c-12.686-8.454-25.641-10.624-36.479-6.112c-3.657,1.523-6.679,3.659-9.346,5.543
    c-2.475,1.749-5.034,3.558-6.609,3.648c-1.571,0.101-4.382-1.999-6.375-5.654c-1.258-2.308-2.28-5.017-3.363-7.885
    c-1.312-3.476-2.669-7.07-4.676-10.688c-10.392-18.726-26.614-20.71-40.926-22.462c-2.364-0.289-4.808-0.588-7.185-0.956
    c-15.001-2.319-29.72-9.257-40.382-19.032c-1.345-1.233-1.79-1.795-1.935-2.037c-0.014-0.056-0.023-0.099-0.028-0.13
    c1.321-3.073,13.3-7.396,19.91-7.204c1.869,0.062,3.894,0.293,6.038,0.537c5.538,0.631,11.814,1.347,18.437-0.51
    c6.686-1.874,11.72-5.806,16.162-9.274c1.387-1.084,2.698-2.107,3.979-3.007c3.512-2.466,8.3-2.865,13.844-3.328
    c10.967-0.915,29.323-2.447,32.097-29.691c1.471-14.451-4.039-27.957-8.466-38.809c-4.624-11.335-9.365-23.287-13.236-35.832
    c8.323-1.688,16.779-2.892,25.336-3.614c0.479,1.097,0.961,2.181,1.441,3.246c1.952,4.334,3.796,8.427,4.479,12.467
    c2.418,14.329,9.344,24.771,19.5,29.399c3.636,1.657,7.559,2.451,11.516,2.451c9.261,0,18.703-4.353,25.031-12.181
    c5.092-6.301,9.533-18.546,11.323-29.432c10.915,2.766,21.565,6.373,31.882,10.773c-2.766,2.83-5.762,5.77-8.715,8.665
    c-6.988,6.854-14.213,13.94-19.035,20.183c-1.909,2.471-4.793,6.204-5.609,11.369c-1.385,8.771,4.074,15.784,6.697,19.154
    c4.079,5.241,10.244,13.161,20.136,15.629c2.136,0.532,4.211,0.764,6.222,0.763c7.597,0,14.283-3.292,19.885-6.051
    c4.1-2.019,7.973-3.926,11.231-4.188c3.211-0.262,6.983,0.979,11.35,2.41c4.63,1.518,9.878,3.238,15.716,3.45
    c9.346,0.345,17.2-4.112,22.596-12.387c18.809,21.799,32.941,46.721,41.897,73.527c-1.472,1.064-4.468,1.204-11.5,1.292
    c-3.055,0.038-6.517,0.081-10.208,0.365c-10.281,0.789-18.232-2.155-27.437-5.566c-6.18-2.29-12.57-4.658-20.21-6.176
    c-19.248-3.831-39.138,6.926-50.672,27.396c-2.097,3.722-20.105,36.889-6.781,55.241c4.978,6.855,12.025,11.081,17.688,14.477
    c8.032,4.814,16.338,9.792,25.537,13.503c1.969,0.795,3.958,1.529,5.881,2.239c6.998,2.583,13.607,5.023,16.847,9.457
    c2.711,3.711,3.609,9.584,2.747,17.955c-0.655,6.353-3.022,12.81-5.529,19.645c-5.621,15.33-12.617,34.409,3.783,53.149
    c4.677,5.344,10.292,9.414,16.503,12.088c-3.139,3.566-6.391,7.055-9.78,10.444C354.011,437.118,298.764,460.002,240,460.002z
    M418.692,368.396c-5.705-1.022-10.759-3.917-14.8-8.534c-8.208-9.379-5.664-17.797-0.056-33.092
    c2.82-7.688,5.735-15.64,6.646-24.479c1.393-13.516-0.73-23.919-6.492-31.805c-6.8-9.308-17.038-13.087-26.07-16.421
    c-1.868-0.689-3.632-1.341-5.325-2.023c-7.745-3.125-15.027-7.489-22.736-12.109c-4.527-2.715-9.209-5.521-11.788-9.073
    c-3.17-4.366,0.728-20.731,8.021-33.673c5.479-9.721,16.454-20.158,29.35-17.598c6.08,1.208,11.461,3.202,17.159,5.313
    c10.455,3.874,21.27,7.889,35.921,6.754c3.05-0.234,6.037-0.272,8.925-0.309c5.195-0.065,11.221-0.144,16.727-1.937
    c3.839,16.391,5.827,33.337,5.827,50.592C460.001,286.733,445.515,331.231,418.692,368.396z" />
    </svg>
    """
  end
end
