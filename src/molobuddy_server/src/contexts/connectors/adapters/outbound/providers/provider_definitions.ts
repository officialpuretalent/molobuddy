import { DocumentedAccountingProviderAdapter } from './documented_accounting_provider_adapter.js';
import type {
  AccountingProviderDefinition,
  AccountingRecordKind,
  ProviderEndpointTemplate,
} from '../../../domain/accounting_provider.js';

const get = (url: string, description: string): ProviderEndpointTemplate => ({
  method: 'GET',
  url,
  description,
});

const providerReadEndpoints = (
  endpoints: Readonly<Record<AccountingRecordKind, string>>,
): Readonly<Record<AccountingRecordKind, ProviderEndpointTemplate>> => ({
  account: get(endpoints.account, 'List chart-of-account records.'),
  bank_transaction: get(
    endpoints.bank_transaction,
    'List bank or transaction records.',
  ),
  bill: get(endpoints.bill, 'List purchase/bill records.'),
  contact: get(
    endpoints.contact,
    'List customer, supplier or contact records.',
  ),
  credit_note: get(endpoints.credit_note, 'List credit-note records.'),
  invoice: get(endpoints.invoice, 'List sales-invoice records.'),
  payment: get(endpoints.payment, 'List payment records.'),
  tax_rate: get(endpoints.tax_rate, 'List tax-rate records.'),
});

/**
 * Xero Accounting API contract. New applications use granular scopes, rather
 * than the legacy accounting.transactions scope.
 */
export const xeroDefinition: AccountingProviderDefinition = {
  key: 'xero',
  displayName: 'Xero',
  dataSourceKind: 'tenant',
  documentationUrl:
    'https://developer.xero.com/documentation/guides/oauth2/auth-flow/',
  oauth: {
    authorizationEndpoint: 'https://login.xero.com/identity/connect/authorize',
    tokenEndpoint: 'https://identity.xero.com/connect/token',
    revocationEndpoint: 'https://identity.xero.com/connect/revocation',
    clientAuthentication: 'basic_authorization_header',
    scopeDelimiter: 'space',
    usesPkce: false,
  },
  api: {
    baseUrl: 'https://api.xero.com/api.xro/2.0/',
    sourceContext: {
      name: 'xero-tenant-id',
      location: 'header',
      description:
        'The selected Xero tenant ID required by Accounting API calls.',
    },
    endpoints: providerReadEndpoints({
      account: 'Accounts',
      bank_transaction: 'BankTransactions',
      bill: 'Invoices?where=Type%3D%3D%22ACCPAY%22',
      contact: 'Contacts',
      credit_note: 'CreditNotes',
      invoice: 'Invoices?where=Type%3D%3D%22ACCREC%22',
      payment: 'Payments',
      tax_rate: 'TaxRates',
    }),
  },
  scopeBundles: [
    { capability: 'accounts.read', scopes: ['accounting.settings.read'] },
    {
      capability: 'bank_transactions.read',
      scopes: ['accounting.banktransactions.read'],
    },
    { capability: 'bills.read', scopes: ['accounting.invoices.read'] },
    { capability: 'contacts.read', scopes: ['accounting.contacts.read'] },
    { capability: 'credit_notes.read', scopes: ['accounting.invoices.read'] },
    { capability: 'invoices.read', scopes: ['accounting.invoices.read'] },
    { capability: 'payments.read', scopes: ['accounting.payments.read'] },
    { capability: 'tax_rates.read', scopes: ['accounting.settings.read'] },
  ],
  supportedCapabilities: [
    'accounts.read',
    'bank_transactions.read',
    'bills.read',
    'contacts.read',
    'credit_notes.read',
    'invoices.read',
    'payments.read',
    'tax_rates.read',
  ],
  supportsWebhooks: true,
  supportsScheduledReconciliation: true,
};

/**
 * Zoho Books API contract. The base URL is a `.com` default only: a live
 * credential response supplies `api_domain`, which must replace this host.
 */
export const zohoBooksDefinition: AccountingProviderDefinition = {
  key: 'zoho_books',
  displayName: 'Zoho Books',
  dataSourceKind: 'organisation',
  documentationUrl: 'https://www.zoho.com/books/api/v3/oauth/',
  oauth: {
    authorizationEndpoint: 'https://accounts.zoho.com/oauth/v2/auth',
    tokenEndpoint: 'https://accounts.zoho.com/oauth/v2/token',
    revocationEndpoint: 'https://accounts.zoho.com/oauth/v2/token/revoke',
    clientAuthentication: 'client_id_and_secret_body',
    scopeDelimiter: 'comma',
    usesPkce: false,
  },
  api: {
    baseUrl: 'https://www.zohoapis.com/books/v3/',
    sourceContext: {
      name: 'organization_id',
      location: 'query',
      description: 'The selected Zoho Books organisation ID.',
    },
    endpoints: providerReadEndpoints({
      account: 'chartofaccounts',
      bank_transaction: 'banktransactions',
      bill: 'bills',
      contact: 'contacts',
      credit_note: 'creditnotes',
      invoice: 'invoices',
      payment: 'customerpayments',
      tax_rate: 'settings/taxes',
    }),
  },
  scopeBundles: [
    { capability: 'accounts.read', scopes: ['ZohoBooks.settings.READ'] },
    {
      capability: 'bank_transactions.read',
      scopes: ['ZohoBooks.banktransactions.READ'],
    },
    { capability: 'bills.read', scopes: ['ZohoBooks.bills.READ'] },
    { capability: 'contacts.read', scopes: ['ZohoBooks.contacts.READ'] },
    { capability: 'credit_notes.read', scopes: ['ZohoBooks.creditnotes.READ'] },
    { capability: 'invoices.read', scopes: ['ZohoBooks.invoices.READ'] },
    {
      capability: 'payments.read',
      scopes: ['ZohoBooks.customerpayments.READ'],
    },
    { capability: 'tax_rates.read', scopes: ['ZohoBooks.settings.READ'] },
  ],
  supportedCapabilities: [
    'accounts.read',
    'bank_transactions.read',
    'bills.read',
    'contacts.read',
    'credit_notes.read',
    'invoices.read',
    'payments.read',
    'tax_rates.read',
  ],
  supportsWebhooks: true,
  supportsScheduledReconciliation: true,
};

