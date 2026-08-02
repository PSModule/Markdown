---
title: Markdown object model
description: The capability that turns a Markdown document into a typed, section-oriented object model and back again.
---

# Markdown object model

Markdown text goes in, a typed object model comes out, and Markdown comes back. The model is organised the way a document reads — a tree of sections, each owning its heading, its own content, and the sections nested inside it — so documentation automation manipulates structure instead of matching patterns in text.

| Document | Answers |
| --- | --- |
| [spec.md](spec.md) | Why the model exists and what it must do |
| [design.md](design.md) | How it is built — the node types, the sectioning pass, and rendering |

## At a glance

```text
Document
├── FrontMatter                     the metadata part
├── (blocks)                        content before the first heading
└── Section
    ├── Heading
    ├── (blocks)                    content before the first subheading
    └── Section                     recursive, empty for a leaf section
```

```powershell
$doc = Get-Content -Raw 'README.md' | ConvertFrom-Markdown

$doc.GetSection('Usage').Descendants('Link') | Select-Object Destination, Title
$doc.GetSection('Usage', 'Parameters').Children = $generated.Children

$doc | ConvertTo-Markdown | Set-Content 'README.md'
```

The composition DSL is a separate, complementary surface: `Set-Markdown*` is how Markdown is written from nothing, the object model is how existing Markdown is read and changed.
