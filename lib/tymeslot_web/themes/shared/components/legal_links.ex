defmodule TymeslotWeb.Themes.Shared.Components.LegalLinks do
  @moduledoc """
  The organiser's legal notice and privacy policy links, as a guest sees them
  at the foot of every public booking page.

  The links come from `Tymeslot.Profiles.public_legal_links/1`: the
  organiser's own, else the instance defaults. The page assigns them as
  `:legal_links` wherever it assigns `:organizer_profile`, and every theme's
  wrapper renders `footer/1` once, after the theme extensions and outside
  their `show_extensions` guard, so the payment return pages keep it. It sits
  inside the theme's page grid, which keeps it inside the booker root that
  the embed's auto-resize measures.

  Neutral class names here; the styling is shared by every theme, in
  `assets/css/scheduling/shared/components/legal-links.css`.
  """

  use Phoenix.Component
  use Gettext, backend: TymeslotWeb.Gettext

  alias TymeslotWeb.Components.CoreComponents.Brand

  attr :links, :map,
    required: true,
    doc: "`%{legal_notice_url:, privacy_policy_url:}`, either URL nil, or nil for none"

  @doc """
  Renders the source offer for this build and any organiser legal links.
  Each link opens in a new tab.
  """
  @spec footer(map()) :: Phoenix.LiveView.Rendered.t()
  def footer(assigns) do
    assigns =
      assign(assigns,
        legal_notice_url: assigns.links && assigns.links[:legal_notice_url],
        privacy_policy_url: assigns.links && assigns.links[:privacy_policy_url]
      )

    ~H"""
    <footer
      class="legal-links"
      data-testid={(@legal_notice_url || @privacy_policy_url) && "legal-links"}
    >
      <Brand.source_link class="legal-links__link source-offer" />
      <a
        :if={@legal_notice_url}
        href={@legal_notice_url}
        target="_blank"
        rel="noopener noreferrer"
        class="legal-links__link"
      >
        {dgettext("booking", "Legal notice")}
      </a>
      <a
        :if={@privacy_policy_url}
        href={@privacy_policy_url}
        target="_blank"
        rel="noopener noreferrer"
        class="legal-links__link"
      >
        {dgettext("booking", "Privacy policy")}
      </a>
    </footer>
    """
  end
end
