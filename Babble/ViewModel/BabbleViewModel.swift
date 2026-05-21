import Foundation

@Observable
class BabbleViewModel {
    struct GenerationMetadata {
        let bookTitles: [String]
        let maxNGramOrder: Int
        let outputLength: Int

        var summary: String {
            let shown = Array(bookTitles.prefix(3))
            let overflow = bookTitles.count - shown.count
            let bookStr = shown.joined(separator: ", ")
                        + (overflow > 0 ? " +\(overflow) more" : "")
            return "Order \(maxNGramOrder) · \(outputLength) chars · \(bookStr)"
        }
    }

    var selectedBooks: Set<BookSource> = Set(BookSource.all)
    var maxNGramOrder: Int = 5
    var outputLength: Int = 500
    var generatedText: String = ""
    var generationMetadata: GenerationMetadata? = nil
    var isGenerating: Bool = false
    var progress: Double = 0.0
    var errorMessage: String? = nil

    var canGenerate: Bool {
        !selectedBooks.isEmpty && !isGenerating
    }

    func generate() async {
        guard canGenerate else { return }

        isGenerating = true
        progress = 0.0
        errorMessage = nil
        generatedText = ""
        generationMetadata = nil

        do {
            // Phase 1: Load bundled text files (progress 0 → 0.1)
            let books = BookSource.all.filter { selectedBooks.contains($0) }
            let metadata = GenerationMetadata(
                bookTitles: books.map { $0.title },
                maxNGramOrder: maxNGramOrder,
                outputLength: outputLength
            )
            var rawTexts: [String] = []
            for (i, book) in books.enumerated() {
                guard let url = book.bundleURL else {
                    throw BabbleError.missingResource(book.id)
                }
                rawTexts.append(try String(contentsOf: url, encoding: .utf8))
                progress = Double(i + 1) / Double(books.count) * 0.1
            }

            // Phase 2: Normalize text (progress 0.1 → 0.3)
            let encodedTexts: [[Int]] = rawTexts.map { TextProcessor.normalize($0) }
            progress = 0.3

            // Phase 3: Build n-gram model on a background executor (progress 0.3 → 0.9)
            let order = maxNGramOrder
            let model = await Task.detached(priority: .userInitiated) {
                NGramModel.build(from: encodedTexts, maxN: order)
            }.value
            progress = 0.9

            // Phase 4: Generate text (progress 0.9 → 1.0)
            let length = outputLength
            generatedText = BabbleViewModel.generateText(model: model, length: length, maxN: order)
            generationMetadata = metadata
            progress = 1.0

        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    private static func generateText(model: NGramModel, length: Int, maxN: Int) -> String {
        let windowSize = max(0, maxN - 1)
        // Seed the context with a space so generation starts at a word boundary.
        // The seed is not emitted to output.
        var context: [Int] = windowSize > 0 ? [26] : []
        var output: [Character] = []
        output.reserveCapacity(length)

        while output.count < length {
            let next = model.sampleNextChar(context: context, maxN: maxN)
            output.append(NGramModel.decode(next))
            if windowSize > 0 {
                context.append(next)
                if context.count > windowSize {
                    context.removeFirst()
                }
            }
        }

        return String(output)
    }
}

enum BabbleError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let id):
            return "Missing text file for \"\(id)\" in the app bundle."
        }
    }
}
