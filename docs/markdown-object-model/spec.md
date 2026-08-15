---
title: Markdown object model
description: The typed object model a Markdown document parses into — a tree of sections that owns its content and renders back to specification-valid Markdown.
---

# Markdown object model

A Markdown document is available as a typed object model that can be inspected, queried, transformed, and rendered back to Markdown. The model is organised the way a document reads: a document holds a tree of sections, and a section carries the heading that opens it, its own content, and the sections nested inside it.

## Why

Markdown is edited by section. Automation extracts a named section from a README, replaces a generated section while leaving hand-written ones untouched, lifts a section and everything under it into another document, or asserts that every required section exists. Without an object model, each of these jobs is done with regular expressions against raw text — fragile against nesting, fenced code, and inline markup.

A model that mirrors the specification's own block sequence does not solve this either. In that shape a heading is a leaf sitting next to the content it introduces, so a caller has to re-derive the outline — find the heading, scan forward to the next heading of the same or a lower level, slice — at every call site. The outline rules of Markdown belong in the model, stated once.

## Outcomes and impact

- **Outcome:** Markdown is read and rewritten as structured data, by section, with no text-level pattern matching and no outline arithmetic in caller code.
- **DORA:** Lead time for changes improves for documentation-generating automation, which today re-implements Markdown parsing per repository. Change-failure rate improves as generated-content updates stop corrupting hand-written sections.
- **Domain signal:** The share of documentation automation across the ecosystem that manipulates Markdown structurally rather than by string replacement.

## Users and jobs

| User | Job |
| --- | --- |
| Module and workflow authors | Generate part of a document and merge it into a hand-written file without disturbing the rest |
| Documentation tooling | Read a document's outline, extract a section, and check that required sections are present |
| Contributors | Rewrite links, adjust heading levels, or move a section across documents in bulk |
| Agents | Take a document apart, change one part of it, and put it back without reformatting the whole file |

## Scope

**In scope**

