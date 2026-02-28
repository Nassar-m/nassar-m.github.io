---
layout: post
title: "Get-MigrationReports: Automated Exchange Migration Diagnostics"
date: 2022-09-22
categories: [Automation]
tags: [exchange, migration, powershell, diagnostic, automation]
excerpt: "When a mailbox migration fails, Microsoft Support will ask you to manually collect a long list of cmdlet outputs before triaging begins. This script automates the entire process — one run per mailbox, full XML exports, and a grouped failure summary."
---

When an Exchange mailbox migration fails or stalls, Microsoft Support will typically ask you to manually collect a long list of cmdlet outputs before they can begin triaging. This script automates that entire process.

Give it one or more mailbox identities and it pulls every relevant diagnostic object, serializes each to XML with full type fidelity, and writes a plain-text failure summary per mailbox that groups and deduplicates error types for quick human review.

**[View on GitHub](https://github.com/Nassar-m/PowerShell-Scripts/blob/main/Get-MigrationReports.ps1)** &nbsp;·&nbsp; **[Download raw](https://raw.githubusercontent.com/Nassar-m/PowerShell-Scripts/main/Get-MigrationReports.ps1)**

---

## Requirements

- **Exchange Online PowerShell** (`Connect-ExchangeOnline`) or Exchange On-Premises Management Shell
- **Migration Administrator** permissions (or equivalent RBAC roles)
- PowerShell 5.1 or PowerShell 7+

---

## Usage

**Single mailbox:**
```powershell
.\Get-MigrationReports.ps1 -Identity john@contoso.com
```

**Multiple mailboxes:**
```powershell
.\Get-MigrationReports.ps1 -Identity user1@contoso.com, user2@contoso.com, user3@contoso.com
```

**Custom output folder:**
```powershell
.\Get-MigrationReports.ps1 -Identity john@contoso.com -OutputFolder "C:\MigrationLogs\2026-02"
```

The output folder is created automatically if it does not exist. Each run appends to the same `LogFile.txt` so you have a complete audit trail across multiple executions.

---

## What Gets Collected

For each mailbox the script exports the following files into the output folder:

| File | Contents |
|---|---|
| `MoveRequest_<mailbox>.xml` | Full move request object |
| `MoveRequestStatistics_<mailbox>.xml` | Statistics with embedded failure report |
| `MigrationUser_<mailbox>.xml` | Migration user object |
| `MigrationUserStatistics_<mailbox>.xml` | User statistics with skipped items |
| `MigrationBatch_<mailbox>.xml` | Batch configuration and timeline |
| `MigrationEndpoint_<name>.xml` | Endpoint configuration (verbose) |
| `MigrationConfig.xml` | Tenant-level migration service config |
| `MailboxStatistics_<mailbox>.xml` | Mailbox stats with move report |
| `MoveHistory_<mailbox>.xml` | Most recent move history entry |
| `Text-Summary_<mailbox>.txt` | Human-readable grouped failure summary |
| `LogFile.txt` | Timestamped execution log |

All object data is exported via `Export-Clixml`, preserving the full type structure rather than flattened text. This means you or Microsoft Support can `Import-Clixml` the files later and work with the objects natively in PowerShell — including drilling into nested properties like `Report.Failures`.

---

## Reading the Output

The text summary is the fastest starting point. Open `Text-Summary_<mailbox>.txt` to see the move status, overall message, and a grouped count of each failure type. This tells you at a glance whether you are dealing with a transient network issue (many `TooManyObjectsOpenedFailure` entries), a permissions problem, a corrupt item count threshold breach, and so on.

For deeper analysis, import the XML files back into PowerShell:

```powershell
$stats = Import-Clixml .\MoveRequestStatistics_john@contoso.com.xml

# Group failures by type, most frequent first
$stats.Report.Failures | Group-Object FailureType | Sort-Object Count -Descending

# Read the full message of a specific failure type
$stats.Report.Failures |
    Where-Object { $_.FailureType -eq 'TooManyObjectsOpenedFailure' } |
    Select-Object -Last 1 |
    Format-List Timestamp, FailureSide, Message
```


---

## License

MIT — use at your own risk. No warranties are given.

Original script by **Mustafa Nassar** · [PowerShell-Scripts on GitHub](https://github.com/Nassar-m/PowerShell-Scripts/blob/main/Get-MigrationReports.ps1)
