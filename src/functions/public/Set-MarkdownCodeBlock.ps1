function Set-MarkdownCodeBlock {
    <#
        .SYNOPSIS
        Generates a fenced code block for Markdown using the specified language.

        .DESCRIPTION
        This function takes a programming language and a script block, and depending on the provided parameters,
        either captures the script block's literal text (with indentation normalized) or executes it and captures the
        string representation of the output. It then formats the result as a fenced code block suitable for Markdown.

        .EXAMPLE
        Set-MarkdownCodeBlock -Language 'powershell' -Content {
            Get-Process
        }

        Output:
        ```powershell
        Get-Process
        ```

        Generates a fenced code block with the specified PowerShell script.

        .EXAMPLE
        CodeBlock 'powershell' {
            Get-Process
        }

        Output:
        ```powershell
        Get-Process
        ```

        Generates a fenced code block with the specified PowerShell script.

        .EXAMPLE
        CodeBlock -Language 'powershell' -Content {
            Get-Process | Select-Object -First 1
        } -Execute

        Output:
        ```powershell
        NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
        ------    -----      -----     ------      --  -- -----------
            13     4.09      15.91       0.00    9904   0 AggregatorHost
        ```

        Generates a fenced code block with the output of the specified PowerShell script.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted fenced code block as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownCodeBlock/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Block')]
    [Alias('CodeBlock')]
    [Alias('Fence')]
    [Alias('CodeFence')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Language,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock] $Content,

        [Parameter()]
        [switch] $Execute
    )

    # If -Execute is specified, run the script block and capture its output.
    if ($Execute) {
        # Execute the script block and capture all output as a single string.
        $output = . $Content | Out-String
        # Split the output into lines.
        $lines = $output -split "`r?`n"
    } else {
        # Capture the raw text of the script block.
        $raw = $Content.Ast.Extent.Text
        $lines = $raw -split "`r?`n"

        # Remove leading and trailing blank lines.
        while ($lines.Count -gt 0 -and $lines[0].Trim() -eq '') {
            $lines = $lines[1..($lines.Count - 1)]
        }
        while ($lines.Count -gt 0 -and $lines[-1].Trim() -eq '') {
            $lines = $lines[0..($lines.Count - 2)]
        }

        # If the first and last lines are only '{' and '}', remove them.
        if ($lines.Count -ge 2 -and $lines[0].Trim() -eq '{' -and $lines[-1].Trim() -eq '}') {
            $lines = $lines[1..($lines.Count - 2)]
        }

        # Determine common leading whitespace (indentation) on non-empty lines.
        $nonEmpty = $lines | Where-Object { $_.Trim().Length -gt 0 }
        if ($nonEmpty) {
            $commonIndent = ($nonEmpty | ForEach-Object {
                    $_.Length - $_.TrimStart().Length
                } | Measure-Object -Minimum).Minimum

            # Remove the common indent from each line.
            $lines = $lines | ForEach-Object {
                if ($_.Length -ge $commonIndent) { $_.Substring($commonIndent) } else { $_ }
            }
        }
    }

    # Build the Markdown fenced code block.
    $return = @()
    $return += '```{0}' -f $Language
    $return += $lines
    $return += '```'
    $return += ''

    $return -join [Environment]::NewLine
}
