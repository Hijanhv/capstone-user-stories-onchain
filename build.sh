#!/usr/bin/env bash
set -euo pipefail

# Build the combined deliverable PDF from the two markdown sources.
# Uses pandoc to render markdown -> standalone HTML, then headless Chrome
# to print the HTML to PDF. This avoids needing a LaTeX toolchain.
#
# Requires: pandoc, Google Chrome (or Chromium).

cd "$(dirname "$0")"

OUT_DIR="dist"
HTML_FILE="$OUT_DIR/cordon-user-stories.html"
PDF_FILE="$OUT_DIR/cordon-user-stories.pdf"
mkdir -p "$OUT_DIR"

# Locate a Chromium-family browser.
CHROME=""
for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  "$(command -v chromium 2>/dev/null || true)" \
  "$(command -v google-chrome 2>/dev/null || true)"
do
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    CHROME="$candidate"
    break
  fi
done

if [[ -z "$CHROME" ]]; then
  echo "error: no Chromium-family browser found" >&2
  echo "install Chrome from https://www.google.com/chrome/ or Chromium via brew install --cask chromium" >&2
  exit 1
fi

# Inline CSS for a readable, printable A4-ish page.
CSS_FILE="$(mktemp -t cordon-css.XXXXXX).css"
trap 'rm -f "$CSS_FILE"' EXIT

cat > "$CSS_FILE" <<'CSS'
@page { size: A4; margin: 22mm 18mm; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 10.5pt;
  line-height: 1.45;
  color: #1a1a1a;
  max-width: none;
}
h1 { font-size: 20pt; margin-top: 1.6em; page-break-before: always; }
h1:first-of-type { page-break-before: avoid; }
h2 { font-size: 14pt; margin-top: 1.4em; border-bottom: 1px solid #ddd; padding-bottom: 0.2em; }
h3 { font-size: 12pt; margin-top: 1.2em; }
h4 { font-size: 11pt; margin-top: 1em; }
p, li { orphans: 3; widows: 3; }
code {
  font-family: "SF Mono", Menlo, Consolas, monospace;
  font-size: 9.5pt;
  background: #f4f4f4;
  padding: 0.1em 0.3em;
  border-radius: 3px;
}
pre {
  background: #f6f8fa;
  padding: 0.8em;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 9pt;
}
pre code { background: transparent; padding: 0; }
table { border-collapse: collapse; margin: 1em 0; font-size: 10pt; }
th, td { border: 1px solid #ccc; padding: 0.4em 0.6em; text-align: left; vertical-align: top; }
th { background: #f0f0f0; }
blockquote {
  border-left: 3px solid #888;
  margin-left: 0;
  padding-left: 1em;
  color: #444;
  font-style: italic;
}
hr { border: none; border-top: 1px solid #ccc; margin: 1.6em 0; }
a { color: #0366d6; text-decoration: none; }
ul, ol { padding-left: 1.4em; }
.title-block { margin-bottom: 2em; }
.title-block h1 { page-break-before: avoid; border-bottom: 2px solid #1a1a1a; padding-bottom: 0.3em; }
nav#TOC { page-break-after: always; }
nav#TOC ul { list-style: none; padding-left: 1em; }
nav#TOC > ul { padding-left: 0; }
CSS

# Render markdown -> standalone HTML with embedded CSS and a TOC.
pandoc \
  --standalone \
  --toc --toc-depth=2 \
  --css "$CSS_FILE" \
  --self-contained 2>/dev/null \
  --metadata title="Cordon — User Stories & On-Chain Requirements" \
  --metadata author="Janhavi Chavada · Turbin3 Builders Cohort" \
  --metadata date="$(date +'%B %Y')" \
  part-a-deliverable.md \
  part-b-process-appendix.md \
  -o "$HTML_FILE" \
  || pandoc \
       --standalone \
       --toc --toc-depth=2 \
       --css "$CSS_FILE" \
       --embed-resources \
       --metadata title="Cordon — User Stories & On-Chain Requirements" \
       --metadata author="Janhavi Chavada · Turbin3 Builders Cohort" \
       --metadata date="$(date +'%B %Y')" \
       part-a-deliverable.md \
       part-b-process-appendix.md \
       -o "$HTML_FILE"

# Print HTML -> PDF with headless Chrome.
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --no-pdf-header-footer \
  --print-to-pdf="$PWD/$PDF_FILE" \
  "file://$PWD/$HTML_FILE" \
  2>/dev/null

echo "built: $PDF_FILE"
