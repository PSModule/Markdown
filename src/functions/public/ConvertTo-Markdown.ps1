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

        Write-MarkdownNode -Node $InputObject.Content -Builder $sb

        # Trim trailing whitespace but keep a single trailing newline
        $result = $sb.ToString().TrimEnd()
        $result
    }
}
