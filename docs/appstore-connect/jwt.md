# App Store Connect JWT

`scripts/appstore/jwt.sh` generates a short-lived JWT for App Store Connect API calls.

## Header

```json
{
  "alg": "ES256",
  "kid": "<APPSTORE_API_KEY_ID>",
  "typ": "JWT"
}
```

## Claims

```json
{
  "iss": "<APPSTORE_API_ISSUER_ID>",
  "iat": <unix_timestamp>,
  "exp": <unix_timestamp_plus_short_ttl>,
  "aud": "appstoreconnect-v1"
}
```

## Constraints

- Algorithm must be `ES256`.
- `aud` must be `appstoreconnect-v1`.
- Token lifetime must be short; this project defaults to 10 minutes (`JWT_TTL_SECONDS=600`).
- Do not cache tokens across long-running jobs.

## Environment Variables

- `APPSTORE_API_PRIVATE_KEY`: private key content.
- `APPSTORE_API_PRIVATE_KEY_FILE`: optional path alternative to private key content.
- `APPSTORE_API_KEY_ID`: key ID.
- `APPSTORE_API_ISSUER_ID`: issuer ID.
- `JWT_TTL_SECONDS`: optional TTL override, max 1200.

## Rotation Guidance

- Rotate keys on a regular cadence (for example every 90 days).
- Rotate immediately on suspected exposure.
- Validate with a manual `workflow_dispatch` run before deleting previous key.

## Clock Skew Guidance

- CI runner time must be accurate (NTP-synced).
- If you get authentication failures around `iat`/`exp`, check system clock drift first.

## Troubleshooting

- `401 NOT_AUTHORIZED`: check key ID, issuer ID, and key pair.
- `INVALID_AUTHENTICATION_CREDENTIALS`: verify `aud=appstoreconnect-v1` and token expiry.
- `INVALID_SIGNATURE`: verify exact `.p8` content and no whitespace corruption in secret.
