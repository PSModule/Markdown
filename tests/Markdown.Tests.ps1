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

Describe 'ConvertFrom-MarkdownMarkdown' {
    BeforeAll {
        $testFile = Join-Path ([System.IO.Path]::GetTempPath()) "PesterMarkdownTest_$([guid]::NewGuid().ToString()).md"
        @'
# Main Title

Some introductory text

## Sub Section

Sub section text

<details><summary>Expandable Section</summary>

Details content here

<details><summary>Nested Details</summary>

Nested details content

</details>

</details>

```powershell
Get-Process
```

<p>

This is a tagged paragraph

</p>

Plain text without paragraph tags

| Column1 | Column2 |
| - | - |
| Value1 | Value2 |
| Value3 | Value4 |

# Second Top Level

More content here
'@ | Set-Content -Path $testFile -NoNewline
        $result = ConvertFrom-MarkdownMarkdown -Path $testFile
    }

    AfterAll {
        if (Test-Path $testFile) {
            Remove-Item -Path $testFile -Force
        }
    }

    Context 'Sections' {
        It 'Should parse a level 1 heading with correct type, level and title' {
            $result.Content[0].Type | Should -Be 'Header'
            $result.Content[0].Level | Should -Be 1
            $result.Content[0].Title | Should -Be 'Main Title'
        }

        It 'Should parse a nested level 2 heading inside a level 1 heading' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' -and $_.Level -eq 2 }
            $subSection | Should -Not -BeNullOrEmpty
            $subSection.Title | Should -Be 'Sub Section'
        }

        It 'Should parse multiple level 1 headings as sibling elements' {
            $topLevelHeaders = $result.Content | Where-Object { $_.Type -eq 'Header' -and $_.Level -eq 1 }
            $topLevelHeaders.Count | Should -Be 2
            $topLevelHeaders[1].Title | Should -Be 'Second Top Level'
        }
    }

    Context 'Details' {
        It 'Should parse a details block with the correct summary title' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $details = $subSection.Content | Where-Object { $_.Type -eq 'Details' } | Select-Object -First 1
            $details | Should -Not -BeNullOrEmpty
            $details.Title | Should -Be 'Expandable Section'
        }

        It 'Should capture string content inside a details block' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $details = $subSection.Content | Where-Object { $_.Type -eq 'Details' } | Select-Object -First 1
            $strings = $details.Content | Where-Object { $_ -is [string] }
            $strings | Should -Contain 'Details content here'
        }

        It 'Should parse nested details blocks' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $details = $subSection.Content | Where-Object { $_.Type -eq 'Details' } | Select-Object -First 1
            $nestedDetails = $details.Content | Where-Object { $_.Type -eq 'Details' }
            $nestedDetails | Should -Not -BeNullOrEmpty
            $nestedDetails.Title | Should -Be 'Nested Details'
        }
    }

    Context 'Codeblocks' {
        It 'Should parse a fenced code block as CodeBlock type' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $codeBlock = $subSection.Content | Where-Object { $_.Type -eq 'CodeBlock' }
            $codeBlock | Should -Not -BeNullOrEmpty
            $codeBlock.Type | Should -Be 'CodeBlock'
        }

        It 'Should detect the language of the code block' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $codeBlock = $subSection.Content | Where-Object { $_.Type -eq 'CodeBlock' }
            $codeBlock.Language | Should -Be 'powershell'
        }

        It 'Should capture the code block content lines' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $codeBlock = $subSection.Content | Where-Object { $_.Type -eq 'CodeBlock' }
            $codeBlock.Content | Should -Contain 'Get-Process'
        }
    }

    Context 'Paragraphs with tags' {
        It 'Should parse <p> tagged content as a Paragraph type' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $paragraph = $subSection.Content | Where-Object { $_.Type -eq 'Paragraph' }
            $paragraph | Should -Not -BeNullOrEmpty
            $paragraph.Type | Should -Be 'Paragraph'
        }

        It 'Should set the Parameters property to -Tags for tagged paragraphs' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $paragraph = $subSection.Content | Where-Object { $_.Type -eq 'Paragraph' }
            $paragraph.Parameters | Should -Be '-Tags'
        }

        It 'Should capture the paragraph content text' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $paragraph = $subSection.Content | Where-Object { $_.Type -eq 'Paragraph' }
            $paragraph.Content | Should -Contain 'This is a tagged paragraph'
        }
    }

    Context 'Paragraphs without tags' {
        It 'Should store plain text as string content in the parent object' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $strings = $subSection.Content | Where-Object { $_ -is [string] }
            $strings | Should -Contain 'Sub section text'
        }

        It 'Should not create a Paragraph object for untagged text' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $strings = $subSection.Content | Where-Object { $_ -is [string] }
            $strings | Should -Contain 'Plain text without paragraph tags'

            $paragraphs = $subSection.Content | Where-Object { $_.Type -eq 'Paragraph' }
            $paragraphs | Should -BeNullOrEmpty
        }
    }

    Context 'Tables' {
        It 'Should parse a markdown table as Table type' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $table = $subSection.Content | Where-Object { $_.Type -eq 'Table' }
            $table | Should -Not -BeNullOrEmpty
            $table.Type | Should -Be 'Table'
        }

        It 'Should create the correct number of rows as PSCustomObjects' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $table = $subSection.Content | Where-Object { $_.Type -eq 'Table' }
            $table.Content.Count | Should -Be 2
        }

        It 'Should map column headings to row values correctly' {
            $subSection = $result.Content[0].Content | Where-Object { $_.Type -eq 'Header' }
            $table = $subSection.Content | Where-Object { $_.Type -eq 'Table' }
            $table.Content[0].Column1 | Should -Be 'Value1'
            $table.Content[0].Column2 | Should -Be 'Value2'
            $table.Content[1].Column1 | Should -Be 'Value3'
            $table.Content[1].Column2 | Should -Be 'Value4'
        }
    }
}

