Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ========== Constants ==========
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$saveDir = Join-Path $scriptDir "save_data"
if (!(Test-Path $saveDir)) {
    New-Item -ItemType Directory -Path $saveDir | Out-Null
}

$aliasFile = Join-Path $saveDir "aliases.txt"
$partialFile = Join-Path $saveDir "partials.txt"

# ========== Font ==========
$font = New-Object System.Drawing.Font("Segoe UI", 10)

# ========== Form ==========
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell Aliases & Partials Manager"
$form.Size = New-Object System.Drawing.Size(600, 830)
$form.StartPosition = "CenterScreen"
$form.Font = $font

# ========== Alias Inputs ==========
$labelAlias = New-Object System.Windows.Forms.Label
$labelAlias.Text = "Alias:"
$labelAlias.Location = New-Object System.Drawing.Point(20, 20)
$labelAlias.AutoSize = $true
$form.Controls.Add($labelAlias)

$textAliasKey = New-Object System.Windows.Forms.TextBox
$textAliasKey.Location = New-Object System.Drawing.Point(70, 18)
$textAliasKey.Size = New-Object System.Drawing.Size(120, 25)
$textAliasKey.Font = $font
$form.Controls.Add($textAliasKey)

$textAliasValue = New-Object System.Windows.Forms.TextBox
$textAliasValue.Location = New-Object System.Drawing.Point(200, 18)
$textAliasValue.Size = New-Object System.Drawing.Size(250, 25)
$textAliasValue.Font = $font
$form.Controls.Add($textAliasValue)

$buttonAddAlias = New-Object System.Windows.Forms.Button
$buttonAddAlias.Text = "Add Alias"
$buttonAddAlias.Location = New-Object System.Drawing.Point(460, 16)
$buttonAddAlias.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($buttonAddAlias)

# ========== Partial Inputs ==========
$labelPartial = New-Object System.Windows.Forms.Label
$labelPartial.Text = "Partial:"
$labelPartial.Location = New-Object System.Drawing.Point(20, 60)
$labelPartial.AutoSize = $true
$form.Controls.Add($labelPartial)

$textPartialKey = New-Object System.Windows.Forms.TextBox
$textPartialKey.Location = New-Object System.Drawing.Point(70, 58)
$textPartialKey.Size = New-Object System.Drawing.Size(120, 25)
$textPartialKey.Font = $font
$form.Controls.Add($textPartialKey)

$textPartialValue = New-Object System.Windows.Forms.TextBox
$textPartialValue.Location = New-Object System.Drawing.Point(200, 58)
$textPartialValue.Size = New-Object System.Drawing.Size(250, 25)
$textPartialValue.Font = $font
$form.Controls.Add($textPartialValue)

$buttonAddPartial = New-Object System.Windows.Forms.Button
$buttonAddPartial.Text = "Add Partial"
$buttonAddPartial.Location = New-Object System.Drawing.Point(460, 56)
$buttonAddPartial.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($buttonAddPartial)

# ========== Alias List ==========
$labelAliasList = New-Object System.Windows.Forms.Label
$labelAliasList.Text = "Aliases:"
$labelAliasList.Location = New-Object System.Drawing.Point(20, 110)
$form.Controls.Add($labelAliasList)

$listAliases = New-Object System.Windows.Forms.ListBox
$listAliases.Location = New-Object System.Drawing.Point(20, 140)
$listAliases.Size = New-Object System.Drawing.Size(260, 300)
$listAliases.Font = $font
$form.Controls.Add($listAliases)

# Context Menu for Aliases
$contextMenuAlias = New-Object System.Windows.Forms.ContextMenu
$menuItemDeleteAlias = New-Object System.Windows.Forms.MenuItem "Delete"
$contextMenuAlias.MenuItems.Add($menuItemDeleteAlias)
$listAliases.ContextMenu = $contextMenuAlias

# ========== Partial List ==========
$labelPartialList = New-Object System.Windows.Forms.Label
$labelPartialList.Text = "Partials:"
$labelPartialList.Location = New-Object System.Drawing.Point(300, 110)
$form.Controls.Add($labelPartialList)

$listPartials = New-Object System.Windows.Forms.ListBox
$listPartials.Location = New-Object System.Drawing.Point(300, 140)
$listPartials.Size = New-Object System.Drawing.Size(260, 300)
$listPartials.Font = $font
$form.Controls.Add($listPartials)

