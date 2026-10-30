# Established PowerShell workflow for AAP 2.7

Use this reference first when setting up AAP resources. The UniFi section
below is a project-specific example, not a requirement for other repositories.
Robert has repeatedly used PowerShell successfully to configure AAP through
its REST API. Prefer this established workflow for interactive bootstrap
instead of reconstructing authentication from prior conversations.

## Connection and authentication

- Run PowerShell 7 on the administrator's workstation.
- Base URL: https://aap-01.rh.corp.ritcsusa.com
- Existing conventions: $aapBase and $aapToken.
- $aapToken is a SecureString; reuse it if already present in that session.
- If needed, acquire the token with Read-Host -AsSecureString.
- Invoke-RestMethod uses -Authentication Bearer -Token $aapToken.
- Keep normal certificate validation. Never use -SkipCertificateCheck.
- Never print the token, save it to Git, or request it in chat.

```powershell
$aapBase = 'https://aap-01.rh.corp.ritcsusa.com'
$controllerApi = "$aapBase/api/controller/v2"
# Only when no token is loaded in the current session:
$aapToken = Read-Host 'AAP API token' -AsSecureString
Invoke-RestMethod "$controllerApi/me/" -Authentication Bearer -Token $aapToken
```

Gateway root: /api/gateway/v1/
Controller root: /api/controller/v2/
Organizations are discoverable through /api/gateway/v1/organizations/.
Do not substitute the older direct-controller /api/v2/ path without checking
the live instance. Use /me/ and /ping/ to establish identity and API access.

## Discovery before writes

Query current resources and reuse exact matches. Historical IDs are not
authoritative. Start with narrow searches for the project and a working
reference template, then inspect its related resources.

Controller collections:
- projects/
- inventories/
- execution_environments/
- credential_types/
- credentials/ (metadata only)
- job_templates/
- schedules/

Search results contain count, next and results. Follow next when non-null;
do not assume page_size=200 retrieved everything. The previously used
Get-AapReadCollection helper follows pagination, checks collected counts,
detects repeated pages and rejects pagination outside the original origin.
Reuse that helper if loaded; do not assume it exists in a fresh shell.

Use GET first, OPTIONS when schema/accepted fields are uncertain, then the
supported POST/PATCH and relationship endpoints. Review exact intended
changes before writes, reuse existing resources and avoid duplicates.
Inspect the resulting resource after mutation and monitor asynchronous
project updates/job runs through their returned identifiers.

## Identity and execution conventions

- Reuse the working Linux SSH/sudo credential pattern from existing jobs
  such as the Heimdall deployment. Inspect its live configuration first.
- Do not casually add a Machine credential, invent IDs or replace existing
  credentials merely because an unrelated custom credential is present.
- Custom credentials can inject extra_vars. That does not make them the
  SSH identity and does not automatically establish identity under delegate_to.
- Kerberos tickets must exist in the actual execution context. AAP does not
  inherit the interactive workstation/builder ticket automatically.
- Use the existing maintained enterprise execution environment after
  inspecting its live name/version and available collections.
- Keep secret values out of surveys, project extra_vars, inventory and Git.
  Read credential metadata without displaying its inputs.

## UniFi reference example (infra-unifi-deploy only)

Repository: https://github.com/rathbunr/infra-unifi-deploy
Target: unifi-01.rh.corp.ritcsusa.com (10.0.20.128)

- infra-unifi-maintenance runs maintain.yml with the existing Linux
  connection credential plus a UniFi custom credential.
- UniFi custom credential injects uos_unifi_username and
  uos_unifi_password as extra_vars; username is svc_unifi.
  Mark the password input secret.
- infra-unifi-schedule runs aap/configure-maintenance.yml using the existing
  Controller API credential, separate from target-host SSH credentials.
- Schedule survey: Enabled/Disabled, weekday, hour, minute.
  Times use America/New_York. Start disabled until an AAP pilot succeeds.
- Existing bootstrap expects resource names in uos_controller_organization,
  uos_controller_project, uos_controller_inventory,
  uos_controller_ssh_credential, uos_controller_unifi_credential and
  uos_controller_api_credential.
- Confirm TCP 11443 access from the actual AAP execution node: the existing
  source-scoped host rules were initially approved for workstation
  10.0.10.51 and builder-01 10.0.20.5. Do not silently broaden them.
- CLI maintenance acceptance passed: ok=97, changed=2 (provenance directory
  and release metadata), failed=0. New UOS upgrade and changed-certificate
  paths were not exercised by that unchanged-version acceptance run.
- No live AAP resources or active weekly schedule have been confirmed yet.

This document is a reusable reference, not a deployed automation or a
guarantee of automatic cross-conversation memory. Live API output remains
authoritative for current resources and permissions.
