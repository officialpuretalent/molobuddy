import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { describe, it } from 'node:test';

function filesUnder(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const full = join(directory, entry);
    return statSync(full).isDirectory()
      ? filesUnder(full)
      : full.endsWith('.ts')
        ? [full]
        : [];
  });
}

describe('context dependency rules', () => {
  it('keeps vendor SDKs out of domain and application code', () => {
    const offenders: string[] = [];
    let inspected = 0;

    for (const file of filesUnder('src/contexts')) {
      const normalised = file.replaceAll('\\', '/');
      if (
        !normalised.includes('/domain/') &&
        !normalised.includes('/application/')
      ) {
        continue;
      }
      inspected += 1;
      const source = readFileSync(file, 'utf8');
      for (const vendor of ['firebase-admin', 'fastify', '@google-cloud']) {
        if (source.includes(`from '${vendor}`)) {
          offenders.push(`${normalised} imports ${vendor}`);
        }
      }
    }

    // Without this the guard passes vacuously from the wrong directory, which
    // is the one failure mode a containment test must not have.
    assert.ok(inspected > 0, 'no domain or application files were inspected');
    assert.deepEqual(offenders, []);
  });
});
