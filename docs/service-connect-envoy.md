# Tuning AWS Service Connect Envoy Sidecars

AWS ECS Service Connect injects and manages Envoy proxy sidecars for every enabled task. The
sidecars are operated by AWS and cannot be modified directly (for example, you cannot supply a
custom `envoy.yaml`). Instead, tuning is limited to the configuration surface that ECS exposes in
`service_connect_configuration`.

## What you *can* tune

The following knobs are available today:

- **Per-request and idle timeouts** – Configure `timeout { per_request_timeout_seconds ... idle_timeout_seconds ... }` on
each `service { ... }` block. This is the primary lever for keeping long-lived connections, such as
Server-Sent Events, open past the 15‑second default.
- **Client aliases and DNS overrides** – Use `client_alias` blocks to control the DNS name and port
that other services use when connecting through Service Connect. You can combine this with timeout
overrides to create dedicated entries for latency-sensitive consumers.
- **Ingress port overrides** – The `ingress_port_override` field lets you tell the managed Envoy
listener which container port to forward to if it differs from the declared mapping.
- **Client policies** – `client_policy` supports TLS configuration and, in the case of gRPC, retry and
per‑method timeout policies. This is the only way to configure managed retries today.
- **Logging/observability** – You can enable Envoy access logs via the `log_configuration` block and
ship them to CloudWatch Logs for visibility into proxy behaviour.

## What you *cannot* tune

- There is **no access** to raw Envoy bootstrap configuration. You cannot change cluster circuit
breakers, connection pools, or response buffer limits.
- You cannot install additional Envoy filters, Lua scripts, or WASM modules.
- Idle keep-alive pings, HTTP/2 flow-control windows, and similar advanced knobs are not exposed. For
requirements beyond the provided options, AWS recommends migrating to **Amazon VPC Lattice** or
**AWS App Mesh**, where you can manage Envoy configuration yourself.

## Recommended approach for SSE flows

1. Set `per_request_timeout_seconds` and `idle_timeout_seconds` high enough (for example, five minutes
   or more) on the upstream Service Connect service that terminates the SSE connection.
2. Ensure upstream proxies (Caddy, ALB, API service) do not add a `Content-Length` header and flush
   data promptly.
3. Monitor the Service Connect access logs to confirm the managed Envoy proxy is not closing the
   stream early.

Beyond these steps, there is no additional tuning surface for the managed Envoy sidecars; deeper
customisation requires a self-managed Envoy deployment.
