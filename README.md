# Babble

Babble is an iOS/macOS app that demonstrates English-like text generation using character-level n-gram language models.

The app trains on classic public-domain novels — Pride and Prejudice, Moby-Dick, Ulysses, and seven others — then samples characters one at a time based on the statistical patterns found in those texts. The result is prose that looks plausible at a glance but is entirely invented.

## How the parameters affect output

**N-gram order** (1–5) controls how much context the model uses when picking the next character:

- Order 1 (unigram): characters are chosen purely by how common they are overall — output looks like random letter soup.
- Order 2–3: recognisable words start to emerge, though sentences are mostly nonsense.
- Order 4–5: output reads like plausible English sentences, often with vocabulary characteristic of the selected books.

**Source texts** shape the style and vocabulary. Using only Ulysses produces denser, stranger output; mixing in Huckleberry Finn shifts the register toward conversational American English. Combining many books produces a blended average style.

**Output length** sets how many characters to generate (100–2000).

## Building

Open `Babble.xcodeproj` in Xcode 16 or later and build for iOS 26+ or macOS. The text files used for training are already bundled in `Babble/Resources/`. To refresh or replace them, run the download script from the project root:

```sh
bash download_books.sh
```

## Architecture

See [docs/architecture.md](docs/architecture.md) for a full description of the n-gram algorithm, text normalization pipeline, MVVM structure, concurrency model, and known limitations.

## Credits

Built with [Claude Code](https://claude.ai/code).

Training texts sourced from [Standard Ebooks](https://standardebooks.org), a volunteer-run project producing free, carefully formatted public-domain ebooks.
