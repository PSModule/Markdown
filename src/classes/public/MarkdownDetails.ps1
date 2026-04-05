class MarkdownDetails {
    [string] $Title
    [object[]] $Content

    MarkdownDetails() {
        $this.Title = ''
        $this.Content = @()
    }

    MarkdownDetails([string] $title) {
        $this.Title = $title
        $this.Content = @()
    }

    MarkdownDetails([string] $title, [object[]] $content) {
        $this.Title = $title
        $this.Content = $content
    }
}
