class MarkdownTable {
    [psobject[]] $Rows

    MarkdownTable() {
        $this.Rows = @()
    }

    MarkdownTable([psobject[]] $rows) {
        $this.Rows = $rows
    }
}
