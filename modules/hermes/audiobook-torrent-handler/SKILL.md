---
name: audiobook-torrent-handler
description: Handle newly downloaded audiobook torrents on this media server by finding new files in /tank/media/downloads, identifying the author/series/book, and hardlinking them into the correct /tank/media/audiobooks/Author/Series/Book folder structure. Use this skill whenever the user asks to "handle the newest audiobook torrents", "link the new audiobooks", "process downloads", "organize the audiobooks folder", or anything else about getting recently-downloaded audiobook files into the library -- even if they phrase it differently or don't mention "skill" at all. This skill does NOT touch Audiobookshelf (no scanning, no matching, no API calls) -- that is always a separate, explicitly-requested step.
---

# Audiobook Torrent Handler

This server downloads audiobook torrents into `/tank/media/downloads`. The
library that Audiobookshelf actually serves lives at `/tank/media/audiobooks`,
organized as `Author Name/Series Name/Book N - Title/file.ext`. This skill's
job is to get new downloads into that structure correctly — nothing more.

**Scope boundary:** this skill never calls the Audiobookshelf API, never
triggers a scan or match, and never stores or asks for credentials. If the
user wants that, it's a separate request they'll make explicitly.

## The core rule: hardlink, never move, never symlink

Always `ln source dest` from the file still sitting in `downloads/` into its
new home under `audiobooks/`. Never `mv` a file that's already hardlinked
into place (e.g. to shuffle it into a newly-discovered subfolder) — `mv`
breaks the link to the original inode, and if that inode's only remaining
reference was the one you just moved, cleanup tools or a reseed can silently
delete the "same" file out from under the other link. If a file needs to end
up in a different folder than where it was first linked, create the new
hardlink from the **downloads** copy, not by moving the existing library
copy.

Never symlink. Audiobookshelf (and some torrent clients) can behave oddly
with symlinks across the tools involved here; hardlinks on the same
filesystem are the established convention and keep both the seed and the
library copy as equally-real files.

## Step 1 — find what's new

Run the bundled script, which uses the most recently linked file in the
library as its own watermark (so it doesn't depend on anything from a prior
conversation):

```
bash scripts/find_new_audiobooks.sh
```

