class MarkdownHeader {
    [int] $Level
    [string] $Title
    [object[]] $Content

    MarkdownHeader() {
        $this.Level = 1
        $this.Title = ''
        $this.Content = @()
    }

    MarkdownHeader([int] $level, [string] $title) {
        $this.Level = $level
        $this.Title = $title
        $this.Content = @()
    }

    MarkdownHeader([int] $level, [string] $title, [object[]] $content) {
        $this.Level = $level
        $this.Title = $title
        $this.Content = $content
    }
}
