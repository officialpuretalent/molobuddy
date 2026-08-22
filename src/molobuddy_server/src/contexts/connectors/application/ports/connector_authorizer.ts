import type { VerifiedActor } from '../../../identity_access/index.js';

export type ConnectorAccessCapability =
  'connectors.manage' | 'connectors.read' | 'connectors.sync';

export type ConnectorAuthorisationResult =
  | Readonly<{ ok: true }>
  | Readonly<{
      ok: false;
      code:
        'capability_required' | 'region_route_mismatch' | 'resource_not_found';
    }>;

/** Server-owned practice and capability resolution for regional endpoints. */
export interface ConnectorAuthorizer {
  authorize(input: {
    actor: VerifiedActor;
    practiceId: string;
    regionalCellKey: string;
    capability: ConnectorAccessCapability;
  }): Promise<ConnectorAuthorisationResult>;
}
