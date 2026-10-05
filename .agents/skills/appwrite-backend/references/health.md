# Health

Health checks self-hosted Appwrite.

---

## Agent Diagnosis

Agent health reads → [mcp-servers.md](mcp-servers.md) catalog search. No health operation (current catalog has no Health service) = capability gap; report it.

---

## Application Code

| SDK | `Health` service |
|-----|------------------|
| `dart_appwrite` | through `25.1.0`; removed in `26.0.0` |
| `node-appwrite` | through `26.2.0`; removed in `27.0.0` |
| Python `appwrite` | through `21.0.0`; removed in `22.0.0` |

Release-matched `1.9.6` + `2.x` pins ([self-hosting.md](self-hosting.md)) lack `Health` → missing SDK endpoint under [SKILL.md](../SKILL.md) invariant 1; never downgrade a pin to regain it.

| Check | Route | Scope |
|-------|-------|-------|
| Liveness | `GET /v1/health/version` | public |
| Overall | `GET /v1/health` | `health.read` |
| Database, cache, pub/sub | `GET /v1/health/db`, `/cache`, `/pubsub` | `health.read` |
| Storage | `GET /v1/health/storage`, `/storage/local` | `health.read` |
| Antivirus | `GET /v1/health/anti-virus` | `health.read` |
| Certificate | `GET /v1/health/certificate?domain=<DOMAIN>` | `health.read` |
| Time | `GET /v1/health/time` | `health.read` |
| Failed jobs | `GET /v1/health/queue/failed/:name` | `health.read` |
| Queue depth | `GET /v1/health/queue/<queue>` — `1.9.x` only; removed in `2.x` | `health.read` |

Time diff >30s break auth.

---

## Public Cloud Note

Cloud managed internally — endpoints self-hosted only.

---

## Monitoring Integration

Health check uses:

- **Uptime monitors:** Pingdom, UptimeRobot
- **Kubernetes probes:** Liveness/readiness
- **Alerting:** PagerDuty, Slack notifications
- **Dashboards:** Grafana, Datadog

---

## Scaled Deployments

Scaling topology, container types, and tuning variables are owned by
[self-hosting.md](self-hosting.md). Health-check consequences of scaling:

- Probe each container instance, not only the load-balancer VIP — a single
  healthy node masks failed replicas behind round-robin.
- Route unauthenticated load-balancer health checks at `/v1/health/version`
  so bad nodes drain automatically.
- Queue depth is cluster-wide; rising depth with healthy nodes = worker
  starvation, not a node failure.

---

## Related

- [self-hosting.md](self-hosting.md) — scaling, tuning, security
- [self-hosting-ops.md](self-hosting-ops.md) — backup, restore, upgrade
- [functions-advanced.md](functions-advanced.md) — scheduled health automation
- [webhooks.md](webhooks.md) — alerting
- [performance.md](performance.md) — Redis caching patterns
