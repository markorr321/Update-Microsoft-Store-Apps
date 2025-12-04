# Windows Store Apps Update Remediation

Intune proactive remediation solution to automatically detect and trigger Windows Store Apps (UWP) updates on managed endpoints. Includes validation scripts for before/after comparison of app versions.

## 📋 Overview

This solution ensures Windows Store Apps remain current on Intune-managed devices by:
- **Detecting** outdated Store Apps via MDM WMI queries
- **Remediating** by triggering automatic update scans
- **Validating** changes through before/after version comparison

## 🙏 Credits

Implementation based on the excellent article by **@byteben**:  
**[Keeping Windows Store Apps Updated with Intune](https://www.oddsandendpoints.co.uk/psts/windows-updating-store-apps/)**

## 📦 Scripts Included

### Intune Proactive Remediation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `Update-Microsoft-Store-Apps-Detection.ps1` | Detection script for Intune | Checks WMI `LastScanError` to determine if updates are needed |
| `Update-Microsoft-Store-Apps-Remediation.ps1` | Remediation script for Intune | Triggers `UpdateScanMethod` via WMI to force Store Apps update scan |

### Validation Scripts (Optional)

| Script | Purpose | Usage |
|--------|---------|-------|
| `Capture-StoreAppVersions.ps1` | Captures current Store App versions | Run before/after remediation to document changes |
| `Compare-AppVersionCSVs.ps1` | Compares two version snapshots | Analyzes differences between before/after CSV files |

## 🚀 Deployment - Intune Proactive Remediation

### Step 1: Create Proactive Remediation Package

1. Navigate to **Microsoft Intune admin center** > **Devices** > **Remediations**
2. Click **Create script package**
3. Configure the package:
   - **Name**: Windows Store Apps Update
   - **Description**: Automatically detect and trigger Store Apps updates
   - **Detection script**: Upload `Update-Microsoft-Store-Apps-Detection.ps1`
   - **Remediation script**: Upload `Update-Microsoft-Store-Apps-Remediation.ps1`
   - **Run this script using logged-on credentials**: No (use System context)
   - **Enforce script signature check**: No
   - **Run script in 64-bit PowerShell**: Yes

### Step 2: Assign to Device Groups

1. Assign the remediation to target device groups
2. Configure schedule (recommended: daily)
3. Save and monitor deployment status

### Step 3: Monitor Results

- View remediation results in **Intune admin center** > **Devices** > **Remediations**
- Logs stored on endpoints: `C:\ProgramData\IntuneRemediations\StoreApps\`
- Exit codes:
  - `0` = Success (detection passed or remediation completed)
  - `1` = Remediation needed (detection only)
  - `2000` = Failure (WMI query error)

## 🔍 Manual Validation Workflow

To validate that Store Apps are actually being updated, use the capture and comparison scripts:

### Step 1: Capture BEFORE Snapshot

Run on the endpoint before triggering remediation:

```powershell
.\Capture-StoreAppVersions.ps1
```

This creates a timestamped CSV on the desktop: `StoreApps-YYYYMMDD-HHMMSS.csv`

### Step 2: Trigger Remediation

Manually trigger the Intune remediation:
- In Intune admin center, force a sync on the device
- Wait for remediation to complete (5-10 minutes)
- Allow time for Store Apps to update (15-30 minutes)

### Step 3: Capture AFTER Snapshot

Run again on the endpoint after remediation completes:

```powershell
.\Capture-StoreAppVersions.ps1
```

### Step 4: Compare Results

Compare the before/after snapshots:

```powershell
.\Compare-AppVersionCSVs.ps1 -BeforeCSV "C:\Users\YourUser\Desktop\StoreApps-20251204-020000.csv" -AfterCSV "C:\Users\YourUser\Desktop\StoreApps-20251204-023000.csv"
```

The comparison will show:
- ✅ **Updated apps** with version changes
- 🆕 **New apps** installed
- ❌ **Removed apps** uninstalled
- Results exported to: `Comparison-YYYYMMDD-HHMMSS.csv`

## 📊 How It Works

### Detection Process

1. Queries WMI namespace: `Root\cimv2\mdm\dmmap`
2. Retrieves class: `MDM_EnterpriseModernAppManagement_AppManagement01`
3. Checks `LastScanError` property:
   - `0` = Apps are current (compliant)
   - Any other value = Update scan needed (remediation required)

### Remediation Process

1. Queries same WMI namespace and class
2. Invokes method: `UpdateScanMethod`
3. Triggers Windows Store to scan for and install available app updates
4. Updates complete in background over next 15-30 minutes

## 🔧 Requirements

- Device enrolled in Microsoft Intune/MDM
- PowerShell execution policy allowing script execution
- Access to `Root\cimv2\mdm\dmmap` WMI namespace (requires MDM enrollment)
- Sufficient permissions to invoke WMI methods (System context for Intune remediation)

## 📝 Log Locations

All scripts write detailed logs for troubleshooting:

### Intune Remediation Logs
- **Location**: `C:\ProgramData\IntuneRemediations\StoreApps\`
- **Files**: 
  - `Detection-YYYYMMDD-HHMMSS.log`
  - `Remediation-YYYYMMDD-HHMMSS.log`

### Validation Script Output
- **Location**: `%USERPROFILE%\Desktop\`
- **Files**:
  - `StoreApps-YYYYMMDD-HHMMSS.csv` (version snapshots)
  - `Comparison-YYYYMMDD-HHMMSS.csv` (change analysis)

## 🎯 Use Cases

- **Proactive Maintenance**: Automatically keep Store Apps updated without user intervention
- **Compliance**: Ensure security updates are applied to UWP applications
- **Validation**: Document and verify update effectiveness during testing
- **Troubleshooting**: Compare app versions before/after to identify update failures

## 📄 License

This project is provided as-is for use in enterprise environments.

## 🤝 Contributing

Improvements and suggestions welcome. Please test thoroughly in a lab environment before production deployment.

---

**Author**: Mark Orr
**Based on**: [Keeping Windows Store Apps Updated with Intune](https://www.oddsandendpoints.co.uk/psts/windows-updating-store-apps/) by @byteben
