function Set-MarkdownDetails {
    <#
        .SYNOPSIS
        Generates a collapsible Markdown details block.

        .DESCRIPTION
        This function creates a collapsible Markdown `<details>` block with a summary title
        and formatted content. It captures the output of the provided script block and
        wraps it in a Markdown details structure.

        .EXAMPLE
        Details 'More Information' {
            'This is detailed content.'
        }

        Output:
        ```powershell
        <details><summary>More Information</summary>
        <p>

        This is detailed content.

        </p>
        </details>
        ```

        Generates a Markdown details block with the title "More Information" and the specified content.

        .OUTPUTS
        string

        .NOTES
        Returns the formatted Markdown details block as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownDetails/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns', '',
        Justification = 'Markdown details are a collection of information. Language specific'
    )]
    [Alias('Details')]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # The title of the Markdown details block.
        [Parameter(Mandatory, Position = 0)]
        [string] $Title,

        # The content inside the Markdown details block.
        [Parameter(Mandatory, Position = 1)]
        [ScriptBlock] $Content
    )

    $captured = & $Content | Out-String
    $captured = $captured.TrimEnd()

    @"
<details><summary>$Title</summary>
<p>

$captured

</p>
</details>

"@
}
