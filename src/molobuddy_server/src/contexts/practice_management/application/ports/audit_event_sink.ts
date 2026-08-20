export type AuditEvent = Readonly<{
  actorUid: string;
  practiceId: string;
  action: 'practice.provisioned';
  correlationId: string;
  /** Safe authorisation state after the action. Never a token or a credential. */
  resultingState: Readonly<{ role: 'owner'; status: 'active' }>;
}>;

export interface AuditEventSink {
  record(event: AuditEvent): Promise<void>;
}
