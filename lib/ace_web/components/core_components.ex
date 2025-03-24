defmodule AceWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for the ACE web interface.
  
  The components in this module use Phoenix.Component,
  making them easy to use in LiveView templates.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button.

  ## Examples

      <.button>Send</.button>
      <.button phx-click="go" class="ml-2">Send</.button>
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
        "px-4 py-2 rounded-md bg-blue-600 text-white font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
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
    <header class={["flex items-center justify-between pb-4 border-b border-gray-200", @class]}>
      <div>
        <h1 class="text-2xl font-semibold text-gray-900">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-1 text-sm text-gray-500">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex items-center gap-2">
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  @doc """
  Renders a simple card.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["bg-white overflow-hidden shadow rounded-lg p-4", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a modal.
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
      class="hidden relative z-50"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-gray-900/90 transition-opacity" aria-hidden="true" />
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
            <.modal_content
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="bg-white rounded-lg shadow-lg relative"
            >
              <div class="absolute top-4 right-4">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-2 p-2 text-gray-400 hover:text-gray-500"
                  aria-label="close"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div id={"#{@id}-content"} class="p-4">
                <%= render_slot(@inner_block) %>
              </div>
            </.modal_content>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Internal component for modal content.
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def modal_content(assigns) do
    ~H"""
    <div id={@id} tabindex="-1" class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}")
    |> JS.hide(to: "##{id}-bg", transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"})
    |> JS.hide(to: "##{id}-container", transition: {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0", "opacity-0 translate-y-4"})
  end

  defp show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg", transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"})
    |> JS.show(to: "##{id}-container", transition: {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4", "opacity-100 translate-y-0"})
  end
  
  @doc """
  Shows the element by the given ID with a transition.
  """
  def show(id) do
    JS.show(to: id, transition: {"ease-in-out duration-300", "opacity-0", "opacity-100"})
  end
  
  @doc """
  Hides the element by the given ID with a transition.
  """
  def hide(id) do
    JS.hide(to: id, transition: {"ease-in-out duration-300", "opacity-100", "opacity-0"})
  end
  
  @doc """
  Renders a custom styled link.
  """
  attr :href, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(method data-confirm)
  slot :inner_block, required: true

  def custom_link(assigns) do
    ~H"""
    <a href={@href} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  @doc """
  Renders a heroicon.
  
  ## Examples
  
      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  
  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest}></span>
    """
  end
  
  @doc """
  Renders flash notices.
  
  ## Examples
  
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"
  
  slot :inner_block, doc: "the optional inner block that renders the flash message"
  
  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.remove_class("opacity-100") |> JS.hide(to: "##{@id}", time: 200, transition: {"ease-in duration-200", "opacity-100", "opacity-0"})}
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md shadow-zinc-900/5 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 p-3 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      role="alert"
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label="close">
        <.icon name="hero-x-mark" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
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
      <div class="mt-10 space-y-8">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end
  
  @doc """
  Renders a flash group with standard titles and content.
  
  ## Examples
  
      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  
  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
      hidden
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end
end 