Describe 'ConvertTo-MarkdownDSL' {
    Context 'Sections' {
        It 'Should generate DSL for a heading with level and title' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Header'
                            Level   = 1
                            Title   = 'Test Heading'
                            Content = @('Heading content')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Header 1 "Test Heading"'
        }

        It 'Should include string content inside the heading block' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Header'
                            Level   = 2
                            Title   = 'Sub Heading'
                            Content = @('Sub heading text')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Header 2 "Sub Heading"'
            $dsl | Should -Match 'Sub heading text'
        }
    }

    Context 'Details' {
        It 'Should generate DSL for a details block with title' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Details'
                            Title   = 'My Details'
                            Content = @('Details body')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Details "My Details"'
            $dsl | Should -Match 'Details body'
        }
    }

    Context 'Codeblocks' {
        It 'Should generate DSL for a code block with language' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type     = 'CodeBlock'
                            Language = 'powershell'
                            Content  = @('Get-Process')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'CodeBlock "powershell"'
            $dsl | Should -Match 'Get-Process'
        }

        It 'Should not wrap code block content in quotes' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type     = 'CodeBlock'
                            Language = 'powershell'
                            Content  = @('Get-ChildItem')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Not -Match '"Get-ChildItem'
        }
    }

    Context 'Paragraphs with tags' {
        It 'Should generate DSL with -Tags parameter for tagged paragraphs' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type       = 'Paragraph'
                            Parameters = '-Tags'
                            Content    = @('Tagged paragraph text')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Paragraph'
            $dsl | Should -Match '-Tags'
            $dsl | Should -Match 'Tagged paragraph text'
        }
    }

    Context 'Paragraphs without tags' {
        It 'Should generate DSL without -Tags parameter for untagged paragraphs' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Paragraph'
                            Content = @('Untagged paragraph text')
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Paragraph'
            $dsl | Should -Not -Match '-Tags'
            $dsl | Should -Match 'Untagged paragraph text'
        }
    }

    Context 'Tables' {
        It 'Should generate DSL with PSCustomObject syntax for table rows' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Table'
                            Content = @(
                                [PSCustomObject]@{ Name = 'Alice'; Age = '30' }
                                [PSCustomObject]@{ Name = 'Bob'; Age = '25' }
                            )
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match 'Table'
            $dsl | Should -Match '\[PSCustomObject\]@\{'
            $dsl | Should -Match "'Name' = 'Alice'"
            $dsl | Should -Match "'Name' = 'Bob'"
        }

        It 'Should wrap table content in an array syntax' {
            $obj = @(
                [PSCustomObject]@{
                    Level   = 0
                    Content = @(
                        [PSCustomObject]@{
                            Type    = 'Table'
                            Content = @(
                                [PSCustomObject]@{ Col = 'Val' }
                            )
                        }
                    )
                }
            )
            $dsl = ConvertTo-MarkdownDSL -InputObject $obj -AsString
            $dsl | Should -Match '@\('
            $dsl | Should -Match '\)'
        }
    }
}

