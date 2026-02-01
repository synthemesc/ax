//
//  ActionsDoc.swift
//  ax
//
//  Documentation for common accessibility actions.
//

import Foundation

/// Documentation for accessibility actions
struct ActionsDoc {

    static let text = """
ACCESSIBILITY ACTIONS

Actions are operations that can be performed on elements. Use:
  ax action <element-id> <action-name>

COMMON ACTIONS
  press             Activate button, checkbox, menu item, etc.
                    Equivalent to clicking or pressing Enter/Space.

  show_menu         Show the element's popup/context menu.
                    Available on pop_up_button, menu_button, etc.

  cancel            Cancel current operation or close menu.
                    Common on sheets and dialogs.

  confirm           Confirm/accept current operation.
                    Common on sheets and dialogs.

  raise             Bring window to front.
                    Available on window elements.

  pick              Select item in picker or list.
                    Selects the item without activating.

VALUE ADJUSTMENTS
  increment         Increase value (slider, stepper, etc.)
  decrement         Decrease value (slider, stepper, etc.)

SCROLLING
  scroll_left_by_page    Scroll left by one page
  scroll_right_by_page   Scroll right by one page
  scroll_up_by_page      Scroll up by one page
  scroll_down_by_page    Scroll down by one page

DISCLOSURE
  expand            Expand disclosure triangle or outline row
  collapse          Collapse disclosure triangle or outline row

NOTES
- Not all elements support all actions
- Use 'ax ls <element-id>' to see available actions in the "actions" array
- Action names are lowercase with underscores (e.g., show_menu, not showMenu)
- 'ax click <id>' uses 'press' action automatically when available
"""

    static let entries: [ActionEntry] = [
        ActionEntry(name: "press", description: "Activate button, checkbox, menu item. Equivalent to clicking or pressing Enter/Space.", applicableRoles: ["button", "check_box", "radio_button", "menu_item", "menu_bar_item", "link", "disclosure_triangle", "row"]),
        ActionEntry(name: "show_menu", description: "Show the element's popup/context menu.", applicableRoles: ["pop_up_button", "menu_button", "combo_box"]),
        ActionEntry(name: "cancel", description: "Cancel current operation or close menu.", applicableRoles: ["sheet", "window"]),
        ActionEntry(name: "confirm", description: "Confirm/accept current operation.", applicableRoles: ["sheet", "window"]),
        ActionEntry(name: "raise", description: "Bring window to front.", applicableRoles: ["window"]),
        ActionEntry(name: "pick", description: "Select item in picker or list without activating.", applicableRoles: ["row", "cell"]),
        ActionEntry(name: "increment", description: "Increase value (slider, stepper, etc.)", applicableRoles: ["slider", "incrementor", "value_indicator"]),
        ActionEntry(name: "decrement", description: "Decrease value (slider, stepper, etc.)", applicableRoles: ["slider", "incrementor", "value_indicator"]),
        ActionEntry(name: "scroll_left_by_page", description: "Scroll left by one page.", applicableRoles: ["scroll_area"]),
        ActionEntry(name: "scroll_right_by_page", description: "Scroll right by one page.", applicableRoles: ["scroll_area"]),
        ActionEntry(name: "scroll_up_by_page", description: "Scroll up by one page.", applicableRoles: ["scroll_area"]),
        ActionEntry(name: "scroll_down_by_page", description: "Scroll down by one page.", applicableRoles: ["scroll_area"]),
        ActionEntry(name: "expand", description: "Expand disclosure triangle or outline row.", applicableRoles: ["disclosure_triangle", "row", "outline"]),
        ActionEntry(name: "collapse", description: "Collapse disclosure triangle or outline row.", applicableRoles: ["disclosure_triangle", "row", "outline"]),
    ]
}
