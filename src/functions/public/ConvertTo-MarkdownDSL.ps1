function ConvertTo-MarkdownDSL {
    <#
        .SYNOPSIS
        Converts a structured object representation of Markdown content into a Markdown DSL script block.

        .DESCRIPTION
        The ConvertTo-MarkdownDSL function takes an object that represents Markdown content, including its type, level, title, language, and parameters. It processes this object recursively to generate a string that represents the Markdown content in a DSL format. The resulting string can be returned as a script block or as a plain string based on the parameters provided.

        .PARAMETER InputObject
        The structured object representing the Markdown content to be converted.

        .PARAMETER AsString
        If specified, the output will be returned as a plain string instead of a script block.

        .PARAMETER DontQuoteString
        If specified, string content will not be wrapped in quotes. This is useful for content that should be treated as raw Markdown or code.

        .EXAMPLE
        $markdownObject = @{
            Type = 'Heading'
            Level = 1
            Title = 'My Heading'
            Content = 'This is a heading'
        }
        ConvertTo-MarkdownDSL -InputObject $markdownObject -AsString

        Output:
        Heading 1 "My Heading" { "This is a heading" }
        This example converts a simple Markdown heading object into a DSL string format.

        .EXAMPLE
        $markdownObject = @{
            Type = 'CodeBlock'
            Language = 'powershell'
            Content = 'Get-Process'
        }
        ConvertTo-MarkdownDSL -InputObject $markdownObject -DontQuoteString
        Output:
        CodeBlock "powershell" { Get-Process }
        This example converts a code block object into a DSL format without quoting the content.

        .EXAMPLE
        $markdownObject = @{
            Type = 'Table'
            Content = @(
                @{ Name = 'Process1'; ID = 1234 },
                @{ Name = 'Process2'; ID = 5678 }
            )
        }
        ConvertTo-MarkdownDSL -InputObject $markdownObject
        Output:
        Table {
            [PSCustomObject]@{
                'Name' = 'Process1'; 'ID' = 1234;
            }
            [PSCustomObject]@{
                'Name' = 'Process2'; 'ID' = 5678;
            }
        }
        This example converts a table object with custom objects as content into a DSL format.
        You can execute this DSL via Invoke-Command to generate the corresponding Markdown output.

        .OUTPUTS
        string or scriptblock

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownCodeBlock/
    #>

    [OutputType([scriptblock])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Object[]] $InputObject,

        [Parameter(Mandatory = $false, Position = 1)]
        [Switch] $AsString,

        [Parameter(Mandatory = $false, Position = 2)]
        [Switch] $DontQuoteString
    )

    # First the file is converted to a string containing the syntaxt for the markdown file then it will be invoked to be converted by the other functions.
    $markDownString = ''

    # Determine what to use for a newline
    $newline = [System.Environment]::NewLine

    # Check if the level of the inputObject is 0 if so go into the content.
    if ($InputObject.Level -eq 0) {
        Write-Debug "[Root] Level is 0, descending into content"
        $InputObject = $InputObject.Content
    }


    # Loop through all childeren of the input object
    foreach ($child in $InputObject) {
        # Check if the input object is just a string
        If ($null -ne $child.Content) {
            Write-Debug "[Element] Processing type: $($child.Type), Title: $($child.Title), Level: $($child.Level)"
            # Create a string based on the input object
            $markDownString += "$($child.Type) "
            if ($child.Level) { $markDownString += "$($child.Level) " }
            if ($child.Title) { $markDownString += "`"$($child.Title)`" " }
            if ($child.Language) { $markDownString += "`"$($child.Language)`" " }
            $markDownString += "{$newline"

            # Check if DontQuoteString should be enabled
            $dqs = $DontQuoteString

            # Text inside a codeblock should be treated special
            if ($child.Type -eq "CodeBlock") {
                $dqs = $true
            }

            # If the type is a table add the start of an array to the markdown string
            if ($child.Type -eq "Table") {
                Write-Debug "[Table] Adding array start for table content"
                $markDownString += "@($newline"
            }

            # Add the content of the child to the string
            Write-Debug "[Element] Recursing into child content of type: $($child.Type)"
            $markDownString += (ConvertTo-MarkdownDSL -InputObject $child.Content -AsString -DontQuoteString:$dqs)

            # If the type is a table add the end of an array to the markdown string
            if ($child.Type -eq "Table") {
                $markDownString += ")$newline"
            }

            # Close the content of the child object
            $markDownString += "}"

            # Add extra parameters
            if ($child.Parameters) { $markDownString += " $($child.Parameters)" }

            # Add a new line
            $markDownString += "$newline"
        }
        else {
            if ($DontQuoteString) {
                # The content is special and should be kept as is
                Write-Debug "[Content] Adding raw string (DontQuoteString): $($child)"
                $markDownString += "$($child)$newline"
            }
            else {
                # Check if the child is of the type PsCustomObject if so it needs to be printed in the syntax of an array with pscustomobjects
                if ($child -is [PsCustomObject]) {
                    Write-Debug "[Table] Serializing PSCustomObject row"
                    foreach ($item in $child) {
                        $markDownString += "[PSCustomObject]@{"
                        foreach ($property in $item.PSObject.Properties) {
                            $markDownString += "'$($property.Name)' = `'$($property.Value)`'; "
                        }
                        $markDownString += "}$newline"
                    }
                    continue
                }
                else {
                    # If the content is just a string add it to the markdown string so add an extra line and quotes around it
                    Write-Debug "[Content] Adding quoted string: $($child.trim())"
                    $markDownString += "`"$($child.trim())$newline`"$newline"
                }
            }
        }
    }

    # return the right value
    if ($AsString) {
        Write-Debug "[Output] Returning as string"
        return $markDownString
    }
    else {
        Write-Debug "[Output] Returning as scriptblock"
        return [scriptblock]::Create($markDownString)
    }
}