---
name: powershell-expert
description: PowerShell scripting best practices and style guidelines
---

# PowerShell Best Practices & Style Guide

Based on the [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/).

## Style Guide

### Capitalization
- **PascalCase** for all public identifiers: function names, parameters, variables, module names
- **lowercase** for language keywords (`foreach`, `if`, `param`)
- **lowercase** for operators (`-eq`, `-match`, `-gt`)
- **UPPERCASE** for comment-based help keywords (`.SYNOPSIS`, `.DESCRIPTION`)
- Two-letter acronyms: both caps (`$PSBoundParameters`, `Get-PSDrive`)

### Naming Conventions
- Functions: `Verb-Noun` format with approved verbs (`Get-`, `Set-`, `New-`, `Remove-`)
- Parameters: PascalCase, descriptive names
- Variables: PascalCase for public, optionally camelCase for private

### Brace Style (One True Brace Style)
```powershell
# Opening brace on same line, closing brace on own line
function Get-Something {
    [CmdletBinding()]
    param (
        [string]$Name
    )
    
    if ($Name) {
        "Hello, $Name"
    } else {
        "Hello, World"
    }
}

# Exception: short scriptblocks on one line
Get-ChildItem | Where-Object { $_.Length -gt 10mb }
```

### Function Structure
Always start with `[CmdletBinding()]` and use proper block order:
```powershell
function Verb-Noun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RequiredParam,
        
        [string]$OptionalParam = "default"
    )
    
    begin {
        # Initialization
    }
    
    process {
        # Pipeline processing
    }
    
    end {
        # Cleanup
    }
}
```

### Formatting
- **Indentation:** 4 spaces (not tabs)
- **Line length:** Max 115 characters
- **Blank lines:** 2 before functions, 1 between methods
- **No trailing whitespace**
- **No semicolons** as line terminators
- **Spaces around operators:** `$x = $y + 1` not `$x=$y+1`
- **Spaces inside braces:** `$( ... )` and `{ ... }`

### Splatting for Long Commands
```powershell
# Instead of long lines, use splatting
$params = @{
    Path        = $FilePath
    Destination = $DestPath
    Force       = $true
    Recurse     = $true
}
Copy-Item @params
```

## Error Handling

### Use -ErrorAction Stop
```powershell
try {
    Get-Item -Path $Path -ErrorAction Stop
    Remove-Item -Path $Path -ErrorAction Stop
} catch {
    Write-Error "Failed: $_"
}
```

### Set $ErrorActionPreference for Non-Cmdlets
```powershell
$ErrorActionPreference = 'Stop'
try {
    # External command or .NET call
    [System.IO.File]::ReadAllText($Path)
} catch {
    Write-Error "Failed: $_"
} finally {
    $ErrorActionPreference = 'Continue'
}
```

### Avoid Anti-Patterns
```powershell
# BAD: Using flags
$success = $false
try { Do-Thing; $success = $true } catch { }
if ($success) { Do-Next }

# GOOD: Keep transaction together
try {
    Do-Thing -ErrorAction Stop
    Do-Next -ErrorAction Stop
} catch {
    Handle-Error $_
}

# BAD: Testing $?
Do-Something
if (-not $?) { Write-Error "Failed" }

# GOOD: Use try/catch
try {
    Do-Something -ErrorAction Stop
} catch {
    Write-Error "Failed: $_"
}
```

### Copy Error to Variable
```powershell
catch {
    $errorRecord = $_  # Copy immediately
    Write-Log "Error: $($errorRecord.Exception.Message)"
    Write-Log "At: $($errorRecord.InvocationInfo.PositionMessage)"
}
```

## Security

### Always Use PSCredential
```powershell
function Connect-Service {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    
    # If you must pass plaintext (avoid if possible)
    $plainPassword = $Credential.GetNetworkCredential().Password
}
```

### Secure String Handling
```powershell
# Prompt securely
$secureString = Read-Host -Prompt "Enter secret" -AsSecureString

# Save encrypted to disk (user/machine specific)
ConvertFrom-SecureString -SecureString $secureString | 
    Out-File -Path "$env:APPDATA\secret.bin"

# Load from disk
$secureString = Get-Content -Path "$env:APPDATA\secret.bin" | 
    ConvertTo-SecureString

# Save full credential
Get-Credential | Export-Clixml -Path "$env:APPDATA\cred.xml"
$cred = Import-Clixml -Path "$env:APPDATA\cred.xml"
```

## Cross-Platform Considerations

### Path Handling
```powershell
# Use Join-Path instead of string concatenation
$fullPath = Join-Path -Path $BaseDir -ChildPath "subdir" -AdditionalChildPath "file.txt"

# Use [System.IO.Path] for cross-platform
$tempFile = [System.IO.Path]::GetTempFileName()
$separator = [System.IO.Path]::DirectorySeparatorChar
```

### Environment Variables
```powershell
# Cross-platform temp directory
$tempDir = [System.IO.Path]::GetTempPath()

# User home directory
$homeDir = $env:HOME ?? $env:USERPROFILE
```

## Output Best Practices

### Return Objects, Not Strings
```powershell
# BAD: Returning formatted strings
function Get-DiskInfo {
    "Disk C: has 50GB free"
}

# GOOD: Return objects
function Get-DiskInfo {
    [PSCustomObject]@{
        Drive     = "C:"
        FreeGB    = 50
        TotalGB   = 500
        UsedPct   = 90
    }
}
```

### Use Write-* Cmdlets Appropriately
```powershell
Write-Verbose "Processing item $i"      # -Verbose to see
Write-Debug "Variable state: $var"       # -Debug to see
Write-Information "Status update"        # Informational
Write-Warning "This might cause issues"  # Warnings
Write-Error "Something failed"           # Errors (non-terminating)
throw "Critical failure"                 # Terminating error
```

## Reference
- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [Approved Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