# Context Menu for Partials
$contextMenuPartial = New-Object System.Windows.Forms.ContextMenu
$menuItemDeletePartial = New-Object System.Windows.Forms.MenuItem "Delete"
$contextMenuPartial.MenuItems.Add($menuItemDeletePartial)
$listPartials.ContextMenu = $contextMenuPartial

# ========== Description ==========
$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Location = New-Object System.Drawing.Point(20, 450)
$descriptionLabel.Size = New-Object System.Drawing.Size(560, 350)
$descriptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$descriptionLabel.Text = @"
This application lets you manage your PowerShell aliases and partials.

- An alias is a shortcut that represents the start of a command.
  Example: 'gp' / 'git pull'

- A partial is a shortcut for any part of a command, usually used after the initial command.
  Example: 'om' / 'origin master'
                 'ni'  / '--non-interactive'

You can combine aliases and partials to build full commands quickly.
For example: typing 'gp om ni' expands to:
    git pull origin master --non-interactive

You can use multiple partials in the same command to simplify repetitive tasks.

To add an alias or partial:
- Type the shortcut key (left box) and what it resolves to (right box), then click 'Add Alias/Partial'.

To delete one:
- Right-click the item in the list, then click 'Delete'.
"@
$descriptionLabel.AutoSize = $false
$descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
$form.Controls.Add($descriptionLabel)

# ========== Storage ==========
$aliases = @{}
$partials = @{}

function Load-Data {
    if (Test-Path $aliasFile) {
        $lines = Get-Content $aliasFile
        for ($i = 0; $i -lt $lines.Count; $i += 2) {
            if ($i + 1 -lt $lines.Count) {
                $aliases[$lines[$i]] = $lines[$i + 1]
            }
        }
    }

    if (Test-Path $partialFile) {
        $lines = Get-Content $partialFile
        for ($i = 0; $i -lt $lines.Count; $i += 2) {
            if ($i + 1 -lt $lines.Count) {
                $partials[$lines[$i]] = $lines[$i + 1]
            }
        }
    }

    Refresh-List
}

function Save-Data {
    if ($aliases.Count -eq 0) {
        "" | Set-Content $aliasFile
    }
    else {
        $aliases.GetEnumerator() | ForEach-Object { $_.Key; $_.Value } | Set-Content $aliasFile
    }

    if ($partials.Count -eq 0) {
        "" | Set-Content $partialFile
    }
    else {
        $partials.GetEnumerator() | ForEach-Object { $_.Key; $_.Value } | Set-Content $partialFile
    }
}

function Refresh-List {
    $listAliases.Items.Clear()
    foreach ($alias in $aliases.Keys) {
        $listAliases.Items.Add("$alias / $($aliases[$alias])")
    }

    $listPartials.Items.Clear()
    foreach ($partial in $partials.Keys) {
        $listPartials.Items.Add("$partial / $($partials[$partial])")
    }
}

# ========== Events ==========
$buttonAddAlias.Add_Click({
        $key = $textAliasKey.Text.Trim()
        $value = $textAliasValue.Text.Trim()

        if ($key -and $value) {
            $aliases[$key] = $value
            Refresh-List
            Save-Data
            $textAliasKey.Clear()
            $textAliasValue.Clear()
        }
    })

$buttonAddPartial.Add_Click({
        $key = $textPartialKey.Text.Trim()
        $value = $textPartialValue.Text.Trim()

        if ($key -and $value) {
            $partials[$key] = $value
            Refresh-List
            Save-Data
            $textPartialKey.Clear()
            $textPartialValue.Clear()
        }
    })

$menuItemDeleteAlias.Add_Click({
        if ($listAliases.SelectedItem) {
            $entry = $listAliases.SelectedItem
            $key = $entry -split ' / ', 2 | Select-Object -First 1
            if ($aliases.ContainsKey($key)) {
                $aliases.Remove($key)
                Refresh-List
                Save-Data
            }
        }
    })

$menuItemDeletePartial.Add_Click({
        if ($listPartials.SelectedItem) {
            $entry = $listPartials.SelectedItem
            $key = $entry -split ' / ', 2 | Select-Object -First 1
            if ($partials.ContainsKey($key)) {
                $partials.Remove($key)
                Refresh-List
                Save-Data
            }
        }
    })

# ========== Show Form ==========
$form.Add_Shown({ 
        Load-Data
        $form.Activate()
    })

# ========== Run ==========
$form.Topmost = $true
[void]$form.ShowDialog()
