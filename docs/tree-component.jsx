/* global React, GLIcon, DSButton */
// GeniusLink DS — Account Tree component engine.
// Recursive 5-level chart-of-accounts hierarchy with bilingual labels,
// roll-up balances, type filters, expand/collapse and a recursive search
// with live match highlighting. Exports AccountTreeLive + a few atoms to window.

(function () {

/* ════════════════════════════════════════════════════════════
   DATA — leaves carry an explicit `bal`; group totals roll up
   so every figure reconciles. Depth 0 → 4 (five levels).
   ════════════════════════════════════════════════════════════ */
const TREE = [
  { code: '1000', name: 'Assets', ar: 'الأصول', type: 'Asset', children: [
    { code: '1100', name: 'Current Assets', ar: 'الأصول المتداولة', type: 'Asset', children: [
      { code: '1110', name: 'Cash & Cash Equivalents', ar: 'النقد وما في حكمه', type: 'Asset', children: [
        { code: '1111', name: 'Bank Accounts', ar: 'الحسابات البنكية', type: 'Asset', children: [
          { code: '1111-01', name: 'Al Rajhi Bank — Main', ar: 'مصرف الراجحي — الرئيسي', type: 'Asset', bal: 186420 },
          { code: '1111-02', name: 'NCB — Riyadh Branch', ar: 'الأهلي — فرع الرياض', type: 'Asset', bal: 92300 },
          { code: '1111-03', name: 'Riyad Bank — USD', ar: 'بنك الرياض — دولار', type: 'Asset', bal: 41250 },
        ] },
        { code: '1112', name: 'Cash on Hand', ar: 'النقد في الصندوق', type: 'Asset', children: [
          { code: '1112-01', name: 'Main Cash Box', ar: 'الصندوق الرئيسي', type: 'Asset', bal: 18500 },
          { code: '1112-02', name: 'Petty Cash', ar: 'المصروفات النثرية', type: 'Asset', bal: 3200 },
        ] },
      ] },
      { code: '1120', name: 'Trade Receivables', ar: 'الذمم المدينة', type: 'Asset', children: [
        { code: '1121', name: 'Local Customers', ar: 'عملاء محليون', type: 'Asset', children: [
          { code: '1121-01', name: 'Retail Customers', ar: 'عملاء التجزئة', type: 'Asset', bal: 64800 },
          { code: '1121-02', name: 'Wholesale Customers', ar: 'عملاء الجملة', type: 'Asset', bal: 88600 },
        ] },
        { code: '1122', name: 'Export Customers', ar: 'عملاء التصدير', type: 'Asset', children: [
          { code: '1122-01', name: 'GCC Customers', ar: 'عملاء دول الخليج', type: 'Asset', bal: 37400 },
        ] },
      ] },
      { code: '1130', name: 'Inventory', ar: 'المخزون', type: 'Asset', children: [
        { code: '1131', name: 'Finished Goods', ar: 'بضائع تامة الصنع', type: 'Asset', children: [
          { code: '1131-01', name: 'Warehouse A', ar: 'المستودع أ', type: 'Asset', bal: 124000 },
          { code: '1131-02', name: 'Warehouse B', ar: 'المستودع ب', type: 'Asset', bal: 76500 },
        ] },
        { code: '1132', name: 'Raw Materials', ar: 'المواد الخام', type: 'Asset', children: [
          { code: '1132-01', name: 'Steel & Metals', ar: 'الحديد والمعادن', type: 'Asset', bal: 54200 },
        ] },
      ] },
    ] },
    { code: '1500', name: 'Non-Current Assets', ar: 'الأصول غير المتداولة', type: 'Asset', children: [
      { code: '1510', name: 'Property & Equipment', ar: 'الممتلكات والمعدات', type: 'Asset', children: [
        { code: '1511', name: 'Machinery', ar: 'الآلات', type: 'Asset', children: [
          { code: '1511-01', name: 'Production Line 1', ar: 'خط الإنتاج 1', type: 'Asset', bal: 210000 },
          { code: '1511-02', name: 'Production Line 2', ar: 'خط الإنتاج 2', type: 'Asset', bal: 145000 },
        ] },
        { code: '1512', name: 'Vehicles', ar: 'المركبات', type: 'Asset', children: [
          { code: '1512-01', name: 'Delivery Fleet', ar: 'أسطول التوصيل', type: 'Asset', bal: 88000 },
          { code: '1512-02', name: 'Company Cars', ar: 'سيارات الشركة', type: 'Asset', bal: 52000 },
        ] },
      ] },
      { code: '1520', name: 'Intangible Assets', ar: 'الأصول غير الملموسة', type: 'Asset', children: [
        { code: '1521', name: 'Software Licenses', ar: 'تراخيص البرمجيات', type: 'Asset', children: [
          { code: '1521-01', name: 'ERP License', ar: 'رخصة نظام تخطيط الموارد', type: 'Asset', bal: 36000 },
        ] },
      ] },
    ] },
  ] },
  { code: '2000', name: 'Liabilities', ar: 'الخصوم', type: 'Liability', children: [
    { code: '2100', name: 'Current Liabilities', ar: 'الخصوم المتداولة', type: 'Liability', children: [
      { code: '2110', name: 'Trade Payables', ar: 'الذمم الدائنة', type: 'Liability', children: [
        { code: '2111', name: 'Local Suppliers', ar: 'موردون محليون', type: 'Liability', children: [
          { code: '2111-01', name: 'Material Suppliers', ar: 'موردو المواد', type: 'Liability', bal: 92400 },
          { code: '2111-02', name: 'Service Providers', ar: 'مزودو الخدمات', type: 'Liability', bal: 38600 },
        ] },
        { code: '2112', name: 'Foreign Suppliers', ar: 'موردون أجانب', type: 'Liability', children: [
          { code: '2112-01', name: 'Asia Imports', ar: 'واردات آسيا', type: 'Liability', bal: 64200 },
        ] },
      ] },
      { code: '2120', name: 'Accrued Expenses', ar: 'المصروفات المستحقة', type: 'Liability', children: [
        { code: '2121', name: 'Payroll Accruals', ar: 'مستحقات الرواتب', type: 'Liability', children: [
          { code: '2121-01', name: 'Salaries Payable', ar: 'رواتب مستحقة', type: 'Liability', bal: 48500 },
          { code: '2121-02', name: 'End of Service', ar: 'مكافأة نهاية الخدمة', type: 'Liability', bal: 31200 },
        ] },
        { code: '2122', name: 'Tax Accruals', ar: 'المستحقات الضريبية', type: 'Liability', children: [
          { code: '2122-01', name: 'VAT Payable', ar: 'ضريبة القيمة المضافة', type: 'Liability', bal: 27800 },
        ] },
      ] },
    ] },
    { code: '2500', name: 'Non-Current Liabilities', ar: 'الخصوم غير المتداولة', type: 'Liability', children: [
      { code: '2510', name: 'Long-Term Loans', ar: 'القروض طويلة الأجل', type: 'Liability', children: [
        { code: '2511', name: 'Bank Loans', ar: 'القروض البنكية', type: 'Liability', children: [
          { code: '2511-01', name: 'Equipment Loan', ar: 'قرض المعدات', type: 'Liability', bal: 180000 },
          { code: '2511-02', name: 'Expansion Loan', ar: 'قرض التوسعة', type: 'Liability', bal: 120000 },
        ] },
      ] },
    ] },
  ] },
  { code: '3000', name: 'Equity', ar: 'حقوق الملكية', type: 'Equity', children: [
    { code: '3100', name: 'Paid-In Capital', ar: 'رأس المال المدفوع', type: 'Equity', children: [
      { code: '3110', name: 'Share Capital', ar: 'رأس مال الأسهم', type: 'Equity', children: [
        { code: '3111', name: 'Founders', ar: 'المؤسسون', type: 'Equity', children: [
          { code: '3111-01', name: 'Founder A', ar: 'المؤسس أ', type: 'Equity', bal: 300000 },
          { code: '3111-02', name: 'Founder B', ar: 'المؤسس ب', type: 'Equity', bal: 200000 },
        ] },
      ] },
    ] },
    { code: '3200', name: 'Retained Earnings', ar: 'الأرباح المحتجزة', type: 'Equity', children: [
      { code: '3210', name: 'Prior Years', ar: 'سنوات سابقة', type: 'Equity', children: [
        { code: '3211', name: 'Accumulated', ar: 'المتراكمة', type: 'Equity', children: [
          { code: '3211-01', name: 'Accumulated Profit', ar: 'أرباح متراكمة', type: 'Equity', bal: 154470 },
        ] },
      ] },
      { code: '3220', name: 'Current Year', ar: 'السنة الحالية', type: 'Equity', children: [
        { code: '3221', name: 'Net Income', ar: 'صافي الدخل', type: 'Equity', children: [
          { code: '3221-01', name: 'YTD Profit', ar: 'ربح حتى تاريخه', type: 'Equity', bal: 61000 },
        ] },
      ] },
    ] },
  ] },
  { code: '4000', name: 'Income', ar: 'الإيرادات', type: 'Income', children: [
    { code: '4100', name: 'Operating Revenue', ar: 'إيرادات التشغيل', type: 'Income', children: [
      { code: '4110', name: 'Product Sales', ar: 'مبيعات المنتجات', type: 'Income', children: [
        { code: '4111', name: 'Domestic Sales', ar: 'المبيعات المحلية', type: 'Income', children: [
          { code: '4111-01', name: 'Retail Sales', ar: 'مبيعات التجزئة', type: 'Income', bal: 642000 },
          { code: '4111-02', name: 'Wholesale Sales', ar: 'مبيعات الجملة', type: 'Income', bal: 388000 },
        ] },
        { code: '4112', name: 'Export Sales', ar: 'مبيعات التصدير', type: 'Income', children: [
          { code: '4112-01', name: 'GCC Exports', ar: 'صادرات دول الخليج', type: 'Income', bal: 214000 },
        ] },
      ] },
      { code: '4120', name: 'Service Revenue', ar: 'إيرادات الخدمات', type: 'Income', children: [
        { code: '4121', name: 'Maintenance Contracts', ar: 'عقود الصيانة', type: 'Income', children: [
          { code: '4121-01', name: 'Annual Contracts', ar: 'عقود سنوية', type: 'Income', bal: 96000 },
        ] },
      ] },
    ] },
  ] },
  { code: '5000', name: 'Expenses', ar: 'المصروفات', type: 'Expense', children: [
    { code: '5100', name: 'Cost of Goods Sold', ar: 'تكلفة البضاعة المباعة', type: 'Expense', children: [
      { code: '5110', name: 'Direct Materials', ar: 'المواد المباشرة', type: 'Expense', children: [
        { code: '5111', name: 'Raw Material Cost', ar: 'تكلفة المواد الخام', type: 'Expense', children: [
          { code: '5111-01', name: 'Steel Purchases', ar: 'مشتريات الحديد', type: 'Expense', bal: 318000 },
        ] },
      ] },
      { code: '5120', name: 'Direct Labor', ar: 'العمالة المباشرة', type: 'Expense', children: [
        { code: '5121', name: 'Factory Wages', ar: 'أجور المصنع', type: 'Expense', children: [
          { code: '5121-01', name: 'Production Staff', ar: 'موظفو الإنتاج', type: 'Expense', bal: 142000 },
        ] },
      ] },
    ] },
    { code: '5500', name: 'Operating Expenses', ar: 'المصروفات التشغيلية', type: 'Expense', children: [
      { code: '5510', name: 'Administrative', ar: 'إدارية', type: 'Expense', children: [
        { code: '5511', name: 'Salaries & Benefits', ar: 'الرواتب والمزايا', type: 'Expense', children: [
          { code: '5511-01', name: 'Admin Salaries', ar: 'رواتب إدارية', type: 'Expense', bal: 188000 },
        ] },
        { code: '5512', name: 'Rent & Utilities', ar: 'الإيجار والمرافق', type: 'Expense', children: [
          { code: '5512-01', name: 'Office Rent', ar: 'إيجار المكتب', type: 'Expense', bal: 72000 },
        ] },
      ] },
    ] },
  ] },
];

const TYPE_DOT = { Asset: '#4A7CFF', Liability: '#F97316', Equity: '#1DB88A', Income: '#38BDF8', Expense: '#EF4444' };
const TYPE_NATURE = { Asset: 'debit', Expense: 'debit', Liability: 'credit', Equity: 'credit', Income: 'credit' };
const TYPE_ORDER = ['Asset', 'Liability', 'Equity', 'Income', 'Expense'];

/* ── tree maths ── */
function nodeTotal(n) { return n.children ? n.children.reduce((s, c) => s + nodeTotal(c), 0) : (n.bal || 0); }
function leafCount(n) { return n.children ? n.children.reduce((s, c) => s + leafCount(c), 0) : 1; }
const fmt = (n) => n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const fmtShort = (n) => { if (n >= 1e6) return (n / 1e6).toFixed(2) + 'M'; if (n >= 1e3) return Math.round(n / 1e3) + 'K'; return String(n); };
function groupCodes(nodes, maxD = Infinity, d = 0, out = []) {
  nodes.forEach((n) => { if (n.children && n.children.length) { if (d <= maxD) out.push(n.code); groupCodes(n.children, maxD, d + 1, out); } });
  return out;
}
// recursive search filter — keeps a node if it (or any descendant) matches q
function filterTree(nodes, q) {
  const needle = q.trim().toLowerCase();
  if (!needle) return nodes;
  const walk = (n) => {
    const self = (n.code + ' ' + n.name + ' ' + n.ar).toLowerCase().includes(needle);
    const kids = n.children ? n.children.map(walk).filter(Boolean) : null;
    if (self) return n;                        // keep whole subtree under a match
    if (kids && kids.length) return { ...n, children: kids };
    return null;
  };
  return nodes.map(walk).filter(Boolean);
}
function countMatches(nodes, q) {
  const needle = q.trim().toLowerCase();
  if (!needle) return 0;
  let n = 0;
  const walk = (node) => {
    if ((node.code + ' ' + node.name + ' ' + node.ar).toLowerCase().includes(needle)) n++;
    (node.children || []).forEach(walk);
  };
  nodes.forEach(walk);
  return n;
}

/* ── flatten the currently-visible nodes (respecting expansion / search) ── */
function flattenVisible(nodes, expanded, searching, out = []) {
  nodes.forEach((n) => {
    out.push(n);
    const open = searching || expanded.has(n.code);
    if (n.children && n.children.length && open) flattenVisible(n.children, expanded, searching, out);
  });
  return out;
}
function parentOf(nodes, code, parent = null) {
  for (const n of nodes) {
    if (n.code === code) return parent;
    if (n.children) { const hit = parentOf(n.children, code, n); if (hit !== undefined && hit !== null) return hit; if (hit === null && n.children.some((c) => c.code === code)) return n; }
  }
  return null;
}

/* ── shared keyboard navigation hook ──
   Wires ↑↓ move · ←→ collapse/expand-or-step · Home/End · Enter/Space
   open-leaf/toggle-group · / focus search · Esc clear · * expand all
   · \ collapse all · ? cheatsheet. Returns an onKeyDown for the tree body. */
function useTreeKeyboard({ roots, expanded, setExpanded, searching, focusId, setFocusId, onOpen, searchRef, expandAll, collapseAll, clearQuery, openHelp }) {
  return React.useCallback((e) => {
    // global-ish keys
    if (e.key === '/') { e.preventDefault(); searchRef.current && searchRef.current.focus(); return; }
    if (e.key === '?') { e.preventDefault(); openHelp && openHelp(); return; }
    if (e.key === '*') { e.preventDefault(); expandAll(); return; }
    if (e.key === '\\') { e.preventDefault(); collapseAll(); return; }

    const flat = flattenVisible(roots, expanded, searching);
    if (!flat.length) return;
    const idx = flat.findIndex((n) => n.code === focusId);
    const cur = idx >= 0 ? flat[idx] : null;
    const hasKids = (n) => n && n.children && n.children.length;

    switch (e.key) {
      case 'ArrowDown': e.preventDefault(); setFocusId(flat[Math.min(idx < 0 ? 0 : idx + 1, flat.length - 1)].code); break;
      case 'ArrowUp': e.preventDefault(); setFocusId(flat[Math.max(idx < 0 ? 0 : idx - 1, 0)].code); break;
      case 'Home': e.preventDefault(); setFocusId(flat[0].code); break;
      case 'End': e.preventDefault(); setFocusId(flat[flat.length - 1].code); break;
      case 'ArrowRight':
        e.preventDefault();
        if (hasKids(cur)) {
          if (!searching && !expanded.has(cur.code)) setExpanded((p) => new Set(p).add(cur.code));
          else setFocusId(cur.children[0].code);
        }
        break;
      case 'ArrowLeft':
        e.preventDefault();
        if (hasKids(cur) && !searching && expanded.has(cur.code)) { setExpanded((p) => { const n = new Set(p); n.delete(cur.code); return n; }); }
        else if (cur) { const par = parentOf(roots, cur.code); if (par) setFocusId(par.code); }
        break;
      case 'Enter': case ' ':
        e.preventDefault();
        if (!cur) break;
        if (hasKids(cur)) setExpanded((p) => { const n = new Set(p); n.has(cur.code) ? n.delete(cur.code) : n.add(cur.code); return n; });
        else onOpen && onOpen(cur);
        break;
      default: break;
    }
  }, [roots, expanded, setExpanded, searching, focusId, setFocusId, onOpen, searchRef, expandAll, collapseAll, openHelp]);
}

/* ── keyboard-shortcuts cheatsheet modal ── */
const SHORTCUTS = [
  ['↑  ↓', 'Move between rows'],
  ['←  →', 'Collapse / step out · expand / step in'],
  ['Home  End', 'Jump to first / last row'],
  ['Enter  Space', 'Open a leaf · toggle a group'],
  ['/', 'Focus the search field'],
  ['Esc', 'Clear the search'],
  ['*  \\', 'Expand all · collapse all'],
  ['?', 'This cheatsheet'],
];
function ShortcutsHelp({ onClose }) {
  React.useEffect(() => {
    const h = (e) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [onClose]);
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }}>
      <div onClick={(e) => e.stopPropagation()} style={{ width: 440, maxWidth: '90vw', background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-lg)', boxShadow: '0 24px 60px rgba(0,0,0,.4)', padding: '20px 22px 22px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 14 }}>
          <GLIcon name="command" size={17} color="var(--gl-blue-500)" />
          <span style={{ fontWeight: 700, fontSize: 16, color: 'var(--gl-fg-1)' }}>Keyboard shortcuts</span>
          <span style={{ flex: 1 }} />
          <button type="button" onClick={onClose} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', display: 'flex', padding: 4 }}><GLIcon name="close" size={15} /></button>
        </div>
        {SHORTCUTS.map(([k, d]) => (
          <div key={k} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '5px 0' }}>
            <span style={{ width: 130, fontFamily: 'var(--gl-font-mono)', fontSize: 12.5, fontWeight: 700, color: 'var(--gl-fg-2)' }}>{k}</span>
            <span style={{ fontSize: 13, color: 'var(--gl-fg-3)' }}>{d}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── small icon-only button (help / etc) ── */
function IconBtn({ name, title, onClick }) {
  const [hv, setHv] = React.useState(false);
  return (
    <button type="button" onClick={onClick} title={title} onMouseEnter={() => setHv(true)} onMouseLeave={() => setHv(false)}
      style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 36, height: 36, borderRadius: 'var(--gl-radius-sm)', cursor: 'pointer', color: hv ? 'var(--gl-fg-1)' : 'var(--gl-fg-2)', background: hv ? 'var(--gl-hover)' : 'transparent', border: '1px solid var(--gl-border-strong)', transition: 'background var(--gl-dur-base)' }}>
      <GLIcon name={name} size={16} />
    </button>
  );
}

