---
name: obsidian-reading-note-format-guide
description: Write consistent Obsidian reading notes using a stable structure, numbered reference list, and simplified in-text citations like [[#^ref-key|1]].
---

# Obsidian Reading Note Format Guide

This skill is a formatting guide for writing “reading notes” (notes grounded in one or more sources) in Obsidian, using:

- A predictable section layout
- Numbered references (`1.` … `n.`)
- Stable block IDs on each reference item (`^ref-...`)
- Simplified in-text citations that point to reference block IDs while showing numeric labels (e.g. `[[#^ref-risk|1]]` but not but not `[[#^ref-key|[1]]]`)

## When to use

Use this when you’re writing notes that:

- Summarize a paper, book, PDF, blog post, talk, or internal doc
- Need fast re-reading later (scanable + consistently structured)
- Need source grounding without repeating long citations everywhere

## Core format rules

1. **One note = one main question**
   - Put the question in the H1 title (e.g. “What’s an anti-corruption layer pattern”).
2. **Keep “purpose/why” near the top**
   - Readers should get value within 10–20 seconds.
3. **Citations should be short in-body**
   - Don’t repeat full source names/pages inline; store that detail in `## References`.
4. **References must be verbatim (no paraphrases)**
   - Each reference item should quote the source _verbatim_ (a sentence or short excerpt), not your summary.
   - Keep quoted excerpts short (prefer ≤25 words) and include page/section info.
   - You should check the page/section info correctness, which should be exactly match the original source. (e.g. the page number should be correct)
5. **References must be stable**
   - Every reference item gets a unique `^ref-...` block ID and you don’t change it later.
6. **Reference numbers are for readability**
   - You may reorder reference list numbering over time; the block IDs remain stable.

## Canonical note skeleton

Recommended headings (adjust as needed, but keep ordering consistent):

- `## TL;DR` (optional but recommended)
- `## Purposes` (or `## Key Takeaways`)
- `## Definition` (optional)
- `## When to Use` (optional)
- `## When NOT to Use` (optional)
- `## How It Works` (optional)
- `## Example` / `## Implementation Notes`
- `## Pitfalls` (optional)
- `## Checklist` (optional)
- `## References`

## In-text citation pattern (Obsidian)

### Reference item format

In `## References`, use a numbered list; each item ends with a block ID:

```md
## References

1. "Exact quote from the source." (source.pdf, p. 3) ^ref-claim-a
2. "Another exact quote." (some-article, section “X”) ^ref-claim-b
```

### In-body citation format

In sections like `## Purposes`, cite like this:

```md
... your sentence. [[#^ref-claim-a|1]]
```

- The `#^ref-claim-a` part links to the exact reference block.
- The displayed label `1` stays short and scanable.
- If you reorder the numbered reference list later, update the displayed `n` labels to match your new sequence, but keep the `^ref-...` IDs unchanged.

## Writing style guidelines

### Extremely Important (Top Priority)

- All important information must be included. If sentence length is to be adjusted, the importance of the information should be the top priority.

### guidelines

- Prefer **numbered lists** for “Purposes/Takeaways” (3–6 points).
- Keep each point to be concise when possible, but still should contain all the important info and keywords:
  - Line 1: English statement + citation
  - Line 2: Traditional Chinese translation as a blockquote (always writing bilingual notes, only if explicitly say no), e.g. `> ...`
- When keeping concise contradicts the importance, should still follow the top priority rule
- Use consistent phrasing:
  - Start purposes with verbs (Reduce…, Enable…, Decouple…, Support…).
- Keep “what” separate from “how”:
  - “Purposes” = why it matters
  - “Example/Implementation Notes” = how to do it

## Template you can paste

```md
---
title: <Question-style title>
tags: [reading-note]
status: draft
source: <optional: primary source name>
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <Question-style title>

## TL;DR

- <3 bullets max>

## Purposes

1. **<Purpose>**:
   <1–2 sentences>. [[#^ref-...|1]]
   <中文摘要（可選）>

## When to Use

- <bullets>

## When NOT to Use

- <bullets>

## Example

- <bullets / short steps>

## Pitfalls

- <bullets>

## Checklist

- [ ] Purposes list is 3–6 points
- [ ] Every non-trivial claim cites a `^ref-...`
- [ ] References are numbered and block IDs are stable

## References

1. "<Verbatim quote from source (keep it short)>". (<source>, p. X) ^ref-...
```

## Quick QA checklist (before you consider the note “done”)

- Is the H1 a question you would actually search later?
- Can you understand the note by reading only `## TL;DR` + `## Purposes`?
- Do the citations have correct page number and verbatim contents from the original source?
- Are citations consistent (`[[#^ref-...|n]]`) and do they jump to the right spot?
- Are reference block IDs stable and unique (`^ref-...`)?
