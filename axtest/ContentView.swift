//
//  ContentView.swift
//  axtest
//
//  Test harness UI for ax CLI verification
//

import SwiftUI

struct ContentView: View {
    // State for tracking interactions
    @State private var actionLog = ""
    @State private var clickCount = 0
    @State private var toggleOn = false
    @State private var textFieldValue = "initial text"
    @State private var textAreaValue = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10"
    @State private var sliderValue = 50.0
    @State private var stepperValue = 5

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("ax Test Harness")
                .font(.title)
                .accessibilityIdentifier("header")

            // Action log display - this is the key verification element
            // Using TextField with isEnabled=false to ensure it's always in accessibility tree
            TextField("", text: .constant(actionLog))
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, minHeight: 30)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                .disabled(true)
                .accessibilityIdentifier("action_log")

            Divider()

            // Test elements in a grid-like layout
            HStack(spacing: 20) {
                // Left column - Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Button("Click Me") {
                        clickCount += 1
                        actionLog = "button_clicked:\(clickCount)"
                    }
                    .accessibilityIdentifier("test_button")

                    Button("Secondary") {
                        actionLog = "button2_clicked"
                    }
                    .accessibilityIdentifier("test_button_2")

                    Toggle("Toggle", isOn: $toggleOn)
                        .onChange(of: toggleOn) { _, newValue in
                            actionLog = "toggle_changed:\(newValue)"
                        }
                        .accessibilityIdentifier("test_toggle")

                    Stepper("Stepper: \(stepperValue)", value: $stepperValue, in: 0...10)
                        .onChange(of: stepperValue) { _, newValue in
                            actionLog = "stepper_changed:\(newValue)"
                        }
                        .accessibilityIdentifier("test_stepper")
                }
                .frame(minWidth: 150)

                // Right column - Input elements
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Enter text", text: $textFieldValue)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .onChange(of: textFieldValue) { _, newValue in
                            actionLog = "textfield_changed:\(newValue)"
                        }
                        .accessibilityIdentifier("test_textfield")

                    Slider(value: $sliderValue, in: 0...100)
                        .frame(width: 200)
                        .onChange(of: sliderValue) { _, newValue in
                            actionLog = "slider_changed:\(Int(newValue))"
                        }
                        .accessibilityIdentifier("test_slider")

                    Text("Slider: \(Int(sliderValue))")
                        .font(.caption)
                        .accessibilityIdentifier("slider_label")
                }
            }
            .padding(.horizontal)

            Divider()

            // TextEditor in a ScrollView for scroll testing
            ScrollView {
                TextEditor(text: $textAreaValue)
                    .frame(minHeight: 120)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: textAreaValue) { _, newValue in
                        let lineCount = newValue.components(separatedBy: "\n").count
                        actionLog = "textarea_changed:lines=\(lineCount)"
                    }
                    .accessibilityIdentifier("test_textarea")
            }
            .frame(height: 150)
            .border(Color.gray.opacity(0.3))
            .accessibilityIdentifier("test_scrollview")

            Divider()

            // Nested container for tree traversal testing
            GroupBox("Nested Container") {
                HStack(spacing: 12) {
                    VStack {
                        Button("Item A") { actionLog = "nested_a_clicked" }
                            .accessibilityIdentifier("nested_item_a")
                        Button("Item B") { actionLog = "nested_b_clicked" }
                            .accessibilityIdentifier("nested_item_b")
                    }
                    VStack {
                        Button("Item C") { actionLog = "nested_c_clicked" }
                            .accessibilityIdentifier("nested_item_c")
                        Button("Item D") { actionLog = "nested_d_clicked" }
                            .accessibilityIdentifier("nested_item_d")
                    }
                }
            }
            .accessibilityIdentifier("test_container")

            Spacer()

            // Reset button
            Button("Reset") {
                actionLog = ""
                clickCount = 0
                toggleOn = false
                textFieldValue = "initial text"
                sliderValue = 50.0
                stepperValue = 5
                actionLog = "reset"
            }
            .accessibilityIdentifier("reset_button")
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
