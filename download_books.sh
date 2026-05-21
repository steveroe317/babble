#!/usr/bin/env bash
# Downloads and pre-processes the 10 Standard Ebooks texts into plain .txt files.
# Run once from the repo root: bash download_books.sh
# Requires: curl, python3

DEST="Babble/Resources"
mkdir -p "$DEST"

# Strip HTML tags and decode common entities, then collapse whitespace.
strip_html() {
    sed 's/<[^>]*>//g' \
    | sed "s/&#x2019;/'/g; s/&#x2018;/'/g; s/&#x201C;/\"/g; s/&#x201D;/\"/g; \
           s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&nbsp;/ /g; \
           s/&#x[0-9A-Fa-f]*;//g; s/&#[0-9]*;//g; s/&[a-z]*;//g" \
    | tr -s '\n\t\r ' ' '
}

fetch_book() {
    local REPO="$1"
    local OUTNAME="$2"
    local OUTFILE
    OUTFILE="$DEST/$OUTNAME.txt"
    local API="https://api.github.com/repos/$REPO/contents/src/epub/text"

    if [ -f "$OUTFILE" ]; then
        echo "  Skipping $OUTNAME (already exists)"
        return 0
    fi
    echo "Fetching $REPO..."

    # Get sorted list of chapter XHTML download URLs, excluding boilerplate pages
    local FILES
    FILES=$(curl -fsSL "$API" | python3 -c "
import sys, json
data = json.load(sys.stdin)
skip = {
    'titlepage.xhtml', 'colophon.xhtml', 'imprint.xhtml',
    'uncopyright.xhtml', 'halftitlepage.xhtml', 'copyright-page.xhtml',
    'dedication.xhtml', 'epigraph.xhtml', 'preface.xhtml',
}
urls = sorted(
    f['download_url'] for f in data
    if f['name'].endswith('.xhtml') and f['name'] not in skip
)
print('\n'.join(urls))
")

    if [ -z "$FILES" ]; then
        echo "  ERROR: No XHTML files found for $REPO"
        return 0
    fi

    # Download each chapter and concatenate, then strip HTML
    {
        while IFS= read -r url; do
            curl -fsSL "$url"
            printf ' '
        done <<< "$FILES"
    } | strip_html > "$OUTFILE"

    local BYTES
    BYTES=$(wc -c < "$OUTFILE")
    echo "  -> $OUTFILE ($BYTES bytes)"
}

fetch_book "standardebooks/jane-austen_pride-and-prejudice" \
           "pride-and-prejudice"

fetch_book "standardebooks/herman-melville_moby-dick" \
           "moby-dick"

fetch_book "standardebooks/mark-twain_the-adventures-of-huckleberry-finn" \
           "adventures-of-huckleberry-finn"

fetch_book "standardebooks/arthur-conan-doyle_the-adventures-of-sherlock-holmes" \
           "adventures-of-sherlock-holmes"

fetch_book "standardebooks/bram-stoker_dracula" \
           "dracula"

fetch_book "standardebooks/charles-dickens_great-expectations" \
           "great-expectations"

fetch_book "standardebooks/oscar-wilde_the-picture-of-dorian-gray" \
           "picture-of-dorian-gray"

fetch_book "standardebooks/james-joyce_ulysses" \
           "ulysses"

fetch_book "standardebooks/leo-tolstoy_war-and-peace_louise-maude_aylmer-maude" \
           "war-and-peace"

fetch_book "standardebooks/fyodor-dostoevsky_crime-and-punishment_constance-garnett" \
           "crime-and-punishment"

echo ""
echo "All done. File sizes:"
ls -lh "$DEST"/*.txt
