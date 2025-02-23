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
            $content = Set-MarkdownCodeBlock -Language 'powershell' -Content {
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
            $content = Set-MarkdownCodeBlock -Language 'powershell' -Content {
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

                        CodeBlock 'powershell' {
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

                CodeBlock 'powershell' {
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
