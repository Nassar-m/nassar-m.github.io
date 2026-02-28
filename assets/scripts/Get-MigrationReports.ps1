# =============================================================================
# Get-MigrationReports.ps1
# Version  : 2.4
# Author   : Mustafa Nassar
# License  : MIT
# GitHub   : https://github.com/mustafa-nassar/Get-MigrationReports
# =============================================================================
#
# DISCLAIMER:
#   THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. USE AT YOUR
#   OWN RISK. THE AUTHOR IS NOT LIABLE FOR ANY DAMAGES ARISING FROM ITS USE.
#
# -----------------------------------------------------------------------------
# OVERVIEW
# -----------------------------------------------------------------------------
# When an Exchange mailbox migration fails or stalls, Microsoft Support will
# ask you to collect a long list of cmdlet outputs before they can begin
# triaging. This script automates that entire data-collection process.
#
# Give it one or more mailbox identities and it pulls every relevant diagnostic
# object, serializes each one to XML via Export-Clixml (full type fidelity,
# importable back into PowerShell), and writes a plain-text summary per mailbox
# that groups and deduplicates failure types for quick human review.
#
# -----------------------------------------------------------------------------
# WHAT GETS COLLECTED (per mailbox)
# -----------------------------------------------------------------------------
#   MoveRequest                  - The move request object
#   MoveRequestStatistics        - Statistics + full embedded failure report
#   MigrationUser                - Migration user object
#   MigrationUserStatistics      - User stats with skipped items + verbose diag
#   MigrationBatch               - Batch config with timeline/time-slot data
#   MigrationEndpoint            - Endpoint config (verbose diagnostics)
#   MigrationConfig              - Tenant-level migration service config
#   MailboxStatistics            - Mailbox stats including move history
#   Text-Summary_<mailbox>.txt   - Human-readable grouped failure summary
#   LogFile.txt                  - Timestamped execution log
#
# -----------------------------------------------------------------------------
# REQUIREMENTS
# -----------------------------------------------------------------------------
#   - Exchange Online PowerShell module  (Connect-ExchangeOnline)
#     OR Exchange On-Premises Management Shell
#   - Migration Administrator permissions (or equivalent RBAC roles)
#   - PowerShell 5.1 or PowerShell 7+
#
# -----------------------------------------------------------------------------
# CHANGELOG
# -----------------------------------------------------------------------------
#   v2.4  - Fixed: $MigrationEndpoint wrong case → filename was always empty
#         - Fixed: MailboxStatistics / MoveHistory[0] had no null guards
#         - Fixed: Export-Summary hardcoded $File = "Text-Summary.txt" in CWD
#                  instead of the per-mailbox path in the output folder
#         - Fixed: PercentComplete shown as Status (duplicated property)
#         - Fixed: Write-Host used invalid -Value parameter
#         - Fixed: No null guard on $MoveRequestStatistics in Export-Summary
#         - Added: Write-Log helper with timestamps for full audit trail
#   v2.3  - Original release by Mustafa Nassar
#
# .SYNOPSIS
#     Generates all reports needed to troubleshoot an Exchange mailbox move request.
#
# .DESCRIPTION
#     Exports MoveRequest, MoveRequestStatistics, MigrationUser,
#     MigrationUserStatistics, MigrationBatch, MigrationEndpoint,
#     MigrationConfig, and MailboxStatistics to XML files, plus a
#     plain-text failure summary per mailbox.
#
# .PARAMETER Identity
#     One or more mailbox identities (UPN or alias) to collect reports for.
#
# .PARAMETER OutputFolder
#     Destination folder for all exported files. Created automatically if it
#     does not exist. Defaults to "Get-MigrationReports" in the current directory.
#
# .EXAMPLE
#     .\Get-MigrationReports.ps1 -Identity john@contoso.com
#
# .EXAMPLE
#     .\Get-MigrationReports.ps1 -Identity user1@contoso.com, user2@contoso.com
#
# .EXAMPLE
#     .\Get-MigrationReports.ps1 -Identity john@contoso.com -OutputFolder "C:\MigrationLogs\2026-02"
# =============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = 'Specify one or more mailbox identities (UPN or alias):')]
    [string[]] $Identity,

    [string] $OutputFolder = "Get-MigrationReports"
)

# ---------------------------------------------------------------------------
# Script-level variables
# ---------------------------------------------------------------------------
$logFile = "$OutputFolder\LogFile.txt"

