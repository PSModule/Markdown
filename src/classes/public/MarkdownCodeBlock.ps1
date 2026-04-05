class MarkdownCodeBlock {
    [string] $Language
    [string] $Code

    MarkdownCodeBlock() {
        $this.Language = ''
        $this.Code = ''
    }

    MarkdownCodeBlock([string] $language, [string] $code) {
        $this.Language = $language
        $this.Code = $code
    }
}
