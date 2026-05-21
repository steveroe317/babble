struct NGramModel {
    nonisolated static let alphabetSize = 27  // 'a'–'z' = 0–25, space = 26

    // Five flat arrays representing 1D through 5D n-gram frequency tables.
    // gram1[c]                                   = frequency of character c
    // gram2[c0*27 + c1]                          = frequency of bigram (c0,c1)
    // gram3[(c0*27+c1)*27 + c2]                  = frequency of trigram
    // gram4[((c0*27+c1)*27+c2)*27 + c3]          = frequency of 4-gram
    // gram5[(((c0*27+c1)*27+c2)*27+c3)*27 + c4]  = frequency of 5-gram
    private(set) var gram1: [UInt32]   // 27
    private(set) var gram2: [UInt32]   // 729
    private(set) var gram3: [UInt32]   // 19,683
    private(set) var gram4: [UInt32]   // 531,441
    private(set) var gram5: [UInt32]   // 14,348,907 (~55 MB)

    nonisolated init() {
        let a = NGramModel.alphabetSize
        gram1 = [UInt32](repeating: 0, count: a)
        gram2 = [UInt32](repeating: 0, count: a * a)
        gram3 = [UInt32](repeating: 0, count: a * a * a)
        gram4 = [UInt32](repeating: 0, count: a * a * a * a)
        gram5 = [UInt32](repeating: 0, count: a * a * a * a * a)
    }

    // MARK: - Building

    /// Accumulates n-gram counts from the given encoded texts.
    /// Each element in `texts` is a sequence of alphabet indices produced by TextProcessor.normalize.
    /// Only fills gram arrays up to order `maxN`.
    nonisolated static func build(from texts: [[Int]], maxN: Int) -> NGramModel {
        var model = NGramModel()
        let a = alphabetSize

        for text in texts {
            let len = text.count
            for i in 0..<len {
                let c = text[i]

                // Unigram
                model.gram1[c] &+= 1

                // Bigram: need i >= 1
                if maxN >= 2, i >= 1 {
                    model.gram2[text[i - 1] * a + c] &+= 1
                }

                // Trigram: need i >= 2
                if maxN >= 3, i >= 2 {
                    model.gram3[(text[i - 2] * a + text[i - 1]) * a + c] &+= 1
                }

                // 4-gram: need i >= 3
                if maxN >= 4, i >= 3 {
                    let base4 = (text[i - 3] * a + text[i - 2]) * a + text[i - 1]
                    model.gram4[base4 * a + c] &+= 1
                }

                // 5-gram: need i >= 4
                if maxN >= 5, i >= 4 {
                    let base5a = (text[i - 4] * a + text[i - 3]) * a + text[i - 2]
                    let base5b = base5a * a + text[i - 1]
                    model.gram5[base5b * a + c] &+= 1
                }
            }
        }

        return model
    }

    // MARK: - Sampling

    /// Returns the next character index using a backoff strategy.
    /// Tries the highest n-gram order first; falls back to lower orders when a row has no data.
    nonisolated func sampleNextChar(context: [Int], maxN: Int) -> Int {
        let a = NGramModel.alphabetSize
        // Never attempt an order higher than what the context can support
        let maxOrder = min(maxN, context.count + 1)

        for n in stride(from: maxOrder, through: 1, by: -1) {
            let ctxLen = n - 1

            // Compute the flat row base for this context prefix
            var rowBase = 0
            let ctxStart = context.count - ctxLen
            for j in ctxStart..<context.count {
                rowBase = rowBase * a + context[j]
            }
            rowBase *= a  // points to slot for next-char index 0

            // Select the appropriate gram array
            let gram: [UInt32]
            switch n {
            case 1:  gram = gram1
            case 2:  gram = gram2
            case 3:  gram = gram3
            case 4:  gram = gram4
            default: gram = gram5
            }

            // Sum the 27 next-char frequencies for this context
            var total: UInt64 = 0
            for i in 0..<a {
                total &+= UInt64(gram[rowBase + i])
            }
            guard total > 0 else { continue }

            // Weighted random sample
            var r = UInt64.random(in: 0..<total)
            for i in 0..<a {
                let freq = UInt64(gram[rowBase + i])
                if r < freq { return i }
                r -= freq
            }
        }

        return 26  // fallback to space (should not be reached with valid training data)
    }

    // MARK: - Helpers

    nonisolated static func decode(_ index: Int) -> Character {
        index == 26 ? " " : Character(UnicodeScalar(UInt8(index + 97)))
    }
}
