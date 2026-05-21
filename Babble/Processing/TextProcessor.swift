enum TextProcessor {
    // Converts raw text into an array of alphabet indices.
    // Index 0–25 = 'a'–'z', index 26 = space.
    // Apostrophes are dropped silently; all other non-letter characters become a space.
    // Consecutive spaces are collapsed and leading/trailing spaces are stripped.
    nonisolated static func normalize(_ raw: String) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(raw.unicodeScalars.count)
        var lastWasSpace = true  // start true to suppress any leading space

        for scalar in raw.unicodeScalars {
            let value = scalar.value
            switch value {
            case 0x0027, 0x2018, 0x2019:
                // Apostrophe and typographic single quotes: drop silently.
                // "it's" → "its", "don't" → "dont"
                continue
            case 0x41...0x5A:
                // A–Z: map to 0–25
                result.append(Int(value - 0x41))
                lastWasSpace = false
            case 0x61...0x7A:
                // a–z: map to 0–25
                result.append(Int(value - 0x61))
                lastWasSpace = false
            default:
                // Everything else (punctuation, digits, whitespace) becomes a space,
                // but consecutive spaces are collapsed.
                if !lastWasSpace {
                    result.append(26)
                    lastWasSpace = true
                }
            }
        }

        // Strip trailing space if present
        if result.last == 26 {
            result.removeLast()
        }

        return result
    }
}