# ---------------------------------------------------------------------------
# Helper: write to both console and log file
# ---------------------------------------------------------------------------
function Write-Log {
    param(
        [string] $Message,
        [ValidateSet('INFO', 'ERROR', 'WARN')]
        [string] $Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $entry
    switch ($Level) {
        'ERROR' { Write-Host $entry -ForegroundColor Red }
        'WARN'  { Write-Host $entry -ForegroundColor Yellow }
        default { Write-Host $entry -ForegroundColor Cyan }
    }
}

# ---------------------------------------------------------------------------
# Export-XMLReports
# Relies on variables set in the main loop (passed via script scope):
#   $MoveRequest, $MoveRequestStatistics, $UserMigration, $UserMigrationStatistics,
#   $MigrationBatch, $MigrationEndPoint, $MailboxStatistics, $Mailbox
# ---------------------------------------------------------------------------
function Export-XMLReports {

    try {
        # --- MoveRequest ---
        if ($null -ne $MoveRequest) {
            $MoveRequest | Export-Clixml "$OutputFolder\MoveRequest_$Mailbox.xml"
            Write-Log "MoveRequest report exported."
        } else {
            Write-Log "No MoveRequest found for $Mailbox." -Level WARN
        }

        # --- MoveRequestStatistics ---
        if ($null -ne $MoveRequestStatistics) {
            $MoveRequestStatistics | Export-Clixml "$OutputFolder\MoveRequestStatistics_$Mailbox.xml"
            Write-Log "MoveRequestStatistics report exported."
        } else {
            Write-Log "No MoveRequestStatistics found for $Mailbox." -Level WARN
        }

        # --- MigrationUser ---
        if ($null -ne $UserMigration) {
            $UserMigration | Export-Clixml "$OutputFolder\MigrationUser_$Mailbox.xml"
            Write-Log "MigrationUser report exported."
        } else {
            Write-Log "No MigrationUser found for $Mailbox." -Level WARN
        }

        # --- MigrationUserStatistics ---
        if ($null -ne $UserMigrationStatistics) {
            $UserMigrationStatistics | Export-Clixml "$OutputFolder\MigrationUserStatistics_$Mailbox.xml"
            Write-Log "MigrationUserStatistics report exported."
        } else {
            Write-Log "No MigrationUserStatistics found for $Mailbox." -Level WARN
        }

        # --- MigrationBatch ---
        if ($null -ne $MigrationBatch) {
            $MigrationBatch | Export-Clixml "$OutputFolder\MigrationBatch_$Mailbox.xml"
            Write-Log "MigrationBatch report exported."
        } else {
            Write-Log "No MigrationBatch found for $Mailbox." -Level WARN
        }

        # --- MigrationEndpoint ---
        # BUG FIX: original used $MigrationEndpoint (wrong case) in the filename,
        # resolving to an empty string and producing a file named "MigrationEndpoint_.xml"
        if ($null -ne $MigrationEndPoint) {
            $endpointName = $MigrationEndPoint.Identity
            $MigrationEndPoint | Export-Clixml "$OutputFolder\MigrationEndpoint_$endpointName.xml"
            Write-Log "MigrationEndpoint report exported."
        } else {
            Write-Log "No MigrationEndpoint found for $Mailbox." -Level WARN
        }

        # --- MigrationConfig (global, one per run is fine) ---
        $migConfig = Get-MigrationConfig -ErrorAction SilentlyContinue
        if ($null -ne $migConfig) {
            $migConfig | Export-Clixml "$OutputFolder\MigrationConfig.xml"
            Write-Log "MigrationConfig report exported."
        } else {
            Write-Log "MigrationConfig could not be retrieved." -Level WARN
        }

        # --- MailboxStatistics ---
        # BUG FIX: original exported without null check; also MoveHistory[0] could be empty
        if ($null -ne $MailboxStatistics) {
            $MailboxStatistics | Export-Clixml "$OutputFolder\MailboxStatistics_$Mailbox.xml"
            Write-Log "MailboxStatistics report exported."

            if ($null -ne $MailboxStatistics.MoveHistory -and $MailboxStatistics.MoveHistory.Count -gt 0) {
                $MailboxStatistics.MoveHistory[0] | Export-Clixml "$OutputFolder\MoveHistory_$Mailbox.xml"
                Write-Log "MoveHistory report exported."
            } else {
                Write-Log "No MoveHistory entries found for $Mailbox." -Level WARN
            }
        } else {
            Write-Log "No MailboxStatistics found for $Mailbox." -Level WARN
        }

    } catch {
        Write-Log "Failed to export XML reports for $Mailbox. Error: $_" -Level ERROR
        throw
    }
}

# ---------------------------------------------------------------------------
# Export-Summary
# Writes a human-readable failure summary for the mailbox.
# BUG FIX: original hardcoded $File = "Text-Summary.txt" inside the function,
# overwriting the per-mailbox path set in the main loop. Fixed by accepting
# the output path as a parameter.
# BUG FIX: PercentComplete was shown as Status (duplicated property).
# BUG FIX: Added null guard for $MoveRequestStatistics.
# ---------------------------------------------------------------------------
function Export-Summary {
    param(
        [Parameter(Mandatory = $true)]
        [string] $SummaryFile
    )

    if ($null -eq $MoveRequestStatistics) {
        Write-Log "Skipping summary for $Mailbox - no MoveRequestStatistics available." -Level WARN
        return
    }

    try {
        $uniqueFailures  = $MoveRequestStatistics.Report.Failures | Select-Object FailureType -Unique
        $detailedFailure = foreach ($u in $uniqueFailures) {
            $MoveRequestStatistics.Report.Failures |
                Where-Object { $_.FailureType -like $u.FailureType } |
                Select-Object Timestamp, FailureType, FailureSide, Message -Last 1 |
                Format-List
        }

        $lines = @()
        $lines += "Move Request Summary: $Mailbox"
        $lines += "======================================================================="
        # BUG FIX: was showing Status twice; second should be PercentComplete
        $lines += "Status      : $($MoveRequestStatistics.Status)"
        $lines += "% Complete  : $($MoveRequestStatistics.PercentComplete)%"
        $lines += ""
        $lines += $MoveRequestStatistics.Message.ToString()
        $lines += ""
        $lines += "-----------------------------------------------------------------------"
        $lines += "Failure Summary (grouped by type):"
        $lines += ($MoveRequestStatistics.Report.Failures | Group-Object FailureType | Format-Table Count, Name | Out-String)
        $lines += "-----------------------------------------------------------------------"
        $lines += "Detailed Failures (last occurrence of each type):"
        $lines += ""
        $lines += ($detailedFailure | Out-String)

        # Write to the per-mailbox summary file
        $lines | Set-Content -Path $SummaryFile -Encoding UTF8
        Write-Log "Text summary exported to $SummaryFile."

    } catch {
        Write-Log "Failed to write summary for $Mailbox. Error: $_" -Level ERROR
        throw
    }
}

# ===========================================================================
# MAIN
# ===========================================================================

# Ensure output folder and log file exist
New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
New-Item -Path $logFile -ItemType File -Force | Out-Null

Write-Log "=== Get-MigrationReports started. Processing $($Identity.Count) mailbox(es). ==="

foreach ($Mailbox in $Identity) {

    Write-Log "--- Processing: $Mailbox ---"

    # Collect all migration objects
    $MoveRequest            = Get-MoveRequest $Mailbox -ErrorAction SilentlyContinue
    $MoveRequestStatistics  = Get-MoveRequestStatistics $Mailbox -IncludeReport -ErrorAction SilentlyContinue

    if ($null -eq $MoveRequest) {
        Write-Log "No MoveRequest found for '$Mailbox'. Check the identity and try again." -Level ERROR
    }

    $Batch                  = $MoveRequestStatistics.BatchName
    $MigrationBatch         = Get-MigrationBatch $Batch -IncludeReport `
                                  -DiagnosticInfo "showtimeslots, showtimeline, verbose" `
                                  -ErrorAction SilentlyContinue

    $UserMigration          = Get-MigrationUser $Mailbox -ErrorAction SilentlyContinue
    $UserMigrationStatistics= Get-MigrationUserStatistics $Mailbox `
                                  -IncludeSkippedItems -IncludeReport `
                                  -DiagnosticInfo "showtimeslots, showtimeline, verbose" `
                                  -ErrorAction SilentlyContinue

    $Endpoint               = $MigrationBatch.SourceEndpoint
    $MigrationEndPoint      = Get-MigrationEndpoint -Identity $Endpoint `
                                  -DiagnosticInfo Verbose `
                                  -ErrorAction SilentlyContinue

    $MailboxStatistics      = Get-MailboxStatistics $Mailbox `
                                  -IncludeMoveReport -IncludeMoveHistory `
                                  -ErrorAction SilentlyContinue

    # Per-mailbox summary file path (used by Export-Summary)
    # BUG FIX: original set $File = "Text-Summary.txt" inside Export-Summary,
    # always writing to CWD instead of the output folder.
    $SummaryFile = "$OutputFolder\Text-Summary_$Mailbox.txt"
    New-Item -Path $SummaryFile -ItemType File -Force | Out-Null

    try {
        Export-XMLReports
        Export-Summary -SummaryFile $SummaryFile
        Write-Log "All reports for '$Mailbox' exported successfully." 
        Write-Host "Reports for $Mailbox written to: $OutputFolder" -ForegroundColor Green
    } catch {
        Write-Log "One or more reports for '$Mailbox' failed to export. Error: $_" -Level ERROR
        # BUG FIX: original used Write-Host with invalid -Value parameter
        Write-Host "Export failed for $Mailbox - see $logFile for details." -ForegroundColor Red
    }
}

Write-Log "=== Get-MigrationReports completed. ==="
