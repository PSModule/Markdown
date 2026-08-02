---
description: How the section tree is built, stored, traversed, and rendered, and why sections are the primary structure rather than a view over a flat block sequence.
---

# Markdown object model — Design

The model is a tree of nodes. Block parsing produces the specification's block sequence, a grouping pass turns runs of blocks introduced by headings into section nodes, and inline parsing fills the leaf blocks. Rendering reverses the grouping, so the section tree changes how a document is *held*, never what it *emits*.

## Specification

[spec.md](spec.md).

## Approach

Every construct is a node deriving from `MarkdownNode`. `MarkdownBlock` and `MarkdownInline` add nothing of their own and exist so `$_ -is [MarkdownBlock]` is a usable filter.

`MarkdownSection` is a block node. It carries the heading that introduces it as a property, and everything that belongs to it — its own blocks, then its nested sections — in the same `Children` collection every other node uses. `MarkdownDocument` is the same container with no heading and a frontmatter property.

```text
MarkdownDocument
├── FrontMatter : MarkdownFrontMatter        the metadata part, not a child node
└── Children
    ├── MarkdownParagraph                    content before the first heading
    └── MarkdownSection
        ├── Heading : MarkdownHeading        the heading that opens the section
        └── Children
            ├── MarkdownParagraph            content before the first subheading
            ├── MarkdownFencedCodeBlock
            └── MarkdownSection              recursive, empty for a leaf section
                ├── Heading : MarkdownHeading
                └── Children
```

Two recursion points remain from the ungrouped model — blocks inside blocks, inlines inside inlines — and sections add a third that reuses the first: a section is a block that contains blocks.

```mermaid
flowchart TD
    Doc(["MarkdownDocument"]) --> BL{{"block level"}}

    BL --> SE["MarkdownSection"]
    BL --> BQ["MarkdownBlockQuote"]
    BL --> LS["MarkdownList"]
    BL --> PA["MarkdownParagraph"]
    BL --> LFB["MarkdownThematicBreak<br>MarkdownIndentedCodeBlock<br>MarkdownFencedCodeBlock<br>MarkdownHtmlBlock<br>MarkdownLinkReferenceDefinition"]

    SE --> HD["MarkdownHeading"]
    SE --> BL
    BQ --> BL
    LS --> LI["MarkdownListItem"]
    LI --> BL

    PA --> IL{{"inline level"}}
    HD --> IL
```

A heading reaches the tree only as a section's `Heading`. Once sections exist, a bare heading in `Children` would mean a heading that introduces nothing, which no document can express.

## Alternatives considered

| Option | Trade-offs | Verdict |
| --- | --- | --- |
| Flat block sequence, headings as siblings | Mirrors the specification exactly and needs no grouping pass. Every caller re-derives the outline by scanning forward for the next heading of the same or a lower level, and the level arithmetic is wrong at the edges more often than it is right. | Rejected — pushes the hardest part of the model onto every consumer |
| Section tree as a derived view over a flat model | Keeps the specification shape as the source of truth. Two representations of one document have to be kept in step, and a mutation through the view has to be written back, which is where this design breaks down. | Rejected — two sources of truth |
| `Blocks[]` and `Sections[]` as separate collections | Reads well and matches how the shape is drawn on a whiteboard. Traversal needs both collections, document order between the two is implicit rather than stored, and a filtered view of one collection under a second name puts the same node on two paths, which duplicates it in serialized output. | Rejected — breaks single-walk traversal and clean serialization |
| Section tree as the primary structure, `Children` as the only storage | Grouping happens once, at parse time, in one place. Document order is preserved by the collection itself. Costs one pass over the block sequence, and heading level is no longer readable from nesting depth. | **Chosen** |

## Architecture

### Node members

| Member | On | Purpose |
| --- | --- | --- |
| `[string] Type` | `MarkdownNode` | The construct name, stable across serialization |
| `[MarkdownNode[]] Children` | `MarkdownNode` | The only storage for contained nodes, in document order |
| `[MarkdownSourceSpan] Source` | `MarkdownNode` | Where the node was parsed from; `$null` for nodes built directly |
| `Descendants()` | `MarkdownNode` | Depth-first walk of the whole subtree |
| `Descendants([string] $type)` | `MarkdownNode` | The same walk, filtered by construct name |
| `Sections()` | `MarkdownNode` | The nested sections in `Children` |
| `Blocks()` | `MarkdownNode` | The blocks in `Children` that are not sections |
| `GetSection([string[]] $path)` | `MarkdownNode` | The section reached by matching heading text at each step |
| `GetText()` | `MarkdownNode` | The plain text of the subtree, markup removed |
| `ToString()` | `MarkdownNode` | The Markdown for the subtree |
| `[MarkdownHeading] Heading` | `MarkdownSection` | The heading that opens the section |
| `[MarkdownFrontMatter] FrontMatter` | `MarkdownDocument` | The metadata part |

