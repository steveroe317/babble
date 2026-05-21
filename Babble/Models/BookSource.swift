import Foundation

struct BookSource: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String

    var bundleURL: URL? {
        Bundle.main.url(forResource: id, withExtension: "txt")
    }

    static let all: [BookSource] = [
        BookSource(id: "pride-and-prejudice",
                   title: "Pride and Prejudice",
                   author: "Jane Austen"),
        BookSource(id: "moby-dick",
                   title: "Moby-Dick",
                   author: "Herman Melville"),
        BookSource(id: "adventures-of-huckleberry-finn",
                   title: "Adventures of Huckleberry Finn",
                   author: "Mark Twain"),
        BookSource(id: "adventures-of-sherlock-holmes",
                   title: "The Adventures of Sherlock Holmes",
                   author: "Arthur Conan Doyle"),
        BookSource(id: "dracula",
                   title: "Dracula",
                   author: "Bram Stoker"),
        BookSource(id: "great-expectations",
                   title: "Great Expectations",
                   author: "Charles Dickens"),
        BookSource(id: "picture-of-dorian-gray",
                   title: "The Picture of Dorian Gray",
                   author: "Oscar Wilde"),
        BookSource(id: "ulysses",
                   title: "Ulysses",
                   author: "James Joyce"),
        BookSource(id: "war-and-peace",
                   title: "War and Peace",
                   author: "Leo Tolstoy"),
        BookSource(id: "crime-and-punishment",
                   title: "Crime and Punishment",
                   author: "Fyodor Dostoevsky"),
    ]
}
