# Notifications API

- **Status:** Draft v0.1
- **Base contract:** [API Design](README.md)
- **Domain owner:** Notifications

This domain owns notification intents, the user inbox, delivery preferences and provider delivery evidence. Domain services request notifications through events; they do not call email, push or WhatsApp providers directly.

## Representations

```ts
type Notification = {
  notificationId: string;
  recipientUid: string;
  categoryCode: string;
  title: string;
  body: string;
  action?: { type: string; resourceId: string };
  createdAt: string;
  readAt?: string;
  archivedAt?: string;
  version: string;
};

type NotificationPreferences = {
  recipientUid: string;
  locale: string;
  timezone: string;
  categoryChannels: Record<string, Array<'in_app' | 'email' | 'push' | 'whatsapp'>>;
  quietHours?: { start: string; end: string };
  version: string;
};
```

`body` must be safe for the authenticated inbox. Push and lock-screen payloads use a stricter safe summary and never include tax identifiers, balances, document contents or sensitive deadlines.

## Endpoint summary

| Method | Path | Access | Concurrency |
|---|---|---|---|
| `GET` | `/v1/practices/{practiceId}/notifications` | Own inbox | — |
| `POST` | `/v1/practices/{practiceId}/notifications/{notificationId}:mark-read` | Own inbox | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/notifications:mark-all-read` | Own inbox | Idempotency key |
| `POST` | `/v1/practices/{practiceId}/notifications/{notificationId}:archive` | Own inbox | Idempotency key |
| `GET` | `/v1/practices/{practiceId}/notification-preferences` | Own preferences | — |
| `PATCH` | `/v1/practices/{practiceId}/notification-preferences` | Own preferences | `If-Match` required |
| `POST` | `/v1/inbound-email/{routingKey}` | Verified email-provider ingress | Provider idempotency |

Inbox and preference endpoints are regional. Inbound email arrives through a public edge that derives the region and practice from the opaque routing key.

## Inbox

Supported filters: `unread`, `categoryCode`, `createdAfter`, `archived`. Sort is fixed to `-createdAt`.

Portal users receive only notifications for taxpayers they can currently access. Revoking a grant removes future access to the target even if an old notification remains; opening the notification never bypasses current authorisation.

Mark-read request has an empty body. The command sets `readAt` once and returns the updated notification. Mark-all-read accepts an optional safe boundary:

```json
{
  "createdBefore": "2026-08-19T15:00:00Z"
}
```

Archiving affects only the recipient's inbox representation, not delivery or audit records.

**Events:** `notification.read.v1`, `notification.archived.v1`.

**Errors:** `404 resource_not_found`.

## Preferences

Update request:

```json
{
  "locale": "en-ZA",
  "timezone": "Africa/Johannesburg",
  "categoryChannels": {
    "document_request": ["in_app", "email"],
    "deadline_reminder": ["in_app", "email", "push"]
  },
  "quietHours": {
    "start": "20:00",
    "end": "07:00"
  }
}
```

Mandatory legal, security and service messages cannot be disabled; the response identifies locked categories. WhatsApp may be selected only after channel-specific consent and address verification. Locale affects rendering, not tax rules or deadlines.

**Events:** `notification_preferences.changed.v1`.

**Errors:** `422 mandatory_channel_required`, `422 channel_not_verified`, `422 locale_not_supported`, `422 quiet_hours_invalid`.

## Inbound email

`POST /v1/inbound-email/{routingKey}` accepts the configured provider's signed webhook format, not Molo's normal JSON envelope. The edge must:

1. verify provider signature and replay timestamp before parsing attachments;
2. resolve the opaque routing key to region, practice and allowed request context;
3. record the provider event ID idempotently;
4. store raw MIME and attachments in the correct regional quarantine path;
5. acknowledge quickly with `202 Accepted`;
6. process attachments through the normal document-upload pipeline.

The endpoint ignores caller-supplied practice, taxpayer, request and region identifiers. Unmatched or ambiguous mail is quarantined for authorised review and never attached automatically.

A valid replay returns the original `202 Accepted` outcome without creating another document or notification effect.

**Errors:** `401 webhook_signature_invalid`, `404 routing_key_unknown`, `413 message_too_large`.

## Internal delivery contract

Workers consume notification intents containing recipient ID, category, template version, locale, timezone, safe parameters and correlation ID. Delivery records contain provider message reference and status but not rendered document content. Provider callbacks update delivery evidence idempotently.

## Contract tests

1. Notification deep links always re-check current resource access.
2. A preference replay does not create multiple side effects.
3. Locale changes alter wording/formatting but not the underlying deadline.
4. A forged inbound-email practice ID is ignored.
5. Push payload snapshots contain no configured sensitive-field fixtures.
