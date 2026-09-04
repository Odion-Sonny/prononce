import Foundation
import CoreServices

/// Helper to query macOS built-in Dictionary Services (DCSCopyTextDefinition)
/// Works completely offline on all macOS versions with zero downloads.
final class DictionaryService {
    static let shared = DictionaryService()

    private init() {}

    /// Looks up a French word or phrase in the local system dictionaries
    func lookup(phrase: String) -> String? {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let cfStr = trimmed as CFString
        let range = CFRangeMake(0, CFStringGetLength(cfStr))

        guard let definitionRef = DCSCopyTextDefinition(nil, cfStr, range) else {
            return nil
        }

        let rawDefinition = definitionRef.takeRetainedValue() as String
        return cleanDefinition(rawDefinition)
    }

    /// Extracts a concise readable summary from the raw dictionary definition
    private func cleanDefinition(_ raw: String) -> String {
        // Strip excessive whitespace and truncate to reasonable length
        let lines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let firstMeaningful = lines.first(where: { $0.contains("exclamation") || $0.contains("noun") || $0.contains("verb") || $0.contains("adjective") || $0.contains("•") }) {
            return firstMeaningful
        }

        return lines.prefix(2).joined(separator: " — ")
    }
}
