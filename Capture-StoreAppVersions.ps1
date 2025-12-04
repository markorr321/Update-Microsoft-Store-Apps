<#
.SYNOPSIS
    Capture Store Apps Versions to CSV

.DESCRIPTION
    Captures current Store App versions and exports to CSV with timestamp.
    
    WORKFLOW INSTRUCTIONS:
    =======================
    # Step 1: Before Intune remediation
    .\Capture-StoreAppVersions.ps1
    
    # Step 2: Trigger Intune remediation manually, wait for completion
    
    # Step 3: After Intune remediation
    .\Capture-StoreAppVersions.ps1
    
    # Step 4: Compare the two CSV files
    .\Compare-AppVersionCSVs.ps1 -BeforeCSV "path\to\before.csv" -AfterCSV "path\to\after.csv"

.PARAMETER OutputPath
    Optional custom path for CSV file. If not specified, saves to Desktop with timestamp.

.EXAMPLE
    .\Capture-StoreAppVersions.ps1
    Saves to Desktop: StoreApps-[timestamp].csv
    
.EXAMPLE
    .\Capture-StoreAppVersions.ps1 -OutputPath "C:\Temp\before.csv"
    Saves to specified location

.NOTES
    Author: First American
    Company: First American
#>

param(
    [string]$OutputPath
)

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Store Apps Version Capture" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Determine output file path
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "StoreApps-$timestamp.csv"
    }
    
    Write-Host "Capturing Store App versions..." -ForegroundColor Yellow
    
    # Get all AppX packages for all users
    $apps = Get-AppxPackage -AllUsers | Select-Object Name, Version, Architecture, Publisher, InstallLocation, PackageFullName | Sort-Object Name
    
    Write-Host "Found $($apps.Count) Store Apps" -ForegroundColor Green
    Write-Host ""
    
    # Export to CSV
    $apps | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "SUCCESS" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "Results saved to:" -ForegroundColor White
    Write-Host "$OutputPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Apps: $($apps.Count)" -ForegroundColor White
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Show sample of captured apps
    Write-Host "Sample of captured apps:" -ForegroundColor Yellow
    $apps | Select-Object Name, Version -First 10 | Format-Table -AutoSize
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
