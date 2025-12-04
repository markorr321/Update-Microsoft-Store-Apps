<#
.SYNOPSIS
    Compare Two Store Apps Version CSV Files

.DESCRIPTION
    Compares BEFORE and AFTER CSV files to show which Store Apps were updated.
    
    WORKFLOW INSTRUCTIONS:
    =======================
    # Step 1: Before Intune remediation
    .\Capture-StoreAppVersions.ps1
    
    # Step 2: Trigger Intune remediation manually, wait for completion
    
    # Step 3: After Intune remediation
    .\Capture-StoreAppVersions.ps1
    
    # Step 4: Compare the two CSV files (this script)
    .\Compare-AppVersionCSVs.ps1 -BeforeCSV "path\to\before.csv" -AfterCSV "path\to\after.csv"

.PARAMETER BeforeCSV
    Path to CSV file captured BEFORE remediation

.PARAMETER AfterCSV
    Path to CSV file captured AFTER remediation

.EXAMPLE
    .\Compare-AppVersionCSVs.ps1 -BeforeCSV "C:\Users\markh\Desktop\StoreApps-20251204-020000.csv" -AfterCSV "C:\Users\markh\Desktop\StoreApps-20251204-021500.csv"

.NOTES
    Author: First American
    Company: First American
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BeforeCSV,
    
    [Parameter(Mandatory=$true)]
    [string]$AfterCSV
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Store Apps Version Comparison" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Verify files exist
if (-not (Test-Path $BeforeCSV)) {
    Write-Host "ERROR: BEFORE file not found: $BeforeCSV" -ForegroundColor Red
    Write-Host ""
    exit 1
}

if (-not (Test-Path $AfterCSV)) {
    Write-Host "ERROR: AFTER file not found: $AfterCSV" -ForegroundColor Red
    Write-Host ""
    exit 1
}

try {
    Write-Host "Loading CSV files..." -ForegroundColor Yellow
    Write-Host "  BEFORE: $BeforeCSV" -ForegroundColor White
    Write-Host "  AFTER:  $AfterCSV" -ForegroundColor White
    Write-Host ""
    
    # Import CSVs
    $beforeApps = Import-Csv $BeforeCSV
    $afterApps = Import-Csv $AfterCSV
    
    Write-Host "  BEFORE: $($beforeApps.Count) apps" -ForegroundColor White
    Write-Host "  AFTER:  $($afterApps.Count) apps" -ForegroundColor White
    Write-Host ""
    
    # Find version changes
    Write-Host "Analyzing changes..." -ForegroundColor Yellow
    Write-Host ""
    
    $changes = @()
    foreach ($before in $beforeApps) {
        $after = $afterApps | Where-Object { $_.Name -eq $before.Name }
        if ($after -and $after.Version -ne $before.Version) {
            $changes += [PSCustomObject]@{
                AppName = $before.Name
                VersionBefore = $before.Version
                VersionAfter = $after.Version
                Status = "UPDATED"
            }
        }
    }
    
    # Find new apps
    $newApps = @()
    foreach ($after in $afterApps) {
        $before = $beforeApps | Where-Object { $_.Name -eq $after.Name }
        if (-not $before) {
            $newApps += [PSCustomObject]@{
                AppName = $after.Name
                VersionBefore = "(not installed)"
                VersionAfter = $after.Version
                Status = "NEW"
            }
        }
    }
    
    # Find removed apps
    $removedApps = @()
    foreach ($before in $beforeApps) {
        $after = $afterApps | Where-Object { $_.Name -eq $before.Name }
        if (-not $after) {
            $removedApps += [PSCustomObject]@{
                AppName = $before.Name
                VersionBefore = $before.Version
                VersionAfter = "(removed)"
                Status = "REMOVED"
            }
        }
    }
    
    # Combine all changes
    $allChanges = $changes + $newApps + $removedApps
    
    Write-Host "======================================================================" -ForegroundColor Cyan
    
    if ($allChanges.Count -gt 0) {
        Write-Host "CHANGES DETECTED" -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        if ($changes.Count -gt 0) {
            Write-Host "UPDATED APPS: $($changes.Count)" -ForegroundColor Yellow
            Write-Host ""
            $changes | Format-Table AppName, VersionBefore, VersionAfter -AutoSize
            Write-Host ""
        }
        
        if ($newApps.Count -gt 0) {
            Write-Host "NEW APPS: $($newApps.Count)" -ForegroundColor Green
            Write-Host ""
            $newApps | Format-Table AppName, VersionAfter -AutoSize
            Write-Host ""
        }
        
        if ($removedApps.Count -gt 0) {
            Write-Host "REMOVED APPS: $($removedApps.Count)" -ForegroundColor Red
            Write-Host ""
            $removedApps | Format-Table AppName, VersionBefore -AutoSize
            Write-Host ""
        }
        
        # Export comparison
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $comparisonFile = Join-Path ([Environment]::GetFolderPath("Desktop")) "Comparison-$timestamp.csv"
        $allChanges | Export-Csv -Path $comparisonFile -NoTypeInformation -Encoding UTF8
        
        Write-Host "Comparison saved to: $comparisonFile" -ForegroundColor Cyan
        
    } else {
        Write-Host "NO CHANGES DETECTED" -ForegroundColor Yellow
        Write-Host "======================================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "All apps have the same versions in both snapshots." -ForegroundColor White
    }
    
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
