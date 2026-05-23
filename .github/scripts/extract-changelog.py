#!/usr/bin/env python3
"""Extract a single version's section from CHANGELOG.md.

Used by the release workflow to turn a tag like `12.0-1` into the
release-notes body. Reads the tag from $TAG and writes the matching
section (stripped of surrounding blank lines) to $OUTPUT. Exits
non-zero if no section is found, so a missing changelog entry fails
CI rather than silently producing an empty release.
"""

import os
import pathlib
import sys


def main() -> int:
    tag = os.environ["TAG"]
    output = pathlib.Path(os.environ.get("OUTPUT", "release-notes.md"))
    changelog = pathlib.Path(os.environ.get("CHANGELOG", "CHANGELOG.md"))

    header = f"## [{tag}]"
    section: list[str] = []
    inside = False
    for line in changelog.read_text().splitlines():
        if line.startswith(header):
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if inside:
            section.append(line)

    body = "\n".join(section).strip()
    if not body:
        print(f"::error::No section for {tag} found in {changelog}")
        return 1

    output.write_text(body + "\n")
    print(f"--- Release notes for {tag} ---")
    print(body)
    return 0


if __name__ == "__main__":
    sys.exit(main())
