import { fetchAPI } from './api';

export const paymentService = {
  // Fetch all transactions
  getTransactions: () => {
    return fetchAPI('/payments/transactions');
  },

  // Fetch pending dues
  getPendingDues: () => {
    return fetchAPI('/payments/pending');
  },

  // Fetch invoices
  getInvoices: () => {
    return fetchAPI('/payments/invoices');
  },

  // Fetch payment KPIs
  getKPIs: () => {
    return fetchAPI('/payments/kpis');
  },

  // Fetch dashboard charts data
  getDashboardData: () => {
    return fetchAPI('/payments/dashboard');
  },

  // Send payment reminder
  sendReminder: (dueId) => {
    return fetchAPI(`/payments/pending/${dueId}/remind`, {
      method: 'POST'
    });
  },

  // Generate and send payment link
  sendPaymentLink: (dueId) => {
    return fetchAPI(`/payments/pending/${dueId}/link`, {
      method: 'POST'
    });
  },

  // Mark as paid manually
  markAsPaid: (dueId) => {
    return fetchAPI(`/payments/pending/${dueId}/mark-paid`, {
      method: 'POST'
    });
  }
};