Describe 'ConvertTo-MarkdownDSL Execution' {
    BeforeAll {
        $execTestFile = Join-Path $env:TEMP "PesterMarkdownExecTest_$([guid]::NewGuid().ToString()).md"
        @'
# Execution Test

Some text content

<details><summary>Test Details</summary>

Details content

</details>

```powershell
Get-Process
```

<p>

Paragraph content

</p>

| Name | Value |
| - | - |
| Key1 | Val1 |

# Another Section

Closing text
'@ | Set-Content -Path $execTestFile -NoNewline
    }

    AfterAll {
        if (Test-Path $execTestFile) {
            Remove-Item -Path $execTestFile -Force
        }
    }

    Context 'Executing generated DSL with Invoke-Command' {
        It 'Should return a scriptblock by default' {
            $parsed = ConvertFrom-MarkdownMarkdown -Path $execTestFile
            $dsl = ConvertTo-MarkdownDSL -InputObject $parsed
            $dsl | Should -BeOfType [scriptblock]
        }

        It 'Should return a string when -AsString is specified' {
            $parsed = ConvertFrom-MarkdownMarkdown -Path $execTestFile
            $dsl = ConvertTo-MarkdownDSL -InputObject $parsed -AsString
            $dsl | Should -BeOfType [string]
        }

        It 'Should execute via Invoke-Command without throwing errors' {
            $parsed = ConvertFrom-MarkdownMarkdown -Path $execTestFile
            $dsl = ConvertTo-MarkdownDSL -InputObject $parsed
            { Invoke-Command -ScriptBlock $dsl } | Should -Not -Throw
        }

        It 'Should execute without prompting for mandatory parameters' {
            $parsed = ConvertFrom-MarkdownMarkdown -Path $execTestFile
            $dsl = ConvertTo-MarkdownDSL -InputObject $parsed
            # -ErrorAction Stop ensures non-terminating errors also throw
            { Invoke-Command -ScriptBlock $dsl -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should produce non-empty output when executed' {
            $parsed = ConvertFrom-MarkdownMarkdown -Path $execTestFile
            $dsl = ConvertTo-MarkdownDSL -InputObject $parsed
            $output = Invoke-Command -ScriptBlock $dsl
            $output | Should -Not -BeNullOrEmpty
        }

        It 'Should execute a complex markdown with all element types without errors' {
            $complexFile = Join-Path $env:TEMP "PesterMarkdownComplex_$([guid]::NewGuid().ToString()).md"
            @'
# Complex Doc

Intro paragraph

## Nested Heading

Section content

<details><summary>Collapsible</summary>

Hidden content

<details><summary>Deeply Nested</summary>

Deep content

</details>

</details>

```powershell
Write-Output "test"
```

<p>

Tagged paragraph text

</p>

Untagged paragraph text

| Header1 | Header2 |
| - | - |
| Cell1 | Cell2 |
| Cell3 | Cell4 |

# Final Section

End content
'@ | Set-Content -Path $complexFile -NoNewline
            try {
                $parsed = ConvertFrom-MarkdownMarkdown -Path $complexFile
                $dsl = ConvertTo-MarkdownDSL -InputObject $parsed
                { Invoke-Command -ScriptBlock $dsl -ErrorAction Stop } | Should -Not -Throw
            }
            finally {
                if (Test-Path $complexFile) {
                    Remove-Item -Path $complexFile -Force
                }
            }
        }
    }
}

AfterAll {
    $PSStyle.OutputRendering = 'Ansi'
}
