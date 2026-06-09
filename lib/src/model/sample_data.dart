/// Sample data backing the default search provider in demos. In a real app this
/// is replaced by per-trigger custom providers hitting your API. Mirrors
/// `SC.DATA` 1:1. Each row is a loose map merged into a [ComposerReference].
class SampleData {
  SampleData._();

  static final Map<String, List<Map<String, dynamic>>> data = {
    'user': [
      {'title': 'Ahmed Al-Rashid', 'subtitle': 'Finance Lead · Riyadh', 'metadata': {'initials': 'AR'}},
      {'title': 'Sara Khan', 'subtitle': 'Accountant', 'metadata': {'initials': 'SK'}},
      {'title': 'Mohammed Nasser', 'subtitle': 'Store Manager', 'metadata': {'initials': 'MN'}},
      {'title': 'Layla Hassan', 'subtitle': 'Auditor', 'metadata': {'initials': 'LH'}},
      {'title': 'Omar Farouk', 'subtitle': 'Operations', 'metadata': {'initials': 'OF'}},
    ],
    'member': [
      {'title': 'Yusuf Idris', 'subtitle': 'Member · #4821'},
      {'title': 'Noura Saleh', 'subtitle': 'Member · #4822'},
    ],
    'team': [
      {'title': 'Finance Team', 'subtitle': '8 members'},
      {'title': 'Audit & Compliance', 'subtitle': '4 members'},
      {'title': 'Procurement', 'subtitle': '6 members'},
    ],
    'club': [
      {'title': 'Riyadh Operations Club', 'subtitle': 'Regional group'},
    ],
    'file': [
      {'title': 'client-a.pdf', 'subtitle': '2.4 MB · PDF', 'path': 'contracts/client-a.pdf', 'mono': true},
      {'title': 'q4-reconciliation.xlsx', 'subtitle': '880 KB · Sheet', 'path': 'finance/q4-reconciliation.xlsx', 'mono': true},
      {'title': 'audit-log-2026.csv', 'subtitle': '1.1 MB · CSV', 'path': 'exports/audit-log-2026.csv', 'mono': true},
    ],
    'folder': [
      {'title': 'contracts', 'subtitle': '24 files', 'path': 'contracts/', 'mono': true},
      {'title': 'finance', 'subtitle': '58 files', 'path': 'finance/', 'mono': true},
      {'title': 'exports', 'subtitle': '12 files', 'path': 'exports/', 'mono': true},
    ],
    'document': [
      {'title': 'Vendor Agreement', 'subtitle': 'DOCX · 6 pages'},
      {'title': 'Q4 Audit Memo', 'subtitle': 'PDF · 3 pages'},
    ],
    'image': [
      {'title': 'storefront-render.png', 'subtitle': '1.2 MB · PNG', 'mono': true},
    ],
    'video': [
      {'title': 'walkthrough.mp4', 'subtitle': '18.4 MB · MP4', 'mono': true},
    ],
    'invoice': [
      {'title': 'INV-2026-001', 'subtitle': 'Client A · \$5,240.00', 'mono': true, 'metadata': {'amount': '\$5,240.00'}},
      {'title': 'INV-2026-014', 'subtitle': 'Vendor X · \$1,180.00', 'mono': true, 'metadata': {'amount': '\$1,180.00'}},
      {'title': 'INV-2026-022', 'subtitle': 'Overdue · \$920.00', 'mono': true, 'state': 'error', 'metadata': {'amount': '\$920.00'}},
    ],
    'payment': [
      {'title': 'PAY-9042', 'subtitle': 'Settled · \$5,240.00', 'mono': true},
      {'title': 'PAY-9051', 'subtitle': 'Pending · \$1,180.00', 'mono': true},
    ],
    'financialAccount': [
      {'title': 'Main Bank Account', 'subtitle': 'SAR · \$284,120.00'},
      {'title': 'Petty Cash', 'subtitle': 'SAR · \$4,200.00'},
      {'title': 'Current Assets', 'subtitle': 'Ledger group'},
      {'title': 'Accounts Receivable', 'subtitle': 'Ledger group'},
    ],
    'bankAccount': [
      {'title': 'Al-Rajhi · ****6612', 'subtitle': 'Operating'},
      {'title': 'SNB · ****0048', 'subtitle': 'Reserve'},
    ],
    'transaction': [
      {'title': 'TR-9042', 'subtitle': 'Inter-account · \$5,000.00', 'mono': true},
      {'title': 'TR-9061', 'subtitle': 'Deposit · +\$12,400.00', 'mono': true},
    ],
    'report': [
      {'title': 'Q4 P&L', 'subtitle': 'Generated · 2026-01-04'},
      {'title': 'Trial Balance', 'subtitle': 'Live'},
      {'title': 'Cash Flow 2026', 'subtitle': 'Draft'},
    ],
    'task': [
      {'title': 'Prepare Report', 'subtitle': 'Due Fri · High'},
      {'title': 'Reconcile Q4', 'subtitle': 'In progress'},
      {'title': 'Vendor onboarding', 'subtitle': 'Archived', 'state': 'disabled'},
    ],
    'project': [
      {'title': 'Year-End Close', 'subtitle': '12 tasks'},
      {'title': 'ERP Migration', 'subtitle': '34 tasks'},
    ],
    'tool': [
      {'title': 'Web Search', 'subtitle': 'Fetch live results'},
      {'title': 'Code Interpreter', 'subtitle': 'Run & analyze'},
      {'title': 'Ledger Query', 'subtitle': 'Read the books'},
    ],
    'skill': [
      {'title': 'Summarize', 'subtitle': 'Condense long text'},
      {'title': 'Translate', 'subtitle': 'EN ⇄ AR'},
      {'title': 'Reconciliation', 'subtitle': 'Match transactions'},
    ],
    'command': [
      {'title': 'due', 'subtitle': 'Set a due date', 'metadata': {'args': '/due tomorrow'}},
      {'title': 'status', 'subtitle': 'Change status', 'metadata': {'args': '/status done'}},
      {'title': 'assign', 'subtitle': 'Assign to user', 'metadata': {'args': '/assign @ahmed'}},
      {'title': 'summarize', 'subtitle': 'Summarize thread'},
      {'title': 'export', 'subtitle': 'Export as…'},
    ],
    'link': [
      {'title': 'genius.link/q4-board', 'subtitle': 'External · dashboard', 'mono': true},
    ],
  };
}