- Parsing a Markdown string into the object model.
- Sections as the organising structure of the model, nested as deeply as heading levels allow.
- Every block and inline construct defined by [CommonMark](https://spec.commonmark.org/0.31.2/).
- Rendering any node of the model back to Markdown, whole document or single subtree.
- Constructing a document from scratch, without parsing.
- Addressing a section by its heading, including a path through nested headings.

**Out of scope**

- Markdown dialects beyond CommonMark, including tables, task list items, and strikethrough.
- Parsing and emitting frontmatter content. The model reserves a place for it; interpreting it is separate work.
- Heading anchors and slugs, which are a platform convention rather than a Markdown construct.
- Reading, writing, and locating files. The caller supplies text and decides where output lands.
- Structural validation, normalisation, and formatting policy.

## Non-goals

- **Byte-exact round-tripping.** Preserving every space and indentation detail would push insignificant whitespace into every node. The model preserves the stylistic choices a reader would notice and normalises the rest.
- **Rendering to formats other than Markdown.** The model is plain data, so any general-purpose serializer reaches other formats without the module owning a renderer for each.
- **Replacing the composition DSL.** The `Set-Markdown*` functions stay the way Markdown is composed imperatively. The object model is how existing Markdown is read and transformed.

## Functional requirements

### FR1 — A Markdown string parses into a typed object model {#fr1}

Parsing MUST accept any text valid under [CommonMark](https://spec.commonmark.org/0.31.2/) and MUST produce a typed object for every block and inline construct the specification defines. Parsing MUST NOT fail on structurally unusual but valid input.

### FR2 — A section carries its heading and owns everything beneath it {#fr2}

A section MUST expose the level, the title, and the heading style of the heading that introduces it, together with the content that follows that heading and the sections nested inside it. There MUST NOT be a separate node type for a heading. The title MUST be held as inline nodes, so that markup written inside a heading survives a parse and render cycle, and a section MUST also expose its title as plain text. Content that follows a heading, up to the next heading of the same or a lower level, MUST belong to that section.

### FR3 — A section without nested sections is the same kind of thing {#fr3}

A section that has no nested sections MUST be the same type as one that does, holding an empty collection. There MUST NOT be a distinct type for leaf sections.

### FR4 — A document is a section container without a heading {#fr4}

The document MUST be the same kind of container as a section, differing only in that it carries no heading level, title, or style, and carries the document's metadata part instead. Content appearing before the first heading MUST belong to the document.

### FR5 — Sectioning applies wherever blocks appear {#fr5}

Any construct that contains a sequence of blocks — the document, a section, a block quote, a list item — MUST group its own blocks into sections by the same rule. A heading inside a container MUST section that container and MUST NOT affect its ancestors.

### FR6 — Heading level survives nesting {#fr6}

A section's level MUST be preserved independently of how deeply that section is nested. A document that skips a level MUST nest the deeper section directly under the shallower one, MUST NOT introduce a section that is not present in the document, and MUST re-render each section at its original level. A document that starts below the first level, or whose heading levels rise again later, MUST parse without error.

### FR7 — A section is addressable by its heading {#fr7}

A section MUST be reachable by its title text and by a path of title texts through nested sections, without the caller indexing into a collection or computing heading levels.

### FR8 — The whole model is traversable in one walk {#fr8}

A single recursive traversal MUST reach every node in the model, without the caller branching on node type. The inline nodes a section holds as its title MUST be reached by that traversal, before the section's content.

### FR9 — A document can be built without parsing {#fr9}

Every node MUST be constructible directly, so a document can be assembled in memory and rendered without any Markdown text existing first.

### FR10 — Any node renders to specification-valid Markdown {#fr10}

Rendering MUST accept any node and MUST return Markdown for that node and everything below it, so a whole document and a single section are rendered the same way. Output MUST be valid under [CommonMark](https://spec.commonmark.org/0.31.2/) — correctly escaped, with sufficient fence lengths and correct list indentation — not merely text this module can read back. Rendering a section MUST produce the same text as its heading line, reconstructed from its level, title, and style, followed by its content in document order.

### FR11 — Round-tripping is semantically stable {#fr11}

Text parsed into the model, rendered, and parsed again MUST produce an equivalent model. Rendering MUST be idempotent from the second pass onward. Two models are equivalent when their content and structure match, regardless of where they were parsed from.

### FR12 — Every parsed node records where it came from {#fr12}

A node produced by parsing MUST record its position in the source text, so tooling can report diagnostics against line numbers. A node built directly MUST report no position, and position MUST be ignored when models are compared for equivalence.

### FR13 — The composition DSL is unaffected {#fr13}

The existing `Set-Markdown*` functions MUST keep working unchanged.

### FR14 — Section nesting is bounded at six levels; the tree is not bounded at all {#fr14}

A chain of sections nested one inside another MUST NOT exceed six. Sections nest only where levels strictly increase, and an ATX heading is an opening sequence of one to six unescaped `#` characters ([§4.2](https://spec.commonmark.org/0.31.2/#atx-headings)), so the longest chain a document can express runs from level one to level six. There is no seventh level.

Total depth of the model MUST NOT be bounded. Sectioning restarts inside every block container, and a heading is legal inside a block quote and inside a list item, so a block quote nested in a level six section may hold a section of its own at level one. The bound is six levels of sectioning per container, across an unlimited number of containers.

### FR15 — A comment is a node of the model {#fr15}

A comment MUST be its own kind of node rather than opaque raw HTML, at block level and at inline level alike, and every comment MUST report the same construct name so that one query finds all of them.

A block is a comment only when the block is exactly a comment. [CommonMark](https://spec.commonmark.org/0.31.2/#html-blocks) ends an HTML block at the first line containing `-->`, and whatever follows the terminator on that line belongs to the same block — in [example 177](https://spec.commonmark.org/0.31.2/#example-177), `<!-- foo -->*bar*` is one HTML block in which `*bar*` is not emphasized. A block whose comment is followed by other content on the same line MUST therefore stay an HTML block, because promoting it would discard the trailing content.

### FR16 — A comment exposes its text and whether it was terminated {#fr16}

A comment MUST expose its inner text without the `<!--` and `-->` delimiters, so that reading a comment requires no string handling by the caller. It MUST also expose whether the comment was terminated in the source.

### FR17 — An unterminated comment runs to the end of the document {#fr17}

Where no line containing `-->` follows, the comment MUST extend to the last line of the document, which is the end condition [§4.6](https://spec.commonmark.org/0.31.2/#html-blocks) defines. The model MUST record the comment as unterminated rather than presenting it as closed.

### FR18 — The degenerate comment forms are comments {#fr18}

`<!-->` and `<!--->` are comments under [§6.6](https://spec.commonmark.org/0.31.2/#raw-html). Both MUST parse as comments, MUST carry no inner text, and MUST render back exactly as written.

### FR19 — A comment's delimiters and inner spacing are preserved {#fr19}

A comment MUST re-render in the form it was written, so `<!-- x -->` MUST NOT become `<!--x-->`. Preservation of the written form is independent of the inner text a caller reads.

### FR20 — Comment-looking text inside code is not a comment {#fr20}

Text resembling a comment inside a code span, a fenced code block, or an indented code block is code content. It MUST NOT be recognised as a comment, and it MUST render back unchanged.

## Non-functional requirements

### NFR1 — Conformance is measured against the specification's own examples {#nfr1}

Every example published by [commonmark-spec](https://github.com/commonmark/commonmark-spec) MUST parse without error and MUST round-trip idempotently. Examples that cannot be satisfied MUST be recorded as known gaps rather than skipped silently.

### NFR2 — Parsing is fast enough to use in a pipeline {#nfr2}

A 1,000-line document MUST parse in under two seconds, and the conformance suite MUST complete within the repository's normal test job.

### NFR3 — The model serializes with a general-purpose serializer {#nfr3}

The object graph MUST be acyclic and MUST contain no node reachable by more than one path, so that converting a parsed document to JSON, YAML, or CLIXML produces complete output with no duplicated nodes and no special handling.

## Acceptance criteria

```gherkin
Feature: Sections own their content

  Scenario: Content follows the heading it belongs to
    Given a document with a level 1 heading followed by a paragraph
    When the document is parsed
    Then the paragraph is content of the section introduced by that heading

  Scenario: A subsection nests inside its parent
    Given a document with a level 1 heading followed by a level 2 heading
    When the document is parsed
    Then the level 2 section is nested inside the level 1 section
    And the level 1 section reports one nested section

  Scenario: A section without subsections holds an empty collection
    Given a document with a single heading and a paragraph
    When the document is parsed
    Then that section holds no nested sections
    And it is the same type as a section that has them

  Scenario: A section title keeps its inline markup
    Given a document whose heading contains emphasis and a code span
    When the document is parsed
    Then the section's title holds that emphasis and code span as inline nodes
    And rendering the section reproduces the heading with its markup intact

  Scenario: Content before the first heading belongs to the document
    Given a document that opens with a paragraph before any heading
    When the document is parsed
    Then that paragraph is content of the document
    And it is not content of any section

  Scenario: A skipped level nests without inventing a section
    Given a document with a level 1 heading followed by a level 3 heading
    When the document is parsed
    Then the level 3 section is nested directly inside the level 1 section
    And no section exists for level 2
    And rendering the document emits the second heading at level 3

  Scenario: A heading inside a block quote sections the block quote
    Given a block quote containing a heading followed by a paragraph
    When the document is parsed
    Then the section is content of the block quote
    And the document reports no section for that heading

  Scenario: A container restarts the section depth
    Given a level 6 section containing a block quote that opens with a level 1 heading
    When the document is parsed
    Then the block quote holds a section at level 1
    And no chain of nested sections within a single container exceeds six

  Scenario: A section renders on its own
    Given a parsed document containing a section with nested sections
    When that section is rendered
    Then the result is its heading line followed by its content and nested sections
    And the result parses back to an equivalent section

  Scenario: Rendering is stable
    Given any example from the CommonMark specification example set
    When it is parsed, rendered, and parsed again
    Then the two models are equivalent
    And rendering the second model produces identical text
```

```gherkin
Feature: Comments are part of the model

  Scenario: A block that is exactly a comment is a comment
    Given a document containing a line that holds only a comment
    When the document is parsed
    Then that block is a comment
    And its text is the comment content without the delimiters

  Scenario: A comment with trailing content stays an HTML block
    Given a document containing the line "<!-- foo -->*bar*"
    When the document is parsed
    Then that block is an HTML block
    And the trailing content is retained verbatim

  Scenario: An unterminated comment reaches the end of the document
    Given a document containing an opening comment delimiter and no terminator
    When the document is parsed
    Then the comment extends to the last line of the document
    And it reports that it was not terminated

  Scenario: Comment-looking text in code stays code
    Given a fenced code block whose content looks like a comment
    When the document is parsed
    Then the document reports no comment
    And the code block content renders back unchanged
```

## Constraints and assumptions

- **Constraint:** The model is the module's public surface. Its shape is settled before it first ships, because changing it afterwards is a breaking change for every consumer.
- **Constraint:** Nodes carry content, structure, and source style only. Rendering behaviour lives outside them, so the model stays plain data that any serializer can handle ([NFR3](#nfr3)).
- **Constraint:** The section tree is a grouping of the specification's block sequence, never a departure from it. Rendered output is identical to the text the ungrouped block sequence would produce ([FR10](#fr10)).
- **Assumption:** Sections are the unit callers work in. The model optimises for reaching a section and treating it as a whole, at the cost of a grouping pass at parse time.
- **Assumption:** Documents whose heading levels are irregular are common enough that they are handled by the model rather than rejected ([FR6](#fr6)).

## Dependencies

- [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/) — the construct inventory and the parsing rules the model is derived from.
- [commonmark-spec](https://github.com/commonmark/commonmark-spec) — the machine-readable example set conformance is measured against ([NFR1](#nfr1)).
