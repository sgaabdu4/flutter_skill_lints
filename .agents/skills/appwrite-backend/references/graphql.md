# GraphQL API

## Endpoint

```
POST /v1/graphql
```

Headers required:
- `X-Appwrite-Project: <project-id>`
- `X-Appwrite-Key: <api-key>` (server) or `X-Appwrite-JWT: <jwt>` (client)

---

## Introspection

Explore types + ops.

```graphql
query {
  __schema {
    types {
      name
      fields {
        name
        type { name }
      }
    }
  }
}
```

---

## Query Tables (TablesDB)

- Operations = `tablesDB<Method>` (`tablesDBListRows`, `tablesDBGetRow`, …); every row operation takes `databaseId` + `tableId`.
- Row fields = `_id`, `_databaseId`, `_tableId`, `_permissions`, `data`; `data` = JSON string of the columns → parse it.
- `queries` = SDK `Query.*` output strings (JSON), passed as variables.

```graphql
query ListRows($databaseId: String!, $tableId: String!, $queries: [String!]) {
  tablesDBListRows(databaseId: $databaseId, tableId: $tableId, queries: $queries) {
    total
    rows { _id _databaseId _tableId _permissions data }
  }
}

query GetRow($databaseId: String!, $tableId: String!, $rowId: String!) {
  tablesDBGetRow(databaseId: $databaseId, tableId: $tableId, rowId: $rowId) {
    _id _tableId _permissions data
  }
}
```

```json
{
  "databaseId": "main",
  "tableId": "products",
  "queries": [
    "{\"method\":\"equal\",\"attribute\":\"category\",\"values\":[\"electronics\"]}",
    "{\"method\":\"lessThan\",\"attribute\":\"price\",\"values\":[500]}"
  ]
}
```

---

## Mutations (TablesDB)

`data` variable = `Json!` object; delete returns `status`.

```graphql
mutation CreateRow($databaseId: String!, $tableId: String!, $rowId: String!, $data: Json!, $permissions: [String!]) {
  tablesDBCreateRow(databaseId: $databaseId, tableId: $tableId, rowId: $rowId, data: $data, permissions: $permissions) {
    _id data
  }
}

mutation UpdateRow($databaseId: String!, $tableId: String!, $rowId: String!, $data: Json!) {
  tablesDBUpdateRow(databaseId: $databaseId, tableId: $tableId, rowId: $rowId, data: $data) {
    _id data
  }
}

mutation DeleteRow($databaseId: String!, $tableId: String!, $rowId: String!) {
  tablesDBDeleteRow(databaseId: $databaseId, tableId: $tableId, rowId: $rowId) {
    status
  }
}
```

---

## Batching

Combine ops in one request with aliases.

```graphql
query BatchedQueries($databaseId: String!, $firstTen: [String!]) {
  products: tablesDBListRows(databaseId: $databaseId, tableId: "products", queries: $firstTen) {
    rows { _id data }
  }
  categories: tablesDBListRows(databaseId: $databaseId, tableId: "categories") {
    rows { _id data }
  }
}
```

Source: `2.3.0` [GraphQL TablesDB e2e queries](https://github.com/appwrite/appwrite/blob/2.3.0/tests/e2e/Services/GraphQL/Base.php#L1246-L1419) (same shape in `1.9.6`).

---

## File Uploads via GraphQL

Use the official Storage SDK for uploads.

---

## Rate Limits

Appwrite API limits apply.

---

## SDK Usage

Send GraphQL through the official SDK `Graphql` service. Raw Appwrite HTTP follows [SKILL.md](../SKILL.md) invariant 1.

---

## When to Use GraphQL

- Agent admin/debug work → MCP ([mcp-servers.md](mcp-servers.md)). Approval never supplies a missing MCP capability → report the gap.
- App code → GraphQL only where the official SDK lacks the endpoint.

❌ **Use SDK instead:**
- File up/download
- Bulk ops
- Transactions
- Realtime subs
- TablesDB CRUD/queries
