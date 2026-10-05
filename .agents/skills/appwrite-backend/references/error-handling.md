# Error Handling

## Client Request Coordination

Client SDK traffic owner = one shared coordinator per endpoint/project. Foreground actions + background sync + authentication cleanup + table pulls + transaction writes + retries use that owner.

- In-flight bound = measured target behavior; recovery default = `1`; write-heavy sync default = `1..2` until measurement supports more.
- `429` → one shared cooldown for endpoint/project/auth scope → honor exposed reset/retry header OR bounded exponential backoff + jitter.
- Transport failure → pause sibling retries; per-table/datasource simultaneous wake-up = forbidden.
- `AppwriteException.code == null || code == 0` → transport candidate only when preserved cause/message matches socket + connection reset/closed + DNS + TLS + timeout; otherwise unknown.
- Operation budget = one deadline + one attempt count; nested retry multiplication = forbidden.
- Idempotent read → retry after shared cooldown. Create → persist one preallocated `ID.unique()` before attempt 1 + reuse.
- Timed-out/closed write or transaction = ambiguous outcome → read exact affected rows/state before retry → postcondition holds = success; absent = same resource ID OR fresh transaction rebuilt from current state.
- Unexpected operation → report once at owning boundary; propagation adds structured context only. Partial-sync result = application state, not a second incident.
- Required table failure → keep per-table + whole-sync checkpoints unchanged; retain failed-table list + operation ID for next bounded attempt.

Safe diagnostic allowlist = operation ID/name + read/write/transaction kind + resource type + attempt + Appwrite code/type + recovery result. Exclude user identity + payloads + secrets + session values + raw request bodies.

## Rate Limiting

Rate limits hit Client SDKs. Server SDKs w/ API keys bypass.

### Response Headers

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Max req per window |
| `X-RateLimit-Remaining` | Req left in window |
| `X-RateLimit-Reset` | Unix ts when window reset |

### 429 Response

```json
{
    "message": "Too many requests",
    "code": 429
}
```

### Exponential Backoff

Snippets below = delay calculation only. Production caller → shared coordinator. Per-datasource `withRetry` instance = forbidden.

```dart
// Dart
Future<T> withRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
        try {
            return await operation();
        } on AppwriteException catch (e) {
            if (e.code != 429 || attempt == maxRetries - 1) rethrow;

            final delay = Duration(seconds: (1 << attempt)); // 1, 2, 4 seconds
            await Future.delayed(delay);
        }
    }
    throw Exception('Max retries exceeded');
}

// Usage
final result = await withRetry(() => tablesDB.createRow(...));
```

```python
# Python
import time
from appwrite.exception import AppwriteException

def with_retry(operation, max_retries=3):
    for attempt in range(max_retries):
        try:
            return operation()
        except AppwriteException as e:
            if e.code != 429 or attempt == max_retries - 1:
                raise

            delay = 2 ** attempt  # 1, 2, 4 seconds
            time.sleep(delay)

    raise Exception('Max retries exceeded')

# Usage
result = with_retry(lambda: tables_db.create_row(...))
```

```typescript
// TypeScript
async function withRetry<T>(
    operation: () => Promise<T>,
    maxRetries = 3,
): Promise<T> {
    for (let attempt = 0; attempt < maxRetries; attempt++) {
        try {
            return await operation();
        } catch (e) {
            if (e.code !== 429 || attempt === maxRetries - 1) throw e;

            const delay = Math.pow(2, attempt) * 1000; // 1, 2, 4 seconds
            await new Promise(r => setTimeout(r, delay));
        }
    }
    throw new Error('Max retries exceeded');
}

// Usage
const result = await withRetry(() => tablesDB.createRow({...}));
```

---

## Dev Keys

Self-hosted `1.9.x` only = bypass client rate limits in development.

- `2.0.0`–`2.2.0` reject new dev keys; existing keys work until the `2.3.0` `migrate`.
- `2.3.0`+ (Cloud included) removed dev keys + `X-Appwrite-Dev-Key` + `devKey`; Flutter `27.0.0` + Web `28.0.0` removed `setDevKey`.

1. Console → Project Settings → Dev keys → Add key
2. Set it on the client SDK:

```dart
// Flutter appwrite 25.3.0, self-hosted 1.9.x only
final client = Client()
    .setEndpoint('https://<YOUR_APPWRITE_DOMAIN>/v1')
    .setProject('<PROJECT_ID>')
    .setDevKey('<DEV_KEY>');
```

**Never in prod.** Dev keys expose app to abuse.

