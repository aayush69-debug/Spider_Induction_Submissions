# DevOps Audit Report: Vault Sweep
**Author:** Aayush

## 1. Threat Detection Patterns
The following configurations were flagged as dangerous during execution:
* **`rm -rf /`:** Malicious command capable of wiping the root filesystem directory.
* **`o+w` / 777 Permissions:** Grants write access to any unprivileged entity on the host system, allowing arbitrary local code injection.
* **Hardcoded Tokens:** Plaintext strings containing high-entropy keys exposed directly inside source files (`.js`, `.py`), susceptible to exposure via source control leaks.

## 2. Environment Variable Validation Rule Breakdown
* **Spaces around Assignment (`KEY = value`):** Dropped because standard bash parses spaces as individual command invocations rather than clean variables.
* **Hyphenated Keys (`SERVER-NAME`):** Dropped because POSIX standards restrict environmental keys strictly to alphanumeric characters and underscores.
* **Plaintext Secrets (`PASSWORD`):** Restricted keywords were dropped completely to ensure sensitive tokens are injected via proper secret vaults rather than bare tracking files.

## 3. Background Automation & Alerting (Bonus Implementation)
* **Continuous Monitoring (`watchdog.sh`):** Built a standalone automation wrapper that handles hands-free execution over targeted repository endpoints.
* **Proactive Notification Architecture:** Leveraged macOS native `osascript` AppleScript bindings to bridge backend shell telemetry logs directly into front-end system UI alert banners.
* **Cron Daemon Scheduling:** Engineered a background cron expression (`*/30 * * * *`) ensuring system state drift is audited and mitigated automatically every 30 minutes without requiring manual administrator initialization.