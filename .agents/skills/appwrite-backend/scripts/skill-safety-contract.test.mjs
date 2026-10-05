import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import test from 'node:test';

const root = new URL('../', import.meta.url);
const text = (path) => readFile(new URL(path, root), 'utf8');

test('agent operations route exclusively through MCP while application SDK guidance remains', async () => {
  const [skill, mcp] = await Promise.all([text('SKILL.md'), text('references/mcp-servers.md')]);
  assert.match(skill, /Any agent operation against Appwrite[\s\S]*mcp-servers\.md/u);
  assert.match(skill, /MCP for agent operations; official SDKs for application code/u);
  assert.match(skill, /no direct SDK, HTTP, or command-line fallback for agent operations/u);
  assert.match(mcp, /appwrite_get_context[\s\S]*appwrite_search_tools[\s\S]*appwrite_call_tool/u);
  assert.match(mcp, /Context mismatch or unknown target = stop/u);
  assert.match(mcp, /top-level `project_id` or `organization_id`/u);
  assert.match(mcp, /flag acknowledges a write; it grants no authorization/u);
  assert.match(mcp, /read the exact resource\/transaction\/deployment state before any retry/u);
});

test('function deploys preserve every live setting or fail before mutation', async () => {
  const migration = await text('references/production-migrations.md');
  assert.match(migration, /capture the full live function model \+ prior active deployment/u);
  assert.match(migration, /pass every protected field explicitly/u);
  assert.match(
    migration,
    /`execute` \+ `events` \+ `schedule` \+ `scopes` \+ provider fields \+ build\/runtime specifications \+ deployment retention/u,
  );
  assert.match(migration, /partial snapshot, or unrepresentable setting = stop before mutation/u);
  assert.match(migration, /read back every protected field exactly/u);
  assert.match(migration, /Rollback restores the full settings snapshot before the prior deployment/u);
});

test('schema contraction binds complete destructive and access state', async () => {
  const migration = await text('references/production-migrations.md');
  assert.match(migration, /full models for every affected database \+ table, complete columns \+ indexes/u);
  assert.match(migration, /row security, permissions, constraints, and relationships/u);
  assert.match(migration, /previews do not prove completeness/u);
  assert.match(migration, /Pagination requires progress \+ stable totals \+ bounded pages\/items\/deadline/u);
  assert.match(migration, /unknown material schema\/access field[\s\S]*fail closed/u);
  assert.match(migration, /exact resource IDs \+ before\/after definitions \+ backup \+ tested recovery \+ explicit authorized scope/u);
  assert.match(migration, /Omission from a local list never authorizes deletion/u);
});

