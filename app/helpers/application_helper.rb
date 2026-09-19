module ApplicationHelper
  def usd(cents, precision: 0)
    number_to_currency(cents.to_i / 100.0, precision: precision)
  end

  def nav_link_classes(path)
    if current_page?(path)
      "flex items-center gap-3 px-3 py-2.5 rounded-lg bg-green-800 text-white font-semibold"
    else
      "flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-600 font-medium hover:bg-gray-100"
    end
  end

  # Inline SVG for any Iconable::ICON_KEYS value. Returns a stroked 24x24 icon
  # that inherits `currentColor`, so callers control size and color with classes.
  def icon_svg(key, class_name: "w-4 h-4")
    tag.svg(icon_paths(key).html_safe, class: class_name, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round")
  end

  # Tint styles for a category badge, derived from the category's stored hex color.
  # Tailwind can't generate classes for runtime colors, so this goes inline: an
  # 8-digit hex appends an alpha channel for the soft background.
  def category_badge_style(color)
    hex = color.presence || "#6b7280"
    "background-color: #{hex}1f; color: #{hex};"
  end

  private

  ICON_PATHS = {
    "home" => '<path d="M3 10l9-7 9 7v9a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 21v-7h6v7"/>',
    "utensils" => '<path d="M5 3v7a2 2 0 004 0V3"/><path d="M7 10v11"/><path d="M17 3c-1.5 1.5-2 3.5-2 5.5 0 1.7.8 2.5 2 2.5v10"/>',
    "car" => '<path d="M5 13l1.5-4.5A2 2 0 018.4 7h7.2a2 2 0 011.9 1.5L19 13"/><path d="M4 13h16v4H4z"/><circle cx="7.5" cy="17.5" r="1.5"/><circle cx="16.5" cy="17.5" r="1.5"/>',
    "shopping-bag" => '<path d="M6 2h12l2 6v12a2 2 0 01-2 2H6a2 2 0 01-2-2V8z"/><path d="M4 8h16"/><path d="M15 11a3 3 0 11-6 0"/>',
    "film" => '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 4v16M17 4v16M3 12h18"/>',
    "file-text" => '<path d="M14 3H7a2 2 0 00-2 2v14a2 2 0 002 2h10a2 2 0 002-2V8z"/><path d="M14 3v5h5"/><path d="M9 13h6M9 17h4"/>',
    "piggy-bank" => '<path d="M4 12a6 6 0 016-6h3a6 6 0 016 6v1l2 1v3h-2l-1 2h-3v-2H9v2H6v-2a6 6 0 01-2-4z"/><circle cx="15" cy="11" r="0.5" fill="currentColor"/>',
    "dollar-sign" => '<path d="M12 2v20"/><path d="M17 6.5H9.5a3 3 0 000 6h5a3 3 0 010 6H6"/>',
    "more-horizontal" => '<circle cx="5" cy="12" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="19" cy="12" r="1" fill="currentColor"/>',
    "plane" => '<path d="M10 3l2 6 8 2-8 2-2 6-2-6-6-2 6-2z"/>',
    "heart" => '<path d="M12 20s-7-4.5-7-9.5A4 4 0 0112 8a4 4 0 017 2.5C19 15.5 12 20 12 20z"/>',
    "book" => '<path d="M4 4a2 2 0 012-2h13v18H6a2 2 0 00-2 2z"/><path d="M4 18h15"/>',
    "briefcase" => '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2"/>',
    "dumbbell" => '<path d="M3 12h18"/><rect x="2" y="9" width="4" height="6" rx="1"/><rect x="18" y="9" width="4" height="6" rx="1"/>',
    "paw" => '<circle cx="8" cy="7" r="2"/><circle cx="16" cy="7" r="2"/><circle cx="5" cy="13" r="2"/><circle cx="19" cy="13" r="2"/><path d="M12 12c3 0 5 2.5 5 4.5S15 21 12 21s-5-2-5-4.5S9 12 12 12z"/>',
    "phone" => '<rect x="6" y="2" width="12" height="20" rx="2"/><path d="M11 18h2"/>',
    "gift" => '<rect x="3" y="9" width="18" height="12" rx="1"/><path d="M3 13h18M12 9v12"/><path d="M12 9C9 9 7 8 7 6a2 2 0 014 0c0 2 1 3 1 3zm0 0c3 0 5-1 5-3a2 2 0 00-4 0c0 2-1 3-1 3z"/>',
    "coffee" => '<path d="M4 8h13v6a5 5 0 01-5 5H9a5 5 0 01-5-5z"/><path d="M17 9h2a2 2 0 010 4h-2"/><path d="M4 22h14"/>',
    "graduation-cap" => '<path d="M2 9l10-4 10 4-10 4z"/><path d="M6 11v5c0 1.5 3 3 6 3s6-1.5 6-3v-5"/>',
    "wrench" => '<path d="M15 3a5 5 0 00-4.6 7L3 17.4 6.6 21l7.4-7.4A5 5 0 1015 3z"/>',
    "credit-card" => '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M6 15h4"/>',
    "umbrella" => '<path d="M12 3a9 9 0 019 9H3a9 9 0 019-9z"/><path d="M12 12v6a2.5 2.5 0 005 0"/>',
    "camera" => '<path d="M3 8h3l2-3h8l2 3h3v12H3z"/><circle cx="12" cy="13" r="3.5"/>',
    "music" => '<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
    "tree" => '<path d="M12 3l6 8h-4l4 6H6l4-6H6z"/><path d="M12 17v4"/>',
    "baby" => '<circle cx="12" cy="8" r="4"/><path d="M10 7h.01M14 7h.01"/><path d="M6 21a6 6 0 0112 0"/>',
    "target" => '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1" fill="currentColor"/>',
    "star" => '<path d="M12 3l2.8 5.7 6.2.9-4.5 4.4 1 6.2L12 17.3 6.5 20.2l1-6.2L3 9.6l6.2-.9z"/>'
  }.freeze

  def icon_paths(key)
    ICON_PATHS.fetch(key.to_s, '<circle cx="12" cy="12" r="8"/>')
  end
end
