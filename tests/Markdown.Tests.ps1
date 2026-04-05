[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param()

BeforeAll {
    $PSStyle.OutputRendering = 'Host'
}

Describe 'Module' {
    Context 'Set-MarkdownSection' {
        It 'Can render a #2 heading with a paragraph' {
            $content = Set-MarkdownSection -Level 2 -Title 'Example Section' -Content {
                'This is an example of Markdown content.'
            }

            $expected = @'
## Example Section

This is an example of Markdown content.

'@
            $content | Should -Be $expected
        }
    }

    Context 'Set-MarkdownDetails' {
        It 'Can render a details block with a paragraph' {
            $content = Set-MarkdownDetails -Title 'More Information' -Content {
                'This is detailed content.'
            }

            $expected = @'
<details><summary>More Information</summary>
<p>

This is detailed content.

</p>
</details>

'@
            $content | Should -Be $expected
        }
    }

    Context 'Set-MarkdownTable' {
        It 'Can render a table with two columns' {
            $content = Set-MarkdownTable -InputScriptBlock {
                @(
                    [PSCustomObject]@{
                        Name = 'John Doe'
                        Age  = 30
                    }
                    [PSCustomObject]@{
                        Name = 'Jane Doe'
                        Age  = 25
                    }
                )
            }

            $expected = @'
| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |

'@
            $content | Should -Be $expected
        }
    }

    Context 'Set-MarkdownCodeBlock' {
        It 'Can render a code block with PowerShell code' {
            $content = Set-MarkdownCodeBlock -Language 'PowerShell' -Content {
                Get-Process
            }

            $expected = @'
```powershell
Get-Process
```

'@
            $content | Should -Be $expected
        }

        It 'Can execute and render a code block with PowerShell code' {
            $content = Set-MarkdownCodeBlock -Language 'PowerShell' -Content {
                [PSCustomObject]@{
                    Name = 'John Doe'
                    Age  = 30
                }
            } -Execute

            $expected = @'
```powershell

Name     Age
----     ---
John Doe  30


```

'@
            $content | Should -Be $expected
        }
    }

    Context 'Set-MarkdownParagraph' {
        It 'Can render a paragraph' {
            $content = Set-MarkdownParagraph -Content {
                'This is a simple Markdown paragraph generated dynamically.'
            }

            $expected = @'

This is a simple Markdown paragraph generated dynamically.

'@
            $content | Should -Be $expected

        }
        It 'Can render a paragraph with HTML <p> tags' {
            $content = Set-MarkdownParagraph -Content {
                'This is a simple Markdown paragraph generated dynamically.'
            } -Tags

            $expected = @'

<p>

This is a simple Markdown paragraph generated dynamically.

</p>

'@
            $content | Should -Be $expected

        }
    }

    Context 'Combined' {
        It 'Can write a markdown doc as DSL' {
            $content = Heading 1 'This is the section title' {
                'Some string content here'

                Heading 2 'Should be able to call nested sections' {
                    'Some string content here too'

                    Details 'This is the detail title' {
                        'Some string content here'

                        CodeBlock 'PowerShell' {
                            Get-Process
                        }

                        Details 'Should be able to call nested details' {
                            'Some string content here too'
                        }
                    }

                    Paragraph {
                        'This is a paragraph'
                    } -Tags

                    'This is the end of the section'
                }

                CodeBlock 'PowerShell' {
                    @(
                        [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
                        [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
                    )
                } -Execute

                Table {
                    @(
                        [PSCustomObject]@{ Name = 'John Doe'; Age = 30 }
                        [PSCustomObject]@{ Name = 'Jane Doe'; Age = 25 }
                    )
                }


                'This is the end of the document'
            }

            $expected = @'
# This is the section title

Some string content here
## Should be able to call nested sections

Some string content here too
<details><summary>This is the detail title</summary>
<p>

Some string content here
```powershell
Get-Process
```

<details><summary>Should be able to call nested details</summary>
<p>

Some string content here too

</p>
</details>

</p>
</details>


<p>

This is a paragraph

</p>

This is the end of the section

```powershell

Name     Age
----     ---
John Doe  30
Jane Doe  25


```

| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |

This is the end of the document

'@
            $content | Should -Be $expected
        }
    }
}

Describe 'ConvertFrom-Markdown' {
    Context 'Headings' {
        It 'Should parse a level 1 heading' {
            $md = @'
# Main Title

Some text
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $doc | Should -BeOfType 'MarkdownDocument'
            $doc.Content[0] | Should -BeOfType 'MarkdownHeader'
            $doc.Content[0].Level | Should -Be 1
            $doc.Content[0].Title | Should -Be 'Main Title'
        }

        It 'Should parse nested headings with correct hierarchy' {
            $md = @'
# Top Level

## Sub Section

Sub text

### Deep Section

Deep text
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $doc.Content[0] | Should -BeOfType 'MarkdownHeader'
            $doc.Content[0].Level | Should -Be 1
            $doc.Content[0].Title | Should -Be 'Top Level'

            $sub = $doc.Content[0].Content | Where-Object { $_ -is [MarkdownHeader] }
            $sub | Should -Not -BeNullOrEmpty
            $sub.Level | Should -Be 2
            $sub.Title | Should -Be 'Sub Section'

            $deep = $sub.Content | Where-Object { $_ -is [MarkdownHeader] }
            $deep | Should -Not -BeNullOrEmpty
            $deep.Level | Should -Be 3
            $deep.Title | Should -Be 'Deep Section'
        }

        It 'Should parse multiple top-level headings as siblings' {
            $md = @'
# First

# Second
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $headers = $doc.Content | Where-Object { $_ -is [MarkdownHeader] }
            $headers.Count | Should -Be 2
            $headers[0].Title | Should -Be 'First'
            $headers[1].Title | Should -Be 'Second'
        }

        It 'Should handle heading level jumps (1 to 3)' {
            $md = @'
# Top

### Skip to 3

Text
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $doc.Content[0].Level | Should -Be 1
            $nested = $doc.Content[0].Content | Where-Object { $_ -is [MarkdownHeader] }
            $nested.Level | Should -Be 3
        }
    }

    Context 'Code blocks' {
        It 'Should parse a fenced code block with language' {
            $md = @'
```powershell
Get-Process
Get-Service
```
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $cb = $doc.Content[0]
            $cb | Should -BeOfType 'MarkdownCodeBlock'
            $cb.Language | Should -Be 'powershell'
            $cb.Code | Should -Be ("Get-Process{0}Get-Service" -f [Environment]::NewLine)
        }

        It 'Should parse a code block without language' {
            $md = @'
```
some code
```
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $cb = $doc.Content[0]
            $cb | Should -BeOfType 'MarkdownCodeBlock'
            $cb.Language | Should -Be ''
            $cb.Code | Should -Be 'some code'
        }
    }

    Context 'Paragraphs' {
        It 'Should parse <p> tagged paragraphs' {
            $md = @'
<p>

This is a tagged paragraph

</p>
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $para = $doc.Content[0]
            $para | Should -BeOfType 'MarkdownParagraph'
            $para.Tags | Should -Be $true
            $para.Content | Should -Be 'This is a tagged paragraph'
        }
    }

    Context 'Tables' {
        It 'Should parse a table with rows as PSCustomObjects' {
            $md = @'
| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $table = $doc.Content[0]
            $table | Should -BeOfType 'MarkdownTable'
            $table.Rows.Count | Should -Be 2
            $table.Rows[0].Name | Should -Be 'John Doe'
            $table.Rows[0].Age | Should -Be '30'
            $table.Rows[1].Name | Should -Be 'Jane Doe'
            $table.Rows[1].Age | Should -Be '25'
        }
    }

    Context 'Details' {
        It 'Should parse a details block with summary' {
            $md = @'
<details><summary>More Information</summary>
<p>

Details content here

</p>
</details>
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $details = $doc.Content[0]
            $details | Should -BeOfType 'MarkdownDetails'
            $details.Title | Should -Be 'More Information'
        }

        It 'Should parse nested details blocks' {
            $md = @'
<details><summary>Outer</summary>
<p>

Outer text

<details><summary>Inner</summary>
<p>

Inner text

</p>
</details>

</p>
</details>
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $outer = $doc.Content[0]
            $outer | Should -BeOfType 'MarkdownDetails'
            $outer.Title | Should -Be 'Outer'

            $inner = $outer.Content | Where-Object { $_ -is [MarkdownDetails] }
            $inner | Should -Not -BeNullOrEmpty
            $inner.Title | Should -Be 'Inner'
        }
    }

    Context 'Plain text' {
        It 'Should parse plain text as MarkdownText nodes' {
            $md = @'
Just some text
Another line
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $texts = $doc.Content | Where-Object { $_ -is [MarkdownText] }
            $texts.Count | Should -Be 2
            $texts[0].Text | Should -Be 'Just some text'
            $texts[1].Text | Should -Be 'Another line'
        }

        It 'Should place plain text under the correct header scope' {
            $md = @'
# Title

Text under title
'@
            $doc = ConvertFrom-Markdown -InputObject $md
            $header = $doc.Content[0]
            $header | Should -BeOfType 'MarkdownHeader'
            $text = $header.Content | Where-Object { $_ -is [MarkdownText] }
            $text | Should -Not -BeNullOrEmpty
            $text.Text | Should -Be 'Text under title'
        }
    }

    Context 'Empty document' {
        It 'Should return an empty MarkdownDocument for blank input' {
            $doc = ConvertFrom-Markdown -InputObject ''
            $doc | Should -BeOfType 'MarkdownDocument'
            $doc.Content.Count | Should -Be 0
        }
    }

    Context 'Pipeline input' {
        It 'Should accept input from pipeline' {
            $md = '# Pipeline Test'
            $doc = $md | ConvertFrom-Markdown
            $doc.Content[0].Title | Should -Be 'Pipeline Test'
        }
    }
}

Describe 'ConvertTo-Markdown' {
    Context 'Headings' {
        It 'Should render a heading with correct level' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownHeader]::new(2, 'Test Title')
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -BeLike '## Test Title*'
        }

        It 'Should render nested headings' {
            $doc = [MarkdownDocument]::new()
            $h1 = [MarkdownHeader]::new(1, 'Top')
            $h2 = [MarkdownHeader]::new(2, 'Sub')
            $h1.Content += $h2
            $doc.Content += $h1
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match '# Top'
            $result | Should -Match '## Sub'
        }
    }

    Context 'Code blocks' {
        It 'Should render a fenced code block with language' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownCodeBlock]::new('powershell', 'Get-Process')
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match '```powershell'
            $result | Should -Match 'Get-Process'
            $result | Should -Match '```'
        }
    }

    Context 'Paragraphs' {
        It 'Should render a tagged paragraph with <p> tags' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownParagraph]::new('Tagged content', $true)
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match '<p>'
            $result | Should -Match 'Tagged content'
            $result | Should -Match '</p>'
        }

        It 'Should render an untagged paragraph without <p> tags' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownParagraph]::new('Plain content', $false)
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match 'Plain content'
            $result | Should -Not -Match '<p>'
        }
    }

    Context 'Tables' {
        It 'Should render a table with header and rows' {
            $doc = [MarkdownDocument]::new()
            $rows = @(
                [PSCustomObject]@{ Name = 'John'; Age = '30' }
                [PSCustomObject]@{ Name = 'Jane'; Age = '25' }
            )
            $doc.Content += [MarkdownTable]::new($rows)
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match '\| Name \| Age \|'
            $result | Should -Match '\| - \| - \|'
            $result | Should -Match '\| John \| 30 \|'
            $result | Should -Match '\| Jane \| 25 \|'
        }
    }

    Context 'Details' {
        It 'Should render a details block with summary' {
            $doc = [MarkdownDocument]::new()
            $details = [MarkdownDetails]::new('Summary Title')
            $details.Content += [MarkdownText]::new('Details body')
            $doc.Content += $details
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Match '<details><summary>Summary Title</summary>'
            $result | Should -Match 'Details body'
            $result | Should -Match '</details>'
        }
    }

    Context 'Text' {
        It 'Should render MarkdownText as plain text lines' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownText]::new('Hello world')
            $result = ConvertTo-Markdown -InputObject $doc
            $result | Should -Be 'Hello world'
        }
    }

    Context 'Pipeline input' {
        It 'Should accept input from pipeline' {
            $doc = [MarkdownDocument]::new()
            $doc.Content += [MarkdownHeader]::new(1, 'Pipeline')
            $result = $doc | ConvertTo-Markdown
            $result | Should -Match '# Pipeline'
        }
    }
}

