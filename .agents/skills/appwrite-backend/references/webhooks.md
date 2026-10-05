# Webhooks

## Overview

Webhooks send HTTP requests to external URLs when events occur.

---

## Create Webhook

Console → Project Settings → Webhooks → Add Webhook

Or via API:

```dart
// Dart (Server SDK)
final webhook = await webhooks.create(
    webhookId: ID.unique(),
    name: 'Order Notifications',
    url: 'https://api.example.com/webhooks/appwrite',
    events: [
        'databases.*.tables.orders.rows.*',
        'users.*.create',
    ],
    tls: true,  // verify the endpoint's TLS certificate
);
```

- `webhook.secret` = signature key; returned only by `create` + `updateSecret` → store it in the secret manager immediately ([Agent Management](#agent-management)).
- Optional `secret` (8–256 chars) sets the key; omitted → generated.

---

## Event Patterns

| Pattern | Description |
|---------|-------------|
| `users.*` | All user events |
| `users.*.create` | User creation only |
| `databases.*` | All database events |
| `databases.main.tables.orders.rows.*.create` | New orders in specific table |
| `storage.*.files.*.create` | New file uploads |
| `functions.*.executions.*` | Function executions |

### Wildcard Rules

- `*` matches any single segment
- Cannot use `**` for multi-level matching
- Be specific to reduce noise

---

## Signature Verification

Every delivery is signed: `X-Appwrite-Webhook-Signature` = `base64(HMAC-SHA1(secret, webhookUrl + rawBody))`.

- `webhookUrl` = the webhook's configured `url`, byte-for-byte; not the proxied request URL.
- `rawBody` = unparsed request bytes; re-serialized JSON breaks the signature.
- Compare in constant time; mismatch → `401` before any processing.
- No timestamp/nonce header → replay protection = idempotent processing keyed by events + resource `$id` + `$updatedAt`; `$id` alone merges distinct updates to one resource. Ordering: create/update applies only when its `$updatedAt` is newer than the stored one; a `.delete` event carries the deleted resource's last `$updatedAt` → apply it at an equal or newer revision and keep a tombstone so a delayed update cannot resurrect the resource.
- Signature covers URL + body only → `X-Appwrite-Webhook-*` headers are unsigned hints. Before a destructive downstream action, confirm with Appwrite (the resource `get` returns `404`); a replayed body with an edited events header must not delete a live resource.

### Headers

| Header | Description |
|--------|-------------|
| `X-Appwrite-Webhook-Id` | Webhook ID |
| `X-Appwrite-Webhook-Events` | Comma-separated triggering events |
| `X-Appwrite-Webhook-Name` | Webhook name |
| `X-Appwrite-Webhook-User-Id` | Triggering user; empty for API key + guest events |
| `X-Appwrite-Webhook-Project-Id` | Project ID |
| `X-Appwrite-Webhook-Signature` | Base64 HMAC-SHA1 signature |

### Verify Signature

```typescript
// TypeScript - Express handler
import crypto from 'node:crypto';
import express from 'express';

const WEBHOOK_URL = 'https://api.example.com/webhooks/appwrite';

app.post('/webhooks/appwrite', express.raw({ type: 'application/json' }), (req, res) => {
    const received = Buffer.from(req.get('x-appwrite-webhook-signature') ?? '');
    const expected = Buffer.from(
        crypto
            .createHmac('sha1', process.env.APPWRITE_WEBHOOK_SECRET!)
            .update(Buffer.concat([Buffer.from(WEBHOOK_URL), req.body]))
            .digest('base64'),
    );
    if (received.length !== expected.length || !crypto.timingSafeEqual(received, expected)) {
        return res.status(401).send('Invalid signature');
    }

    const events = (req.get('x-appwrite-webhook-events') ?? '').split(',');
    const resource = JSON.parse(req.body.toString('utf8'));
    // Queue durable work keyed by events + resource.$id + resource.$updatedAt; confirm deletes with Appwrite first.
    return res.sendStatus(200);
});
```

```python
# Python - Flask handler
import base64
import hashlib
import hmac
import os

from flask import request

WEBHOOK_URL = 'https://api.example.com/webhooks/appwrite'

@app.post('/webhooks/appwrite')
def handle_webhook():
    received = request.headers.get('X-Appwrite-Webhook-Signature', '').encode()
    expected = base64.b64encode(hmac.new(
        os.environ['APPWRITE_WEBHOOK_SECRET'].encode(),
        WEBHOOK_URL.encode() + request.get_data(),
        hashlib.sha1,
    ).digest())
    if not hmac.compare_digest(received, expected):
        return 'Invalid signature', 401

    events = request.headers.get('X-Appwrite-Webhook-Events', '').split(',')
    resource = request.get_json()
    return 'OK', 200
```

---

## Webhook Payload

Body = the event's resource, same shape as its API response; no envelope. Event names → `X-Appwrite-Webhook-Events`.

```json
{
  "$id": "order_456",
  "$tableId": "orders",
  "$databaseId": "main",
  "$createdAt": "2025-01-15T10:30:00.000+00:00",
  "$updatedAt": "2025-01-15T10:30:00.000+00:00",
  "$permissions": [],
  "customer": "John Doe",
  "total": 99.99
}
```

---

## HTTP Basic Auth

Sent only when both `authUsername` + `authPassword` are set.

```dart
await webhooks.create(
    webhookId: ID.unique(),
    name: 'External API',
    url: 'https://api.example.com/webhook',
    events: ['databases.*.tables.*.rows.*'],
    tls: true,
    authUsername: 'api_user',
    authPassword: basicAuthPassword,  // from the secret manager
);
```

---

## Update Webhook

`update` replaces every setting: omitted `enabled` → `true`, `tls` → `false`, auth → empty. Read current → change the target field → pass every field. Done = `get` returns the intended settings.

```dart
final current = await webhooks.get(webhookId: 'webhook_123');
await webhooks.update(
    webhookId: current.$id,
    name: current.name,
    url: current.url,
    events: ['databases.*.tables.orders.rows.*'],
    enabled: current.enabled,
    tls: current.tls,
    authUsername: current.authUsername,
    authPassword: current.authPassword,
);
```

Secret rotation → `updateSecret`; `update` never changes the key.

---

## Disable/Enable

Same full-settings `update` with `enabled: false` / `enabled: true`.

---

## Delete Webhook

```dart
await webhooks.delete(webhookId: 'webhook_123');
```

---

## Best Practices

1. **Always verify signatures** — Prevent spoofed requests
2. **Respond quickly** — Return 2xx within 15 seconds
3. **Process async** — Queue heavy work, respond immediately
4. **Handle duplicates** — Dedupe by event + resource `$id` + `$updatedAt` ([replay protection](#signature-verification))
5. **Use specific events** — Avoid wildcard spam

---

## Retry Behavior

Per worker source ([`2.3.0`](https://github.com/appwrite/appwrite/blob/2.3.0/src/Appwrite/Platform/Workers/Webhooks.php#L123-L220)):

- One POST per event; 15 s connect + total timeout.
- Failure = transport error or HTTP `>= 400` → `attempts` +1 + `logs` updated. Success resets `attempts` to `0`.
- `attempts` ≥ `_APP_WEBHOOK_MAX_FAILED_ATTEMPTS` (default `10`) → webhook disabled + alert. Fix the endpoint → re-enable via [full-settings update](#update-webhook).
- Automatic redelivery of a failed event = undocumented → reconcile missed events from the source of truth.

Source: [webhooks docs](https://appwrite.io/docs/apis/webhooks)

---

## Webhook Logs

View in Console → Project Settings → Webhooks → Select webhook → Logs

Shows:
- Request timestamp
- Response status
- Response time
- Payload sent

---

## Agent Management

Discover webhook operations through [mcp-servers.md](mcp-servers.md). Verify
the exact endpoint/project + webhook ID before changes; absence from a local
list never authorizes deletion. Missing control-plane access = capability gap.

Keep webhook secrets out of tracked config. Store them in the deployment
environment or secret manager.

---

## Related

- [realtime.md](realtime.md) — client-side updates
- [functions-advanced.md](functions-advanced.md) — server-side event processing
- [mcp-servers.md](mcp-servers.md) — agent operations + capability boundaries
