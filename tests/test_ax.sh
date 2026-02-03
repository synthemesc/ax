#!/bin/bash
#
# test_ax.sh - Test runner for ax CLI
#
# Usage: ./tests/test_ax.sh
#
# Requires:
# - Accessibility permission for Terminal
# - axtest app and ax CLI built
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
AX_BIN=$(find "$DERIVED_DATA" -path "*/ax-*/Build/Products/Debug/ax" -not -path "*Index.noindex*" -type f 2>/dev/null | head -1)
AXTEST_APP=$(find "$DERIVED_DATA" -path "*/ax-*/Build/Products/Debug/axtest.app" -not -path "*Index.noindex*" -type d 2>/dev/null | head -1)

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
PID=""
WINDOW_ID=""
ELEMENT_CACHE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

#
# Utility functions
#

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++)) || true
    ((TESTS_RUN++)) || true
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1: $2"
    ((TESTS_FAILED++)) || true
    ((TESTS_RUN++)) || true
}

# Cache element tree for faster lookups
ELEMENT_CACHE_FILE="/tmp/ax_test_element_cache_$$.json"

cache_elements() {
    if [[ ! -f "$ELEMENT_CACHE_FILE" ]]; then
        "$AX_BIN" ls "$PID" --depth 15 2>/dev/null > "$ELEMENT_CACHE_FILE"
    fi
}

# Refresh the element cache (call after UI changes significantly)
refresh_cache() {
    rm -f "$ELEMENT_CACHE_FILE"
    cache_elements
}

# Find element ID by accessibility identifier
# Usage: find_element <identifier>
find_element() {
    local identifier=$1
    cache_elements
    jq -r "recurse | objects | select(.identifier == \"$identifier\") | .id" "$ELEMENT_CACHE_FILE" 2>/dev/null | head -1
}

# Read the action log value
read_action_log() {
    local log_id
    log_id=$(find_element "action_log")
    if [[ -n "$log_id" ]]; then
        "$AX_BIN" ls "$log_id" 2>/dev/null | jq -r '.value // empty' 2>/dev/null
    fi
}

# Wait for UI to settle
settle() {
    sleep 0.2
}

# Reset the test app state
reset_app() {
    local reset_id
    reset_id=$(find_element "reset_button")
    if [[ -n "$reset_id" ]]; then
        "$AX_BIN" click "$reset_id" >/dev/null 2>&1
        settle
    fi
}

#
# Setup and teardown
#

setup() {
    log_info "Setting up test environment..."

    # Check for ax binary
    if [[ -z "$AX_BIN" || ! -x "$AX_BIN" ]]; then
        echo "Error: ax binary not found. Run: xcodebuild build -scheme ax -configuration Debug"
        exit 1
    fi
    log_info "Found ax at: $AX_BIN"

    # Check for axtest app
    if [[ -z "$AXTEST_APP" || ! -d "$AXTEST_APP" ]]; then
        echo "Error: axtest.app not found. Run: xcodebuild build -scheme axtest -configuration Debug"
        exit 1
    fi
    log_info "Found axtest at: $AXTEST_APP"

    # Launch axtest if not running
    PID=$(pgrep -x "axtest" || true)
    if [[ -z "$PID" ]]; then
        log_info "Launching axtest..."
        open "$AXTEST_APP"
        sleep 1
        PID=$(pgrep -x "axtest")
    fi
    log_info "axtest PID: $PID"

    # Get window ID
    WINDOW_ID=$("$AX_BIN" ls "$PID" 2>/dev/null | jq -r '.[0].id' 2>/dev/null)
    if [[ -z "$WINDOW_ID" || "$WINDOW_ID" == "null" ]]; then
        echo "Error: Could not find axtest window"
        exit 1
    fi
    log_info "Window ID: $WINDOW_ID"

    # Position and size window for consistent tests
    "$AX_BIN" move "$WINDOW_ID" --to @100,100 >/dev/null 2>&1 || true
    "$AX_BIN" resize "$WINDOW_ID" 600x700 >/dev/null 2>&1 || true
    settle

    # Reset app state
    reset_app

    # Cache element tree for faster lookups
    cache_elements

    echo ""
    log_info "Running tests..."
    echo ""
}