Describe 'Markdown Round-Trip' {
    It 'Should preserve structure through a round-trip for headings and text' {
        $md = @'
# Title

Some text

## Sub Title

More text
'@
        $doc = ConvertFrom-Markdown -InputObject $md
        $result = ConvertTo-Markdown -InputObject $doc
        $result | Should -Match '# Title'
        $result | Should -Match 'Some text'
        $result | Should -Match '## Sub Title'
        $result | Should -Match 'More text'
    }

    It 'Should preserve structure through a round-trip for code blocks' {
        $md = @'
```powershell
Get-Process
```
'@
        $doc = ConvertFrom-Markdown -InputObject $md
        $result = ConvertTo-Markdown -InputObject $doc
        $result | Should -Match '```powershell'
        $result | Should -Match 'Get-Process'
        $result | Should -Match '```'
    }

    It 'Should preserve structure through a round-trip for tables' {
        $md = @'
| Name | Age |
| - | - |
| John | 30 |
| Jane | 25 |
'@
        $doc = ConvertFrom-Markdown -InputObject $md
        $result = ConvertTo-Markdown -InputObject $doc
        $result | Should -Match '\| Name \| Age \|'
        $result | Should -Match '\| John \| 30 \|'
        $result | Should -Match '\| Jane \| 25 \|'
    }

    It 'Should preserve structure through a round-trip for details blocks' {
        $md = @'
<details><summary>Info</summary>
<p>

Content here

</p>
</details>
'@
        $doc = ConvertFrom-Markdown -InputObject $md
        $result = ConvertTo-Markdown -InputObject $doc
        $result | Should -Match '<details><summary>Info</summary>'
        $result | Should -Match 'Content here'
        $result | Should -Match '</details>'
    }

    It 'Should round-trip a complex document' {
        $md = @'
# Main

Intro text

## Features

<details><summary>Feature Details</summary>
<p>

Feature description

```powershell
Get-Feature
```

</p>
</details>

| Name | Value |
| - | - |
| A | 1 |
| B | 2 |
'@
        $doc = ConvertFrom-Markdown -InputObject $md
        $result = ConvertTo-Markdown -InputObject $doc
        $result | Should -Match '# Main'
        $result | Should -Match 'Intro text'
        $result | Should -Match '## Features'
        $result | Should -Match '<details><summary>Feature Details</summary>'
        $result | Should -Match 'Feature description'
        $result | Should -Match '```powershell'
        $result | Should -Match 'Get-Feature'
        $result | Should -Match '\| Name \| Value \|'
        $result | Should -Match '\| A \| 1 \|'
    }
}

AfterAll {
    $PSStyle.OutputRendering = 'Ansi'
}
