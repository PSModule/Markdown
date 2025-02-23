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
CodeBlock 'powershell' {
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
CodeBlock 'powershell' {
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

            CodeBlock 'powershell' {
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

    CodeBlock 'powershell' {
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

## Contributing

Whether you’re a user with valuable feedback or a developer with innovative ideas, your contributions are welcome. Here’s how you can get involved:

### For Users

If you encounter unexpected behavior, error messages, or missing functionality, please open an issue in the repository.
Your insights are crucial for refining the module.

### For Developers

We welcome contributions that enhance automation, extend functionality, or improve cross-platform compatibility.
Please review the [Contribution Guidelines](CONTRIBUTING.md) before submitting pull requests. Whether you want to tackle an existing
issue or propose a new feature, your ideas are essential for pushing the boundaries of what's possible with PowerShell documentation automation.
