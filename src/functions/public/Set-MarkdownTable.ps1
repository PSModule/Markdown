function Set-MarkdownTable {
    <#
        .SYNOPSIS
        Converts objects from a script block into a Markdown table.

        .DESCRIPTION
        The Set-MarkdownTable function executes a provided script block and formats the resulting objects as a Markdown table.
        Each property of the objects becomes a column, and each object becomes a row in the table. If no objects are returned,
        a warning is displayed, and no output is produced.

        .EXAMPLE
        Table {
            Get-Process | Select-Object -First 3 Name, Id
        }

        Output:
        ```powershell
        | Name | Id |
        | ---- | -- |
        | notepad | 1234 |
        | explorer | 5678 |
        | chrome | 91011 |
        ```

        Generates a Markdown table from the first three processes, displaying their Name and Id properties.

        .OUTPUTS
        string

        .NOTES
        The Markdown-formatted table as a string output.

        This function returns a Markdown-formatted table string, which can be used in documentation or exported.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownTable/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Table')]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # Script block containing commands whose output will be converted into a Markdown table.
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock] $InputScriptBlock
    )

    # Execute the script block and capture the output objects.
    $results = & $InputScriptBlock

    if (-not $results) {
        Write-Warning 'No objects to display.'
        return
    }

    # Use the first object to get the property names.
    $first = $results | Select-Object -First 1
    $props = $first.psobject.Properties.Name

    # Build the Markdown header row.
    $header = '| ' + ($props -join ' | ') + ' |'
    # Build the separator row.
    $separator = '| ' + ( ($props | ForEach-Object { '-' }) -join ' | ' ) + ' |'

    # Output header rows.
    $content = @()
    $content += $header
    $content += $separator

    # For each object, output a table row.
    foreach ($item in $results) {
        $rowValues = foreach ($prop in $props) {
            $val = $item.$prop
            if ($null -eq $val) { '' } else { $val.ToString() }
        }
        $row = '| ' + ($rowValues -join ' | ') + ' |'
        $content += $row
    }
    $content += ''

    # Return the Markdown table as a string.
    $content -join [Environment]::NewLine
}
