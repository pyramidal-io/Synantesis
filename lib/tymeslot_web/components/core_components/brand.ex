defmodule TymeslotWeb.Components.CoreComponents.Brand do
  @moduledoc "Brand-related components (logos, marks) extracted from CoreComponents."
  use Phoenix.Component
  use Gettext, backend: TymeslotWeb.Gettext

  alias Tymeslot.SourceRevision

  attr :class, :string, default: nil

  @doc "Links users to the public source for this build."
  @spec source_link(map()) :: Phoenix.LiveView.Rendered.t()
  def source_link(assigns) do
    {url, exact?} = SourceRevision.link()
    assigns = assign(assigns, url: url, exact?: exact?)

    ~H"""
    <a
      href={@url}
      target="_blank"
      rel="noopener noreferrer"
      class={@class}
      data-source-link
    >
      <%= if @exact? do %>
        {dgettext("common", "Source code for this version (AGPLv3)")}
      <% else %>
        {dgettext("common", "Source repository (AGPLv3)")}
      <% end %>
    </a>
    """
  end

  @doc """
  Renders the Synantesis logo.

  ## Attributes
    * `mode` - Either :full (logo + text) or :icon (logo only). Defaults to :full.
    * `class` - Additional CSS classes for the container.
    * `img_class` - Additional CSS classes for the image element.
  """
  attr :mode, :atom, default: :full, values: [:full, :icon]
  attr :class, :string, default: nil
  attr :img_class, :string, default: "h-10"

  @spec logo(map()) :: Phoenix.LiveView.Rendered.t()
  def logo(assigns) do
    ~H"""
    <div class={["flex items-center", @class]}>
      <%= if @mode == :full do %>
        <img
          src="/images/brand/logo-with-text.svg"
          alt="Synantesis"
          width="620"
          height="200"
          class={[@img_class, "w-auto"]}
        />
      <% else %>
        <img
          src="/images/brand/logo.svg"
          alt={dgettext("common", "Synantesis logo")}
          width="200"
          height="200"
          class={[@img_class, "w-auto"]}
        />
      <% end %>
    </div>
    """
  end
end
