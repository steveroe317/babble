import Testing
@testable import Babble

// MARK: - TextProcessor

@Suite("TextProcessor")
struct TextProcessorTests {

    @Test func lowercasesUppercase() {
        // "Hello" → h=7, e=4, l=11, l=11, o=14
        #expect(TextProcessor.normalize("Hello") == [7, 4, 11, 11, 14])
    }

    @Test func apostropheDropped() {
        // "it's" → i=8, t=19, s=18 (apostrophe removed, no space inserted)
        #expect(TextProcessor.normalize("it's") == [8, 19, 18])
    }

    @Test func typographicRightQuoteDropped() {
        #expect(TextProcessor.normalize("it\u{2019}s") == [8, 19, 18])
    }

    @Test func typographicLeftQuoteDropped() {
        #expect(TextProcessor.normalize("it\u{2018}s") == [8, 19, 18])
    }

    @Test func numberBecomesSpace() {
        // "a1b" → a=0, space=26, b=1
        #expect(TextProcessor.normalize("a1b") == [0, 26, 1])
    }

    @Test func consecutiveSpacesCollapsed() {
        #expect(TextProcessor.normalize("a  b") == [0, 26, 1])
    }

    @Test func punctuationBecomesSpace() {
        // "hello, world" → comma and extra space collapse into one space
        // h=7,e=4,l=11,l=11,o=14,space=26,w=22,o=14,r=17,l=11,d=3
        #expect(TextProcessor.normalize("hello, world") == [7, 4, 11, 11, 14, 26, 22, 14, 17, 11, 3])
    }

    @Test func emptyStringReturnsEmpty() {
        #expect(TextProcessor.normalize("").isEmpty)
    }

    @Test func leadingNonLetterSuppressed() {
        // Leading '!' would become space, but the start flag suppresses it
        #expect(TextProcessor.normalize("!hi") == [7, 8])
    }

    @Test func trailingNonLetterStripped() {
        #expect(TextProcessor.normalize("hi!") == [7, 8])
    }

    @Test func spaceIsIndex26() {
        #expect(TextProcessor.normalize("a b") == [0, 26, 1])
    }
}

// MARK: - NGramModel sizes

@Suite("NGramModel sizes")
struct NGramModelSizeTests {

    @Test func gram1Size() { #expect(NGramModel().gram1.count == 27) }
    @Test func gram2Size() { #expect(NGramModel().gram2.count == 729) }
    @Test func gram3Size() { #expect(NGramModel().gram3.count == 19683) }
    @Test func gram4Size() { #expect(NGramModel().gram4.count == 531441) }
    @Test func gram5Size() { #expect(NGramModel().gram5.count == 14348907) }

    @Test func allZeroAtInit() {
        let m = NGramModel()
        #expect(m.gram1.allSatisfy { $0 == 0 })
        #expect(m.gram2[0] == 0)
        #expect(m.gram5[0] == 0)
    }
}

// MARK: - NGramModel build

@Suite("NGramModel build")
struct NGramModelBuildTests {

    @Test func unigramCounts() {
        // [a, a, b] → a×2, b×1
        let m = NGramModel.build(from: [[0, 0, 1]], maxN: 1)
        #expect(m.gram1[0] == 2)
        #expect(m.gram1[1] == 1)
        #expect(m.gram1[2] == 0)
    }

    @Test func bigramCount() {
        // [a, b] → bigram a→b at index 0*27+1 = 1
        let m = NGramModel.build(from: [[0, 1]], maxN: 2)
        #expect(m.gram2[1] == 1)
        #expect(m.gram2[0] == 0)
    }

    @Test func gram3ZeroWhenMaxN2() {
        let m = NGramModel.build(from: [[0, 1, 2]], maxN: 2)
        #expect(m.gram3.allSatisfy { $0 == 0 })
    }

    @Test func gram4ZeroWhenMaxN3() {
        let m = NGramModel.build(from: [[0, 1, 2, 3]], maxN: 3)
        #expect(m.gram4.allSatisfy { $0 == 0 })
    }

    @Test func gram5ZeroWhenMaxN4() {
        let m = NGramModel.build(from: [[0, 1, 2, 3, 4]], maxN: 4)
        #expect(m.gram5.allSatisfy { $0 == 0 })
    }

    @Test func multipleTextsAccumulate() {
        let m = NGramModel.build(from: [[0], [0]], maxN: 1)
        #expect(m.gram1[0] == 2)
    }
}

// MARK: - NGramModel sampling

@Suite("NGramModel sampling")
struct NGramModelSampleTests {

    @Test func unigramAlwaysPicksOnlyOption() {
        // Corpus: only 'a' → every sample must return 0
        let text = Array(repeating: 0, count: 100)
        let m = NGramModel.build(from: [text], maxN: 5)
        for _ in 0..<20 {
            #expect(m.sampleNextChar(context: [], maxN: 5) == 0)
        }
    }

    @Test func bigramDeterministicWithOneSuccessor() {
        // ababab… → after 'a', only 'b' ever follows
        var text = [Int]()
        for _ in 0..<50 { text.append(contentsOf: [0, 1]) }
        let m = NGramModel.build(from: [text], maxN: 2)
        for _ in 0..<20 {
            #expect(m.sampleNextChar(context: [0], maxN: 2) == 1)
        }
    }

    @Test func backoffOnUnseenContext() {
        // Corpus: 'a' and 'b' only. Context [5,6] never seen → falls back to unigram.
        let text = [0, 1, 0, 1, 0, 1]
        let m = NGramModel.build(from: [text], maxN: 3)
        for _ in 0..<20 {
            let result = m.sampleNextChar(context: [5, 6], maxN: 3)
            #expect(result == 0 || result == 1)
        }
    }

    @Test func emptyContextUsesUnigram() {
        // Only 'z'=25 in corpus; empty context should still return 25
        let text = Array(repeating: 25, count: 50)
        let m = NGramModel.build(from: [text], maxN: 3)
        for _ in 0..<10 {
            #expect(m.sampleNextChar(context: [], maxN: 3) == 25)
        }
    }
}

// MARK: - NGramModel decode

@Suite("NGramModel decode")
struct NGramModelDecodeTests {

    @Test func decodesLetters() {
        #expect(NGramModel.decode(0) == "a")
        #expect(NGramModel.decode(25) == "z")
    }

    @Test func decodesSpace() {
        #expect(NGramModel.decode(26) == " ")
    }
}
