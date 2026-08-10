# Markdown

A PowerShell module that converts a custom DSL into Markdown documents with ease. It empowers you to programmatically generate well-structured
Markdown—featuring headings, collapsible details, code fences, and tables — using intuitive DSL commands. Built for automation and fully
cross-platform, this module challenges the conventional approach to documentation generation.

## Installation

To install the module from the PowerShell Gallery, run the following commands:

```powershell
Install-PSResource -Name Markdown
Import-Module -Name Markdown
```

## Usage

The `Markdown` module introduces a Domain Specific Language (DSL) that simplifies the creation of Markdown files. With straightforward commands, you
can generate headings, details blocks, fenced code blocks, and tables without manually formatting Markdown.

### Heading

Create Markdown headings by specifying the level, title, and content.

```powershell
Heading 1 'Title' {
    'Content under the title'
}
```

This produces:

```markdown
# Title

Content under the title
```

Supports nested headings.

```powershell
Heading 1 'Title' {
    'Content under the title'

    Heading 2 'Nested Title' {
        'Content under the nested title'
    }
}
```

This produces:

```markdown
# Title

Content under the title

## Nested Title

Content under the nested title
```

### Paragraph

Create a paragraph of text.

```powershell
Paragraph {
    'This is a paragraph'
}
```

This produces:

```markdown

This is a paragraph

```

Supports tags for inline formatting.

```powershell
Paragraph {
    'This is a paragraph with tags'
} -Tags
```

This produces:

```markdown
<p>

This is a paragraph with tags

</p>
```

### Details

Generate collapsible sections with a summary title.

```powershell
Details 'More Information' {
    'Detailed content goes here'
}
```

This produces:

```markdown
<details><summary>More Information</summary>
<p>

Detailed content goes here

</p>
</details>
```

Supports nested details blocks.

```powershell
Details 'More Information' {
    'Detailed content goes here'

    Details 'Nested Information' {
        'Nested content goes here'
    }
}
```

This produces:

```markdown
<details><summary>More Information</summary>
<p>

Detailed content goes here

<details><summary>Nested Information</summary>
<p>

Nested content goes here

</p>
</details>

</p>
</details>
```


### CodeBlock

Create fenced code blocks for any programming language.

```powershell
CodeBlock 'PowerShell' {
    Get-Process
}
```

This produces:

````markdown
```powershell
Get-Process
```
````

It can also execute PowerShell code directly and use the output in the code block (using the `-Execute` switch).

```powershell
CodeBlock 'PowerShell' {
    @(
        [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
        [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
    )
} -Execute
```

This produces:

````markdown
```powershell

Name     Age
----     ---
John Doe  30
Jane Doe  25

```
````

### Table

Convert a collection of PowerShell objects into a Markdown table.

```powershell
Table {
    @(
        [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
        [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
    )
}
```

This produces:

```markdown
| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |
```

### Example: Full Markdown Document Generation

Below is an example DSL script that demonstrates how to compose a complete Markdown document:

```powershell
Heading 1 'This is the section title' {
    'Some string content here'

    Heading 2 'Should be able to call nested sections' {
        'Some string content here too'

        Details 'This is the detail title' {
            'Some string content here'

            CodeBlock 'PowerShell' {
                Get-Process
            }

            Details 'Should be able to call nested details' {
                'Some string content here too'
            }
        }

        Paragraph {
            'This is a paragraph'
        } -Tags

        'This is the end of the section'
    }

    CodeBlock 'PowerShell' {
        @(
            [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
            [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
        )
    } -Execute

    Table {
        @(
            [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
            [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
        )
    }


    'This is the end of the document'
}
```

The DSL above automatically generates the following Markdown:

````markdown
# This is the section title

Some string content here
## Should be able to call nested sections

Some string content here too
<details><summary>This is the detail title</summary>
<p>

Some string content here
```powershell
Get-Process
```

<details><summary>Should be able to call nested details</summary>
<p>

Some string content here too

</p>
</details>

</p>
</details>


<p>

This is a paragraph

</p>

This is the end of the section

```powershell

Name     Age
----     ---
John Doe  30
Jane Doe  25


```

| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |

This is the end of the document

````

## Conversion Functions

The module also provides `ConvertFrom-Markdown` and `ConvertTo-Markdown` functions for parsing and generating Markdown,
following the standard PowerShell `ConvertFrom-`/`ConvertTo-` verb convention (like `ConvertFrom-Json`/`ConvertTo-Json`).

### ConvertFrom-Markdown

Parses a Markdown string into a structured object tree (AST) containing headings, code blocks, paragraphs, tables, and details
sections — enabling programmatic inspection and transformation.

> **Note:** PowerShell 6.1+ includes a built-in `ConvertFrom-Markdown` cmdlet that converts markdown to HTML/VT100. This module's
> function shadows it when loaded. To use the built-in, call `Microsoft.PowerShell.Utility\ConvertFrom-Markdown`.

```powershell
$markdown = Get-Content -Raw '.\README.md'
$doc = $markdown | ConvertFrom-Markdown
$doc.Content          # Top-level elements
$doc.Content[0].Title # First heading title
```

### ConvertTo-Markdown

Converts a structured MarkdownDocument object back into a well-formatted Markdown string. This enables **round-tripping**: read a
Markdown document, inspect or transform it, and write it back.

```powershell
$markdown = Get-Content -Raw '.\README.md'
$doc = $markdown | ConvertFrom-Markdown
$result = $doc | ConvertTo-Markdown
$result | Set-Content '.\output.md'
```

### Supported Node Types

| Class | Properties | Represents |
| - | - | - |
| `MarkdownDocument` | `Content` (node array) | Root document container |
| `MarkdownHeader` | `Level`, `Title`, `Content` (node array) | Heading `#`–`######` with nested content |
| `MarkdownCodeBlock` | `Language`, `Code` (string) | Fenced code block |
| `MarkdownParagraph` | `Content` (string), `Tags` (bool) | Paragraph text (supports `<p>` tag variant) |
| `MarkdownTable` | `Rows` (PSCustomObject array) | Markdown table |
| `MarkdownDetails` | `Title`, `Content` (node array) | Collapsible `<details>` section |
| `MarkdownText` | `Text` (string) | Plain text content |

### Round-Trip Example

```powershell
# Parse → inspect → regenerate
$doc = Get-Content -Raw '.\example.md' | ConvertFrom-Markdown

# Find all headings
$doc.Content | Where-Object { $_ -is [MarkdownHeader] } | ForEach-Object { $_.Title }

# Convert back to markdown
$doc | ConvertTo-Markdown | Set-Content '.\output.md'
```

## Contributing

Whether you’re a user with valuable feedback or a developer with innovative ideas, your contributions are welcome. Here’s how you can get involved:

### For Users

If you encounter unexpected behavior, error messages, or missing functionality, please open an issue in the repository.
Your insights are crucial for refining the module.

### For Developers

We welcome contributions that enhance automation, extend functionality, or improve cross-platform compatibility.
Please review the [Contribution Guidelines](CONTRIBUTING.md) before submitting pull requests. Whether you want to tackle an existing
issue or propose a new feature, your ideas are essential for pushing the boundaries of what's possible with PowerShell documentation automation.
