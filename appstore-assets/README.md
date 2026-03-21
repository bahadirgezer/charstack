# App Store Asset Contracts

This folder holds source-controlled assets and review metadata used by automated App Store Connect workflows.

## Structure

- `screenshots/<locale>/<display-family>/...`
- `previews/<locale>/<display-family>/...`
- `review/review-notes.md`
- `review/submission-checklist.json`

Tracked placeholders:

- `screenshots/.gitkeep`
- `previews/.gitkeep`

The `.gitkeep` files exist only to keep empty directories in git until you add real assets.

## Display Family Examples

Use App Store Connect display family identifiers:

- `APP_IPHONE_67`
- `APP_IPHONE_65`
- `APP_IPHONE_61`
- `APP_IPHONE_55`
- `APP_IPAD_PRO_3GEN_129`

## Current Automation Scope

- Screenshot and preview upload support is gated behind `sync_assets=true` input in `appstore-submit` workflow dispatch.
- Review assets under `review/` are validated by pre-submit checks.
- In-App Event and In-App Purchase assets are intentionally out of scope for now.

## Generation Model

- This repo does not auto-generate screenshots or previews.
- You produce media manually, then place them in the expected folders.
- The workflow uploads what is present; it does not create content.

## Example Layout

```text
appstore-assets/
  screenshots/
    .gitkeep
    en-US/
      APP_IPHONE_67/
        01-home.png
        02-backlog.png
  previews/
    .gitkeep
    en-US/
      APP_IPHONE_67/
        preview.mov
  review/
    review-notes.md
    submission-checklist.json
```
