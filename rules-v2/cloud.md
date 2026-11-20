# Cloud Storage and Managed Services Standards

**Applies when** the application stores objects or files in cloud storage (e.g., object buckets, blob containers), integrates with cloud-provider managed services, or maintains cloud-hosted backups. Does not apply to purely local or on-premises applications that use no cloud storage, cloud-provider managed services, or cloud-hosted backups.

Defines stack-agnostic ideals for keeping cloud storage private, protecting data at rest
and keys, issuing short-lived transfer URLs, preferring short-lived or managed cloud
credentials, and verifying backup restoration. General secret storage and encryption
principles live in `security.md` when present.

## Storage Access Defaults

- **Keep storage containers private**: configure every cloud storage bucket, container, and snapshot store private with anonymous access and public directory listing disabled — granting access explicitly per workload or authenticated identity rather than opening container-wide public access, unless the application's specification and rules explicitly designate a public-assets container.

## Encryption at Rest and Key Management

- **Encrypt stored objects with separated key governance**: enable encryption at rest on cloud storage and backups, and manage encryption keys with explicit ownership, rotation schedules, and access policies separated from storage data permissions (`security.md`, when present).

## Short-Lived Signed Transfer URLs

- **Issue scoped, short-lived signed URLs for direct transfers**: when delegating file downloads or uploads directly to cloud storage rather than proxying through the application, generate least-privilege signed URLs restricted to the specific object and operation with the shortest practical expiration window — never permanent public URLs or shared long-lived access tokens. (When `security.md` applies alongside this file, scoped short-lived transfer URLs satisfy this rule rather than triggering `security.md`'s prohibition on placing caller credentials in URLs.)

## Short-Lived and Managed Cloud Identities

- **Authenticate with managed identities or short-lived tokens**: access cloud APIs and storage using platform-managed identities, workload identity federation, or short-lived scoped credentials rather than static long-lived access keys; where an external integration constraint requires a static key, store it in a platform secret store (`security.md`, when present) with a defined rotation schedule.

## Verified Backup Restoration

- **Periodically test restoring backups**: configure automated backups with defined recovery point and recovery time targets for durable cloud-stored data, and periodically run operational recovery drills restoring backups into an isolated non-production environment (distinct from automated repository-built boundary test suites under `testing.md`) to verify completeness, decryption, and usability.
