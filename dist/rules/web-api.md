# Web API Standards

**Applies when** the application exposes an HTTP or Web API consumed by external callers, browser/desktop/mobile clients, or other services. Does not apply to applications that only make outbound network requests without serving inbound HTTP endpoints (`remote-calls.md`, when present), or to standalone CLI or desktop applications exposing no HTTP API.

Defines stack-agnostic ideals for consistent error responses and HTTP status codes,
paginated collections, backward-compatible API evolution, request size and rate bounds,
and encrypted header/body credential transport. Input validation and output escaping live
in `standard.md`; secret management and authorization live in `security.md` when present.

## Uniform Error Format and Status Codes

- **Consistent error payload across every endpoint**: return all error responses in one consistent machine-readable structure across the API (e.g., RFC 9457 Problem Details) without leaking internal exceptions, stack traces, or host details (`standard.md` Failure Handling and Reporting).
- **Use HTTP status codes per protocol semantics**: return status codes matching the outcome class (e.g., `2xx` for success, `4xx` for caller/validation/authorization/not-found failures, `5xx` for unexpected server failures) — never wrap an error payload inside a `200 OK` response.

## Bounded and Paginated Collections

- **Enforce pagination and maximum page size on variable-length lists**: require explicit pagination and a server-enforced maximum page size on every collection endpoint whose result set grows with stored data, backed by a deterministic total sort order (`db.md` Query Shape and Parameters, when present) so concurrent writes never skip or duplicate items across pages.

## Backward-Compatible Evolution and Versioning

- **Evolve published schemas compatibly or version explicitly**: add optional fields or new endpoints without breaking existing callers; whenever an incompatible change to published endpoints or payloads is unavoidable, expose it under a distinct API version and retain prior versions until external callers outside the repository have migrated (`standard.md` Leave No Vestiges — External compatibility exception).

## Request Size and Rate Limits

- **Bound request payload sizes upfront**: enforce explicit maximum sizes for request bodies, headers, and query parameters at the API boundary before buffering requests into memory (complementing `file-exchange.md`, when present, for file uploads).
- **Enforce rate and concurrency limits**: protect exposed endpoints with explicit per-caller or per-endpoint rate or concurrency bounds, returning standard throttling responses with retry guidance (e.g., `429 Too Many Requests` with `Retry-After`) rather than letting traffic spikes exhaust the service.

## Transport Encryption and Credentials

- **Require encrypted transport for exposed APIs**: serve Web API endpoints over encrypted transport (HTTPS/TLS) at deployment (terminated at the application or a trusted reverse proxy directly in front of it) so credentials, payloads, and responses cannot be intercepted or tampered with in transit; reserve unencrypted loopback HTTP strictly for isolated local development or automated test harnesses (`security.md`, when present).
- **Accept credentials in headers or bodies over encrypted transport only**: for authenticated endpoints, accept bearer tokens, API keys, and credentials solely in HTTP headers (e.g., `Authorization`) or request bodies transmitted over that encrypted channel, and reject credentials passed in URL paths or query strings, which persist unencrypted in access logs, proxies, and browser histories (`security.md`, when present).
