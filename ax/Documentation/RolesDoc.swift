//
//  RolesDoc.swift
//  ax
//
//  Documentation for common accessibility roles.
//

import Foundation

/// Documentation for accessibility roles
struct RolesDoc {

    static let text = """
ACCESSIBILITY ROLES

Roles describe the type of UI element. Common roles:

INTERACTIVE ELEMENTS
  button            Clickable button (press)
  check_box         Toggle checkbox, value is 0 or 1 (press)
  radio_button      Radio button in a group (press)
  pop_up_button     Dropdown/popup menu button (press, show_menu)
  menu_button       Button that shows a menu (press, show_menu)
  slider            Adjustable slider (increment, decrement)
  text_field        Editable text input
  text_area         Multi-line text input
  combo_box         Editable dropdown combo box
  color_well        Color picker
  date_field        Date input

CONTAINERS
  window            Application window (raise, close)
  sheet             Modal dialog sheet
  drawer            Slide-out drawer panel
  group             Grouping container
  scroll_area       Scrollable container (scroll_*)
  split_group       Split view container
  tab_group         Tab container
  toolbar           Toolbar container

DISPLAY ELEMENTS
  static_text       Non-editable text label
  image             Image element
  progress_indicator Loading/progress bar
  busy_indicator    Spinning activity indicator
  relevance_indicator Relevance/rating indicator
  level_indicator   Level/volume indicator
  value_indicator   Generic value display

MENUS
  menu              Menu container
  menu_item         Clickable menu item (press)
  menu_bar          Application menu bar
  menu_bar_item     Top-level menu item (press)

LISTS & TABLES
  list              List container
  table             Table container
  outline           Hierarchical outline/tree
  row               Row in list/table/outline (press)
  cell              Cell in table
  column            Table column

SPECIALIZED
  link              Clickable hyperlink (press)
  disclosure_triangle Expand/collapse control (press)
  incrementor       Stepper control (increment, decrement)
  browser           Column-based file browser
  help_tag          Tooltip/help popup
  matte             Background/decorative element
  ruler             Ruler/guide element
  ruler_marker      Marker on a ruler
  grid              Grid container
  layout_area       Layout container
  layout_item       Item in layout
  handle            Resize/drag handle

SUBROLES (refinements)
  close_button      Window close button
  minimize_button   Window minimize button
  zoom_button       Window zoom/maximize button
  toolbar_button    Button in toolbar
  search_field      Search-specific text field
  secure_text_field Password input (obscured)

Use 'ax ls <pid> --depth N' to explore the element hierarchy and discover roles.
"""

    static let entries: [RoleEntry] = [
        RoleEntry(name: "button", description: "Clickable button", commonActions: ["press"]),
        RoleEntry(name: "check_box", description: "Toggle checkbox, value is 0 or 1", commonActions: ["press"]),
        RoleEntry(name: "radio_button", description: "Radio button in a group", commonActions: ["press"]),
        RoleEntry(name: "pop_up_button", description: "Dropdown/popup menu button", commonActions: ["press", "show_menu"]),
        RoleEntry(name: "menu_button", description: "Button that shows a menu", commonActions: ["press", "show_menu"]),
        RoleEntry(name: "slider", description: "Adjustable slider", commonActions: ["increment", "decrement"]),
        RoleEntry(name: "text_field", description: "Editable text input", commonActions: []),
        RoleEntry(name: "text_area", description: "Multi-line text input", commonActions: []),
        RoleEntry(name: "combo_box", description: "Editable dropdown combo box", commonActions: []),
        RoleEntry(name: "window", description: "Application window", commonActions: ["raise", "close"]),
        RoleEntry(name: "sheet", description: "Modal dialog sheet", commonActions: []),
        RoleEntry(name: "group", description: "Grouping container", commonActions: []),
        RoleEntry(name: "scroll_area", description: "Scrollable container", commonActions: ["scroll_left_by_page", "scroll_right_by_page", "scroll_up_by_page", "scroll_down_by_page"]),
        RoleEntry(name: "static_text", description: "Non-editable text label", commonActions: []),
        RoleEntry(name: "image", description: "Image element", commonActions: []),
        RoleEntry(name: "progress_indicator", description: "Loading/progress bar", commonActions: []),
        RoleEntry(name: "menu", description: "Menu container", commonActions: []),
        RoleEntry(name: "menu_item", description: "Clickable menu item", commonActions: ["press"]),
        RoleEntry(name: "menu_bar", description: "Application menu bar", commonActions: []),
        RoleEntry(name: "menu_bar_item", description: "Top-level menu item", commonActions: ["press"]),
        RoleEntry(name: "list", description: "List container", commonActions: []),
        RoleEntry(name: "table", description: "Table container", commonActions: []),
        RoleEntry(name: "outline", description: "Hierarchical outline/tree", commonActions: []),
        RoleEntry(name: "row", description: "Row in list/table/outline", commonActions: ["press"]),
        RoleEntry(name: "cell", description: "Cell in table", commonActions: []),
        RoleEntry(name: "link", description: "Clickable hyperlink", commonActions: ["press"]),
        RoleEntry(name: "disclosure_triangle", description: "Expand/collapse control", commonActions: ["press"]),
        RoleEntry(name: "incrementor", description: "Stepper control", commonActions: ["increment", "decrement"]),
        RoleEntry(name: "toolbar", description: "Toolbar container", commonActions: []),
        RoleEntry(name: "tab_group", description: "Tab container", commonActions: []),
    ]
}