---

## Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad request | Check req structure |
| 401 | Unauthorized | Check API key/session |
| 403 | Forbidden | Check perms |
| 404 | Not found | Verify resource exists |
| 409 | Conflict | ID collision **or** unique-index violation — see below |
| 429 | Rate limited | Backoff |
| 500 | Server error | Idempotent read → retry via [coordinator](#client-request-coordination); write → reconcile before any repeat |

### 409 `row_already_exists`

One type + message covers two causes, and the message always names the
**requested** row ID, never the row that actually conflicts.

| Cause | Named ID exists? |
|-------|------------------|
| Primary-key collision | yes |
| Unique-index violation | no — the named ID exists in no table |

Named ID absent everywhere = unique-index violation, not an impossible error.
Diagnosis:

1. List the target table's indexes through the MCP catalog ([mcp-servers.md](mcp-servers.md)) → every `unique` index.
2. Query by that index's exact column tuple → the retained conflicting row.
3. Read its owner + counter values before any retry; a fresh `ID.unique()`
   never clears a unique-index conflict.

Counter design rule →
[schema-management.md](schema-management.md#index-rules).

---

## Typed Error Handling

`AppwriteException` exposes structured fields. Log enough for debugging without
leaking secrets:

| SDK | Fields |
|-----|--------|
| Dart | `message`, `code`, `type`, `response` |
| Python | `message`, `code`, `type`, `response` |
| TypeScript | `message`, `code`, `type`, `response` |

Python fields are available as `e.message`, `e.code`, `e.type`, and
`e.response`.

- TypeScript boundary classification = numeric `code` + present `type` or `response`.
- `constructor.name === 'AppwriteException'` is forbidden; production bundling can rename the class and misroute Appwrite `4xx` errors to generic `500`.

Classify at the owning boundary → rethrow. `409` → [409 diagnosis](#409-row_already_exists) before any repeat; create → `updateRow` = forbidden. `429` → [shared coordinator](#client-request-coordination); local sleep + continue = forbidden.

```dart
// Dart
try {
    await tablesDB.createRow(
        databaseId: 'db', tableId: 'orders', rowId: orderId, data: order);
} on AppwriteException catch (e) {
    switch (e.code) {
        case 409:
            throw RowConflictError(e);
        case 429:
            throw RateLimitedError(e);
        case 404:
            throw RowNotFoundError(e.message);
        default:
            rethrow;
    }
}
```

```python
# Python
from appwrite.exception import AppwriteException

try:
    tables_db.create_row(
        database_id='db', table_id='orders', row_id=order_id, data=order)
except AppwriteException as e:
    if e.code == 409:
        raise RowConflictError(e) from e
    if e.code == 429:
        raise RateLimitedError(e) from e
    if e.code == 404:
        raise RowNotFoundError(e.message) from e
    raise
```

```typescript
// TypeScript
try {
    await tablesDB.createRow({ databaseId: 'db', tableId: 'orders', rowId: orderId, data: order });
} catch (e) {
    const err = e as Partial<AppwriteException>;
    if (typeof err.code !== 'number' || (err.type === undefined && err.response === undefined)) throw e;
    if (err.code === 409) throw new RowConflictError(e);
    if (err.code === 429) throw new RateLimitedError(e);
    if (err.code === 404) throw new RowNotFoundError(err.message);
    throw e;
}
```

---

## Timeout Handling

API timeout: 15s. Long ops may fail.

```dart
// Dart - Handle timeout
try {
    await tablesDB.listRows(...).timeout(Duration(seconds: 30));
} on TimeoutException {
    // Query too slow - add index or reduce result set
}
```

Longer client timeout ≠ burst/ambiguous-write fix. Timeout = operation contract + one overall deadline. Write timeout → source-of-truth reconciliation.

---

## Regression Proof

- Simultaneous table reads + foreground write never exceed the configured shared concurrency.
- One 429 pauses sibling requests and resumes them after one shared cooldown without a wake-up burst.
- Code-zero connection-closed and bad-file-descriptor fixtures retry as transport failures; an unknown code-zero fixture does not.
- Recovery lasting longer than one second succeeds within the overall deadline.
- A timed-out create that already committed produces no duplicate row and reuses its persisted resource ID.
- A transaction primary failure plus rollback failure retains both stacks and keeps the primary failure on top.
- One failed sync run emits one remote incident, records every failed table, and leaves its checkpoints unchanged.

---

## Related

- Rate limits → limits info
- Performance → query optimization
