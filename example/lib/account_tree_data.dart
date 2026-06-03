// ============================================================
// Account Tree — sample data (chart of accounts).
// A five-level GeniusLink chart of accounts. Leaf accounts carry a `bal`;
// group balances roll up from their descendants so every figure reconciles.
// Each node: id = account code, label = English name, data = {ar, type, bal?}.
//   File: example/lib/account_tree_data.dart
// ============================================================

import 'package:geniuslink_design_system/geniuslink_tree.dart';

/// Compact node builder used only to author the sample tree below.
TreeNode _acc(String code, String en, String ar, String type, {int? bal, List<TreeNode> children = const []}) {
  return TreeNode(
    id: code,
    label: en,
    children: children,
    data: {'ar': ar, 'type': type, if (bal != null) 'bal': bal},
  );
}

/// The sample chart of accounts (5 levels · Asset / Liability / Equity / Income / Expense).
final List<TreeNode> kAccountTreeRoots = [
  _acc('1000', 'Assets', 'الأصول', 'Asset', children: [
    _acc('1100', 'Current Assets', 'الأصول المتداولة', 'Asset', children: [
      _acc('1110', 'Cash & Cash Equivalents', 'النقد وما في حكمه', 'Asset', children: [
        _acc('1111', 'Bank Accounts', 'الحسابات البنكية', 'Asset', children: [
          _acc('1111-01', 'Al Rajhi Bank — Main', 'مصرف الراجحي — الرئيسي', 'Asset', bal: 186420),
          _acc('1111-02', 'NCB — Riyadh Branch', 'الأهلي — فرع الرياض', 'Asset', bal: 92300),
          _acc('1111-03', 'Riyad Bank — USD', 'بنك الرياض — دولار', 'Asset', bal: 41250),
        ]),
        _acc('1112', 'Cash on Hand', 'النقد في الصندوق', 'Asset', children: [
          _acc('1112-01', 'Main Cash Box', 'الصندوق الرئيسي', 'Asset', bal: 18500),
          _acc('1112-02', 'Petty Cash', 'المصروفات النثرية', 'Asset', bal: 3200),
        ]),
      ]),
      _acc('1120', 'Trade Receivables', 'الذمم المدينة', 'Asset', children: [
        _acc('1121', 'Local Customers', 'عملاء محليون', 'Asset', children: [
          _acc('1121-01', 'Retail Customers', 'عملاء التجزئة', 'Asset', bal: 64800),
          _acc('1121-02', 'Wholesale Customers', 'عملاء الجملة', 'Asset', bal: 88600),
        ]),
        _acc('1122', 'Export Customers', 'عملاء التصدير', 'Asset', children: [
          _acc('1122-01', 'GCC Customers', 'عملاء دول الخليج', 'Asset', bal: 37400),
        ]),
      ]),
      _acc('1130', 'Inventory', 'المخزون', 'Asset', children: [
        _acc('1131', 'Finished Goods', 'بضائع تامة الصنع', 'Asset', children: [
          _acc('1131-01', 'Warehouse A', 'المستودع أ', 'Asset', bal: 124000),
          _acc('1131-02', 'Warehouse B', 'المستودع ب', 'Asset', bal: 76500),
        ]),
        _acc('1132', 'Raw Materials', 'المواد الخام', 'Asset', children: [
          _acc('1132-01', 'Steel & Metals', 'الحديد والمعادن', 'Asset', bal: 54200),
        ]),
      ]),
    ]),
    _acc('1500', 'Non-Current Assets', 'الأصول غير المتداولة', 'Asset', children: [
      _acc('1510', 'Property & Equipment', 'الممتلكات والمعدات', 'Asset', children: [
        _acc('1511', 'Machinery', 'الآلات', 'Asset', children: [
          _acc('1511-01', 'Production Line 1', 'خط الإنتاج 1', 'Asset', bal: 210000),
          _acc('1511-02', 'Production Line 2', 'خط الإنتاج 2', 'Asset', bal: 145000),
        ]),
        _acc('1512', 'Vehicles', 'المركبات', 'Asset', children: [
          _acc('1512-01', 'Delivery Fleet', 'أسطول التوصيل', 'Asset', bal: 88000),
          _acc('1512-02', 'Company Cars', 'سيارات الشركة', 'Asset', bal: 52000),
        ]),
      ]),
      _acc('1520', 'Intangible Assets', 'الأصول غير الملموسة', 'Asset', children: [
        _acc('1521', 'Software Licenses', 'تراخيص البرمجيات', 'Asset', children: [
          _acc('1521-01', 'ERP License', 'رخصة نظام تخطيط الموارد', 'Asset', bal: 36000),
        ]),
      ]),
    ]),
  ]),
  _acc('2000', 'Liabilities', 'الخصوم', 'Liability', children: [
    _acc('2100', 'Current Liabilities', 'الخصوم المتداولة', 'Liability', children: [
      _acc('2110', 'Trade Payables', 'الذمم الدائنة', 'Liability', children: [
        _acc('2111', 'Local Suppliers', 'موردون محليون', 'Liability', children: [
          _acc('2111-01', 'Material Suppliers', 'موردو المواد', 'Liability', bal: 92400),
          _acc('2111-02', 'Service Providers', 'مزودو الخدمات', 'Liability', bal: 38600),
        ]),
        _acc('2112', 'Foreign Suppliers', 'موردون أجانب', 'Liability', children: [
          _acc('2112-01', 'Asia Imports', 'واردات آسيا', 'Liability', bal: 64200),
        ]),
      ]),
      _acc('2120', 'Accrued Expenses', 'المصروفات المستحقة', 'Liability', children: [
        _acc('2121', 'Payroll Accruals', 'مستحقات الرواتب', 'Liability', children: [
          _acc('2121-01', 'Salaries Payable', 'رواتب مستحقة', 'Liability', bal: 48500),
          _acc('2121-02', 'End of Service', 'مكافأة نهاية الخدمة', 'Liability', bal: 31200),
        ]),
        _acc('2122', 'Tax Accruals', 'المستحقات الضريبية', 'Liability', children: [
          _acc('2122-01', 'VAT Payable', 'ضريبة القيمة المضافة', 'Liability', bal: 27800),
        ]),
      ]),
    ]),
    _acc('2500', 'Non-Current Liabilities', 'الخصوم غير المتداولة', 'Liability', children: [
      _acc('2510', 'Long-Term Loans', 'القروض طويلة الأجل', 'Liability', children: [
        _acc('2511', 'Bank Loans', 'القروض البنكية', 'Liability', children: [
          _acc('2511-01', 'Equipment Loan', 'قرض المعدات', 'Liability', bal: 180000),
          _acc('2511-02', 'Expansion Loan', 'قرض التوسعة', 'Liability', bal: 120000),
        ]),
      ]),
    ]),
  ]),
  _acc('3000', 'Equity', 'حقوق الملكية', 'Equity', children: [
    _acc('3100', 'Paid-In Capital', 'رأس المال المدفوع', 'Equity', children: [
      _acc('3110', 'Share Capital', 'رأس مال الأسهم', 'Equity', children: [
        _acc('3111', 'Founders', 'المؤسسون', 'Equity', children: [
          _acc('3111-01', 'Founder A', 'المؤسس أ', 'Equity', bal: 300000),
          _acc('3111-02', 'Founder B', 'المؤسس ب', 'Equity', bal: 200000),
        ]),
      ]),
    ]),
    _acc('3200', 'Retained Earnings', 'الأرباح المحتجزة', 'Equity', children: [
      _acc('3210', 'Prior Years', 'سنوات سابقة', 'Equity', children: [
        _acc('3211', 'Accumulated', 'المتراكمة', 'Equity', children: [
          _acc('3211-01', 'Accumulated Profit', 'أرباح متراكمة', 'Equity', bal: 154470),
        ]),
      ]),
      _acc('3220', 'Current Year', 'السنة الحالية', 'Equity', children: [
        _acc('3221', 'Net Income', 'صافي الدخل', 'Equity', children: [
          _acc('3221-01', 'YTD Profit', 'ربح حتى تاريخه', 'Equity', bal: 61000),
        ]),
      ]),
    ]),
  ]),
  _acc('4000', 'Income', 'الإيرادات', 'Income', children: [
    _acc('4100', 'Operating Revenue', 'إيرادات التشغيل', 'Income', children: [
      _acc('4110', 'Product Sales', 'مبيعات المنتجات', 'Income', children: [
        _acc('4111', 'Domestic Sales', 'المبيعات المحلية', 'Income', children: [
          _acc('4111-01', 'Retail Sales', 'مبيعات التجزئة', 'Income', bal: 642000),
          _acc('4111-02', 'Wholesale Sales', 'مبيعات الجملة', 'Income', bal: 388000),
        ]),
        _acc('4112', 'Export Sales', 'مبيعات التصدير', 'Income', children: [
          _acc('4112-01', 'GCC Exports', 'صادرات دول الخليج', 'Income', bal: 214000),
        ]),
      ]),
      _acc('4120', 'Service Revenue', 'إيرادات الخدمات', 'Income', children: [
        _acc('4121', 'Maintenance Contracts', 'عقود الصيانة', 'Income', children: [
          _acc('4121-01', 'Annual Contracts', 'عقود سنوية', 'Income', bal: 96000),
        ]),
      ]),
    ]),
  ]),
  _acc('5000', 'Expenses', 'المصروفات', 'Expense', children: [
    _acc('5100', 'Cost of Goods Sold', 'تكلفة البضاعة المباعة', 'Expense', children: [
      _acc('5110', 'Direct Materials', 'المواد المباشرة', 'Expense', children: [
        _acc('5111', 'Raw Material Cost', 'تكلفة المواد الخام', 'Expense', children: [
          _acc('5111-01', 'Steel Purchases', 'مشتريات الحديد', 'Expense', bal: 318000),
        ]),
      ]),
      _acc('5120', 'Direct Labor', 'العمالة المباشرة', 'Expense', children: [
        _acc('5121', 'Factory Wages', 'أجور المصنع', 'Expense', children: [
          _acc('5121-01', 'Production Staff', 'موظفو الإنتاج', 'Expense', bal: 142000),
        ]),
      ]),
    ]),
    _acc('5500', 'Operating Expenses', 'المصروفات التشغيلية', 'Expense', children: [
      _acc('5510', 'Administrative', 'إدارية', 'Expense', children: [
        _acc('5511', 'Salaries & Benefits', 'الرواتب والمزايا', 'Expense', children: [
          _acc('5511-01', 'Admin Salaries', 'رواتب إدارية', 'Expense', bal: 188000),
        ]),
        _acc('5512', 'Rent & Utilities', 'الإيجار والمرافق', 'Expense', children: [
          _acc('5512-01', 'Office Rent', 'إيجار المكتب', 'Expense', bal: 72000),
        ]),
      ]),
    ]),
  ]),
];