This filters out the junk that regularly shows up in the same downloads
folder: images, subtitles, `.nfo`/`.txt`, `slskd/` (a Soundcloud/Soulseek
music client's own download tree), `incomplete/` (still downloading — skip
these, they'll show up again once finished), and obvious video containers
(`.mkv`, `.mp4`). It is a first pass, not a verdict — still read the output
yourself. Two things it can't filter out:

- **Non-audiobook media that slipped through**: TV/movie downloads sometimes
  land in the same `downloads/` root. If a result is obviously a show or
  movie (episode-numbered filenames, a name you don't recognize as a book),
  just skip it — don't link it anywhere.
- **Already-linked files that still look "new"**: if the watermark file
  itself hasn't been touched in a while but something else was re-downloaded
  or re-processed, you might see a path you already handled. Before doing
  any work on a candidate, check whether it's already hardlinked into the
  library — `ls -i` on both the downloads path and the suspected destination
  and compare inode numbers. If they match, it's already done; skip it.

## Step 2 — identify the book for each new candidate

For each real audiobook file (usually `.m4b`, sometimes `.mp3`, occasionally
`.ogg` for serialized releases), pull its embedded metadata:

```
ffprobe -v quiet -print_format json -show_format "<file>" | grep -E '"artist"|"album_artist"|"album"'
```

`artist`/`album_artist` is almost always the author. `album` usually carries
the book title and sometimes the series + book number (e.g. `"Book of the
Dead 4: Vengeance: A LitRPG Adventure"`). The `comment` tag often has the
back-cover blurb, which is useful for figuring out reading order when the
filename doesn't say (e.g. one book's blurb says "Ajax finished his delves
and is returning home..." right after a book called "The Delves" — that's
how you confirm it's the very next one in sequence, not just "some other
book by the same author").

If metadata is missing, contradictory, or the filename suggests a different
author than the tags do, do a web search to confirm before proceeding —
don't guess. If the search doesn't resolve it either, stop and ask the user
(see "When to stop and ask" below).

An extensionless file or a file inside a folder `find -maxdepth` treats
oddly can look empty or invalid when it isn't — before concluding a
candidate is broken, run `ffprobe` on it directly to confirm.

## Step 3 — find where it belongs in the existing library

1. Check for an existing author folder: `ls /tank/media/audiobooks | grep -i "<author name>"`.
   - **No match** → new author. Create `Author Name/` using the author's
     name as it appears in the metadata (match the existing library's
     general casing conventions, e.g. title case, but don't overthink it).
   - **Exactly one match** → use it.
   - **More than one match**, especially ones differing only in
     capitalization or spacing (this has happened before — e.g. `PathofPen`
     vs `PathOfPen`, or a stray leading space like ` zaifyr` vs `Zaifyr`) →
     **stop and ask the user** which folder to use, or whether to merge
     them. Don't silently pick one; the existing split usually means content
     is already divided between them and guessing wrong scatters a series
     further.

2. Once you have the author folder, look at what's already inside it to find
   the right series folder, and inside *that*, look at how existing books
   are named. **Mirror whatever convention is already there** rather than
   inventing a new one — the existing folders in this library use several
   different patterns and you want the new entry to look like a sibling, not
   an outlier:
   - `Book 1`, `Book 2`, ... (plain numbered)
   - `Book 1 - Title`, `Book 2 - Title`, ...
   - The book's full title as the folder name (common when the series
     itself doesn't use numbers in its branding)
   - `Vol. 1`, `Vol. 2`, ... or `#1`, `#2`, ...
   - A `Complete Series` or `The Complete Series` single folder holding every
     part together, when that's how the user has asked for a particular
     series to be organized (rare — only do this if the existing folder
     already works this way, or the user says so)

   If the series doesn't exist yet under that author, create it using
   whichever pattern feels most natural for how the download itself is
   labeled, but lean toward `Book N` or `Book N - Title` as the default when
   there's no existing convention to match.

3. If you can't tell where in a series a book belongs (no number in the
   metadata or filename, and the blurb doesn't make the sequence obvious),
   **stop and ask the user** rather than guessing at a book number.

## Step 4 — hardlink it in

```
mkdir -p "/tank/media/audiobooks/Author Name/Series Name/Book N - Title"
ln "/tank/media/downloads/.../source-file.m4b" \
   "/tank/media/audiobooks/Author Name/Series Name/Book N - Title/Destination Name.m4b"
```

Rename the destination filename to something clean and consistent with
sibling books in the same series if the source filename is a mess (torrent
release tags, ASIN codes, underscores-for-spaces, etc.) — the source file in
`downloads/` stays untouched, you're only choosing the name for the new
hardlink.

For a download that's split across multiple files that all belong in the
same destination folder (a multi-chapter book, or several parts of what's
really one release), loop and `ln` every file into that single destination
folder rather than creating one folder per part.

## Step 5 — report back

End with a short summary: what got linked where (one line per book is
enough), and call out anything you weren't fully sure about even if you
didn't stop to ask about it (e.g. "used a reasonable-but-unconfirmed series
position" or "renamed the destination file for consistency").

## When to stop and ask instead of proceeding

Don't make a judgment call and move on in these cases — pause and ask the
user directly:

- The author can't be confidently identified from metadata or a web search.
- Multiple existing author folders could match (capitalization/spelling
  variants) and it's not obvious which one is canonical or whether they
  should be merged.
- A destination folder or file can't be created/linked because of a
  **permissions error** (`mkdir`/`ln` fails with "Permission denied"). This
  almost always means something in that author's folder got root-owned —
  from a prior `sudo jdupes` run or a manual fix — and needs a `sudo chown`/
  `chmod` pass before you can write there. Tell the user which path is
  affected and what command would fix it; don't work around it with `sudo`
  yourself unless they've already said it's fine to do that in this
  session.
- The book's position in a series genuinely can't be determined.
- Anything else where proceeding would mean guessing rather than knowing.

## What this skill deliberately does not do

- It does not call the Audiobookshelf API, trigger a library scan, or
  trigger metadata matching. If the user wants that, it's a separate,
  explicit request — don't fold it into "handling the newest torrents"
  automatically.
- It does not store or ask for any API tokens or credentials.
- It does not delete, move, or modify anything already inside
  `/tank/media/audiobooks` as a side effect of linking in something new —
  the one exception is fixing an author/series folder's *name* when the
  user has explicitly asked for a reorg, which is a different, deliberate
  task from "handle the newest torrents."
