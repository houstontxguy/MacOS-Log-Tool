import AppKit
import SwiftUI

struct SuggestionTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var suggestions: [String]
    var isDisabled: Bool = false

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.placeholderString = placeholder
        comboBox.isEditable = true
        comboBox.hasVerticalScroller = true
        comboBox.usesDataSource = true
        comboBox.completes = true
        comboBox.numberOfVisibleItems = 10
        comboBox.delegate = context.coordinator
        comboBox.dataSource = context.coordinator
        comboBox.isBordered = true
        comboBox.bezelStyle = .roundedBezel
        comboBox.font = .systemFont(ofSize: NSFont.systemFontSize(for: .regular))
        comboBox.controlSize = .regular
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        if comboBox.stringValue != text {
            comboBox.stringValue = text
        }
        comboBox.isEnabled = !isDisabled
        context.coordinator.suggestions = filteredSuggestions
        comboBox.reloadData()
    }

    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return suggestions }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(text) }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, suggestions: suggestions)
    }

    final class Coordinator: NSObject, NSComboBoxDelegate, NSComboBoxDataSource {
        @Binding var text: String
        var suggestions: [String]

        init(text: Binding<String>, suggestions: [String]) {
            self._text = text
            self.suggestions = suggestions
        }

        func numberOfItems(in comboBox: NSComboBox) -> Int {
            suggestions.count
        }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            guard index >= 0 && index < suggestions.count else { return nil }
            return suggestions[index]
        }

        func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
            suggestions.first { $0.localizedCaseInsensitiveContains(string) }
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let index = comboBox.indexOfSelectedItem
            if index >= 0 && index < suggestions.count {
                text = suggestions[index]
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            text = comboBox.stringValue
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            text = comboBox.stringValue
        }
    }
}
