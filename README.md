# Markdown

Markdown is a cross-platform PowerShell module for building Markdown content programmatically. It provides a small set of
composable commands that let you generate well-structured Markdown — headings, paragraphs, collapsible details, fenced code
blocks, and tables — directly from PowerShell, making it a natural fit for automated documentation generation.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Markdown
Import-Module -Name Markdown
```

## Usage

Each command returns a Markdown-formatted string, and they nest inside one another so you can compose a whole document
from PowerShell.

### Example: Build a section with a table and code block

```powershell
Set-MarkdownSection -Level 2 -Title 'Running processes' -Content {
    'A snapshot of the current processes:'

    Set-MarkdownTable -InputScriptBlock {
        Get-Process | Select-Object -First 3 Name, Id
    }

    Set-MarkdownCodeBlock -Language 'powershell' -Content {
        Get-Process | Select-Object -First 3 Name, Id
    }
}
```

### Example: Add a collapsible details block

```powershell
Set-MarkdownDetails -Title 'More information' -Content {
    Set-MarkdownParagraph -Content {
        'Content inside a details block stays hidden until expanded.'
    }
}
```

## Documentation

Documentation is published at [psmodule.io/Markdown](https://psmodule.io/Markdown/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Markdown
Get-Help -Name Set-MarkdownTable -Examples
```