`Sections()` and `Blocks()` are methods rather than properties. A property returning a filtered view of `Children` would put the same node under two names on one object, and `ConvertTo-Json`, `ConvertTo-Yaml`, and `Export-Clixml` would emit it twice — the duplication [NFR3](spec.md#nfr3) rules out. Methods are also how `Descendants()` already works, so the surface stays consistent.

`Descendants()` yields a section's `Heading` before its `Children`. This is the one place traversal knows about a node type, and it lives inside the model so that no caller has to.

### Sectioning

The grouping pass runs after block parsing, over the child block sequence of each block container, before inline parsing. It is the only place the outline rules of Markdown are expressed.

```text
sectionize(blocks):
    roots = []                       # blocks and sections at container level
    open  = []                       # open sections, heading levels strictly increasing

    for block in blocks:
        if block is a heading:
            while open is not empty and open.last.Heading.Level >= block.Level:
                remove open.last
            section = new Section(Heading = block)
            if open is empty: roots.add(section) else: open.last.Children.add(section)
            open.add(section)
        else:
            if open is empty: roots.add(block) else: open.last.Children.add(block)

    return roots
```

The consequences are the behaviour [FR6](spec.md#fr6) requires, and they follow from the algorithm rather than from special cases:

- Blocks before the first heading stay at container level, which is why the document holds content of its own.
- A heading closes every open section at its level or deeper, so a level rising again is ordinary rather than an error.
- A skipped level nests the deeper section directly under the shallower one. Nesting depth is therefore not the heading level, and `MarkdownHeading.Level` remains the only source of truth for rendering.
- A document that starts below level 1 needs no special handling: `open` is empty, so its first section is a root.

Running per container is what makes a heading inside a block quote or a list item section that container and nothing above it ([FR5](spec.md#fr5)).

### Rendering

A section emits its heading, then its children in order. Because `Children` holds blocks and nested sections in document order, and because heading level is read from the heading rather than from depth, the text produced for a document is identical to the text the ungrouped block sequence would produce. Conformance and the round-trip contract are therefore measured on exactly the same output as before sections existed.

### Addressing a section

`GetSection()` takes a path as a string array and matches each element against the plain text of the heading at that level — `$doc.GetSection('Usage', 'Parameters')`. An array rather than a delimited string, because heading text may contain any character a delimiter could use. Matching is ordinal and case-insensitive, and the first match at each level wins; a path that matches nothing returns nothing rather than throwing, so it composes in a pipeline.

## Data and contracts

The model is the module's public contract, so its nodes are plain objects: public, typed, settable properties and no backing fields. That is what lets any general-purpose serializer take a parsed document and produce complete output, and what keeps the graph acyclic — no node holds a reference to its parent.

Validation is not performed in property setters. A node accepts a state it cannot render; the renderer throws on what it cannot express, and structural checking is a separate concern. Validating on assignment would require accessors and backing fields, which conflicts directly with plain serializable properties.

## Security

- Parsing accepts untrusted text. The grouping pass is linear in the number of blocks and holds one stack bounded by the number of open heading levels, so a hostile document cannot drive it into pathological time or unbounded memory.
- Nesting depth is bounded before recursion, so deeply nested input fails with a clear error rather than exhausting the stack.
- The model never resolves or fetches a link destination. Destinations are carried as text, and what is done with them is the caller's decision.

## Testing strategy

| Level | What it covers |
| --- | --- |
| Unit | The grouping pass in isolation: nesting, skipped levels, a level rising again, a document starting below level 1, content before the first heading, and headings inside a block quote and a list item |
| Unit | `Sections()`, `Blocks()`, `Descendants()`, and `GetSection()` against a document with sections three levels deep |
| Contract | Rendered output matches the ungrouped block sequence byte for byte, over the whole [commonmark-spec](https://github.com/commonmark/commonmark-spec) example set |
| Contract | Parse, render, parse again produces an equivalent model, and rendering the second model produces identical text |
| Contract | Converting a parsed document to JSON, YAML, and CLIXML completes with no duplicated node and no cycle |
| Performance | A 1,000-line document parses within the budget in [NFR2](spec.md#nfr2) |

## Rollout and operability

The model ships as one release, before which nothing depends on its shape. It is delivered in slices — node types, block parsing, the grouping pass, inline parsing, rendering — and the conformance suite runs in a known-failing mode until the parsing slices are complete. The release does not go out while the suite is red.

The composition DSL is untouched throughout. It writes Markdown; the model reads and transforms it. Whether the DSL is eventually reimplemented on top of the model is a separate question, deliberately left open.
