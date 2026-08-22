import { randomUUID } from 'node:crypto';

const correlationIdPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/;

export function createOpaqueId(
  prefix: 'con' | 'cor' | 'evt' | 'oas' | 'out' | 'prb' | 'prc' | 'req' | 'syn',
): string {
  return `${prefix}_${randomUUID().replaceAll('-', '')}`;
}

export function resolveCorrelationId(header: unknown): string {
  if (typeof header === 'string' && correlationIdPattern.test(header)) {
    return header;
  }
  return createOpaqueId('cor');
}

/**
 * A fresh optimistic concurrency token.
 *
 * This is the value behind the API's strong ETag. `If-Match` is compared
 * against it to prevent lost updates, so it MUST be regenerated on every write.
 * A constant here would make every comparison succeed and silently disable the
 * protection it appears to provide.
 */
export function createResourceVersion(): string {
  return randomUUID().replaceAll('-', '');
}
