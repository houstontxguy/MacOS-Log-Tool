# Health Scanner

The Health Scanner provides an automated "what's wrong with my Mac?" diagnostic that scans all 12 diagnostic areas and reports findings organized by severity.

## How to Use

1. Click **Health Check** in the sidebar (heart icon)
2. Set the time range (default: last 15 minutes)
3. Click **Scan**
4. Watch the progress bar as each area is checked (1/12, 2/12, ...)
5. Review the results sorted by severity

## How It Works

The scanner iterates through all 12 [diagnostic presets](diagnostic-presets.md) and for each:

1. Builds a log filter from the preset's subsystems/processes/keywords
2. Collects log entries for the configured time range
3. Runs the anomaly detector on the collected entries
4. Classifies the results into a severity level

## Severity Levels

| Severity | Criteria | Icon |
|----------|----------|------|
| **Critical** | 5+ faults, or any anomaly with severity >= 0.8 | Red octagon |
| **Warning** | 10+ errors, or 3+ anomalies | Orange triangle |
| **Info** | Any errors or anomalies present | Blue info circle |
| **OK** | No errors or anomalies | Green checkmark |

## Results Display

### Overall Status
A summary badge showing the worst severity across all areas, with a count breakdown (e.g., "1 critical, 2 warnings, 3 info, 6 ok").

### Issue List
Each area is displayed as a row showing:
- Severity icon (color-coded)
- Area icon and name (e.g., "Wi-Fi Issues")
- Issue title (e.g., "Critical issues detected")
- Error count badge (if any)
- Detailed description (error counts, anomaly counts, total entries)

Issues are sorted with the most severe at the top.

## AI Summary

If an AI provider is configured, click **Get AI Summary** to generate a holistic plain-English analysis of all findings. The AI receives the complete health check results and provides:

- Prioritized list of issues to investigate
- Possible root causes
- Recommended next steps
- Correlations between areas (e.g., network issues affecting software updates)

## Example Output

```
[CRITICAL] Kernel / System: Critical issues detected
  → 8 faults, 3 errors, 2 anomalies in 47 entries

[WARNING] Wi-Fi Issues: Issues detected
  → 15 errors, 3 anomalies in 234 entries

[INFO] Bluetooth: Minor activity
  → 2 errors, 1 anomaly in 89 entries

[OK] Time Machine: Normal
  → 12 entries, no issues

[OK] Spotlight: No recent activity
  → 0 entries, no issues
```

## Tips

- Run a health scan after experiencing issues to quickly identify the affected area
- Use a longer time range (30-60 minutes) for intermittent problems
- Click through to **Quick Diagnostics** for any area that shows warnings or critical issues to see the actual log entries
- The AI Summary is most useful when multiple areas show issues, as it can identify cross-cutting patterns
