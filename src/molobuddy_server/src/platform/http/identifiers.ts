import { randomUUID } from 'node:crypto';

const correlationIdPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/;

export function createOpaqueId(prefix: 'req' | 'cor' | 'prb'): string {
  return `${prefix}_${randomUUID().replaceAll('-', '')}`;
}

export function resolveCorrelationId(header: unknown): string {
  if (typeof header === 'string' && correlationIdPattern.test(header)) {
    return header;
  }
  return createOpaqueId('cor');
}
