param (
    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    [string[]]$args
)

# Determine the directory of the script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$aliasFile = Join-Path $scriptDir "save_data/aliases.txt"
$partialFile = Join-Path $scriptDir "save_data/partials.txt"

# Load Alias and Partials dictionaries
$aliases = @{}
$partials = @{}

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

# Print usage if there's nothing to process
if ($args.Count -eq 0) {
    Write-Host "Usage: papm <command or alias> [partials or args]..."
    Write-Host "Run papm_ui to open the GUI."
    exit 0
}

# Build the command
$expandedCommand = @()

# First item might be an alias
$first = $args[0]
if ($aliases.ContainsKey($first)) {
    $expandedCommand += $aliases[$first]
}
else {
    $expandedCommand += $first
}

# Rest might be partials or not
for ($i = 1; $i -lt $args.Count; $i++) {
    $word = $args[$i]
    if ($partials.ContainsKey($word)) {
        $expandedCommand += $partials[$word]
    }
    else {
        $expandedCommand += $word
    }
}

# Join the command into a string
$commandString = $expandedCommand -join ' '

# Output and run the command
Write-Host "[" -NoNewline
Write-Host -ForegroundColor Green "papm" -NoNewline
Write-Host "] " -NoNewline
Write-Host "Running: $commandString`n"
Invoke-Expression $commandString