/* ── highlight matched substring inside a label ── */
function Highlight({ text, q, style }) {
  const str = String(text);
  const needle = (q || '').trim().toLowerCase();
  if (!needle) return <span style={style}>{str}</span>;
  const idx = str.toLowerCase().indexOf(needle);
  if (idx < 0) return <span style={style}>{str}</span>;
  return (
    <span style={style}>
      {str.slice(0, idx)}
      <mark style={{ background: 'color-mix(in srgb, var(--gl-blue-500) 32%, transparent)', color: 'inherit', borderRadius: 2, padding: '0 1px', boxShadow: '0 0 0 1px color-mix(in srgb, var(--gl-blue-500) 40%, transparent)' }}>{str.slice(idx, idx + needle.length)}</mark>
      {str.slice(idx + needle.length)}
    </span>
  );
}

/* ── DR / CR nature pill ── */
function NaturePill({ nature }) {
  const dr = nature === 'debit';
  const c = dr ? 'var(--gl-blue-500)' : 'var(--gl-warning-500)';
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', height: 19, padding: '0 8px', borderRadius: 999, fontFamily: 'var(--gl-font-mono)', fontSize: 10, fontWeight: 700, letterSpacing: '.04em', color: c, background: `color-mix(in srgb, ${c} 15%, transparent)`, border: `1px solid color-mix(in srgb, ${c} 35%, transparent)` }}>
      {dr ? 'DR' : 'CR'}
    </span>
  );
}

