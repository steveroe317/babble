# Babble — Architecture

## 1. Overview

Babble is an iOS/macOS app that generates English-like text using character-level n-gram statistical models. The user selects one or more classic novels as training data, sets a maximum n-gram order (1–5) and an output length, then taps Generate. The app normalizes the source texts, builds an in-memory frequency model, and samples characters one at a time to produce plausible-looking prose.

---

## 2. Project structure

```
Babble/
├── BabbleApp.swift              — @main entry point
├── ContentView.swift            — NavigationSplitView root
├── Models/
│   ├── BookSource.swift         — Catalogue of 10 bundled books
│   └── NGramModel.swift         — Core statistical model (build + sample)
├── Processing/
│   └── TextProcessor.swift      — Text normalization pipeline
├── ViewModel/
│   └── BabbleViewModel.swift    — @Observable state + generate() async
├── Views/
│   ├── SidebarView.swift        — Pinned generate button + parameter/book lists
│   ├── DetailView.swift         — Progress / error / generated text states
│   ├── ParametersView.swift     — Section: n-gram order + output length steppers
│   └── BookSelectionView.swift  — Section: per-book Toggle list
└── Resources/
    └── *.txt                    — 10 plain-text books (~11.7 MB total)
BabbleTests/
└── BabbleTests.swift            — 29 unit tests (Swift Testing framework)
download_books.sh                — Dev utility: fetch + strip HTML from Standard Ebooks
```

---

## 3. The n-gram algorithm

### 3a. Alphabet

27 symbols: `a–z` = indices 0–25, space = index 26. No case distinction; all punctuation and whitespace collapses to space.

### 3b. Data representation

Five flat `[UInt32]` arrays store frequency counts for n-grams of order 1–5:

| Array | Size | Memory |
|---|---|---|
| `gram1` | 27 | negligible |
| `gram2` | 27² = 729 | negligible |
| `gram3` | 27³ = 19,683 | ~77 KB |
| `gram4` | 27⁴ = 531,441 | ~2 MB |
| `gram5` | 27⁵ = 14,348,907 | ~55 MB |

Row-major flat indexing for order *n* with preceding characters c₀…c_{n-2}:

```
rowBase = ((...(c₀ × 27 + c₁) × 27 + c₂) × 27 ...) × 27
element for next-char c  =  rowBase + c
```

Saturating addition (`&+=`) is used throughout; training on 10 novels keeps all counts well within `UInt32.max`.

### 3c. Build phase

`NGramModel.build(from:maxN:)` — `nonisolated static func` called from `Task.detached`. Iterates every character position across all encoded texts and increments the appropriate cell in each gram array up to order `maxN`. Counts for orders above `maxN` are left at zero, saving time when the user picks a lower order.

### 3d. Count-based backoff sampling

`sampleNextChar(context:maxN:)` produces one character index at a time:

1. Try the highest order `n = min(maxN, context.count + 1)`.
2. Compute `rowBase` from the last `n-1` context characters; sum all 27 next-char frequencies.
3. If the row sum > 0: perform a weighted random draw and return the result.
4. If the row sum == 0 (unseen n-gram): decrement `n` and retry from step 2.
5. Ultimate fallback: return space (26) — unreachable with valid training data.

This strategy naturally produces more varied output at lower orders and more faithful output at higher orders.

---

## 4. Text normalization

`TextProcessor.normalize(_:)` converts raw text into an `[Int]` alphabet-index sequence:

| Input | Treatment |
|---|---|
| U+0027 `'`, U+2018 `'`, U+2019 `'` | Dropped silently ("it's" → "its") |
| A–Z | Mapped to 0–25 (lowercased) |
| a–z | Mapped to 0–25 |
| Everything else | Emitted as space (26); consecutive spaces collapsed |

Leading and trailing spaces are suppressed. The function iterates Unicode scalars (not `Character`) for performance.

---

## 5. Data sources

`BookSource` is a value type (`struct`) cataloguing 10 public-domain novels from Standard Ebooks. `bundleURL` resolves the corresponding `.txt` resource via `Bundle.main.url(forResource:withExtension:)`.

| Title | Author | File |
|---|---|---|
| Pride and Prejudice | Jane Austen | `pride-and-prejudice.txt` |
| Moby-Dick | Herman Melville | `moby-dick.txt` |
| Adventures of Huckleberry Finn | Mark Twain | `adventures-of-huckleberry-finn.txt` |
| The Adventures of Sherlock Holmes | Arthur Conan Doyle | `adventures-of-sherlock-holmes.txt` |
| Dracula | Bram Stoker | `dracula.txt` |
| Great Expectations | Charles Dickens | `great-expectations.txt` |
| The Picture of Dorian Gray | Oscar Wilde | `picture-of-dorian-gray.txt` |
| Ulysses | James Joyce | `ulysses.txt` |
| War and Peace | Leo Tolstoy | `war-and-peace.txt` |
| Crime and Punishment | Fyodor Dostoevsky | `crime-and-punishment.txt` |

