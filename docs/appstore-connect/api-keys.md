# App Store Connect API Keys

This project uses App Store Connect API keys for CI/CD actions (TestFlight and App Store submission).

## Key Lifecycle

1. Create a key in App Store Connect: `Users and Access` -> `Integrations` -> `App Store Connect API` -> `Generate API Key`.
2. Save the `.p8` file immediately. Apple only allows one download.
3. Store key material in GitHub Actions secrets.
4. Rotate keys periodically or immediately after any suspected exposure.
5. Revoke old keys in App Store Connect once replacement is validated.

## Required GitHub Secrets and Variables by Stage

Legend:

- Stage 1 = `testflight-auto.yml` (internal TestFlight automation)
- Stage 2 = `appstore-submit.yml` (App Review submission with approval gate)

### Secrets

| Name | Stage 1 | Stage 2 | Notes |
|---|---|---|---|
| `APPSTORE_API_PRIVATE_KEY` | Required | Required | Full `.p8` contents. |
| `APPSTORE_API_KEY_ID` | Required | Required | ASC key ID. |
| `APPSTORE_API_ISSUER_ID` | Required | Required | ASC issuer ID. |
| `APPLE_DIST_CERT_P12_BASE64` | Required | Not used | Needed only for signed IPA build/upload in Stage 1. |
| `APPLE_DIST_CERT_PASSWORD` | Required | Not used | Needed only for Stage 1 certificate import. |
| `APPLE_KEYCHAIN_PASSWORD` | Required | Not used | Needed only for Stage 1 certificate import. |
| `APPSTORE_EXPORT_OPTIONS_BASE64` | Required | Not used | Needed only for Stage 1 `xcodebuild -exportArchive`. |

### Variables

| Name | Stage 1 | Stage 2 | Notes |
|---|---|---|---|
| `ASC_APP_ID` | Required | Required | App Store Connect app identifier. |
| `ASC_INTERNAL_BETA_GROUP_ID` | Required | Not used | Internal TestFlight group for auto-assignment. |
| `ASC_PRIMARY_LOCALE` | Optional | Optional | Defaults to `en-US`. |
| `ASC_BUNDLE_ID` | Optional | Not used | Defaults to `com.bgzxr.Charstack` in workflow. |
| `ASC_SUPPORT_URL` | Not used | Optional | If set, must match checklist URL during submission preflight. |
| `ASC_PRIVACY_POLICY_URL` | Not used | Optional | If set, must match checklist URL during submission preflight. |
| `APPSTORE_PROVIDER_SHORT_NAME` | Optional | Not used | Optional Transporter provider hint for Stage 1. |

Important:

- For internal TestFlight (Stage 1), `ASC_SUPPORT_URL` and `ASC_PRIVACY_POLICY_URL` are not required.
- For App Review submission (Stage 2), support/privacy URLs are required in `appstore-assets/review/submission-checklist.json` even if the two vars are unset.

## Uploading `.p8` to GitHub

### GitHub UI

1. Open repository -> `Settings` -> `Secrets and variables` -> `Actions`.
2. Choose `New repository secret`.
3. Name: `APPSTORE_API_PRIVATE_KEY`.
4. Paste the full `.p8` content, including begin/end lines.
5. Save.

### GitHub CLI

```bash
gh secret set APPSTORE_API_PRIVATE_KEY < /absolute/path/to/AuthKey_XXXXXXX.p8
```

Add IDs as separate secrets:

```bash
gh secret set APPSTORE_API_KEY_ID --body "<KEY_ID>"
gh secret set APPSTORE_API_ISSUER_ID --body "<ISSUER_ID>"
```

## Revoking Keys

Use App Store Connect `Users and Access` -> `Integrations` -> `App Store Connect API` to revoke compromised or obsolete keys.

Recommended sequence:

1. Create new key.
2. Update GitHub secrets.
3. Validate a TestFlight upload.
4. Revoke old key.

## Security Rules

- Never commit `.p8` files.
- Never print key contents or JWTs in CI logs.
- If key material leaks, revoke and replace immediately.
