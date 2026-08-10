function ConvertTo-Markdown {
    <#
        .SYNOPSIS
        Converts a MarkdownDocument object tree into a Markdown string.

        .DESCRIPTION
        The ConvertTo-Markdown function takes a structured MarkdownDocument object (as produced by
        ConvertFrom-Markdown) and renders it back into a well-formatted Markdown string.
        This enables round-tripping: parse a Markdown document into objects, transform it, and write it back.

        .PARAMETER InputObject
        The MarkdownDocument object to convert. Accepts pipeline input.

        .EXAMPLE
        $doc = ConvertFrom-Markdown -InputObject $markdownString
        $doc | ConvertTo-Markdown

        Round-trips a Markdown string through the object model.

        .EXAMPLE
        $doc = [MarkdownDocument]::new()
        $doc.Content += [MarkdownHeader]::new(1, 'Hello')
        $doc.Content += [MarkdownText]::new('World')
        ConvertTo-Markdown -InputObject $doc

        Programmatically builds a document and renders it to Markdown.

        .OUTPUTS
        string

        .LINK
        https://psmodule.io/Markdown/Functions/ConvertTo-Markdown/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The MarkdownDocument object to convert to a Markdown string.
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