Files are placed in `Babble/Resources/` and automatically included in the app bundle via Xcode's `PBXFileSystemSynchronizedRootGroup` (Xcode 16+); no manual `.pbxproj` edits are needed.

`download_books.sh` (repo root) is a development utility that fetches XHTML chapters from the Standard Ebooks GitHub API, strips HTML tags with `sed`, and writes the plain-text files. Re-run it if books are added or updated.

---

## 6. MVVM architecture

`BabbleViewModel` is an `@Observable` class. `ContentView` owns it via `@State`; child views receive it as a plain `var` (read-only observation) or `@Bindable` (two-way binding for stepper/toggle values).

### generate() async — four phases

| Phase | Progress | Work |
|---|---|---|
| 1 — Load | 0 → 0.1 | `String(contentsOf:)` for each selected book |
| 2 — Normalize | 0.1 → 0.3 | `TextProcessor.normalize` on each raw text |
| 3 — Build model | 0.3 → 0.9 | `NGramModel.build` in `Task.detached` |
| 4 — Generate | 0.9 → 1.0 | `sampleNextChar` loop; assign `generatedText` + `generationMetadata` |

### GenerationMetadata

A nested struct capturing the books, order, and output length at the moment Generate was tapped. Its `summary` computed property renders the detail-pane header (e.g. "Order 5 · 500 chars · Pride and Prejudice, Ulysses +2 more"). It is set atomically with `generatedText` at the end of Phase 4 so the UI never shows a header without text.

---

## 7. UI layout

The app uses `NavigationSplitView` throughout, giving a two-column layout on iPad and Mac, and a single-column stack on iPhone.

### Sidebar (`SidebarView`)

- Generate button is **pinned above** the scrollable list so it is always visible.
- While generating, the button area is replaced by a `ProgressView` spinner + "Generating…" label.
- The scrollable `List` (`.listStyle(.sidebar)`) contains two sections: **Parameters** (`ParametersView`) and **Books** (`BookSelectionView`). All controls are disabled while generating.

**Parameters section** — two `Stepper` controls:
- Max N-gram order: 1–5 (default 5)
- Output length: 100–2000 in steps of 100 (default 500)

**Books section** — one `Toggle` per book, bound to `viewModel.selectedBooks` (a `Set<BookSource>`). The Generate button is disabled when the set is empty.

### Detail (`DetailView`)

Four mutually exclusive states, checked in order:

1. `isGenerating` → centred `ProgressView(value: viewModel.progress)` with a phase label ("Loading texts…", "Normalizing…", "Building model…", "Generating…").
2. `errorMessage != nil` → `ContentUnavailableView("Generation Failed", …)` with the error description.
3. `generationMetadata != nil` → metadata summary header above a `ScrollView` containing selectable generated text.
4. Default → `ContentUnavailableView("No Text Generated", …)` placeholder.

### iPhone auto-navigation

`ContentView` observes `viewModel.isGenerating` via `onChange`. When generation completes and `generatedText` is non-empty, it sets `preferredColumn = .detail`, automatically navigating to the result. On iPad/Mac this binding is ignored because both columns are always visible.

---

## 8. Concurrency model

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so all types are `@MainActor`-isolated by default.

- `NGramModel` and `TextProcessor` methods are marked `nonisolated`, allowing them to run on any executor without Main Actor overhead.
- The model build step uses `Task.detached(priority: .userInitiated)` to keep the ~55 MB array allocation and count-accumulation loop off the main thread.
- `NGramModel` is a `struct` and `[[Int]]` is `Sendable`; both cross the actor boundary without data races.
- All `BabbleViewModel` property mutations remain on the Main Actor: UI-facing `progress` updates happen on-actor throughout `generate()`, and the `await` on `Task.detached` hops back to the Main Actor before assigning results.

---

## 9. Testing

`BabbleTests.swift` uses the Swift Testing framework (`import Testing`, `@Suite`, `@Test`, `#expect`). 29 tests across 5 suites:

| Suite | Tests | Coverage |
|---|---|---|
| `TextProcessor` | 11 | Apostrophe/quote dropping, case mapping, space collapsing, edge cases |
| `NGramModel sizes` | 6 | Correct array sizes at init; all-zero at init |
| `NGramModel build` | 6 | Unigram/bigram accumulation; `maxN` guards; multi-text accumulation |
| `NGramModel sampling` | 4 | Deterministic sampling; count-based backoff on unseen context; empty context |
| `NGramModel decode` | 2 | Letter and space decoding |

Only core logic is unit-tested. The UI is not currently covered by UI tests.

---

## 10. Known limitations and future enhancements

**No model caching.** The n-gram model is rebuilt from scratch on every Generate tap. For a 5-gram model over all 10 books this takes several seconds. A future improvement would cache the built model keyed on the selected book set and order, and only rebuild when those inputs change.

**No settings persistence.** Selected books, n-gram order, and output length reset to defaults on every app launch. These could be persisted cheaply via `@AppStorage` (scalar values) or `SwiftData` (selected book set).

**macOS multi-window.** `WindowGroup` supports multiple independent windows on macOS; each window owns its own `BabbleViewModel` instance. This is intentional — windows are fully independent and do not share state.