/* ── chevron-rotating tool button (Expand all / Collapse) ── */
function ToolBtn({ up, onClick, children }) {
  const [hv, setHv] = React.useState(false);
  return (
    <button type="button" onClick={onClick} onMouseEnter={() => setHv(true)} onMouseLeave={() => setHv(false)}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 7, height: 36, padding: '0 13px', borderRadius: 'var(--gl-radius-sm)', cursor: 'pointer', fontFamily: 'var(--gl-font-body)', fontWeight: 500, fontSize: 13, color: 'var(--gl-fg-1)', background: hv ? 'var(--gl-hover)' : 'transparent', border: '1px solid var(--gl-border-strong)', transition: 'background var(--gl-dur-base)' }}>
      <span style={{ display: 'inline-flex', transform: up ? 'rotate(180deg)' : 'none', color: 'var(--gl-fg-2)' }}><GLIcon name="chevD" size={15} /></span>
      {children}
    </button>
  );
}

/* ── type filter chip ── */
function FilterChip({ active, color, onClick, children }) {
  const [hover, setHover] = React.useState(false);
  return (
    <button type="button" onClick={onClick} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 7, height: 30, padding: '0 12px', borderRadius: 999, cursor: 'pointer', fontFamily: 'var(--gl-font-body)', fontWeight: 700, fontSize: 11, letterSpacing: '.03em',
        background: active ? (color ? `${color}1F` : 'var(--gl-hover)') : (hover ? 'var(--gl-hover)' : 'transparent'),
        border: `1px solid ${active ? (color || 'var(--gl-border-strong)') : 'var(--gl-border)'}`,
        color: active ? (color || 'var(--gl-fg-1)') : 'var(--gl-fg-2)', transition: 'all var(--gl-dur-fast) var(--gl-ease-standard)' }}>
      {color && <span style={{ width: 7, height: 7, borderRadius: 999, background: color }} />}
      {children}
    </button>
  );
}

