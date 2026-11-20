# Remote Call Standards

**Applies when** the application invokes external systems over a network — e.g., HTTP APIs, RPC endpoints, message brokers, or cloud services. Does not apply to database queries executed through a database engine (`db.md`, when present), to inbound HTTP endpoints served by the application (`web-api.md`, when present), or to strictly in-process calls.

Defines stack-agnostic ideals for bounding network waits, retrying safely, reusing
connections, authenticating encrypted transport, and validating remote responses. For
external endpoint addresses as configuration, see `configuration.md` when present; for
secrets carried in requests, see `security.md` when present.

## Timeouts and Cancellation

- **Set explicit timeouts on every call**: configure both connection timeouts and overall operation timeouts explicitly on every outbound network request (never relying on infinite defaults), so an unresponsive remote system cannot hang callers or exhaust threads (`specs.md` UNAVAILABLE, LOOPS); centralize default client timeout policy per `standard.md` (One Home per Piece of Knowledge).
- **Propagate cancellation**: pass caller cancellation into outbound network I/O so aborted or timed-out operations release sockets and resources promptly (`standard.md` Synchronous vs Asynchronous).

## Bounded Retries

- **Retry transient failures only on idempotent operations**: automatically retry only transient transport or temporary availability errors, and only for operations safe to repeat (naturally idempotent operations or operations carrying a caller-fixed idempotency key per `specs.md` REPEAT).
- **Bound retries with exponential backoff and jitter**: enforce a strict maximum retry count or total elapsed deadline measured by the application itself (`specs.md` LOOPS), increasing delay between attempts with randomized jitter so synchronized clients do not overwhelm recovering services.

## Connection Reuse

- **Reuse managed network clients and connection pools**: share long-lived HTTP/network client instances or connection pools across requests rather than instantiating and tearing down clients per call (which exhausts sockets and ephemeral ports), while configuring pool connection lifetimes so DNS updates take effect without application restarts.

## Transport Identity and Response Boundaries

- **Enforce certificate and peer validation**: communicate over encrypted, certificate-validated transport on outbound network connections and never disable TLS or peer certificate verification in application code. Automated tests or local development targeting local test stubs may trust a test-created certificate explicitly (or use local loopback HTTP strictly inside an isolated automated test harness when TLS is not under test), never disabling verification globally (`security.md`, when present).
- **Treat remote responses as untrusted input with size limits**: validate every payload received from a remote system at the response boundary (`standard.md` External Input) and enforce maximum response size limits before buffering content into memory.
