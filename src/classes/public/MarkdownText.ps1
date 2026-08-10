class MarkdownText {
    [string] $Text

    MarkdownText() {
        $this.Text = ''
    }

    MarkdownText([string] $text) {
        $this.Text = $text
    }
}
