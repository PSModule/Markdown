class MarkdownDocument {
    [object[]] $Content

    MarkdownDocument() {
        $this.Content = @()
    }

    MarkdownDocument([object[]] $content) {
        $this.Content = $content
    }
}
