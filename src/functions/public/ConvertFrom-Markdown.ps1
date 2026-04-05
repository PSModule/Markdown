function ConvertFrom-Markdown {
    <#
        .SYNOPSIS
        Converts a markdown string into a structured object representation.

        .DESCRIPTION
        The ConvertFrom-Markdown function parses a markdown string and produces an AST-like object tree
        where each markdown element (heading, code block, paragraph, table, details section) is a typed node.
        This enables programmatic inspection and transformation of markdown documents.

        Note: PowerShell 6.1+ includes a built-in ConvertFrom-Markdown cmdlet in Microsoft.PowerShell.Utility
        that converts markdown to HTML or VT100-encoded strings. This function shadows that cmdlet when the
        module is loaded. Users who need the built-in can call it with its fully qualified name
        (Microsoft.PowerShell.Utility\ConvertFrom-Markdown).

        .PARAMETER InputObject
        The markdown string to parse. Accepts pipeline input.

        .EXAMPLE
        $markdown = Get-Content -Raw '.\README.md'
        $doc = $markdown | ConvertFrom-Markdown
        $doc.Content[0].Title  # First heading title

        Parses a markdown file into an object tree.

        .EXAMPLE
        $doc = ConvertFrom-Markdown -InputObject "# Hello`n`nWorld"
        $doc.Content[0].Title  # 'Hello'

        Parses an inline markdown string.

        .OUTPUTS
        MarkdownDocument

        .LINK
        https://psmodule.io/Markdown/Functions/ConvertFrom-Markdown/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidOverwritingBuiltInCmdlets', '',
        Justification = 'Intentional: this returns a structured AST, not HTML/VT100 like the built-in'
    )]
    [OutputType([MarkdownDocument])]
    [CmdletBinding()]
    param(
        # The markdown string to parse.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string] $InputObject
    )

    process {
        $document = [MarkdownDocument]::new()

        # Stack to track the current container context.
        # Each entry is a hashtable with 'Node' (the container object) and 'Level' (for headers).
        $stack = [System.Collections.Generic.List[hashtable]]::new()
        $stack.Add(@{ Node = $document; Level = 0 })

        $lines = $InputObject -split '\r?\n'
        $i = 0

        while ($i -lt $lines.Count) {
            $line = $lines[$i]

            # --- Fenced code block ---
            if ($line -match '^(`{3,})(.*)$') {
                $fence = $Matches[1]
                $language = $Matches[2].Trim()
                $codeLines = [System.Collections.Generic.List[string]]::new()
                $i++

                while ($i -lt $lines.Count -and $lines[$i] -ne $fence) {
                    $codeLines.Add($lines[$i])
                    $i++
                }
                # Skip the closing fence line
                if ($i -lt $lines.Count) { $i++ }

                $codeBlock = [MarkdownCodeBlock]::new($language, ($codeLines -join [Environment]::NewLine))
                $stack[-1].Node.Content += $codeBlock
                continue
            }

            # --- Details block start: <details><summary>Title</summary> ---
            if ($line -match '^\s*<details>') {
                $detailsTitle = ''

                # Check for <summary> on the same line
                if ($line -match '<summary>(.*?)</summary>') {
                    $detailsTitle = $Matches[1]
                } elseif ($line -match '<summary>(.*)$') {
                    # Summary starts on this line but doesn't close
                    $detailsTitle = $Matches[1]
                    $i++
                    while ($i -lt $lines.Count -and $lines[$i] -notmatch '</summary>') {
                        $detailsTitle += $lines[$i]
                        $i++
                    }
                    if ($i -lt $lines.Count -and $lines[$i] -match '^(.*)</summary>') {
                        $detailsTitle += $Matches[1]
                    }
                }

                $details = [MarkdownDetails]::new($detailsTitle)
                $stack[-1].Node.Content += $details
                $stack.Add(@{ Node = $details; Level = -1 })
                $i++
                continue
            }

            # --- Details block end ---
            if ($line -match '^\s*</details>\s*$') {
                # Pop back to the parent of the details block
                for ($j = $stack.Count - 1; $j -ge 0; $j--) {
                    if ($stack[$j].Node -is [MarkdownDetails]) {
                        while ($stack.Count - 1 -gt $j - 1 -and $stack.Count -gt 1) {
                            $stack.RemoveAt($stack.Count - 1)
                        }
                        break
                    }
                }
                $i++
                continue
            }

            # --- Skip </p> inside details blocks ---
            if ($line -match '^\s*</p>\s*$') {
                $inDetails = $false
                for ($j = $stack.Count - 1; $j -ge 0; $j--) {
                    if ($stack[$j].Node -is [MarkdownDetails]) {
                        $inDetails = $true
                        break
                    }
                }
                if ($inDetails) {
                    $i++
                    continue
                }
                # If not in details, treat as regular text and fall through
            }

            # --- Paragraph with <p> tags ---
            if ($line -match '^\s*<p>\s*$') {
                # If inside a details block, <p>/<p> are structural wrapping — skip them
                $inDetails = $false
                for ($j = $stack.Count - 1; $j -ge 0; $j--) {
                    if ($stack[$j].Node -is [MarkdownDetails]) {
                        $inDetails = $true
                        break
                    }
                }
                if ($inDetails) {
                    $i++
                    continue
                }

                $paraLines = [System.Collections.Generic.List[string]]::new()
                $i++

                while ($i -lt $lines.Count -and $lines[$i] -notmatch '^\s*</p>\s*$') {
                    $paraLines.Add($lines[$i])
                    $i++
                }
                # Skip the closing </p> line
                if ($i -lt $lines.Count) { $i++ }

                # Trim leading/trailing blank lines from the captured content
                while ($paraLines.Count -gt 0 -and $paraLines[0].Trim() -eq '') {
                    $paraLines.RemoveAt(0)
                }
                while ($paraLines.Count -gt 0 -and $paraLines[-1].Trim() -eq '') {
                    $paraLines.RemoveAt($paraLines.Count - 1)
                }

                $paragraph = [MarkdownParagraph]::new(($paraLines -join [Environment]::NewLine), $true)
                $stack[-1].Node.Content += $paragraph
                $i++
                continue
            }

            # --- Table ---
            if ($line -match '^\|.+\|$') {
                # Parse header row
                $headings = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

                # Skip separator row
                $i++
                if ($i -lt $lines.Count -and $lines[$i] -match '^\|[\s\-\|:]+\|$') {
                    $i++
                }

                # Parse data rows
                $rows = [System.Collections.Generic.List[psobject]]::new()
                while ($i -lt $lines.Count -and $lines[$i] -match '^\|.+\|$') {
                    $values = $lines[$i] -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                    $row = [ordered]@{}
                    for ($c = 0; $c -lt $headings.Count; $c++) {
                        $val = if ($c -lt $values.Count) { $values[$c] } else { '' }
                        $row[$headings[$c]] = $val
                    }
                    $rows.Add([PSCustomObject]$row)
                    $i++
                }

                $table = [MarkdownTable]::new($rows.ToArray())
                $stack[-1].Node.Content += $table
                continue
            }

            # --- Heading ---
            if ($line -match '^(#{1,6})\s+(.+)$') {
                $level = $Matches[1].Length
                $title = $Matches[2]

                # Pop the stack until we find a container at a lower level
                while ($stack.Count -gt 1 -and $stack[-1].Level -ge $level) {
                    $stack.RemoveAt($stack.Count - 1)
                }

                $header = [MarkdownHeader]::new($level, $title)
                $stack[-1].Node.Content += $header
                $stack.Add(@{ Node = $header; Level = $level })
                $i++
                continue
            }

            # --- Blank line ---
            if ($line.Trim() -eq '') {
                $i++
                continue
            }

            # --- Plain text (collected into MarkdownText) ---
            $text = [MarkdownText]::new($line)
            $stack[-1].Node.Content += $text
            $i++
        }

        $document
    }
}