/** Sage Business Cloud Accounting v3.1, not Sage Intacct or a desktop product. */
export const sageBusinessCloudAccountingDefinition: AccountingProviderDefinition =
  {
    key: 'sage_business_cloud_accounting',
    displayName: 'Sage Business Cloud Accounting',
    dataSourceKind: 'company',
    documentationUrl:
      'https://developer.sage.com/accounting/docs/v1.0.0/guides/learning/migrating/migrating-from-v3-to-v31',
    oauth: {
      authorizationEndpoint: 'https://www.sageone.com/auth/central',
      tokenEndpoint: 'https://oauth.accounting.sage.com/token',
      clientAuthentication: 'provider_managed',
      scopeDelimiter: 'provider_managed',
      usesPkce: false,
    },
    api: {
      baseUrl: 'https://api.accounting.sage.com/v3.1/',
      sourceContext: {
        name: 'company',
        location: 'provider_managed',
        description: 'Company authorisation context established by Sage.',
      },
      endpoints: providerReadEndpoints({
        account: 'ledger_accounts',
        bank_transaction: 'transactions',
        bill: 'purchase_invoices',
        contact: 'contacts',
        credit_note: 'sales_credit_notes',
        invoice: 'sales_invoices',
        payment: 'transactions',
        tax_rate: 'tax_rates',
      }),
    },
    // Confirm the scope catalogue during Sage app registration; v3.1 migration
    // documentation describes OAuth endpoints but not stable public scope names.
    scopeBundles: [],
    supportedCapabilities: [
      'accounts.read',
      'bank_transactions.read',
      'bills.read',
      'contacts.read',
      'credit_notes.read',
      'invoices.read',
      'payments.read',
      'tax_rates.read',
    ],
    supportsWebhooks: false,
    supportsScheduledReconciliation: true,
  };

/** QuickBooks Online contract. All entity retrieval is issued via QBO query. */
export const quickBooksOnlineDefinition: AccountingProviderDefinition = {
  key: 'quickbooks_online',
  displayName: 'QuickBooks Online',
  dataSourceKind: 'company',
  documentationUrl:
    'https://developer.intuit.com/app/developer/qbo/docs/develop/authentication-and-authorization',
  oauth: {
    authorizationEndpoint: 'https://appcenter.intuit.com/connect/oauth2',
    tokenEndpoint: 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer',
    revocationEndpoint:
      'https://developer.api.intuit.com/v2/oauth2/tokens/revoke',
    clientAuthentication: 'basic_authorization_header',
    scopeDelimiter: 'space',
    usesPkce: false,
  },
  api: {
    baseUrl: 'https://quickbooks.api.intuit.com/v3/company/{dataSourceId}/',
    sourceContext: {
      name: 'realmId',
      location: 'path',
      description: 'The authorised QuickBooks Online company realm ID.',
    },
    endpoints: providerReadEndpoints({
      account: 'query',
      bank_transaction: 'query',
      bill: 'query',
      contact: 'query',
      credit_note: 'query',
      invoice: 'query',
      payment: 'query',
      tax_rate: 'query',
    }),
  },
  scopeBundles: [
    {
      capability: 'accounts.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    {
      capability: 'bank_transactions.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    { capability: 'bills.read', scopes: ['com.intuit.quickbooks.accounting'] },
    {
      capability: 'contacts.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    {
      capability: 'credit_notes.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    {
      capability: 'invoices.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    {
      capability: 'payments.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
    {
      capability: 'tax_rates.read',
      scopes: ['com.intuit.quickbooks.accounting'],
    },
  ],
  supportedCapabilities: [
    'accounts.read',
    'bank_transactions.read',
    'bills.read',
    'contacts.read',
    'credit_notes.read',
    'invoices.read',
    'payments.read',
    'tax_rates.read',
  ],
  supportsWebhooks: true,
  supportsScheduledReconciliation: true,
};

export const documentedAccountingProviderAdapters = [
  new DocumentedAccountingProviderAdapter(quickBooksOnlineDefinition),
  new DocumentedAccountingProviderAdapter(
    sageBusinessCloudAccountingDefinition,
  ),
  new DocumentedAccountingProviderAdapter(xeroDefinition),
  new DocumentedAccountingProviderAdapter(zohoBooksDefinition),
] as const;
