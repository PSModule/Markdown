class MarkdownParagraph {
    [string] $Content
    [bool] $Tags

    MarkdownParagraph() {
        $this.Content = ''
        $this.Tags = $false
    }

    MarkdownParagraph([string] $content) {
        $this.Content = $content
        $this.Tags = $false
    }

    MarkdownParagraph([string] $content, [bool] $tags) {
        $this.Content = $content
        $this.Tags = $tags
    }
}
