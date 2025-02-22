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
    It 'Can write a markdown doc' {

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
            }
            Table {
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
        }

        $expected = @"
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

| Name | Age |
| - | - |
| John Doe | 30 |
| Jane Doe | 25 |

"@
        $content | Should -Be $expected
    }
}
