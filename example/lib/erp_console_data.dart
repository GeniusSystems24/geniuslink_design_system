// ============================================================
// ERP Console — DATA.
// ------------------------------------------------------------
// Pure, widget-free content for the ERP console demo: a tiny bilingual
// string helper, the navigation Tree (Finance / Sales / Inventory → leaves),
// and the six "screens", each declaring its EditableTable column schema, its
// seed rows and a few KPI cards. The shell + page widgets read this; nothing
// here imports the shell, so the data layer stays portable.
//   File: example/lib/erp_console_data.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:geniuslink_design_system/geniuslink_tree.dart';
import 'package:geniuslink_design_system/geniuslink_editable_table.dart';
import 'package:geniuslink_design_system/geniuslink_browser_tabs.dart' show GLTabKind;

/// Pick the English or Arabic string for the current language.
String tr(bool ar, String en, String arabic) => ar ? arabic : en;

/// A KPI tile shown in a screen header.
class Kpi {
  final String label;
  final String value;
  final String delta; // e.g. "+4.2%"
  final bool up;
  final IconData icon;
  const Kpi(this.label, this.value, this.delta, this.up, this.icon);
}

/// One ERP screen: a tab + its EditableTable content + KPIs.
class ErpScreen {
  final String id;
  final GLTabKind kind;
  final IconData icon;
  final bool dirty; // seeds the tab's unsaved dot
  final String Function(bool ar) title;
  final String Function(bool ar) module; // breadcrumb root
  final List<EditableColumn> Function(bool ar) columns;
  final List<EditableRow> Function(bool ar) rows;
  final List<Kpi> Function(bool ar) kpis;
  final bool showTotals;
  final String Function(bool ar)? unit;

  const ErpScreen({
    required this.id,
    required this.kind,
    required this.icon,
    this.dirty = false,
    required this.title,
    required this.module,
    required this.columns,
    required this.rows,
    required this.kpis,
    this.showTotals = false,
    this.unit,
  });
}

// ════════════════════════════════════════════════════════════
// Navigation tree  (selecting a leaf opens its screen via data['screen'])
// ════════════════════════════════════════════════════════════
List<TreeNode> erpNavTree(bool ar) => [
      TreeNode(
        id: 'finance',
        label: tr(ar, 'Finance', 'المالية'),
        icon: Icons.account_balance_outlined,
        folder: true,
        children: [
          TreeNode(id: 'coa', label: tr(ar, 'Chart of Accounts', 'دليل الحسابات'), icon: Icons.menu_book_outlined, data: const {'screen': 'coa'}),
          TreeNode(id: 'journal', label: tr(ar, 'Journal Entry', 'قيد يومية'), icon: Icons.edit_note_outlined, badge: tr(ar, 'draft', 'مسودة'), data: const {'screen': 'journal'}),
          TreeNode(id: 'trial', label: tr(ar, 'Trial Balance', 'ميزان المراجعة'), icon: Icons.balance_outlined, data: const {'screen': 'trial'}),
        ],
      ),
      TreeNode(
        id: 'sales',
        label: tr(ar, 'Sales', 'المبيعات'),
        icon: Icons.point_of_sale_outlined,
        folder: true,
        children: [
          TreeNode(id: 'invoice', label: tr(ar, 'Sales Invoice', 'فاتورة مبيعات'), icon: Icons.receipt_long_outlined, data: const {'screen': 'invoice'}),
          TreeNode(id: 'customers', label: tr(ar, 'Customers', 'العملاء'), icon: Icons.groups_outlined, badge: '128', data: const {'screen': 'customers'}),
        ],
      ),
      TreeNode(
        id: 'inventory',
        label: tr(ar, 'Inventory', 'المخزون'),
        icon: Icons.inventory_2_outlined,
        folder: true,
        children: [
          TreeNode(id: 'stock', label: tr(ar, 'Stock Items', 'أصناف المخزون'), icon: Icons.widgets_outlined, data: const {'screen': 'stock'}),
        ],
      ),
    ];

