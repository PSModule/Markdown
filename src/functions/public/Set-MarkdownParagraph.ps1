function Set-MarkdownParagraph {
    <#
        .SYNOPSIS
        Generates a Markdown paragraph.

        .DESCRIPTION
        This function captures the output of the provided script block and formats it as a Markdown paragraph.
        It trims trailing whitespace and surrounds the content with blank lines to ensure proper Markdown formatting.

        .EXAMPLE
        Paragraph {
            "This is a simple Markdown paragraph generated dynamically."
        }

        Output:
        ```markdown

        This is a simple Markdown paragraph generated dynamically.

        ```

        .EXAMPLE
        Paragraph {
            "This is a simple Markdown paragraph generated dynamically."
        } -Tags

        Output:
        ```markdown
        <p>

        This is a simple Markdown paragraph generated dynamically.

        </p>
        ```

        Generates a Markdown paragraph with the specified content.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted Markdown paragraph as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownParagraph/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [OutputType([string])]
    [Alias('Paragraph')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ScriptBlock] $Content,

        [Parameter()]
        [switch] $Tags
    )

    # Capture the output of the script block and trim trailing whitespace.
    $captured = . $Content | Out-String
    $captured = $captured.TrimEnd()

    # Surround the paragraph with blank lines to ensure proper Markdown separation.
    $return = @()
    if ($Tags) {
        $return += ''
        $return += '<p>'
    }
    $return += ''
    $return += $captured
    $return += ''
    if ($Tags) {
        $return += '</p>'
        $return += ''
    }

    $return -join [System.Environment]::NewLine
}
