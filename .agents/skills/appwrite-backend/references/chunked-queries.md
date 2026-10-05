# Chunked ID Queries

`Query.equal()` value cap = deployed target's ([limits.md](limits.md#query-limits)). Chunk bigger lists:

- `idChunkSize` = min(that cap, IDs whose serialized `Query.equal` fits `4096` chars) → `100` on MariaDB/PostgreSQL ([limits.md](limits.md#chunking-large-id-lists)); pass it as `chunkSize`.
- `Query.limit(chunk.length)` per chunk — default page `25` silently truncates.
- Chunks run sequentially. Client SDK → every call through the [shared coordinator](error-handling.md#client-request-coordination); unbounded `Future.wait`/`Promise.all`/`asyncio.gather` = forbidden.

## Dart

```dart
import 'package:dart_appwrite/models.dart';

Future<List<Row>> fetchByIds(
    String dbId, String tableId, List<String> ids,
    {required int chunkSize, List<String> select = const []}) async {
    final rows = <Row>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final result = await tablesDB.listRows(
            databaseId: dbId, tableId: tableId,
            queries: [
                Query.equal('\$id', chunk),
                Query.limit(chunk.length),
                if (select.isNotEmpty) Query.select(select),
            ],
            total: false,
        );
        rows.addAll(result.rows);
    }
    return rows;
}

// Usage
final patients = await fetchByIds('db', 'patients', patientIds,
    chunkSize: idChunkSize, select: ['name', 'email', 'phone']);
```

---

## Python

```python
from typing import List, Optional
from appwrite.models import Row

def fetch_by_ids(
    db_id: str, table_id: str, ids: List[str], chunk_size: int,
    select: Optional[List[str]] = None,
) -> List[Row]:
    rows: List[Row] = []
    for i in range(0, len(ids), chunk_size):
        chunk = ids[i:i + chunk_size]
        queries = [Query.equal('$id', chunk), Query.limit(len(chunk))]
        if select:
            queries.append(Query.select(select))
        result = tables_db.list_rows(
            database_id=db_id, table_id=table_id,
            queries=queries, total=False,
        )
        rows.extend(result.rows)
    return rows
```

---

## TypeScript

```typescript
async function fetchByIds<T extends Models.Row>(
    dbId: string, tableId: string, ids: string[], chunkSize: number,
    select?: string[],
): Promise<T[]> {
    const rows: T[] = [];
    for (let i = 0; i < ids.length; i += chunkSize) {
        const chunk = ids.slice(i, i + chunkSize);
        const result = await tablesDB.listRows<T>({
            databaseId: dbId, tableId: tableId,
            queries: [
                Query.equal('$id', chunk),
                Query.limit(chunk.length),
                ...(select ? [Query.select(select)] : []),
            ],
            total: false,
        });
        rows.push(...result.rows);
    }
    return rows;
}

// Usage
const patients = await fetchByIds<Patient>('db', 'patients', patientIds,
    idChunkSize, ['name', 'email', 'phone']);
```

---

## When to Use

- Fetch specific rows by known IDs
- Load related data from ID refs
- Faster than fetch-all + in-memory filter

---

## Related

- [bulk-operations.md](bulk-operations.md) — Bulk create/update/delete
- [query-optimization.md](query-optimization.md) — Query patterns