// ════════════════════════════════════════════════════════════
// The six screens
// ════════════════════════════════════════════════════════════
final List<ErpScreen> erpScreens = [
  // 1 ── Chart of Accounts ───────────────────────────────────
  ErpScreen(
    id: 'coa',
    kind: GLTabKind.ledger,
    icon: Icons.menu_book_outlined,
    title: (ar) => tr(ar, 'Chart of Accounts', 'دليل الحسابات'),
    module: (ar) => tr(ar, 'Finance', 'المالية'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'code', label: tr(ar, 'Code', 'الرمز'), width: 96, mono: true, required: true),
      EditableColumn(key: 'name', label: tr(ar, 'Account', 'الحساب'), width: 220, required: true),
      EditableColumn(key: 'type', label: tr(ar, 'Type', 'النوع'), width: 130, type: EditableColumnType.select, options: [
        tr(ar, 'Asset', 'أصل'),
        tr(ar, 'Liability', 'التزام'),
        tr(ar, 'Equity', 'حقوق ملكية'),
        tr(ar, 'Revenue', 'إيراد'),
        tr(ar, 'Expense', 'مصروف'),
      ]),
      EditableColumn(key: 'debit', label: tr(ar, 'Debit', 'مدين'), width: 130, type: EditableColumnType.number, includeInTotal: true),
      EditableColumn(key: 'credit', label: tr(ar, 'Credit', 'دائن'), width: 130, type: EditableColumnType.number, includeInTotal: true),
    ],
    rows: (ar) => [
      {'code': '1010', 'name': tr(ar, 'Cash on hand', 'نقدية بالصندوق'), 'type': tr(ar, 'Asset', 'أصل'), 'debit': '85,000.00', 'credit': '0.00'},
      {'code': '1020', 'name': tr(ar, 'Bank — Al Rajhi', 'بنك — الراجحي'), 'type': tr(ar, 'Asset', 'أصل'), 'debit': '412,300.00', 'credit': '0.00'},
      {'code': '1200', 'name': tr(ar, 'Accounts receivable', 'ذمم مدينة'), 'type': tr(ar, 'Asset', 'أصل'), 'debit': '196,540.00', 'credit': '0.00'},
      {'code': '2010', 'name': tr(ar, 'Accounts payable', 'ذمم دائنة'), 'type': tr(ar, 'Liability', 'التزام'), 'debit': '0.00', 'credit': '143,900.00'},
      {'code': '3000', 'name': tr(ar, 'Share capital', 'رأس المال'), 'type': tr(ar, 'Equity', 'حقوق ملكية'), 'debit': '0.00', 'credit': '500,000.00'},
      {'code': '4000', 'name': tr(ar, 'Sales revenue', 'إيرادات المبيعات'), 'type': tr(ar, 'Revenue', 'إيراد'), 'debit': '0.00', 'credit': '318,420.00'},
      {'code': '5000', 'name': tr(ar, 'Cost of goods sold', 'تكلفة المبيعات'), 'type': tr(ar, 'Expense', 'مصروف'), 'debit': '171,880.00', 'credit': '0.00'},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Total assets', 'إجمالي الأصول'), '693,840', '+6.1%', true, Icons.account_balance_wallet_outlined),
      Kpi(tr(ar, 'Liabilities', 'الالتزامات'), '143,900', '-2.3%', false, Icons.credit_card_outlined),
      Kpi(tr(ar, 'Accounts', 'عدد الحسابات'), '142', '+4', true, Icons.tag_outlined),
    ],
  ),

  // 2 ── Journal Entry ───────────────────────────────────────
  ErpScreen(
    id: 'journal',
    kind: GLTabKind.doc,
    icon: Icons.edit_note_outlined,
    dirty: true,
    title: (ar) => tr(ar, 'Journal Entry — JV-2024-0042', 'قيد يومية — JV-2024-0042'),
    module: (ar) => tr(ar, 'Finance', 'المالية'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'account', label: tr(ar, 'Account', 'الحساب'), width: 240, required: true),
      EditableColumn(key: 'memo', label: tr(ar, 'Description', 'البيان'), width: 240),
      EditableColumn(key: 'debit', label: tr(ar, 'Debit', 'مدين'), width: 130, type: EditableColumnType.number, includeInTotal: true),
      EditableColumn(key: 'credit', label: tr(ar, 'Credit', 'دائن'), width: 130, type: EditableColumnType.number, includeInTotal: true),
    ],
    rows: (ar) => [
      {'account': tr(ar, '1020 · Bank — Al Rajhi', '1020 · بنك — الراجحي'), 'memo': tr(ar, 'Customer settlement', 'تحصيل من عميل'), 'debit': '48,000.00', 'credit': '0.00'},
      {'account': tr(ar, '1200 · Accounts receivable', '1200 · ذمم مدينة'), 'memo': tr(ar, 'Invoice INV-3391', 'فاتورة INV-3391'), 'debit': '0.00', 'credit': '48,000.00'},
      {'account': tr(ar, '5100 · Salaries expense', '5100 · مصروف الرواتب'), 'memo': tr(ar, 'October payroll', 'رواتب أكتوبر'), 'debit': '62,500.00', 'credit': '0.00'},
      {'account': tr(ar, '1020 · Bank — Al Rajhi', '1020 · بنك — الراجحي'), 'memo': tr(ar, 'Payroll transfer', 'تحويل الرواتب'), 'debit': '0.00', 'credit': '62,500.00'},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Total debit', 'إجمالي المدين'), '110,500', '', true, Icons.south_west),
      Kpi(tr(ar, 'Total credit', 'إجمالي الدائن'), '110,500', '', true, Icons.north_east),
      Kpi(tr(ar, 'Status', 'الحالة'), tr(ar, 'Balanced', 'متوازن'), '', true, Icons.verified_outlined),
    ],
  ),

  // 3 ── Sales Invoice ───────────────────────────────────────
  ErpScreen(
    id: 'invoice',
    kind: GLTabKind.store,
    icon: Icons.receipt_long_outlined,
    title: (ar) => tr(ar, 'Sales Invoice — INV-3391', 'فاتورة مبيعات — INV-3391'),
    module: (ar) => tr(ar, 'Sales', 'المبيعات'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'item', label: tr(ar, 'Item', 'الصنف'), width: 230, required: true),
      EditableColumn(key: 'qty', label: tr(ar, 'Qty', 'الكمية'), width: 80, type: EditableColumnType.number),
      EditableColumn(key: 'price', label: tr(ar, 'Unit price', 'سعر الوحدة'), width: 120, type: EditableColumnType.number),
      EditableColumn(key: 'disc', label: tr(ar, 'Disc %', 'خصم %'), width: 90, type: EditableColumnType.number),
      EditableColumn(key: 'total', label: tr(ar, 'Line total', 'إجمالي السطر'), width: 130, type: EditableColumnType.number, includeInTotal: true),
    ],
    rows: (ar) => [
      {'item': tr(ar, 'Smart shelf sensor', 'حساس رف ذكي'), 'qty': '40', 'price': '320.00', 'disc': '5', 'total': '12,160.00'},
      {'item': tr(ar, 'Gateway hub X2', 'بوابة شبكة X2'), 'qty': '8', 'price': '1,450.00', 'disc': '0', 'total': '11,600.00'},
      {'item': tr(ar, 'Install & setup', 'تركيب وإعداد'), 'qty': '1', 'price': '6,500.00', 'disc': '0', 'total': '6,500.00'},
      {'item': tr(ar, 'Annual support', 'دعم سنوي'), 'qty': '12', 'price': '480.00', 'disc': '10', 'total': '5,184.00'},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Subtotal', 'الإجمالي الفرعي'), '35,444', '', true, Icons.summarize_outlined),
      Kpi(tr(ar, 'VAT 15%', 'ضريبة 15%'), '5,316', '', true, Icons.percent_outlined),
      Kpi(tr(ar, 'Grand total', 'الإجمالي'), '40,760', '+12%', true, Icons.payments_outlined),
    ],
  ),

  // 4 ── Stock Items ─────────────────────────────────────────
  ErpScreen(
    id: 'stock',
    kind: GLTabKind.store,
    icon: Icons.widgets_outlined,
    title: (ar) => tr(ar, 'Stock Items', 'أصناف المخزون'),
    module: (ar) => tr(ar, 'Inventory', 'المخزون'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'sku', label: tr(ar, 'SKU', 'الرمز'), width: 110, mono: true, required: true),
      EditableColumn(key: 'name', label: tr(ar, 'Product', 'المنتج'), width: 220, required: true),
      EditableColumn(key: 'cat', label: tr(ar, 'Category', 'الفئة'), width: 130, type: EditableColumnType.select, options: [
        tr(ar, 'Sensors', 'حساسات'),
        tr(ar, 'Gateways', 'بوابات'),
        tr(ar, 'Services', 'خدمات'),
        tr(ar, 'Accessories', 'ملحقات'),
      ]),
      EditableColumn(key: 'onhand', label: tr(ar, 'On hand', 'المتوفر'), width: 90, type: EditableColumnType.number),
      EditableColumn(key: 'reorder', label: tr(ar, 'Reorder', 'حد الطلب'), width: 90, type: EditableColumnType.number),
      EditableColumn(key: 'value', label: tr(ar, 'Stock value', 'قيمة المخزون'), width: 130, type: EditableColumnType.number, includeInTotal: true),
    ],
    rows: (ar) => [
      {'sku': 'SNS-100', 'name': tr(ar, 'Smart shelf sensor', 'حساس رف ذكي'), 'cat': tr(ar, 'Sensors', 'حساسات'), 'onhand': '320', 'reorder': '80', 'value': '76,800.00'},
      {'sku': 'GW-X2', 'name': tr(ar, 'Gateway hub X2', 'بوابة شبكة X2'), 'cat': tr(ar, 'Gateways', 'بوابات'), 'onhand': '54', 'reorder': '20', 'value': '62,640.00'},
      {'sku': 'CBL-3M', 'name': tr(ar, 'Sensor cable 3m', 'كابل حساس 3م'), 'cat': tr(ar, 'Accessories', 'ملحقات'), 'onhand': '14', 'reorder': '50', 'value': '1,260.00'},
      {'sku': 'MNT-STD', 'name': tr(ar, 'Wall mount kit', 'طقم تثبيت جداري'), 'cat': tr(ar, 'Accessories', 'ملحقات'), 'onhand': '210', 'reorder': '60', 'value': '8,400.00'},
      {'sku': 'BAT-Li', 'name': tr(ar, 'Li-ion battery pack', 'بطارية ليثيوم'), 'cat': tr(ar, 'Accessories', 'ملحقات'), 'onhand': '9', 'reorder': '40', 'value': '990.00'},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Stock value', 'قيمة المخزون'), '150,090', '+3.4%', true, Icons.inventory_outlined),
      Kpi(tr(ar, 'SKUs', 'عدد الأصناف'), '86', '+2', true, Icons.qr_code_2_outlined),
      Kpi(tr(ar, 'Below reorder', 'تحت حد الطلب'), '2', '+1', false, Icons.warning_amber_outlined),
    ],
  ),

  // 5 ── Customers ───────────────────────────────────────────
  ErpScreen(
    id: 'customers',
    kind: GLTabKind.user,
    icon: Icons.groups_outlined,
    title: (ar) => tr(ar, 'Customers', 'العملاء'),
    module: (ar) => tr(ar, 'Sales', 'المبيعات'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'name', label: tr(ar, 'Customer', 'العميل'), width: 220, required: true),
      EditableColumn(key: 'acc', label: tr(ar, 'Account', 'رقم الحساب'), width: 110, mono: true),
      EditableColumn(key: 'phone', label: tr(ar, 'Phone', 'الهاتف'), width: 140, mono: true),
      EditableColumn(key: 'balance', label: tr(ar, 'Balance', 'الرصيد'), width: 130, type: EditableColumnType.number, includeInTotal: true),
      EditableColumn(key: 'status', label: tr(ar, 'Status', 'الحالة'), width: 120, type: EditableColumnType.select, options: [
        tr(ar, 'Active', 'نشط'),
        tr(ar, 'On hold', 'موقوف'),
        tr(ar, 'Overdue', 'متأخر'),
      ]),
    ],
    rows: (ar) => [
      {'name': tr(ar, 'Najd Retail Co.', 'شركة نجد للتجزئة'), 'acc': 'C-1042', 'phone': '+966 50 112 3344', 'balance': '48,000.00', 'status': tr(ar, 'Active', 'نشط')},
      {'name': tr(ar, 'Coastal Markets', 'أسواق الساحل'), 'acc': 'C-1067', 'phone': '+966 55 998 7766', 'balance': '12,500.00', 'status': tr(ar, 'Overdue', 'متأخر')},
      {'name': tr(ar, 'Vision Tech LLC', 'فيجن تك'), 'acc': 'C-1090', 'phone': '+966 53 445 1212', 'balance': '0.00', 'status': tr(ar, 'Active', 'نشط')},
      {'name': tr(ar, 'Desert Logistics', 'لوجستيات الصحراء'), 'acc': 'C-1103', 'phone': '+966 56 220 8080', 'balance': '31,200.00', 'status': tr(ar, 'On hold', 'موقوف')},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Receivable', 'إجمالي الذمم'), '91,700', '+5.0%', true, Icons.request_quote_outlined),
      Kpi(tr(ar, 'Active', 'العملاء النشطون'), '112', '+6', true, Icons.how_to_reg_outlined),
      Kpi(tr(ar, 'Overdue', 'متأخرون'), '7', '+2', false, Icons.schedule_outlined),
    ],
  ),

  // 6 ── Trial Balance ───────────────────────────────────────
  ErpScreen(
    id: 'trial',
    kind: GLTabKind.chart,
    icon: Icons.balance_outlined,
    title: (ar) => tr(ar, 'Trial Balance — FY2024 Q3', 'ميزان المراجعة — 2024 ر3'),
    module: (ar) => tr(ar, 'Finance', 'المالية'),
    showTotals: true,
    unit: (ar) => tr(ar, 'SAR', 'ر.س'),
    columns: (ar) => [
      EditableColumn(key: 'code', label: tr(ar, 'Code', 'الرمز'), width: 96, mono: true, required: true),
      EditableColumn(key: 'name', label: tr(ar, 'Account', 'الحساب'), width: 240, required: true),
      EditableColumn(key: 'debit', label: tr(ar, 'Debit', 'مدين'), width: 140, type: EditableColumnType.number, includeInTotal: true),
      EditableColumn(key: 'credit', label: tr(ar, 'Credit', 'دائن'), width: 140, type: EditableColumnType.number, includeInTotal: true),
    ],
    rows: (ar) => [
      {'code': '1010', 'name': tr(ar, 'Cash on hand', 'نقدية بالصندوق'), 'debit': '85,000.00', 'credit': '0.00'},
      {'code': '1020', 'name': tr(ar, 'Bank — Al Rajhi', 'بنك — الراجحي'), 'debit': '412,300.00', 'credit': '0.00'},
      {'code': '1200', 'name': tr(ar, 'Accounts receivable', 'ذمم مدينة'), 'debit': '196,540.00', 'credit': '0.00'},
      {'code': '2010', 'name': tr(ar, 'Accounts payable', 'ذمم دائنة'), 'debit': '0.00', 'credit': '143,900.00'},
      {'code': '3000', 'name': tr(ar, 'Share capital', 'رأس المال'), 'debit': '0.00', 'credit': '500,000.00'},
      {'code': '4000', 'name': tr(ar, 'Sales revenue', 'إيرادات المبيعات'), 'debit': '0.00', 'credit': '318,420.00'},
      {'code': '5000', 'name': tr(ar, 'Cost of goods sold', 'تكلفة المبيعات'), 'debit': '171,880.00', 'credit': '0.00'},
      {'code': '5100', 'name': tr(ar, 'Salaries expense', 'مصروف الرواتب'), 'debit': '96,600.00', 'credit': '0.00'},
    ],
    kpis: (ar) => [
      Kpi(tr(ar, 'Total debit', 'إجمالي المدين'), '962,320', '', true, Icons.south_west),
      Kpi(tr(ar, 'Total credit', 'إجمالي الدائن'), '962,320', '', true, Icons.north_east),
      Kpi(tr(ar, 'Difference', 'الفرق'), '0', '', true, Icons.check_circle_outline),
    ],
  ),
];

ErpScreen? erpScreenById(String id) {
  for (final s in erpScreens) {
    if (s.id == id) return s;
  }
  return null;
}
