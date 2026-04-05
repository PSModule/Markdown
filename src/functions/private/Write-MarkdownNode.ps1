function Write-MarkdownNode {
    <#
        .SYNOPSIS
        Renders markdown node objects into a StringBuilder.

        .DESCRIPTION
        This function recursively processes an array of markdown node objects (MarkdownHeader,
        MarkdownCodeBlock, MarkdownParagraph, MarkdownTable, MarkdownDetails, MarkdownText)
        and appends their markdown representation to the provided StringBuilder.

        .PARAMETER Node
        An array of markdown node objects to render.

        .PARAMETER Builder
        The StringBuilder instance to append rendered markdown to.

        .EXAMPLE
        $sb = [System.Text.StringBuilder]::new()
        Write-MarkdownNode -Node $doc.Content -Builder $sb

        Renders all nodes in a MarkdownDocument into the StringBuilder.
    #>
    [CmdletBinding()]
    param(
        # The markdown node objects to render.
        [Parameter(Mandatory, Position = 0)]
        [object[]] $Node,

        # The StringBuilder to append rendered output to.
        [Parameter(Mandatory, Position = 1)]
        [System.Text.StringBuilder] $Builder
    )

    for ($idx = 0; $idx -lt $Node.Count; $idx++) {
        $item = $Node[$idx]

        if ($item -is [MarkdownHeader]) {
            $hashes = '#' * $item.Level
            [void]$Builder.AppendLine("$hashes $($item.Title)")
            [void]$Builder.AppendLine()
            if ($item.Content.Count -gt 0) {
                Write-MarkdownNode -Node $item.Content -Builder $Builder
            }
        } elseif ($item -is [MarkdownCodeBlock]) {
            [void]$Builder.AppendLine('```{0}' -f $item.Language)
            [void]$Builder.AppendLine($item.Code)
            [void]$Builder.AppendLine('```')
            [void]$Builder.AppendLine()
        } elseif ($item -is [MarkdownParagraph]) {
            if ($item.Tags) {
                [void]$Builder.AppendLine('<p>')
                [void]$Builder.AppendLine()
                [void]$Builder.AppendLine($item.Content)
                [void]$Builder.AppendLine()
                [void]$Builder.AppendLine('</p>')
            } else {
                [void]$Builder.AppendLine()
                [void]$Builder.AppendLine($item.Content)
                [void]$Builder.AppendLine()
            }
        } elseif ($item -is [MarkdownTable]) {
            if ($item.Rows.Count -gt 0) {
                $props = $item.Rows[0].PSObject.Properties.Name
                $header = '| ' + ($props -join ' | ') + ' |'
                $separator = '| ' + (($props | ForEach-Object { '-' }) -join ' | ') + ' |'
                [void]$Builder.AppendLine($header)
                [void]$Builder.AppendLine($separator)
                foreach ($row in $item.Rows) {
                    $vals = foreach ($prop in $props) {
                        $v = $row.$prop
                        if ($null -eq $v) { '' } else { "$v" }
                    }
                    [void]$Builder.AppendLine('| ' + ($vals -join ' | ') + ' |')
                }
                [void]$Builder.AppendLine()
            }
        } elseif ($item -is [MarkdownDetails]) {
            [void]$Builder.AppendLine("<details><summary>$($item.Title)</summary>")
            [void]$Builder.AppendLine('<p>')
            [void]$Builder.AppendLine()
            if ($item.Content.Count -gt 0) {
                Write-MarkdownNode -Node $item.Content -Builder $Builder
            }
            [void]$Builder.AppendLine('</p>')
            [void]$Builder.AppendLine('</details>')
            [void]$Builder.AppendLine()
        } elseif ($item -is [MarkdownText]) {
            [void]$Builder.AppendLine($item.Text)
        }
    }
}
