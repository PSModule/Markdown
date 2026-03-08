function ConvertFrom-MarkdownMarkdown {
    <#
        .SYNOPSIS
        Converts a Markdown file into a structured object representation.

        .DESCRIPTION
        The ConvertFrom-Markdown function reads a Markdown file and processes its content to create a structured object representation. This representation includes headers, paragraphs, code blocks, tables, and details sections. The function uses regular expressions and string manipulation to identify different Markdown elements and organizes them into a hierarchical structure based on their levels.

        .PARAMETER Path
        The path to the Markdown file that needs to be converted.

        .EXAMPLE
        ConvertFrom-Markdown -Path "C:\Docs\example.md"
        This example reads the "example.md" file and converts its Markdown content into a structured object representation.

        .OUTPUTS
        Object

        .LINK
        https://psmodule.io/Markdown/Functions/Set-MarkdownCodeBlock/
    #>

    [OutputType([Object])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Path
    )

    # Get the file content
    $content = Get-Content -Path $Path -Raw

    # Create a PowerShell object to hold the content of the file
    $returnObject = [PSCustomObject]@{
        Level   = 0
        Content = @()
    }

    # Create a variable to hold the current working object in the converstion and helper variables
    $currentObject = [ref]$returnObject
    $currentLevel = 0
    $inCodeBlock = $false
    $tableHeaings = @()

    # Split the content into lines
    $lines = $content.split([System.Environment]::NewLine)

    # Process each line
    foreach ($line in $lines) {
        # Skip empty lines
        if ($line -eq '') {
            continue
        }

        # Split the line up in each word
        $words = $line.split(' ')

        # Get the first word in the line
        $word = $words[0]
        Write-Debug "[Line] Processing: $line"

        # Check if word starts with a | symbol which indicates a table row
        if ($word -like '|*') {
            # Check if this is the start of a continuation by checking the table headings
            if($tableHeaings) {
                Write-Debug "[Table] Continuation row found: $word"
                # Get all table values if the value is - ignore it
                $tableValues = $words -join ' ' -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -ne '-' }

                # If there are table values create a pscustom object with attributes for every table heading and the values as values
                if($tableValues) {
                    Write-Debug "[Table] Values found: $($tableValues -join ', ')"
                    $tableObject = [PSCustomObject]@{}
                    for ($i = 0; $i -lt $tableHeaings.Count; $i++) {
                        $heading = $tableHeaings[$i]
                        $value = if ($i -lt $tableValues.Count) { $tableValues[$i] } else { '' }
                        $tableObject | Add-Member -NotePropertyName $heading -NotePropertyValue $value
                    }
                    # Add the table object to the current object
                    $currentObject.Value.Content += $tableObject
                }
            }
            else {
                Write-Debug "[Table] Start found: $word"
                # Get all table headings
                $tableHeaings = $words -join ' ' -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

                # Add a object to the current value with the type Table and an empty array as content and go into the content of the table
                $currentObject.Value.Content += [PSCustomObject]@{
                    Type    = 'Table'
                    Parent  = $currentObject.Value
                    Content = @()
                }

                $currentObject = [ref]$currentObject.Value.Content[-1]
            }

            # Continue to the next line
            continue
        }
        else {
            # Clear the tableHeadings
            $tableHeaings = @()

            # Go back to the parent if we are in a table
            if($currentObject.Value.Type -eq 'Table') {
                Write-Debug "[Table] End reached, returning to parent"
                $currentObject = [ref]$currentObject.Value.Parent
            }
        }

        # Check with regex if the word contains any numbers of # symbols
        if ($word -match '^(#+)') {
            Write-Debug "[Header] Start found: $word"
            #Check if the level is lower than the parent level
            $level = $matches[1].Length

            Write-Debug "[Header] Level: $level, Current level: $currentLevel"

            if ($level -le $currentLevel) {
                # Loop through the return object to find the right value
                Write-Debug "[Header] Navigating to parent at appropriate level"
                while ($currentObject.Value.Level -ge $level -or $null -eq $currentObject.Value.Level) {
                    Write-Debug "[Header] Traversing to parent with level: $($currentObject.Value.Parent.Level)"
                    $currentObject = [ref]$currentObject.Value.Parent
                }
            }

            Write-Debug "[Header] Adding header to current level"
            # Add the new header and go into the value of the header
            $currentObject.Value.Content += [PSCustomObject]@{
                Type    = 'Header'
                Level   = $level
                Title   = $words[1..($words.Length - 1)] -join ' '
                Parent  = $currentObject.Value
                Content = @()
            }

            $currentObject = [ref]$currentObject.Value.Content[-1]
            $currentLevel = $level

            # Continue to the next line
            continue
        }

        # Check if the word starts with ```
        if ($word -match '^```') {
            if ($inCodeBlock) {
                Write-Debug "[CodeBlock] End found, returning to parent"
                # Go to the parent
                $currentObject = [ref]$currentObject.Value.Parent

                $inCodeBlock = $false

                # Continue to the next line
                continue
            }
            else {
                Write-Debug "[CodeBlock] Start found, language: $($word.Substring(3))"
                # Get the language of the code block
                $language = $word.Substring(3)

                # Add the new code block and go into the value of the code block
                $currentObject.Value.Content += [PSCustomObject]@{
                    Type     = 'CodeBlock'
                    Language = $language
                    Parent   = $currentObject.Value
                    Content  = @()
                }

                $currentObject = [ref]$currentObject.Value.Content[-1]
                $inCodeBlock = $true

                # Continue to the next line
                continue
            }
        }

        # Check if the word starts with <p>
        if ($word.ToLower() -match '^<p>') {
            Write-Debug "[Paragraph] Start found"

            # Add the new Paragraph and go into the value of the Paragraph
            $currentObject.Value.Content += [PSCustomObject]@{
                Type       = 'Paragraph'
                Parameters = "-Tags"
                Parent     = $currentObject.Value
                Content    = @()
            }

            $currentObject = [ref]$currentObject.Value.Content[-1]

            # Continue to the next line
            continue
        }

        # Check if the word starts with </p>
        if ($word.ToLower() -match '^</p>') {
            Write-Debug "[Paragraph] End found, returning to parent"
            # Go to the parent
            $currentObject = [ref]$currentObject.Value.Parent

            # Continue to the next line
            continue
        }

        # Check if the word starts with <details>
        if ($word.ToLower() -match '^<details>') {
            Write-Debug "[Details] Start found"

            # Add the new Details and go into the value of the Details
            $currentObject.Value.Content += [PSCustomObject]@{
                Type    = 'Details'
                Title   = $null
                Parent  = $currentObject.Value
                Content = @()
            }

            $currentObject = [ref]$currentObject.Value.Content[-1]

            # Continue to the next line if there is no summary in the word, else continue processing
            if (($words -join ' ') -notmatch '<summary') {
                continue
            }
        }

        # Check if the word starts with </details>
        if ($word.ToLower() -match '^</details>') {
            Write-Debug "[Details] End found, returning to parent"
            # Go to the parent
            $currentObject = [ref]$currentObject.Value.Parent

            # Continue to the next line
            continue
        }

        # Check if the word contains with <summary>
        if (($words -join ' ').ToLower() -match '<summary>') {
            Write-Debug "[Summary] Start found"

            #Create a temp object to store the value in summary
            $tempObject = [PSCustomObject]@{
                Content = ''
                Parent  = $currentObject.Value
            }

            $currentObject = [ref]$tempObject

            # Continue to the next line unless </summary is on this line too, then keep processing
            if (($words -join ' ') -notmatch '</summary') {
                continue
            }
        }

        # If nothing else add the line as text
        $currentObject.Value.Content += $words[0..($words.Length - 1)] -join ' '

        # Check if the word contains with </summary> if so the content should be added to the parent
        if (($words -join ' ').ToLower() -match '</summary>') {
            Write-Debug "[Summary] End found, setting title and returning to parent"
            # Set the title
            $title = $currentObject.Value.Content
            if($title.toLower() -match '<summary>') {$title = $title.Substring(($title.toLower().IndexOf('<summary>')+9))}
            if($title.toLower() -match '</summary>') {$title = $title.Substring(0,($title.toLower().IndexOf('</summary>')))}
            $currentObject.Value.Parent.Title = $title

            # Go to the parent
            $currentObject = [ref]$currentObject.Value.Parent

            # Continue to the next line
            continue
        }
    }

    # Return the created object
    $returnObject
}