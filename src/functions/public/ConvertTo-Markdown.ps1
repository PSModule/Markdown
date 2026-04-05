function ConvertTo-Markdown {
    <#
        .SYNOPSIS
        Converts a MarkdownDocument object tree into a markdown string.

        .DESCRIPTION
        The ConvertTo-Markdown function takes a structured MarkdownDocument object (as produced by
        ConvertFrom-Markdown) and renders it back into a well-formatted markdown string.
        This enables round-tripping: parse a markdown document into objects, transform it, and write it back.

        .PARAMETER InputObject
        The MarkdownDocument object to convert. Accepts pipeline input.

        .EXAMPLE
        $doc = ConvertFrom-Markdown -InputObject $markdownString
        $doc | ConvertTo-Markdown

        Round-trips a markdown string through the object model.

        .EXAMPLE
        $doc = [MarkdownDocument]::new()
        $doc.Content += [MarkdownHeader]::new(1, 'Hello')
        $doc.Content += [MarkdownText]::new('World')
        ConvertTo-Markdown -InputObject $doc

        Programmatically builds a document and renders it to markdown.

        .OUTPUTS
        string

        .LINK
        https://psmodule.io/Markdown/Functions/ConvertTo-Markdown/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The MarkdownDocument object to convert to a markdown string.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [MarkdownDocument] $InputObject
    )

    process {
        $sb = [System.Text.StringBuilder]::new()

        function Write-Nodes {
            param(
                [object[]] $Nodes,
                [System.Text.StringBuilder] $Builder
            )

            for ($idx = 0; $idx -lt $Nodes.Count; $idx++) {
                $node = $Nodes[$idx]

                if ($node -is [MarkdownHeader]) {
                    $hashes = '#' * $node.Level
                    [void]$Builder.AppendLine("$hashes $($node.Title)")
                    [void]$Builder.AppendLine()
                    if ($node.Content.Count -gt 0) {
                        Write-Nodes -Nodes $node.Content -Builder $Builder
                    }
                } elseif ($node -is [MarkdownCodeBlock]) {
                    [void]$Builder.AppendLine('```{0}' -f $node.Language)
                    [void]$Builder.AppendLine($node.Code)
                    [void]$Builder.AppendLine('```')
                    [void]$Builder.AppendLine()
                } elseif ($node -is [MarkdownParagraph]) {
                    if ($node.Tags) {
                        [void]$Builder.AppendLine('<p>')
                        [void]$Builder.AppendLine()
                        [void]$Builder.AppendLine($node.Content)
                        [void]$Builder.AppendLine()
                        [void]$Builder.AppendLine('</p>')
                    } else {
                        [void]$Builder.AppendLine()
                        [void]$Builder.AppendLine($node.Content)
                        [void]$Builder.AppendLine()
                    }
                } elseif ($node -is [MarkdownTable]) {
                    if ($node.Rows.Count -gt 0) {
                        $props = $node.Rows[0].PSObject.Properties.Name
                        $header = '| ' + ($props -join ' | ') + ' |'
                        $separator = '| ' + (($props | ForEach-Object { '-' }) -join ' | ') + ' |'
                        [void]$Builder.AppendLine($header)
                        [void]$Builder.AppendLine($separator)
                        foreach ($row in $node.Rows) {
                            $vals = foreach ($prop in $props) {
                                $v = $row.$prop
                                if ($null -eq $v) { '' } else { "$v" }
                            }
                            [void]$Builder.AppendLine('| ' + ($vals -join ' | ') + ' |')
                        }
                        [void]$Builder.AppendLine()
                    }
                } elseif ($node -is [MarkdownDetails]) {
                    [void]$Builder.AppendLine("<details><summary>$($node.Title)</summary>")
                    [void]$Builder.AppendLine('<p>')
                    [void]$Builder.AppendLine()
                    if ($node.Content.Count -gt 0) {
                        Write-Nodes -Nodes $node.Content -Builder $Builder
                    }
                    [void]$Builder.AppendLine('</p>')
                    [void]$Builder.AppendLine('</details>')
                    [void]$Builder.AppendLine()
                } elseif ($node -is [MarkdownText]) {
                    [void]$Builder.AppendLine($node.Text)
                }
            }
        }

        Write-Nodes -Nodes $InputObject.Content -Builder $sb

        # Trim trailing whitespace but keep a single trailing newline
        $result = $sb.ToString().TrimEnd()
        $result
    }
}