/* ── KPI card ── */
function KpiCard({ label, ar, value, accent, sub }) {
  return (
    <div style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow)', padding: '15px 17px', position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column', gap: 9 }}>
      <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, background: accent }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 8 }}>
        <span style={{ fontWeight: 700, fontSize: 10, letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--gl-fg-3)' }}>{label}</span>
        <span dir="rtl" style={{ fontFamily: 'var(--gl-font-arabic)', fontSize: 11, color: 'var(--gl-fg-4)' }}>{ar}</span>
      </div>
      <div style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 20, fontWeight: 700, color: 'var(--gl-fg-1)', letterSpacing: '-0.01em' }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: 'var(--gl-fg-3)' }}>{sub}</div>}
    </div>
  );
}

/* ════════════════════════════════════════════════════════════
   ROW — one node, recursive. Highlights search matches, draws
   connector lines, type dot, roll-up balance and share bar.
   ════════════════════════════════════════════════════════════ */
function TreeNode({ node, depth, expanded, toggle, onOpen, onFocus, rootTotal, forceOpen, query, selected, focusId }) {
  const [hover, setHover] = React.useState(false);
  const hasKids = node.children && node.children.length > 0;
  const open = forceOpen || expanded.has(node.code);
  const total = nodeTotal(node);
  const share = rootTotal > 0 ? total / rootTotal : 0;
  const dot = TYPE_DOT[node.type];
  const nature = TYPE_NATURE[node.type];
  const indent = 14 + depth * 22;
  const isSel = selected === node.code;
  const isFocus = focusId === node.code;

  return (
    <div>
      <div onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
        onClick={() => { onFocus && onFocus(node.code); hasKids ? toggle(node.code) : (onOpen && onOpen(node)); }}
        style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 64px 168px 26px', gap: 12, alignItems: 'center',
          padding: '9px 12px', paddingLeft: indent, borderRadius: 5, cursor: 'pointer',
          background: isSel ? 'color-mix(in srgb, var(--gl-blue-500) 12%, transparent)' : (hover ? 'var(--gl-hover)' : 'transparent'),
          boxShadow: isSel ? 'inset 0 0 0 1px color-mix(in srgb, var(--gl-blue-500) 45%, transparent)' : (isFocus ? 'inset 0 0 0 1.5px color-mix(in srgb, var(--gl-blue-500) 70%, transparent)' : 'none'),
          transition: 'background var(--gl-dur-fast) ease' }}>
        {/* account cell */}
        <span style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0 }}>
          <span style={{ width: 14, display: 'flex', color: 'var(--gl-fg-3)', flexShrink: 0 }}>
            {hasKids ? <span style={{ display: 'inline-flex', transform: open ? 'none' : 'rotate(-90deg)', transition: 'transform var(--gl-dur-moderate) var(--gl-ease-standard)' }}><GLIcon name="chevD" size={13} /></span> : null}
          </span>
          <span style={{ width: 7, height: 7, borderRadius: 999, background: dot, flexShrink: 0, boxShadow: depth === 0 ? `0 0 0 3px ${dot}22` : 'none' }} />
          <Highlight text={node.code} q={query} style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 11.5, color: 'var(--gl-fg-3)', flexShrink: 0, minWidth: depth === 0 ? 34 : undefined }} />
          <Highlight text={node.name} q={query} style={{ fontSize: 13, fontWeight: depth === 0 ? 700 : (depth === 1 ? 600 : 500), color: depth >= 3 ? 'var(--gl-fg-2)' : 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} />
          <span dir="rtl" style={{ flexShrink: 0 }}><Highlight text={node.ar} q={query} style={{ fontFamily: 'var(--gl-font-arabic)', fontSize: 12, color: 'var(--gl-fg-4)' }} /></span>
          {hasKids && (
            <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 9.5, fontWeight: 700, letterSpacing: '.02em', color: 'var(--gl-fg-3)', background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border)', borderRadius: 999, padding: '1px 7px', flexShrink: 0 }}>{leafCount(node)}</span>
          )}
        </span>
        {/* nature */}
        <span style={{ display: 'flex' }}><NaturePill nature={nature} /></span>
        {/* balance + share bar */}
        <span style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4 }}>
          <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 12.5, fontWeight: depth === 0 ? 700 : 500, color: 'var(--gl-fg-1)' }}>{fmt(total)}</span>
          <span style={{ width: '100%', height: 3, borderRadius: 999, background: 'var(--gl-input-bg)', overflow: 'hidden' }}>
            <span style={{ display: 'block', height: '100%', width: `${Math.max(share * 100, 1.5)}%`, background: dot, opacity: depth === 0 ? 0.9 : 0.55, borderRadius: 999 }} />
          </span>
        </span>
        {/* open affordance */}
        <span style={{ display: 'flex', justifyContent: 'flex-end', color: 'var(--gl-fg-4)' }}>
          {!hasKids && hover && <GLIcon name="chevR" size={13} />}
        </span>
      </div>
      {hasKids && open && (
        <div style={{ position: 'relative' }}>
          <div style={{ position: 'absolute', left: indent + 7, top: 0, bottom: 13, width: 1, background: 'var(--gl-border)' }} />
          {node.children.map((c) => (
            <TreeNode key={c.code} node={c} depth={depth + 1} expanded={expanded} toggle={toggle} onOpen={onOpen} onFocus={onFocus} rootTotal={rootTotal} forceOpen={forceOpen} query={query} selected={selected} focusId={focusId} />
          ))}
        </div>
      )}
    </div>
  );
}