test('MCP credentials preserve least scopes and protected consumer transfer', async () => {
  const mcp = await text('references/mcp-servers.md');
  assert.match(mcp, /API-key scopes come from every real consumer call, never a full-scope default/u);
  assert.match(mcp, /Self-hosted initial key creation requires the user's Appwrite Console action/u);
  assert.match(mcp, /exact consumer variable \+ secret-store names/u);
  assert.match(mcp, /actual consumer proof with the candidate key/u);
  assert.match(mcp, /returns the new key into the transcript is not a protected transfer path/u);
  assert.match(mcp, /Metadata alone never proves consumer secret delivery/u);
  assert.match(mcp, /retire the old key only after authorized cutover \+ new-key acceptance proof/u);
  assert.match(mcp, /Secret values never enter tool arguments visible in the transcript/u);
});

test('release-matched SDK pins require call-shape migration proof', async () => {
  const [skill, selfHosting] = await Promise.all([text('SKILL.md'), text('references/self-hosting.md')]);
  assert.match(skill, /Compatible with `1\.9\.x`[^\n]*does not mean release-matched/u);
  assert.match(skill, /audit every intervening breaking change/u);
  assert.match(skill, /real SDK calls against the candidate/u);
  assert.match(selfHosting, /Python `16\.0\.0\+`[^\n]*typed Pydantic models/u);
  assert.match(selfHosting, /requirements-only upgrade leaves `result\["total"\]` \+/u);
  assert.match(selfHosting, /exact isolated dependency resolution/u);
});

test('function execution parsing drift routes to a target-proven response-format repair', async () => {
  const [skill, functionsAdvanced] = await Promise.all([text('SKILL.md'), text('references/functions-advanced.md')]);
  assert.match(skill, /Function execution SDK model or response-format parsing failure[\s\S]*functions-advanced/u);
  assert.match(functionsAdvanced, /execution may already have completed[\s\S]*reconcile the source-of-truth state/u);
  assert.match(functionsAdvanced, /exact installed SDK tag[\s\S]*default `X-Appwrite-Response-Format`[\s\S]*required model fields/u);
  assert.match(functionsAdvanced, /public `Client\.addHeader`[\s\S]*deployed Appwrite target supports/u);
  assert.match(functionsAdvanced, /Flutter `appwrite` `26\.1\.0`[\s\S]*`1\.9\.6`[\s\S]*`Execution\.resourceType`[\s\S]*before `2\.0\.0`/u);
  assert.match(functionsAdvanced, /version-bound workaround[\s\S]*`X-Appwrite-Response-Format: 2\.0\.0`/iu);
  assert.match(functionsAdvanced, /Do not start with an SDK downgrade, private SDK imports, parser-error suppression, or raw HTTP/u);
  assert.match(functionsAdvanced, /client configuration regression[\s\S]*real deployed target/u);
});

test('Dart Function references preserve an honest typed runtime boundary', async () => {
  const referenceFiles = (await readdir(new URL('references/', root))).filter((file) => file.endsWith('.md')).sort();
  const references = await Promise.all(
    referenceFiles.map(async (file) => ({
      file,
      content: await text(`references/${file}`),
    })),
  );
  const dartFunctionExamples = references.flatMap(({ file, content }) =>
    [...content.matchAll(/```dart\n([\s\S]*?)\n```/gu)]
      .map((match) => ({ file, code: match[1] }))
      .filter(({ code }) => /\bmain\s*\(|\bcontext\.res\./u.test(code)),
  );
  const functions = await text('references/functions.md');

  for (const expected of ['authentication.md', 'functions-advanced.md', 'functions.md']) {
    assert.ok(
      dartFunctionExamples.some(({ file }) => file === expected),
      `${expected} must be scanned as a Dart Function reference`,
    );
  }
  for (const { file, code } of dartFunctionExamples) {
    assert.doesNotMatch(code, /Future\s*<\s*dynamic\s*>\s+main\(\s*final\s+context\s*\)/u, file);
    assert.doesNotMatch(code, /main\(\s*dynamic\s+context\s*\)/u, file);
    assert.doesNotMatch(code, /^\s*\/\/\s*ignore(?:_for_file)?:/mu, file);
    assert.doesNotMatch(code, /\bstatusCode\s*:/u, file);
    if (/\bmain\s*\(/u.test(code)) {
      assert.match(code, /Future<Object\?> main\(Object rawContext\)/u, `${file} must accept the runtime as Object`);
    }
  }
  assert.match(functions, /private type[\s\S]*`Future<Object\?> main\(Object rawContext\)`/u);
  assert.match(functions, /operation-specific lint exception/u);
  assert.match(functions, /file-wide ignores[\s\S]*nominal interface casts[\s\S]*application-data casts through `dynamic` are invalid/u);
  assert.match(functions, /typed application data[\s\S]*typed application results/u);
  assert.match(functions, /real runtime HTTP requests:[\s\S]*response status\/body\/headers[\s\S]*error\/log secrecy/u);
});

test('numeric schema distinguishes 32-bit integer from 64-bit bigint', async () => {
  const schema = await text('references/schema-management.md');
  assert.match(schema, /`integer` \| signed 32-bit/u);
  assert.match(schema, /`bigint` \| signed 64-bit/u);
  assert.match(schema, /Number\.isSafeInteger/u);
});

test('retryable creates preallocate and reuse an SDK resource ID', async () => {
  const skill = await text('SKILL.md');
  assert.match(skill, /call `ID\.unique\(\)` before the first attempt/u);
  assert.match(skill, /persist the returned ID in the durable draft\/intent/u);
  assert.match(skill, /reuse that exact ID for every retry\/reconciliation/u);
  assert.match(skill, /identity remains in indexed columns/u);
  assert.match(skill, /never derive resource IDs/u);
});

test('client recovery is coordinated and partial sync reports once', async () => {
  const [skill, errors] = await Promise.all([text('SKILL.md'), text('references/error-handling.md')]);
  assert.match(skill, /one endpoint\/project-scoped coordinator/u);
  assert.match(skill, /never advance a sync checkpoint after partial failure/u);
  assert.match(errors, /Foreground actions \+ background sync \+ authentication cleanup/u);
  assert.match(errors, /one shared cooldown/u);
  assert.match(errors, /code == null \|\| code == 0/u);
  assert.match(errors, /read exact affected rows\/state before retry/u);
  assert.match(errors, /Partial-sync result = application state, not a second incident/u);
  assert.match(errors, /leaves its checkpoints unchanged/u);
});

test('password recovery proves the Appwrite allowlist and delivered route', async () => {
  const auth = await text('references/auth-methods.md');
  assert.match(auth, /Callback web hostname → exact target Appwrite project platform allowlist entry/u);
  assert.match(auth, /native scheme registration \+ Flutter route contract/u);
  assert.match(auth, /actual delivered link/u);
  assert.match(auth, /Successful `createRecovery` response = request acceptance only/u);
});

test('SDK routing lives in the always-loaded router', async () => {
  const skill = await text('SKILL.md');
  assert.match(skill, /`node-appwrite`/u);
  assert.match(skill, /`dart_appwrite`/u);
  assert.match(skill, /https:\/\/<REGION>\.cloud\.appwrite\.io\/v1/u);
  assert.doesNotMatch(skill, /React Native|react-native/iu);
});

test('production migration contract preserves data and exact ACL proof', async () => {
  const migration = await text('references/production-migrations.md');
  assert.match(migration, /bind → preflight → expand → backfill → verify → deploy-compatible → contract → activate → final read-back/u);
  assert.match(migration, /Missing `\$permissions`[\s\S]*never `\[\]`/u);
  assert.match(migration, /row writes do not invalidate cached lists/u);
  assert.match(migration, /rollback-by-deletion requires separate destructive proof\/approval/u);
  assert.match(migration, /secret status = one-way/iu);
});

test('transaction and recovery owners cover recurring production failures', async () => {
  const [transactions, recovery] = await Promise.all([text('references/transactions.md'), text('references/self-hosting-ops.md')]);
  assert.match(transactions, /same `transactionId`/u);
  assert.match(transactions, /schema \+ Auth \+ Storage \+ Functions/u);
  assert.match(transactions, /One bulk row call with `transactionId` = one operation/u);
  assert.match(transactions, /Multiple committed chunks are not globally atomic/u);
  assert.match(transactions, /secondary failure replaces, rethrows over, or erases the primary failure/u);
  assert.match(transactions, /`primaryError` \+ `recoveryError` \+ their stack traces/u);
  assert.match(transactions, /preserves the primary as the top-level operation failure/u);
  assert.match(recovery, /isolated Appwrite\/database clone/u);
  assert.match(recovery, /metadata\/registry \+ database \+ Storage \+ config \+ cache/u);
  assert.match(recovery, /SQL counts alone = incomplete/u);
});

test('destructive erasure is schema-closed, post-commit-proven, and retry-convergent', async () => {
  const [skill, erasure] = await Promise.all([text('SKILL.md'), text('references/destructive-erasure.md')]);
  assert.match(skill, /Permanent account\/subject-data erasure[\s\S]*destructive-erasure\.md/u);
  assert.match(erasure, /one machine-readable registry/u);
  assert.match(erasure, /new\/renamed subject-linked table\/field without one exact disposition = failure/u);
  assert.match(erasure, /field-name matching as candidate discovery only/u);
  assert.match(erasure, /preview counts deletable history as scope, never as a blocker/u);
  assert.match(erasure, /returned Rows List may be empty/u);
  assert.match(erasure, /response IDs\/counts are not affected-row proof/u);
  assert.match(erasure, /list caching disabled to fixed point/u);
  assert.match(erasure, /deterministic completed audit \+ exact postcondition/u);
  assert.match(erasure, /Retry must use a service\/admin identity/u);
  assert.match(erasure, /partial success remains visible until idempotent retry converges/u);
  assert.match(erasure, /Raw exception message \+ stack \+ function `errors` \+ response body stay server-side/u);
  assert.match(erasure, /successful `deleteRows` \+ empty Rows List → commit proceeds/u);
  assert.match(erasure, /completed audit never suppresses a proven post-commit invariant failure/u);
  assert.match(erasure, /no rollback is attempted after commit/u);
});

test('bulk owner matches current Appwrite atomicity and budgeting contracts', async () => {
  const [skill, bulk, limits] = await Promise.all([text('SKILL.md'), text('references/bulk-operations.md'), text('references/limits.md')]);
  assert.match(skill, /Preserve write intent before optimizing/u);
  assert.match(skill, /update-only work never routes through `upsertRow`\/`upsertRows`/u);
  assert.match(skill, /pre-read, existence check, or full payload/u);
  assert.match(skill, /heterogeneous per-row updates → `createOperations` with `action: update`/u);
  assert.match(bulk, /server SDK only/u);
  assert.match(bulk, /one bulk request is all-or-nothing/u);
  assert.match(bulk, /`createRows` \+ `updateRows` \+ `upsertRows` \+ `deleteRows`/u);
  assert.match(bulk, /`deleteRows` → N `deleteRow` calls changes one atomic request into N operations/u);
  assert.match(bulk, /pass its `transactionId` to every `deleteRow` \+ commit explicitly/u);
  assert.match(bulk, /one transaction operation per `deleteRow`/u);
  assert.match(bulk, /silently accepting partial deletion = forbidden/u);
  assert.match(bulk, /injected late delete failure must leave every target row unchanged/u);
  assert.match(bulk, /Domain\/adapter `update` → Appwrite `update`/u);
  assert.match(bulk, /Forbidden = `update` mapped to `upsertRow`\/`upsertRows`/u);
  assert.match(bulk, /transaction state \+ delete\/rollback\/concurrency/u);
  assert.match(bulk, /Heterogeneous per-row data\/ACL → `createOperations`/u);
  assert.match(bulk, /Each top-level update entry consumes one transaction operation/u);
  assert.match(bulk, /never weaken update into upsert/u);
  assert.match(bulk, /Empty queries = all rows/u);
  assert.match(bulk, /without relationship columns/u);
  assert.match(bulk, /One bulk call with `transactionId` \| `1`/u);
  assert.match(bulk, /chunkSize = min\(deployedBulkRowLimit, deployedQueryEqualValueLimit, idsPer4096CharQuery\)/u);
  assert.match(bulk, /transactionOps = ceil\(targetRows \/ chunkSize\) \+ otherStagedOperations/u);
  assert.match(bulk, /first page avoids cursoring after a row/u);
  assert.match(bulk, /both `Query\.equal\('\$id', chunkIds\)` \+ the original source predicate/u);
  assert.match(bulk, /Multiple bulk requests\/chunks = not one atomic unit/u);
  assert.match(bulk, /exact source-owner count `0`/u);
  assert.doesNotMatch(bulk, /partial success OK/u);
  assert.match(limits, /Self-hosted `1\.9\.0` fallback/u);
  assert.match(limits, /Target source\/config wins/u);
  assert.doesNotMatch(`${skill}\n${bulk}\n${limits}`, /\b(?:Free|Pro|Scale)\b/u);
});

test('collection writes must choose batching before implementation', async () => {
  const [skill, bulk] = await Promise.all([text('SKILL.md'), text('references/bulk-operations.md')]);
  assert.match(skill, /Batch collection writes before coding/u);
  assert.match(skill, /target count can exceed one or is data-dependent/u);
  assert.match(skill, /Compatible server bulk method exists → per-row write loop is forbidden/u);
  assert.match(skill, /Bulk is unsupported → complete operation budget/u);
  assert.match(skill, /never split one atomic invariant across committed batches/u);
  assert.match(bulk, /Before implementation = inventory every row mutation/u);
  assert.match(bulk, /Compatible server bulk method exists → use it/u);
  assert.match(bulk, /Row-loop fallback = bulk unsupported/u);
  assert.match(bulk, /Full plan exceeds the transaction cap → redesign/u);
});

test('SKILL remains a bounded router', async () => {
  const skill = await text('SKILL.md');
  assert.ok(skill.split('\n').length <= 220);
  assert.match(skill, /production-migrations\.md/u);
});

test('every reference has exactly one router row and no orphans', async () => {
  const skill = await text('SKILL.md');
  const files = (await readdir(new URL('references/', root))).sort();
  const linked = [...skill.matchAll(/\(references\/([a-z0-9-]+\.md)\)/gu)].map((m) => m[1]);
  assert.deepEqual([...new Set(linked)].sort(), files, 'SKILL.md must link every reference and only existing references');
});

test('recurring production failure contracts stay with canonical owners', async () => {
  const [migration, transactions, performance, query] = await Promise.all([
    text('references/production-migrations.md'),
    text('references/transactions.md'),
    text('references/performance.md'),
    text('references/query-optimization.md'),
  ]);
  assert.match(migration, /explicit `null`/u);
  assert.match(migration, /execution `completed` = transport proof only/u);
  assert.match(migration, /real authenticated critical route/u);
  assert.match(transactions, /count every staged operation/u);
  assert.match(performance, /Dependency-Aware Bootstrap/u);
  assert.match(query, /appwrite-query-contract\.mjs/u);
});

test('MCP wiring binds the server choice to the deployed endpoint', async () => {
  const [skill, mcp] = await Promise.all([text('SKILL.md'), text('references/mcp-servers.md')]);
  assert.match(skill, /MCP server setup[\s\S]*mcp-servers\.md/u);
  assert.match(mcp, /Server choice = deployed endpoint, never preference/u);
  assert.match(mcp, /hosted server authenticates against Appwrite Cloud only and can never reach a self-hosted instance/u);
  assert.match(mcp, /uvx mcp-server-appwrite/u);
  assert.match(mcp, /API key never appears in a committed harness config/u);
  assert.match(mcp, /Read `uvx mcp-server-appwrite --help` before adding arguments/u);
  assert.match(mcp, /\.codex\/config\.toml/u);
  assert.match(mcp, /`confirm_write=true`/u);
  assert.match(mcp, /Self-hosted API-key stdio exposes project-key-compatible operations only/u);
  assert.match(mcp, /Projects\/key management and other console administration are unavailable/u);
  assert.match(mcp, /Read any returned MCP result resource in full/u);
  assert.match(mcp, /Hosted uploads cannot read local paths/u);
  assert.match(mcp, /Never publish private source or secrets merely to obtain an upload URL/u);
});

test('Codex wiring prefers the project file over the global one', async () => {
  const mcp = await text('references/mcp-servers.md');
  assert.match(mcp, /overrides a same-named global server/u);
  assert.match(mcp, /trust_level = "trusted"/u);
  assert.match(mcp, /Untrusted repository = project file silently ignored/u);
  assert.match(mcp, /`codex mcp add` writes the global `~\/\.codex\/config\.toml` and leaks/u);
  assert.doesNotMatch(mcp, /Codex has no project config|No project-level config exists/u);
});

test('documentation lookup prefers the key-free Appwrite feed', async () => {
  const mcp = await text('references/mcp-servers.md');
  assert.match(mcp, /`appwrite_search_docs` activates only when the bundled index and `OPENAI_API_KEY` are both present/u);
  assert.match(mcp, /bound to OpenAI `text-embedding-3-small`, so no other provider substitutes/u);
  assert.match(mcp, /https:\/\/appwrite\.io\/llms-full\.txt/u);
  assert.match(mcp, /`403`; send an identifying User-Agent/u);
  assert.match(mcp, /demote `blog\/` below guides/u);
});