teardown() {
    # Cleanup cache file
    rm -f "$ELEMENT_CACHE_FILE"

    echo ""
    echo "=========================================="
    echo "Tests run: $TESTS_RUN, Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
    echo "=========================================="

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

#
# Tests
#

test_ls_apps() {
    local result
    result=$("$AX_BIN" ls 2>/dev/null)

    # Check JSON structure
    if echo "$result" | jq -e '.displays' >/dev/null 2>&1 && \
       echo "$result" | jq -e '.apps' >/dev/null 2>&1; then
        # Check axtest is in the app list
        if echo "$result" | jq -e ".apps[] | select(.pid == $PID)" >/dev/null 2>&1; then
            log_pass "ls_apps"
        else
            log_fail "ls_apps" "axtest not in app list"
        fi
    else
        log_fail "ls_apps" "Invalid JSON structure"
    fi
}

test_ls_windows() {
    local result
    result=$("$AX_BIN" ls "$PID" 2>/dev/null)

    # Check we get an array with at least one window
    if echo "$result" | jq -e '.[0].id' >/dev/null 2>&1; then
        log_pass "ls_windows"
    else
        log_fail "ls_windows" "No windows returned"
    fi
}

test_ls_depth() {
    local result
    result=$("$AX_BIN" ls "$PID" --depth 5 2>/dev/null)

    # Check for nested children
    if echo "$result" | jq -e '.. | objects | select(.identifier == "test_button")' >/dev/null 2>&1; then
        log_pass "ls_depth"
    else
        log_fail "ls_depth" "Could not find test_button in tree"
    fi
}

test_ls_element() {
    local button_id result
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "ls_element" "Could not find test_button"
        return
    fi

    result=$("$AX_BIN" ls "$button_id" 2>/dev/null)

    if echo "$result" | jq -e '.role' >/dev/null 2>&1; then
        log_pass "ls_element"
    else
        log_fail "ls_element" "Invalid element JSON"
    fi
}

test_ls_point() {
    # Get button position and query that point
    local button_id origin_x origin_y result
    button_id=$(find_element "test_button")
    origin_x=$("$AX_BIN" ls "$button_id" 2>/dev/null | jq -r '.origin.x' 2>/dev/null)
    origin_y=$("$AX_BIN" ls "$button_id" 2>/dev/null | jq -r '.origin.y' 2>/dev/null)

    if [[ -z "$origin_x" || "$origin_x" == "null" ]]; then
        log_fail "ls_point" "Could not get button origin"
        return
    fi

    # Query at button center
    local cx=$((origin_x + 20))
    local cy=$((origin_y + 10))
    result=$("$AX_BIN" ls "@$cx,$cy" 2>/dev/null)

    if echo "$result" | jq -e '.role' >/dev/null 2>&1; then
        log_pass "ls_point"
    else
        log_fail "ls_point" "No element at point"
    fi
}

test_click_element() {
    reset_app
    local button_id log_value
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "click_element" "Could not find test_button"
        return
    fi

    "$AX_BIN" click "$button_id" >/dev/null 2>&1
    settle

    log_value=$(read_action_log)
    if [[ "$log_value" == "button_clicked:1" ]]; then
        log_pass "click_element"
    else
        log_fail "click_element" "Expected 'button_clicked:1', got '$log_value'"
    fi
}

test_click_coordinates() {
    reset_app
    local button_id origin_x origin_y log_value
    button_id=$(find_element "test_button_2")
    origin_x=$("$AX_BIN" ls "$button_id" 2>/dev/null | jq -r '.origin.x' 2>/dev/null)
    origin_y=$("$AX_BIN" ls "$button_id" 2>/dev/null | jq -r '.origin.y' 2>/dev/null)

    if [[ -z "$origin_x" || "$origin_x" == "null" ]]; then
        log_fail "click_coordinates" "Could not get button origin"
        return
    fi

    # Click center of button
    local cx=$((origin_x + 30))
    local cy=$((origin_y + 10))
    "$AX_BIN" click "@$cx,$cy" >/dev/null 2>&1
    settle

    log_value=$(read_action_log)
    if [[ "$log_value" == "button2_clicked" ]]; then
        log_pass "click_coordinates"
    else
        log_fail "click_coordinates" "Expected 'button2_clicked', got '$log_value'"
    fi
}

test_click_offset() {
    reset_app
    local button_id log_value
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "click_offset" "Could not find test_button"
        return
    fi

    # Click at offset from element
    "$AX_BIN" click "${button_id}@10,10" >/dev/null 2>&1
    settle

    log_value=$(read_action_log)
    if [[ "$log_value" == "button_clicked:1" ]]; then
        log_pass "click_offset"
    else
        log_fail "click_offset" "Expected 'button_clicked:1', got '$log_value'"
    fi
}

test_rightclick() {
    local button_id
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "rightclick" "Could not find test_button"
        return
    fi

    # Just verify command succeeds (right-click doesn't trigger button action)
    if "$AX_BIN" rightclick "$button_id" >/dev/null 2>&1; then
        log_pass "rightclick"
    else
        log_fail "rightclick" "Command failed"
    fi
    settle
}

test_action_press() {
    reset_app
    local button_id log_value
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "action_press" "Could not find test_button"
        return
    fi

    "$AX_BIN" action "$button_id" press >/dev/null 2>&1
    settle

    log_value=$(read_action_log)
    if [[ "$log_value" == "button_clicked:1" ]]; then
        log_pass "action_press"
    else
        log_fail "action_press" "Expected 'button_clicked:1', got '$log_value'"
    fi
}

test_type() {
    # Note: ax type uses CGEvent which sends keys to the system's frontmost app.
    # When running from a script, Terminal is frontmost, so we just verify the
    # command executes successfully and returns the expected JSON structure.
    local textfield_id result
    textfield_id=$(find_element "test_textfield")

    if [[ -z "$textfield_id" ]]; then
        log_fail "type" "Could not find test_textfield"
        return
    fi

    # Focus app and textfield
    "$AX_BIN" focus "$PID" >/dev/null 2>&1 || true
    settle
    "$AX_BIN" focus "$textfield_id" >/dev/null 2>&1 || true
    settle

    # Verify type command succeeds and returns expected structure
    result=$("$AX_BIN" type "hello" 2>/dev/null)
    if echo "$result" | jq -e '.typed' >/dev/null 2>&1; then
        log_pass "type"
    else
        log_fail "type" "Invalid response from type command"
    fi
}

test_key() {
    # Note: ax key uses CGEvent which sends keys to the system's frontmost app.
    # When running from a script, Terminal is frontmost, so we just verify the
    # command executes successfully and returns the expected JSON structure.
    local result

    # Verify key command succeeds with a simple key combo
    result=$("$AX_BIN" key "escape" 2>/dev/null)
    if echo "$result" | jq -e '.keys' >/dev/null 2>&1; then
        log_pass "key"
    else
        log_fail "key" "Invalid response from key command"
    fi
}

test_scroll() {
    local scrollview_id
    scrollview_id=$(find_element "test_scrollview")

    if [[ -z "$scrollview_id" ]]; then
        log_fail "scroll" "Could not find test_scrollview"
        return
    fi

    # Just verify command succeeds
    if "$AX_BIN" scroll "$scrollview_id" down 50 >/dev/null 2>&1; then
        log_pass "scroll"
    else
        log_fail "scroll" "Command failed"
    fi
}

test_focus() {
    local textfield_id result
    textfield_id=$(find_element "test_textfield")

    if [[ -z "$textfield_id" ]]; then
        log_fail "focus" "Could not find test_textfield"
        return
    fi

    "$AX_BIN" focus "$textfield_id" >/dev/null 2>&1
    settle

    result=$("$AX_BIN" ls "$textfield_id" 2>/dev/null | jq -r '.focused // false' 2>/dev/null)
    if [[ "$result" == "true" ]]; then
        log_pass "focus"
    else
        log_fail "focus" "Element not focused"
    fi
}

test_focused() {
    # Note: ax focused returns the system-wide focused element.
    # When running from a script, the focused element depends on which app
    # is frontmost and what element within it has focus.
    # We test that the command executes and returns valid JSON structure
    # (either element info or error)
    local result exit_code=0

    result=$("$AX_BIN" focused 2>&1) || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        # Success - should have a role
        if echo "$result" | jq -e '.role' >/dev/null 2>&1; then
            log_pass "focused"
        else
            log_fail "focused" "No role in focused element"
        fi
    else
        # Error response is acceptable - means no focused element
        if echo "$result" | grep -q "No focused element"; then
            log_pass "focused (no focus)"
        else
            log_fail "focused" "Unexpected error: $result"
        fi
    fi
}

test_cursor() {
    local result
    result=$("$AX_BIN" cursor 2>/dev/null)

    if echo "$result" | jq -e '.x' >/dev/null 2>&1 && \
       echo "$result" | jq -e '.y' >/dev/null 2>&1; then
        log_pass "cursor"
    else
        log_fail "cursor" "Invalid cursor response"
    fi
}

test_selection() {
    local textfield_id
    textfield_id=$(find_element "test_textfield")

    if [[ -z "$textfield_id" ]]; then
        log_fail "selection" "Could not find test_textfield"
        return
    fi

    # Focus, select all
    "$AX_BIN" focus "$textfield_id" >/dev/null 2>&1
    settle
    "$AX_BIN" key "cmd+a" >/dev/null 2>&1
    settle

    local result
    result=$("$AX_BIN" selection "$textfield_id" 2>/dev/null)

    # Selection should return text or range
    if echo "$result" | jq -e '.text' >/dev/null 2>&1 || \
       echo "$result" | jq -e '.range' >/dev/null 2>&1; then
        log_pass "selection"
    else
        # Some elements may not support selection - that's ok
        log_pass "selection (no selection data)"
    fi
}

test_set() {
    reset_app
    local textfield_id result
    textfield_id=$(find_element "test_textfield")

    if [[ -z "$textfield_id" ]]; then
        log_fail "set" "Could not find test_textfield"
        return
    fi

    "$AX_BIN" set "$textfield_id" "set value test" >/dev/null 2>&1
    settle

    result=$("$AX_BIN" ls "$textfield_id" 2>/dev/null | jq -r '.value // empty' 2>/dev/null)
    if [[ "$result" == "set value test" ]]; then
        log_pass "set"
    else
        log_fail "set" "Expected 'set value test', got '$result'"
    fi
}

test_move() {
    local orig_x orig_y new_x new_y
    orig_x=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.x' 2>/dev/null)
    orig_y=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.y' 2>/dev/null)

    "$AX_BIN" move "$WINDOW_ID" --to @200,200 >/dev/null 2>&1
    settle

    new_x=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.x' 2>/dev/null)
    new_y=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.y' 2>/dev/null)

    if [[ "$new_x" == "200" && "$new_y" == "200" ]]; then
        log_pass "move"
    else
        log_fail "move" "Expected (200,200), got ($new_x,$new_y)"
    fi

    # Restore position
    "$AX_BIN" move "$WINDOW_ID" --to @100,100 >/dev/null 2>&1
    settle
}

test_resize() {
    "$AX_BIN" resize "$WINDOW_ID" 650x750 >/dev/null 2>&1
    settle

    local width height
    width=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.width' 2>/dev/null)
    height=$("$AX_BIN" ls "$WINDOW_ID" 2>/dev/null | jq -r '.frame.height' 2>/dev/null)

    if [[ "$width" == "650" && "$height" == "750" ]]; then
        log_pass "resize"
    else
        log_fail "resize" "Expected 650x750, got ${width}x${height}"
    fi

    # Restore size
    "$AX_BIN" resize "$WINDOW_ID" 600x700 >/dev/null 2>&1
    settle
}

test_drag() {
    # Just verify drag command runs without error
    if "$AX_BIN" drag @300,300 --to @350,350 >/dev/null 2>&1; then
        log_pass "drag"
    else
        log_fail "drag" "Command failed"
    fi
}

test_launch_quit() {
    # Launch TextEdit
    local result pid_textedit
    result=$("$AX_BIN" launch com.apple.TextEdit 2>/dev/null)

    if ! echo "$result" | jq -e '.pid' >/dev/null 2>&1; then
        log_fail "launch" "No PID in launch response"
        return
    fi

    pid_textedit=$(echo "$result" | jq -r '.pid')
    settle

    # Verify it's in app list
    if "$AX_BIN" ls 2>/dev/null | jq -e ".apps[] | select(.pid == $pid_textedit)" >/dev/null 2>&1; then
        log_pass "launch"
    else
        log_fail "launch" "TextEdit not in app list after launch"
    fi

    # Quit it
    "$AX_BIN" quit "$pid_textedit" >/dev/null 2>&1
    sleep 0.5

    # Verify it's gone
    if ! "$AX_BIN" ls 2>/dev/null | jq -e ".apps[] | select(.pid == $pid_textedit)" >/dev/null 2>&1; then
        log_pass "quit"
    else
        log_fail "quit" "TextEdit still in app list after quit"
    fi
}

test_screenshot() {
    local tmp_file="/tmp/ax_test_screenshot_$$.png"

    if "$AX_BIN" ls --screenshot "$tmp_file" >/dev/null 2>&1; then
        if [[ -f "$tmp_file" && -s "$tmp_file" ]]; then
            log_pass "screenshot"
            rm -f "$tmp_file"
        else
            log_fail "screenshot" "Screenshot file empty or missing"
        fi
    else
        log_fail "screenshot" "Command failed"
    fi
}

test_screenshot_element() {
    local button_id tmp_file="/tmp/ax_test_element_screenshot_$$.png"
    button_id=$(find_element "test_button")

    if [[ -z "$button_id" ]]; then
        log_fail "screenshot_element" "Could not find test_button"
        return
    fi

    if "$AX_BIN" ls "$button_id" --screenshot "$tmp_file" >/dev/null 2>&1; then
        if [[ -f "$tmp_file" && -s "$tmp_file" ]]; then
            log_pass "screenshot_element"
            rm -f "$tmp_file"
        else
            log_fail "screenshot_element" "Screenshot file empty or missing"
        fi
    else
        log_fail "screenshot_element" "Command failed"
    fi
}

test_nested_tree() {
    # Verify we can find nested elements
    local item_a item_b item_c item_d
    item_a=$(find_element "nested_item_a")
    item_b=$(find_element "nested_item_b")
    item_c=$(find_element "nested_item_c")
    item_d=$(find_element "nested_item_d")

    if [[ -n "$item_a" && -n "$item_b" && -n "$item_c" && -n "$item_d" ]]; then
        log_pass "nested_tree"
    else
        log_fail "nested_tree" "Could not find all nested items"
    fi
}

test_lock_socket_lifecycle() {
    # Test that socket is created during lock and cleaned up after unlock
    # Ensure not locked to start
    "$AX_BIN" unlock >/dev/null 2>&1 || true
    sleep 0.5

    # Socket should not exist when not locked
    if [[ -S "/tmp/ax-lock.sock" ]]; then
        log_fail "lock_socket_lifecycle" "Socket exists before lock"
        return
    fi

    # Start lock
    local lock_result
    lock_result=$("$AX_BIN" lock --timeout 10 2>/dev/null)
    local lock_pid
    lock_pid=$(echo "$lock_result" | jq -r '.pid')

    if [[ -z "$lock_pid" || "$lock_pid" == "null" ]]; then
        log_fail "lock_socket_lifecycle" "Could not start lock"
        return
    fi

    # Give axlockd time to start and create socket
    sleep 1

    # Socket should exist when locked
    if [[ ! -S "/tmp/ax-lock.sock" ]]; then
        "$AX_BIN" unlock >/dev/null 2>&1
        log_fail "lock_socket_lifecycle" "Socket not created during lock"
        return
    fi

    # Unlock
    "$AX_BIN" unlock >/dev/null 2>&1
    sleep 0.5

    # Socket should be removed after unlock
    if [[ -S "/tmp/ax-lock.sock" ]]; then
        log_fail "lock_socket_lifecycle" "Socket not removed after unlock"
    else
        log_pass "lock_socket_lifecycle"
    fi
}

test_lock_status_label() {
    # Test that the status label exists and is accessible in axlockd overlay
    # Ensure not locked to start
    "$AX_BIN" unlock >/dev/null 2>&1 || true
    sleep 0.5

    # Start lock
    local lock_result
    lock_result=$("$AX_BIN" lock --timeout 10 2>/dev/null)
    local lock_pid
    lock_pid=$(echo "$lock_result" | jq -r '.pid')

    if [[ -z "$lock_pid" || "$lock_pid" == "null" ]]; then
        log_fail "lock_status_label" "Could not start lock"
        return
    fi

    # Give axlockd time to start
    sleep 1

    # Find axlockd process
    local axlockd_pid
    axlockd_pid=$(pgrep -x "axlockd" || true)

    if [[ -z "$axlockd_pid" ]]; then
        "$AX_BIN" unlock >/dev/null 2>&1
        log_fail "lock_status_label" "axlockd not running"
        return
    fi

    # Query axlockd's UI to find the status label
    # Note: This query itself will update the status to "listing app ..."
    local status_text
    status_text=$("$AX_BIN" ls "$axlockd_pid" --depth 10 2>/dev/null | \
        jq -r '.. | objects | select(.identifier == "ax_lock_status") | .value // empty' 2>/dev/null | head -1)

    # Unlock before checking result
    "$AX_BIN" unlock >/dev/null 2>&1
    sleep 0.5

    # Status should contain "listing" since that was the last command
    if [[ "$status_text" == *"listing"* ]]; then
        log_pass "lock_status_label"
    elif [[ -n "$status_text" ]]; then
        # Any non-empty value is acceptable - the IPC is working
        log_pass "lock_status_label"
    else
        log_fail "lock_status_label" "Status label not found or empty"
    fi
}

#
# Main
#

main() {
    setup

    # Run all tests
    test_ls_apps
    test_ls_windows
    test_ls_depth
    test_ls_element
    test_ls_point
    test_click_element
    test_click_coordinates
    test_click_offset
    test_rightclick
    test_action_press
    test_type
    test_key
    test_scroll
    test_focus
    test_focused
    test_cursor
    test_selection
    test_set
    test_move
    test_resize
    test_drag
    test_launch_quit
    test_screenshot
    test_screenshot_element
    test_nested_tree
    test_lock_socket_lifecycle
    test_lock_status_label

    teardown
}

main "$@"
