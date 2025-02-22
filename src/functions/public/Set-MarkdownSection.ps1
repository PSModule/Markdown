function Set-MarkdownSection {
    <#
        .SYNOPSIS
        Generates a formatted Markdown section with a specified header level, title, and content.

        .DESCRIPTION
        This function creates a Markdown section with a specified header level, title, and formatted content.
        The header level determines the number of `#` symbols used for the Markdown heading.
        The content is provided as a script block and executed within the function.
        The function returns the formatted Markdown as a string.

        .EXAMPLE
        Section 2 "Example Section" {
            "This is an example of Markdown content."
        }

        Output:
        ```powershell
        ## Example Section

        This is an example of Markdown content.
        ```

        Generates a Markdown section with an H2 heading and the given content.

        .OUTPUTS
        string

        .NOTES
        The formatted Markdown section as a string.

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownSection
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Sets text in memory'
    )]
    [Alias('Header')]
    [Alias('Heading')]
    [Alias('Section')]
    [Alias('H')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # Specifies the Markdown header level (1-6).
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 6)]
        [int] $Level,

        # The title of the Markdown section.
        [Parameter(Mandatory, Position = 1)]
        [string] $Title,

        # The content to be included in the Markdown section.
        [Parameter(Mandatory, Position = 2)]
        [scriptblock] $Content
    )

    $captured = & $Content | Out-String
    $captured = $captured.TrimEnd()

    # Create the Markdown header by repeating the '#' character
    $hashes = '#' * $Level
    @"
$hashes $Title

$captured

"@
}