/* ════════════════════════════════════════════════════════════
   LIVE WIDGET — the whole interactive Account Tree.
   ════════════════════════════════════════════════════════════ */
const SAMPLE_QUERIES = ['1111', 'Bank', 'البنك', 'Cash', 'Loan', '5512'];

function AccountTreeLive() {
  const [expanded, setExpanded] = React.useState(() => new Set(groupCodes(TREE, 1)));
  const [query, setQuery] = React.useState('');
  const [typeFilter, setTypeFilter] = React.useState('all');
  const [searchFocus, setSearchFocus] = React.useState(false);
  const [selected, setSelected] = React.useState(null);
  const [focusId, setFocusId] = React.useState(null);
  const [help, setHelp] = React.useState(false);
  const inputRef = React.useRef(null);

  const toggle = (code) => setExpanded((prev) => { const next = new Set(prev); next.has(code) ? next.delete(code) : next.add(code); return next; });
  const expandAll = () => setExpanded(new Set(groupCodes(TREE)));
  const collapseAll = () => setExpanded(new Set());
  const runQuery = (q) => { setQuery(q); if (inputRef.current) inputRef.current.focus(); };
  const openLeaf = (node) => { setSelected(node.code); setFocusId(node.code); };

  const byType = typeFilter === 'all' ? TREE : TREE.filter((n) => n.type === typeFilter);
  const visible = filterTree(byType, query);
  const searching = query.trim().length > 0;
  const matchCount = countMatches(byType, query);

  const onKeyDown = useTreeKeyboard({ roots: visible, expanded, setExpanded, searching, focusId, setFocusId, onOpen: openLeaf, searchRef: inputRef, expandAll, collapseAll, clearQuery: () => runQuery(''), openHelp: () => setHelp(true) });

  const totalOf = (t) => TREE.filter((n) => n.type === t).reduce((s, n) => s + nodeTotal(n), 0);
  const assets = totalOf('Asset'), liabilities = totalOf('Liability'), equity = totalOf('Equity');
  const income = totalOf('Income'), expense = totalOf('Expense');
  const balanced = Math.abs(assets - (liabilities + equity)) < 0.01;
  const totalAccounts = TREE.reduce((s, n) => s + leafCount(n), 0);
  const visibleAccounts = visible.reduce((s, n) => s + leafCount(n), 0);

  const types = [{ id: 'all', label: 'All', color: null }, ...TYPE_ORDER.map((t) => ({ id: t, label: t, color: TYPE_DOT[t] }))];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* KPI summary */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(190px, 1fr))', gap: 14 }}>
        <KpiCard label="Total Assets" ar="الأصول" value={fmt(assets)} accent={TYPE_DOT.Asset} sub="SAR · debit balance" />
        <KpiCard label="Total Liabilities" ar="الخصوم" value={fmt(liabilities)} accent={TYPE_DOT.Liability} sub="SAR · credit balance" />
        <KpiCard label="Total Equity" ar="حقوق الملكية" value={fmt(equity)} accent={TYPE_DOT.Equity} sub="SAR · credit balance" />
        <KpiCard label="Net Income" ar="صافي الدخل" value={fmt(income - expense)} accent={TYPE_DOT.Income} sub={`Income ${fmtShort(income)} − Expense ${fmtShort(expense)} SAR`} />
      </div>

      {/* Toolbar */}
      <div style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow)', padding: 18, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between' }}>
          {/* search */}
          <div style={{ position: 'relative', flex: '1 1 300px', minWidth: 240, height: 40, display: 'flex', alignItems: 'center',
            background: 'var(--gl-input-bg)', borderRadius: 'var(--gl-radius-sm)',
            border: `${searchFocus ? 2 : 1}px solid ${searchFocus ? 'var(--gl-blue-500)' : 'var(--gl-border-strong)'}`,
            padding: `0 ${searchFocus ? 13 : 14}px`, transition: 'border-color var(--gl-dur-base) ease' }}>
            <GLIcon name="search" size={15} color="var(--gl-fg-3)" />
            <input ref={inputRef} value={query} onChange={(e) => setQuery(e.target.value)} onFocus={() => setSearchFocus(true)} onBlur={() => setSearchFocus(false)}
              onKeyDown={(e) => { if (e.key === 'Escape') { runQuery(''); } }}
              placeholder="Search by code, English or Arabic name…   ( / )"
              style={{ flex: 1, height: '100%', border: 'none', outline: 'none', background: 'transparent', color: 'var(--gl-fg-1)', fontFamily: 'var(--gl-font-body)', fontSize: 13.5, padding: '0 10px' }} />
            {searching && <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 11, color: 'var(--gl-fg-3)', flexShrink: 0, marginInlineEnd: 6 }}>{matchCount}</span>}
            {query && (
              <button type="button" onClick={() => runQuery('')} title="Clear" style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', display: 'flex', padding: 4 }}>
                <GLIcon name="close" size={13} />
              </button>
            )}
          </div>
          {/* expand controls */}
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <ToolBtn onClick={expandAll}>Expand all</ToolBtn>
            <ToolBtn up onClick={collapseAll}>Collapse</ToolBtn>
            <IconBtn name="keyboard" title="Keyboard shortcuts  ·  ?" onClick={() => setHelp(true)} />
          </div>
        </div>

        {/* quick-search demo chips */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
          <span style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--gl-fg-3)', marginInlineEnd: 2 }}>Try</span>
          {SAMPLE_QUERIES.map((q) => {
            const on = query === q;
            return (
              <button key={q} type="button" onClick={() => runQuery(q)}
                style={{ height: 26, padding: '0 10px', borderRadius: 999, cursor: 'pointer', fontFamily: 'var(--gl-font-mono)', fontSize: 11.5,
                  background: on ? 'color-mix(in srgb, var(--gl-blue-500) 18%, transparent)' : 'var(--gl-input-bg)',
                  border: `1px solid ${on ? 'var(--gl-blue-500)' : 'var(--gl-border)'}`, color: on ? 'var(--gl-blue-500)' : 'var(--gl-fg-2)', transition: 'all var(--gl-dur-fast) ease' }}>
                {q}
              </button>
            );
          })}
        </div>

        {/* type chips + balance check */}
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
          {types.map((t) => (
            <FilterChip key={t.id} active={typeFilter === t.id} color={t.color} onClick={() => setTypeFilter(t.id)}>{t.label}</FilterChip>
          ))}
          <span style={{ flex: 1 }} />
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 11, fontWeight: 700, letterSpacing: '.04em', textTransform: 'uppercase',
            color: balanced ? 'var(--gl-success-500)' : 'var(--gl-danger-500)',
            background: balanced ? 'rgba(29,184,138,.12)' : 'rgba(239,68,68,.12)',
            border: `1px solid ${balanced ? 'rgba(29,184,138,.4)' : 'rgba(239,68,68,.4)'}`, borderRadius: 999, padding: '6px 12px' }}>
            <GLIcon name={balanced ? 'check' : 'info'} size={13} />
            {balanced ? 'Balanced · A = L + E' : 'Out of balance'}
          </span>
        </div>
      </div>

      {/* The tree */}
      <div tabIndex={0} onKeyDown={onKeyDown} role="tree" aria-label="Chart of accounts"
        style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow)', overflow: 'hidden', outline: 'none' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 12, padding: '18px 24px 0' }}>
          <div style={{ display: 'flex', gap: 11, alignItems: 'baseline' }}>
            <div style={{ width: 4, height: 18, borderRadius: 12, background: 'var(--gl-blue-500)', alignSelf: 'center' }} />
            <div>
              <div style={{ fontWeight: 700, fontSize: 15, color: 'var(--gl-fg-1)' }}>Chart of Accounts Hierarchy</div>
              <div style={{ fontSize: 12, color: 'var(--gl-fg-3)', marginTop: 2 }}>5 levels · click or use ↑↓ ← → · Enter opens a leaf · press ? for shortcuts</div>
            </div>
          </div>
          <span style={{ fontWeight: 700, fontSize: 10, letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--gl-fg-3)', whiteSpace: 'nowrap' }}>
            {searching ? `${visibleAccounts} of ${totalAccounts}` : `${totalAccounts} accounts`}
          </span>
        </div>
        {/* column header */}
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 64px 168px 26px', gap: 12, alignItems: 'center', padding: '14px 28px 12px', margin: '14px 16px 0', borderBottom: '1px solid var(--gl-border)', fontWeight: 700, fontSize: 9.5, letterSpacing: '.08em', textTransform: 'uppercase', color: 'var(--gl-fg-3)' }}>
          <span>Account · الحساب</span>
          <span>Nature</span>
          <span style={{ textAlign: 'right' }}>Balance (SAR)</span>
          <span />
        </div>
        <div style={{ padding: '8px 16px 20px' }}>
          {visible.length === 0 ? (
            <div style={{ padding: '48px 16px', textAlign: 'center', color: 'var(--gl-fg-3)' }}>
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12, color: 'var(--gl-fg-4)' }}><GLIcon name="searchO" size={26} /></div>
              <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--gl-fg-2)' }}>No accounts match “{query}”</div>
              <div style={{ fontSize: 12, marginTop: 4 }}>Try a different code or name, or clear the filters.</div>
            </div>
          ) : (
            visible.map((n) => (
              <TreeNode key={n.code} node={n} depth={0} expanded={expanded} toggle={toggle}
                onOpen={openLeaf} onFocus={setFocusId} rootTotal={nodeTotal(n)} forceOpen={searching} query={query} selected={selected} focusId={focusId} />
            ))
          )}
        </div>
        {/* selection footer — proves leaf click opens a ledger */}
        {selected && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 24px', borderTop: '1px solid var(--gl-border)', background: 'color-mix(in srgb, var(--gl-blue-500) 7%, transparent)' }}>
            <GLIcon name="doc" size={15} color="var(--gl-blue-500)" />
            <span style={{ fontSize: 12.5, color: 'var(--gl-fg-2)' }}>Opened ledger for account <strong style={{ fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-1)' }}>{selected}</strong></span>
            <span style={{ flex: 1 }} />
            <button type="button" onClick={() => setSelected(null)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', display: 'flex', padding: 4 }}><GLIcon name="close" size={13} /></button>
          </div>
        )}
      </div>
      {help && <ShortcutsHelp onClose={() => setHelp(false)} />}
    </div>
  );
}

Object.assign(window, { AccountTreeLive, TreeNode, NaturePill, KpiCard, FilterChip, Highlight, ShortcutsHelp, IconBtn, useTreeKeyboard, flattenVisible, parentOf, GL_TREE: TREE, GL_TYPE_DOT: TYPE_DOT });
})();
