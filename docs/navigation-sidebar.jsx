/* global React, Icon, Logo */
// ────────────────────────────────────────────────────────────────
// NavigationSidebar.jsx — the GeniusLink navigation system, isolated.
//
// Structure (ported back into app.jsx once approved):
//   NavShell        — orchestrates the whole chrome + shared state
//     ├ AppBar      — logo · search field · workspace dropdown · user
//     ├ NavigationSidebar — nav rail/drawer (collapsible + responsive)
//     └ SearchDialog — command-palette modal opened from the search field
//
// Responsive: ≥1200 → sidebar open · ≥768 → collapsed rail · <768 → drawer.
// ────────────────────────────────────────────────────────────────

// ── mock nav data (mirrors app.jsx SCREENS subset used by the sidebar) ──
const NAV_SCREENS = [
  { id: 'login',         label: 'Sign In',             icon: 'lock',      section: 'Auth' },
  { id: 'signup',        label: 'Sign Up',             icon: 'user',      section: 'Auth' },
  { id: 'forgot',        label: 'Forgot Password',     icon: 'lock',      section: 'Auth' },
  { id: 'dashboard',     label: 'Dashboard',           icon: 'briefcase', section: 'Overview' },
  { id: 'invDashboard',  label: 'Inventory Dashboard', icon: 'scanner',   section: 'Overview' },
  { id: 'accountsHub',   label: 'Accounts',            icon: 'ledger',    section: 'Finance' },
  { id: 'ledgerHub',     label: 'Ledger',              icon: 'ledger',    section: 'Finance' },
  { id: 'bankingHub',    label: 'Banking',             icon: 'switch2',   section: 'Finance' },
  { id: 'reportsHub',    label: 'Reports',             icon: 'doc',       section: 'Finance' },
  { id: 'storesHub',     label: 'Inventory & Stores',  icon: 'store',     section: 'Operations' },
  { id: 'salesHub',      label: 'Sales',               icon: 'user',      section: 'Operations' },
  { id: 'procurementHub',label: 'Procurement',         icon: 'briefcase', section: 'Operations' },
  { id: 'configHub',     label: 'Configuration',       icon: 'compass',   section: 'Administration' },
  { id: 'adminHub',      label: 'Team & Access',       icon: 'user',      section: 'Administration' },
  { id: 'settingsHub',   label: 'Settings',            icon: 'settings',  section: 'Administration' },
];

const SIDEBAR_NAV = [
  { group: 'Auth',           items: ['login', 'signup', 'forgot'] },
  { group: 'Overview',       items: ['dashboard', 'invDashboard'] },
  { group: 'Finance',        items: ['accountsHub', 'ledgerHub', 'bankingHub', 'reportsHub'] },
  { group: 'Operations',     items: ['storesHub', 'salesHub', 'procurementHub'] },
  { group: 'Administration', items: ['configHub', 'adminHub', 'settingsHub'] },
];

const SECTION_LABELS = {
  Auth: 'Authentication', Overview: 'Overview', Finance: 'Finance',
  Operations: 'Operations', Administration: 'Administration',
};

// ── Sub-tabs that each module hub drills into (mirrors Hubs.jsx HUBS) ──
// This is what lets the search reach every screen, not just the top-level tabs.
const HUB_TABS = {
  accountsHub: { crumb: 'Finance', title: 'Accounts', groups: [
    { group: 'Chart of Accounts', items: [
      { id: 'accounts', label: 'Chart of Accounts', icon: 'ledger' },
      { id: 'accountTree', label: 'Account Tree', icon: 'briefcase' },
      { id: 'createAccount', label: 'Create Account', icon: 'plus' },
    ] },
    { group: 'Account Groups', items: [
      { id: 'group', label: 'Create Account Group', icon: 'briefcase' },
    ] },
  ] },
  ledgerHub: { crumb: 'Finance', title: 'Ledger', groups: [
    { group: 'Journal Entries', items: [
      { id: 'journals', label: 'Journal Entries', icon: 'ledger' },
      { id: 'createJournal', label: 'Create Journal Entry', icon: 'plus' },
      { id: 'journal', label: 'Opening Journal', icon: 'ledger' },
    ] },
  ] },
  bankingHub: { crumb: 'Finance', title: 'Banking', groups: [
    { group: 'Cash Movements', items: [
      { id: 'deposit', label: 'Create Deposit', icon: 'download' },
      { id: 'withdrawal', label: 'Create Withdrawal', icon: 'upload' },
    ] },
    { group: 'Transfers', items: [
      { id: 'localTransfer', label: 'Local Transfer', icon: 'paperclip' },
      { id: 'extTransfer', label: 'External Transfer', icon: 'compass' },
    ] },
  ] },
  reportsHub: { crumb: 'Finance', title: 'Reports', groups: [
    { group: 'Financial', items: [
      { id: 'trialBalance', label: 'Trial Balance', icon: 'ledger' },
      { id: 'incomeStmt', label: 'Income Statement', icon: 'doc' },
      { id: 'balanceSheet', label: 'Balance Sheet', icon: 'doc' },
    ] },
    { group: 'Inventory', items: [
      { id: 'invValuation', label: 'Inventory Valuation', icon: 'scanner' },
    ] },
    { group: 'Security', items: [
      { id: 'auditLog', label: 'Audit Log', icon: 'lock' },
    ] },
  ] },
  storesHub: { crumb: 'Operations', title: 'Inventory & Stores', groups: [
    { group: 'Catalog', items: [
      { id: 'products', label: 'Products', icon: 'scanner' },
      { id: 'categories', label: 'Categories', icon: 'briefcase' },
      { id: 'uom', label: 'Units of Measure', icon: 'compass' },
      { id: 'priceLists', label: 'Price Lists', icon: 'ledger' },
    ] },
    { group: 'Warehouses', items: [
      { id: 'stores', label: 'Warehouses', icon: 'store' },
      { id: 'createStore', label: 'Create Warehouse', icon: 'plus' },
    ] },
    { group: 'Stock Operations', items: [
      { id: 'inventory', label: 'Issue Inventory', icon: 'scanner' },
      { id: 'receive', label: 'Receive Inventory', icon: 'download' },
      { id: 'transferList', label: 'Stock Transfers', icon: 'paperclip' },
      { id: 'adjust', label: 'Stock Adjustment', icon: 'settings' },
      { id: 'stockTake', label: 'Stock Take', icon: 'check' },
      { id: 'barcodePrint', label: 'Barcode Print', icon: 'scanner' },
    ] },
  ] },
  salesHub: { crumb: 'Operations', title: 'Sales', groups: [
    { group: 'Customers', items: [
      { id: 'customers', label: 'Customers', icon: 'user' },
      { id: 'createCustomer', label: 'Add Customer', icon: 'plus' },
    ] },
  ] },
  procurementHub: { crumb: 'Operations', title: 'Procurement', groups: [
    { group: 'Suppliers', items: [
      { id: 'suppliers', label: 'Suppliers', icon: 'briefcase' },
      { id: 'createSupplier', label: 'Add Supplier', icon: 'plus' },
    ] },
  ] },
  configHub: { crumb: 'Administration', title: 'Configuration', groups: [
    { group: 'Currencies', items: [
      { id: 'currencies', label: 'Currencies', icon: 'briefcase' },
      { id: 'createCurrency', label: 'Add Currency', icon: 'plus' },
      { id: 'exchangeRates', label: 'Exchange Rates', icon: 'compass' },
    ] },
    { group: 'Calendar', items: [
      { id: 'fiscalYear', label: 'Fiscal Year', icon: 'ledger' },
    ] },
  ] },
  adminHub: { crumb: 'Administration', title: 'Team & Access', groups: [
    { group: 'Users', items: [
      { id: 'users', label: 'Users', icon: 'user' },
      { id: 'createUser', label: 'Invite User', icon: 'plus' },
    ] },
    { group: 'Access', items: [
      { id: 'roles', label: 'Roles & Permissions', icon: 'settings' },
    ] },
  ] },
  settingsHub: { crumb: 'Administration', title: 'Settings', groups: [
    { group: 'Workspace', items: [
      { id: 'settingsGeneral', label: 'General', icon: 'settings' },
      { id: 'settingsPlatform', label: 'Platform', icon: 'compass' },
      { id: 'settingsTeam', label: 'Team', icon: 'user' },
    ] },
  ] },
};

// Build the search index: every top-level tab AND every sub-tab, grouped by
// its parent module so results stay legible. Each section is collapsible-free
// but visually headed; sub-items carry a breadcrumb path so context is clear.
const SEARCH_GROUPS = (() => {
  const out = [];
  // top-level non-hub tabs (auth + overview) first
  const flat = [
    { group: 'Authentication', crumb: '', items: NAV_SCREENS.filter((s) => s.section === 'Auth').map((s) => ({ id: s.id, label: s.label, icon: s.icon })) },
    { group: 'Overview', crumb: '', items: NAV_SCREENS.filter((s) => s.section === 'Overview').map((s) => ({ id: s.id, label: s.label, icon: s.icon })) },
  ];
  out.push(...flat);
  // one group per module hub: the hub landing + all its sub-tabs
  Object.keys(HUB_TABS).forEach((hubId) => {
    const hub = HUB_TABS[hubId];
    const top = NAV_SCREENS.find((s) => s.id === hubId);
    const items = [
      { id: hubId, label: hub.title + ' — Overview', icon: top ? top.icon : 'briefcase', isHub: true },
      ...hub.groups.flatMap((g) => g.items.map((it) => ({ ...it, sub: g.group }))),
    ];
    out.push({ group: hub.title, crumb: hub.crumb, items });
  });
  return out;
})();
const SEARCH_TOTAL = SEARCH_GROUPS.reduce((n, g) => n + g.items.length, 0);

// ── 3-level tree model: Section → Module → Group → Item ──────────────────
// Modules and Groups are expandable; Items are leaves. Overview items are
// direct leaves (no module wrapper). Built from HUB_TABS so it stays in sync.
const moduleNode = (hubId) => {
  const hub = HUB_TABS[hubId];
  const top = NAV_SCREENS.find((s) => s.id === hubId);
  return {
    id: hubId, label: hub.title, icon: top ? top.icon : 'briefcase',
    children: hub.groups.map((g) => ({
      id: hubId + ':' + g.group, label: g.group, group: true,
      children: g.items,
    })),
  };
};

const NAV_SECTIONS = [
  { section: 'Overview', items: [
    { id: 'dashboard', label: 'Dashboard', icon: 'briefcase' },
    { id: 'invDashboard', label: 'Inventory Dashboard', icon: 'scanner' },
  ] },
  { section: 'Finance', items: ['accountsHub', 'ledgerHub', 'bankingHub', 'reportsHub'].map(moduleNode) },
  { section: 'Operations', items: ['storesHub', 'salesHub', 'procurementHub'].map(moduleNode) },
  { section: 'Administration', items: ['configHub', 'adminHub', 'settingsHub'].map(moduleNode) },
];

// Map a leaf screen id → the chain of ancestor node ids (module, group) so we
// can auto-open the path to the active screen.
const ANCESTORS = (() => {
  const m = {};
  const walk = (node, chain) => {
    if (node.children) node.children.forEach((c) => walk(c, [...chain, node.id]));
    else m[node.id] = chain;
  };
  NAV_SECTIONS.forEach((sec) => sec.items.forEach((n) => walk(n, [])));
  return m;
})();


const TENANTS = [
  { id: 9,  name: 'Al-Rashid Trading Co.', plan: 'Enterprise' },
  { id: 14, name: 'Najd Holdings',         plan: 'Business' },
  { id: 22, name: 'Coastal Logistics',     plan: 'Business' },
];
const tenantById = (id) => TENANTS.find((t) => t.id === id) || TENANTS[0];

const USER = { name: 'Sara Mansour', role: 'Administrator', email: 'sara.mansour@alrashid.co', initials: 'SM' };

const ACCENT = '#4A7CFF';

// ── responsive layout tokens ──────────────────────────────────
const W_EXPANDED = 248;
const W_RAIL     = 76;
const W_DRAWER   = 280;
const APPBAR_H   = 62;
const APPBAR_H_M = 56;
const TABLET_BP  = 768;
const DESKTOP_BP = 1200;
const EASE       = 'cubic-bezier(0.4, 0, 0.2, 1)';

function getNavMode(w) {
  if (w < TABLET_BP) return 'mobile';
  if (w < DESKTOP_BP) return 'tablet';
  return 'desktop';
}

function useViewportWidth(override) {
  const [w, setW] = React.useState(() => (override != null ? override : window.innerWidth));
  React.useEffect(() => {
    if (override != null) { setW(override); return; }
    const onResize = () => setW(window.innerWidth);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, [override]);
  return override != null ? override : w;
}

function useClickOutside(ref, onOut, active) {
  React.useEffect(() => {
    if (!active) return;
    const h = (e) => { if (ref.current && !ref.current.contains(e.target)) onOut(); };
    window.addEventListener('mousedown', h);
    return () => window.removeEventListener('mousedown', h);
  }, [active]);
}

// A three-bar hamburger built from a single bar + box-shadow (no SVG).
function Hamburger({ size = 18, color = 'var(--gl-fg-1)' }) {
  return (
    <span style={{
      display: 'block', width: size, height: 2, borderRadius: 2, background: color,
      boxShadow: `0 -6px 0 ${color}, 0 6px 0 ${color}`,
    }} />
  );
}

function Avatar({ initials, size = 32 }) {
  return (
    <span style={{
      width: size, height: size, borderRadius: '50%', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'rgba(74,124,255,0.16)', color: ACCENT,
      border: '1px solid rgba(74,124,255,0.35)',
      fontFamily: 'var(--gl-font-body)', fontWeight: 700, fontSize: size * 0.36, letterSpacing: '0.02em',
    }}>{initials}</span>
  );
}

const POPOVER_STYLE = {
  position: 'absolute', top: 'calc(100% + 8px)', insetInlineEnd: 0, zIndex: 80,
  minWidth: 240, background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)',
  borderRadius: 10, boxShadow: 'var(--gl-shadow-pop)', padding: 6,
};

function MenuRow({ icon, label, sub, onClick, danger }) {
  const [hover, setHover] = React.useState(false);
  return (
    <button onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)} onClick={onClick}
      style={{
        width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '9px 10px',
        borderRadius: 7, border: 'none', cursor: 'pointer', textAlign: 'start',
        background: hover ? 'var(--gl-hover)' : 'transparent',
        color: danger ? '#E5484D' : 'var(--gl-fg-1)', fontFamily: 'var(--gl-font-body)',
      }}>
      {icon && <span style={{ display: 'flex', color: danger ? '#E5484D' : 'var(--gl-fg-3)', flexShrink: 0 }}><Icon name={icon} size={15} /></span>}
      <span style={{ flex: 1, minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 13, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</span>
        {sub && <span style={{ display: 'block', fontSize: 10.5, fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-3)' }}>{sub}</span>}
      </span>
    </button>
  );
}

/* =========================================================
   WORKSPACE DROPDOWN  (lives in the AppBar)
   ========================================================= */
function WorkspaceButton({ tenantId, setTenantId, compact }) {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef(null);
  useClickOutside(ref, () => setOpen(false), open);
  const t = tenantById(tenantId);

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button onClick={() => setOpen((v) => !v)} aria-label="Switch workspace" title="Switch workspace"
        style={{
          display: 'flex', alignItems: 'center', gap: 9, height: 40,
          padding: compact ? 0 : '0 10px 0 8px', width: compact ? 40 : 'auto',
          justifyContent: 'center', borderRadius: 9, cursor: 'pointer',
          background: open ? 'var(--gl-hover)' : 'var(--gl-input-bg)',
          border: `1px solid ${open ? ACCENT : 'var(--gl-border)'}`, transition: 'border-color 150ms ease',
        }}>
        <span style={{ width: 26, height: 26, borderRadius: 7, background: 'rgba(74,124,255,0.18)', color: ACCENT, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name="building" size={15} /></span>
        {!compact && (
          <span style={{ textAlign: 'start', minWidth: 0, maxWidth: 150 }}>
            <span style={{ display: 'block', fontSize: 12.5, fontWeight: 600, color: 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.name}</span>
            <span style={{ display: 'block', fontFamily: 'var(--gl-font-mono)', fontSize: 9.5, color: 'var(--gl-fg-3)', letterSpacing: '0.04em' }}>TENANT {t.id}</span>
          </span>
        )}
        {!compact && <Icon name="chevDown" size={14} color="var(--gl-fg-3)" />}
      </button>

      {open && (
        <div style={{ ...POPOVER_STYLE, insetInlineStart: 0, insetInlineEnd: 'auto', minWidth: 250 }}>
          <div style={{ padding: '6px 10px 8px', fontFamily: 'var(--gl-font-mono)', fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--gl-fg-4)' }}>Switch workspace</div>
          {TENANTS.map((opt) => {
            const active = opt.id === tenantId;
            return (
              <button key={opt.id} onClick={() => { setTenantId(opt.id); setOpen(false); }}
                style={{
                  width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px',
                  borderRadius: 7, border: 'none', cursor: 'pointer', textAlign: 'start',
                  background: active ? 'rgba(74,124,255,0.10)' : 'transparent',
                }}>
                <span style={{ width: 28, height: 28, borderRadius: 7, background: 'rgba(74,124,255,0.18)', color: ACCENT, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name="building" size={14} /></span>
                <span style={{ flex: 1, minWidth: 0 }}>
                  <span style={{ display: 'block', fontSize: 13, fontWeight: 600, color: active ? ACCENT : 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{opt.name}</span>
                  <span style={{ display: 'block', fontSize: 10.5, fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-3)' }}>{opt.plan} · Tenant {opt.id}</span>
                </span>
                {active && <span style={{ display: 'flex', color: ACCENT }}><Icon name="check" size={15} /></span>}
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

/* =========================================================
   USER MENU  (lives in the AppBar)
   ========================================================= */
function UserMenu({ compact, setScreen }) {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef(null);
  useClickOutside(ref, () => setOpen(false), open);

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button onClick={() => setOpen((v) => !v)} aria-label="Account menu"
        style={{
          display: 'flex', alignItems: 'center', gap: 9, height: 40,
          padding: compact ? 0 : '0 8px 0 4px', borderRadius: 9, cursor: 'pointer',
          background: open ? 'var(--gl-hover)' : 'transparent',
          border: `1px solid ${open ? 'var(--gl-border-strong)' : 'transparent'}`,
        }}>
        <Avatar initials={USER.initials} size={32} />
        {!compact && (
          <span style={{ textAlign: 'start', minWidth: 0 }}>
            <span style={{ display: 'block', fontSize: 12.5, fontWeight: 600, color: 'var(--gl-fg-1)', whiteSpace: 'nowrap' }}>{USER.name}</span>
            <span style={{ display: 'block', fontSize: 10, fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-3)', letterSpacing: '0.04em' }}>{USER.role}</span>
          </span>
        )}
        {!compact && <Icon name="chevDown" size={14} color="var(--gl-fg-3)" />}
      </button>

      {open && (
        <div style={POPOVER_STYLE}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px 12px', borderBottom: '1px solid var(--gl-border)', marginBottom: 6 }}>
            <Avatar initials={USER.initials} size={38} />
            <span style={{ minWidth: 0 }}>
              <span style={{ display: 'block', fontSize: 13, fontWeight: 600, color: 'var(--gl-fg-1)' }}>{USER.name}</span>
              <span style={{ display: 'block', fontSize: 11, fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-3)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{USER.email}</span>
            </span>
          </div>
          <MenuRow icon="user" label="Profile" onClick={() => setOpen(false)} />
          <MenuRow icon="settings" label="Settings" onClick={() => { setScreen('settingsHub'); setOpen(false); }} />
          <div style={{ height: 1, background: 'var(--gl-border)', margin: '6px 4px' }} />
          <MenuRow icon="lock" label="Sign out" danger onClick={() => setOpen(false)} />
        </div>
      )}
    </div>
  );
}

/* =========================================================
   APP BAR
   ========================================================= */
const searchKbd = { fontFamily: 'var(--gl-font-mono)', fontSize: 10, color: 'var(--gl-fg-4)', border: '1px solid var(--gl-border)', borderRadius: 4, padding: '1px 6px', lineHeight: 1.4, flexShrink: 0 };

function AppBar({ mode, onToggleSidebar, onOpenSearch, tenantId, setTenantId, setScreen }) {
  const isMobile = mode === 'mobile';
  const iconBtn = {
    width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center',
    borderRadius: 9, border: '1px solid var(--gl-border)', background: 'var(--gl-input-bg)',
    cursor: 'pointer', color: 'var(--gl-fg-2)', flexShrink: 0,
  };

  if (isMobile) {
    return (
      <header style={{
        height: APPBAR_H_M, flexShrink: 0, zIndex: 30, position: 'relative',
        display: 'flex', alignItems: 'center', gap: 10, padding: '0 12px',
        background: 'var(--gl-surface)', borderBottom: '1px solid var(--gl-border)',
      }}>
        <button onClick={onToggleSidebar} aria-label="Toggle navigation" title="Toggle navigation" style={iconBtn}><Hamburger /></button>
        <Logo size={22} withWordmark={false} />
        <button onClick={onOpenSearch} aria-label="Search" title="Search" style={{ ...iconBtn, marginInlineStart: 'auto' }}>
          <Icon name="search" size={16} color="var(--gl-fg-3)" />
        </button>
        <WorkspaceButton tenantId={tenantId} setTenantId={setTenantId} compact />
        <UserMenu compact setScreen={setScreen} />
      </header>
    );
  }

  // Desktop / tablet: 3-column grid keeps the search field optically centered
  // regardless of how wide the side clusters are (and mirrors cleanly in RTL).
  const tight = mode !== 'desktop'; // compact the side clusters on tablet so the center stays centered
  return (
    <header style={{
      height: APPBAR_H, flexShrink: 0, zIndex: 30, position: 'relative',
      display: 'grid', gridTemplateColumns: 'minmax(0,1fr) auto minmax(0,1fr)', alignItems: 'center', gap: 16, padding: '0 18px',
      background: 'var(--gl-surface)', borderBottom: '1px solid var(--gl-border)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, minWidth: 0, overflow: 'hidden' }}>
        <Logo size={24} withWordmark={!tight} />
      </div>

      <button onClick={onOpenSearch} aria-label="Search tabs"
        style={{
          width: tight ? 'min(360px, 40vw)' : 'min(480px, 42vw)', height: 40, display: 'flex', alignItems: 'center', gap: 9,
          padding: '0 12px', borderRadius: 9, cursor: 'text', textAlign: 'start',
          background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border)',
        }}>
        <Icon name="search" size={15} color="var(--gl-fg-3)" />
        <span style={{ flex: 1, fontSize: 13, color: 'var(--gl-fg-3)', fontFamily: 'var(--gl-font-body)', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', textAlign: 'start' }}>Search tabs &amp; actions…</span>
        <span style={{ display: 'flex', gap: 3, flexShrink: 0 }}>
          <kbd style={searchKbd}>{IS_MAC ? '⌘' : 'Ctrl'}</kbd>
          <kbd style={searchKbd}>K</kbd>
        </span>
      </button>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 12, minWidth: 0, overflow: 'hidden' }}>
        <WorkspaceButton tenantId={tenantId} setTenantId={setTenantId} compact={tight} />
        <UserMenu compact={tight} setScreen={setScreen} />
      </div>
    </header>
  );
}

/* =========================================================
   SEARCH DIALOG  (command palette)
   ========================================================= */
function SearchDialog({ open, onClose, setScreen }) {
  const [query, setQuery] = React.useState('');
  const [activeIdx, setActiveIdx] = React.useState(0);
  const inputRef = React.useRef(null);
  const listRef = React.useRef(null);

  React.useEffect(() => {
    if (open) {
      setQuery(''); setActiveIdx(0);
      const id = setTimeout(() => { if (inputRef.current) inputRef.current.focus(); }, 30);
      return () => clearTimeout(id);
    }
  }, [open]);

  // Filter the full index (top-level tabs + every sub-tab). A group survives if
  // its header matches or any of its items match; matching items are kept.
  const groups = React.useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return SEARCH_GROUPS;
    const toks = q.split(/\s+/);
    const match = (text) => toks.every((t) => text.includes(t));
    const res = [];
    for (const g of SEARCH_GROUPS) {
      const path = (g.crumb ? g.crumb + ' ' : '') + g.group;
      const groupHit = match(path.toLowerCase());
      const items = g.items.filter((it) => groupHit || match((it.label + ' ' + (it.sub || '') + ' ' + path).toLowerCase()));
      if (items.length) res.push({ ...g, items });
    }
    return res;
  }, [query]);

  // Flat list of selectable items (for keyboard nav), each tagged with its group.
  const flat = React.useMemo(() => {
    const arr = [];
    groups.forEach((g) => g.items.forEach((it) => arr.push({ ...it, _group: g })));
    return arr;
  }, [groups]);

  React.useEffect(() => { setActiveIdx(0); }, [query]);

  // Keep the active row in view WITHOUT scrollIntoView (which can disrupt the page).
  React.useEffect(() => {
    const c = listRef.current; if (!c) return;
    const el = c.querySelector(`[data-row="${activeIdx}"]`); if (!el) return;
    if (el.offsetTop < c.scrollTop) c.scrollTop = el.offsetTop - 8;
    else if (el.offsetTop + el.offsetHeight > c.scrollTop + c.clientHeight)
      c.scrollTop = el.offsetTop + el.offsetHeight - c.clientHeight + 8;
  }, [activeIdx]);

  const choose = (it) => { if (!it) return; setScreen(it.id); onClose(); };

  const onKey = (e) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setActiveIdx((i) => Math.min(i + 1, flat.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActiveIdx((i) => Math.max(i - 1, 0)); }
    else if (e.key === 'Enter') { e.preventDefault(); choose(flat[activeIdx]); }
    else if (e.key === 'Escape') { e.preventDefault(); onClose(); }
  };

  if (!open) return null;

  const q = query.trim();
  let rowCursor = -1; // running index across groups, matches `flat`

  return (
    <div onMouseDown={onClose} role="presentation"
      style={{
        position: 'absolute', inset: 0, zIndex: 100, display: 'flex', justifyContent: 'center',
        alignItems: 'flex-start', padding: '12vh 20px 20px',
        background: 'rgba(8,9,12,0.55)', backdropFilter: 'blur(2px)',
      }}>
      <div onMouseDown={(e) => e.stopPropagation()} role="dialog" aria-label="Search"
        style={{
          width: '100%', maxWidth: 580, background: 'var(--gl-surface)',
          border: '1px solid var(--gl-border-strong)', borderRadius: 14,
          boxShadow: 'var(--gl-shadow-pop)', overflow: 'hidden',
          animation: 'searchPop 160ms ' + EASE,
        }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '14px 16px', borderBottom: '1px solid var(--gl-border)' }}>
          <Icon name="search" size={18} color="var(--gl-fg-3)" />
          <input ref={inputRef} value={query} onChange={(e) => setQuery(e.target.value)} onKeyDown={onKey}
            placeholder="Search tabs & actions…" aria-label="Search tabs"
            style={{
              flex: 1, minWidth: 0, border: 'none', outline: 'none', background: 'transparent',
              color: 'var(--gl-fg-1)', fontFamily: 'var(--gl-font-body)', fontSize: 15.5,
            }} />
          <button onMouseDown={(e) => { e.preventDefault(); onClose(); }} aria-label="Close"
            style={{ display: 'flex', alignItems: 'center', gap: 5, border: '1px solid var(--gl-border)', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', borderRadius: 5, padding: '3px 7px', fontFamily: 'var(--gl-font-mono)', fontSize: 10 }}>
            ESC
          </button>
        </div>

        <div ref={listRef} role="listbox" style={{ maxHeight: 420, overflowY: 'auto', padding: 8 }}>
          <div style={{ padding: '4px 10px 6px', fontFamily: 'var(--gl-font-mono)', fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--gl-fg-4)' }}>
            {q ? `${flat.length} result${flat.length === 1 ? '' : 's'}` : `All tabs · ${SEARCH_TOTAL}`}
          </div>

          {flat.length === 0 ? (
            <div style={{ padding: '28px 12px', textAlign: 'center', fontSize: 13.5, color: 'var(--gl-fg-3)' }}>No tabs match “{q}”</div>
          ) : groups.map((g) => (
            <div key={g.group} style={{ marginBottom: 4 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, padding: '10px 12px 5px' }}>
                <span style={{ fontWeight: 700, fontSize: 10.5, letterSpacing: '0.13em', textTransform: 'uppercase', color: 'var(--gl-fg-3)' }}>{g.group}</span>
                {g.crumb && <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 9.5, color: 'var(--gl-fg-4)', letterSpacing: '0.06em' }}>{g.crumb}</span>}
              </div>
              {g.items.map((it) => {
                rowCursor += 1;
                const i = rowCursor;
                const active = i === activeIdx;
                return (
                  <button key={it.id + '_' + i} data-row={i} role="option" aria-selected={active}
                    onMouseEnter={() => setActiveIdx(i)}
                    onMouseDown={(e) => { e.preventDefault(); choose(it); }}
                    style={{
                      width: '100%', display: 'flex', alignItems: 'center', gap: 12, padding: '9px 12px',
                      borderRadius: 8, border: 'none', cursor: 'pointer', textAlign: 'start',
                      background: active ? 'var(--gl-hover)' : 'transparent',
                    }}>
                    <span style={{ width: 30, height: 30, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, background: active ? 'rgba(74,124,255,0.16)' : 'var(--gl-input-bg)', color: active ? ACCENT : 'var(--gl-fg-3)' }}><Icon name={it.icon} size={16} /></span>
                    <span style={{ flex: 1, minWidth: 0 }}>
                      <span style={{ display: 'block', fontSize: 13.5, fontWeight: it.isHub ? 600 : 500, color: 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{it.label}</span>
                      <span style={{ display: 'block', fontSize: 11, fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-3)' }}>
                        {it.isHub ? 'Module landing' : (it.sub || g.group)}
                      </span>
                    </span>
                    {SCREEN_META[it.id] && SCREEN_META[it.id].badge && <NavBadge badge={SCREEN_META[it.id].badge} small />}
                    {SCREEN_META[it.id] && SCREEN_META[it.id].keys && <KeyHint keys={SCREEN_META[it.id].keys} />}
                    {it.isHub && <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 9, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--gl-fg-4)', border: '1px solid var(--gl-border)', borderRadius: 4, padding: '2px 6px', flexShrink: 0 }}>Hub</span>}
                    {active && <span style={{ display: 'flex', color: 'var(--gl-fg-4)' }}><Icon name="chevRight" size={15} /></span>}
                  </button>
                );
              })}
            </div>
          ))}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '10px 16px', borderTop: '1px solid var(--gl-border)', fontFamily: 'var(--gl-font-mono)', fontSize: 10.5, color: 'var(--gl-fg-4)' }}>
          <span><kbd style={kbdInline}>↑</kbd><kbd style={kbdInline}>↓</kbd> navigate</span>
          <span><kbd style={kbdInline}>↵</kbd> open</span>
          <span><kbd style={kbdInline}>esc</kbd> close</span>
        </div>
      </div>
    </div>
  );
}
const kbdInline = { display: 'inline-block', border: '1px solid var(--gl-border)', borderRadius: 4, padding: '0 5px', marginInlineEnd: 3, color: 'var(--gl-fg-3)' };

/* =========================================================
   SCREEN METADATA  — keyboard shortcuts + badges
   ========================================================= */
// Real keyboard shortcuts: Ctrl (or ⌘) + key, optionally with Shift.
// Each `sc` is { ctrl, shift?, code } and is matched live in NavShell.
// Badges flag screens that need attention (counts / status).
const SCREEN_META = {
  dashboard:    { sc: { ctrl: true, shift: true, code: 'D' } },
  invDashboard: { sc: { ctrl: true, shift: true, code: 'E' } },
  accountTree:  { sc: { ctrl: true, shift: true, code: 'G' } },
  journals:     { sc: { ctrl: true, shift: true, code: 'L' }, badge: { text: '3', tone: 'accent' } },
  trialBalance: { sc: { ctrl: true, shift: true, code: 'M' } },
  products:     { sc: { ctrl: true, shift: true, code: 'O' } },
  stockTake:    { badge: { text: 'New', tone: 'green' } },
  auditLog:     { badge: { text: '12', tone: 'muted' } },
  exchangeRates:{ badge: { text: 'Live', tone: 'green' } },
  approvals:    { badge: { text: '5', tone: 'amber' } },
};
const IS_MAC = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform || '');
function comboLabel(sc) {
  const a = [];
  if (sc.ctrl) a.push(IS_MAC ? '⌘' : 'Ctrl');
  if (sc.shift) a.push('⇧');
  if (sc.alt) a.push('Alt');
  a.push(sc.code.toUpperCase());
  return a;
}
function matchSc(e, sc) {
  if (!sc) return false;
  const ctrl = e.ctrlKey || e.metaKey; // ⌘ on macOS == Ctrl here
  return ctrl === !!sc.ctrl && e.shiftKey === !!sc.shift && e.altKey === !!sc.alt
    && (e.key || '').toUpperCase() === sc.code.toUpperCase();
}
// pre-compute display labels so existing `meta.keys` consumers keep working
Object.keys(SCREEN_META).forEach((id) => { const m = SCREEN_META[id]; if (m.sc) m.keys = comboLabel(m.sc); });
const SHORTCUTS = Object.keys(SCREEN_META)
  .filter((id) => SCREEN_META[id].sc)
  .map((id) => ({ id, sc: SCREEN_META[id].sc }));

const subtreeHasBadge = (node) =>
  node.children ? node.children.some(subtreeHasBadge) : !!(SCREEN_META[node.id] && SCREEN_META[node.id].badge);

const BADGE_TONES = {
  accent: { bg: 'rgba(74,124,255,0.16)', fg: ACCENT,    bd: 'rgba(74,124,255,0.34)' },
  green:  { bg: 'rgba(31,160,99,0.16)',  fg: '#2BBE7C', bd: 'rgba(31,160,99,0.34)' },
  amber:  { bg: 'rgba(217,149,42,0.16)', fg: '#E0A23B', bd: 'rgba(217,149,42,0.34)' },
  muted:  { bg: 'var(--gl-input-bg)',    fg: 'var(--gl-fg-3)', bd: 'var(--gl-border)' },
};

function NavBadge({ badge, small }) {
  if (!badge) return null;
  const t = BADGE_TONES[badge.tone || 'accent'];
  return (
    <span style={{
      flexShrink: 0, fontFamily: 'var(--gl-font-mono)', fontSize: small ? 9 : 9.5, fontWeight: 700,
      lineHeight: 1, padding: small ? '2px 5px' : '3px 6px', borderRadius: 99,
      letterSpacing: '0.02em', background: t.bg, color: t.fg, border: `1px solid ${t.bd}`,
    }}>{badge.text}</span>
  );
}

function KeyHint({ keys, dim }) {
  if (!keys) return null;
  return (
    <span style={{ display: 'flex', gap: 3, flexShrink: 0, opacity: dim ? 0.9 : 1 }}>
      {keys.map((k, i) => (
        <kbd key={i} style={{
          fontFamily: 'var(--gl-font-mono)', fontSize: 9.5, fontWeight: 600, lineHeight: 1.5,
          minWidth: 16, textAlign: 'center', padding: '1px 4px', borderRadius: 4,
          color: 'var(--gl-fg-3)', background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border)',
        }}>{k}</kbd>
      ))}
    </span>
  );
}

/* =========================================================
   SIDEBAR  (3-level tree · rail · drawer · RTL-aware)
   ========================================================= */

// One-time injected styles: an elegant themed scrollbar + the tree fade-in.
(function injectNavStyles() {
  if (typeof document === 'undefined' || document.getElementById('gl-nav-styles')) return;
  const s = document.createElement('style');
  s.id = 'gl-nav-styles';
  s.textContent = `
    .gl-nav-scroll { scrollbar-width: thin; scrollbar-color: var(--gl-border-strong) transparent; }
    .gl-nav-scroll::-webkit-scrollbar { width: 7px; }
    .gl-nav-scroll::-webkit-scrollbar-track { background: transparent; margin: 4px 0; }
    .gl-nav-scroll::-webkit-scrollbar-thumb { background: var(--gl-border-strong); border-radius: 99px; border: 2px solid transparent; background-clip: padding-box; }
    .gl-nav-scroll:hover::-webkit-scrollbar-thumb { background: var(--gl-fg-4); background-clip: padding-box; }
    @keyframes glTreeIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: none; } }
  `;
  document.head.appendChild(s);
})();

// ── geometry: each nesting level steps the content in by GUTTER; connector
//    lines are drawn (with divs) at a fixed offset under each parent's marker.
const GUTTER = 19;
const contentInset = (d) => 13 + d * GUTTER;     // inline padding of a row's content
const lineInset = (d) => contentInset(d) + 10;   // vertical line for THIS node's children
const ELBOW = GUTTER - 8;                          // horizontal stub length
const LINE_COLOR = 'var(--gl-border-strong)';
const ICON_TOP = 20, ICON_ITEM = 16, ITEM_BOX = 28;
const HEAD_H = { direct: 42, module: 42, group: 36, item: 38 };
const nodeKind = (node, depth) => node.children ? (depth === 0 ? 'module' : 'group') : (depth === 0 ? 'direct' : 'item');

function NavigationSidebar({ screen, onNavigate, theme, setTheme, mode, collapsed, mobileOpen, onCloseDrawer, onToggleCollapse, dir = 'ltr' }) {
  const isMobile = mode === 'mobile';
  const railed = !isMobile && collapsed;
  const rtl = dir === 'rtl';
  // chevron points the way the toggle will move the rail: ‹ collapse, › expand
  const collapseIcon = railed ? (rtl ? 'chevLeft' : 'chevRight') : (rtl ? 'chevRight' : 'chevLeft');

  // Expanded node ids. Auto-open the ancestor chain of the active screen.
  const [openIds, setOpenIds] = React.useState(() => {
    const o = {}; (ANCESTORS[screen] || []).forEach((id) => { o[id] = true; }); return o;
  });
  React.useEffect(() => {
    const chain = ANCESTORS[screen]; if (!chain) return;
    setOpenIds((o) => { const n = { ...o }; chain.forEach((id) => { n[id] = true; }); return n; });
  }, [screen]);
  const toggle = (id) => setOpenIds((o) => ({ ...o, [id]: !o[id] }));

  const drawerHidden = rtl ? `translateX(${W_DRAWER + 8}px)` : `translateX(-${W_DRAWER + 8}px)`;
  const asideStyle = {
    direction: dir,
    background: 'var(--gl-surface)',
    borderInlineEnd: '1px solid var(--gl-border)',
    padding: '16px 14px',
    display: 'flex', flexDirection: 'column', gap: 12,
    boxSizing: 'border-box', overflow: 'hidden',
    ...(isMobile
      ? {
          position: 'absolute', top: 0, bottom: 0, insetInlineStart: 0, width: W_DRAWER, zIndex: 60,
          transform: mobileOpen ? 'translateX(0)' : drawerHidden,
          boxShadow: mobileOpen ? 'var(--gl-shadow-pop)' : 'none',
          transition: `transform 280ms ${EASE}`,
        }
      : {
          position: 'relative', flexShrink: 0, height: '100%',
          width: railed ? W_RAIL : W_EXPANDED,
          transition: `width 240ms ${EASE}`,
        }),
  };

  return (
    <aside style={asideStyle}>
      {isMobile && (
        <div style={{ display: 'flex', alignItems: 'center', height: 30, marginBottom: 2 }}>
          <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--gl-fg-4)' }}>Navigation</span>
          <button onClick={onCloseDrawer} aria-label="Close navigation" style={{ marginInlineStart: 'auto', display: 'flex', border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', padding: 6 }}>
            <Icon name="close" size={18} />
          </button>
        </div>
      )}

      {/* collapse toggle sits directly above the nav tree (‹ / ›) */}
      {!isMobile && (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: railed ? 'center' : 'flex-end', paddingBottom: 2 }}>
          <button onClick={onToggleCollapse} aria-label={railed ? 'Expand sidebar' : 'Collapse sidebar'} title={railed ? 'Expand sidebar' : 'Collapse sidebar'}
            style={{ width: 34, height: 34, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, border: '1px solid var(--gl-border)', background: 'var(--gl-input-bg)', cursor: 'pointer', color: 'var(--gl-fg-2)', flexShrink: 0 }}>
            <Icon name={collapseIcon} size={17} />
          </button>
        </div>
      )}

      {railed
        ? <RailNav screen={screen} onNavigate={onNavigate} rtl={rtl} />
        : (
          <nav className="gl-nav-scroll" style={{ display: 'flex', flexDirection: 'column', gap: 2, overflowY: 'auto', overflowX: 'hidden', flex: 1 }}>
            {NAV_SECTIONS.map((sec) => (
              <div key={sec.section} style={{ marginBottom: 6 }}>
                <div style={{ fontWeight: 700, fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--gl-fg-4)', padding: '12px 12px 6px', whiteSpace: 'nowrap', textAlign: 'start' }}>{sec.section}</div>
                {sec.items.map((node) => (
                  <TreeNode key={node.id} node={node} depth={0} screen={screen} openIds={openIds} onToggle={toggle} onNavigate={onNavigate} />
                ))}
              </div>
            ))}
          </nav>
        )
      }

      <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: 12, paddingTop: 4 }}>
        <ThemeToggle theme={theme} setTheme={setTheme} collapsed={railed} />
        <HelpCard collapsed={railed} />
      </div>
    </aside>
  );
}

// Recursive node: renders its own row, then (if open) its children wrapped in
// drawn connectors. Handles any depth; styling varies by kind.
function TreeNode({ node, depth, screen, openIds, onToggle, onNavigate }) {
  const isLeaf = !node.children;
  const kind = nodeKind(node, depth);
  if (isLeaf) {
    return <TreeRow node={node} depth={depth} kind={kind} active={screen === node.id} onClick={() => onNavigate(node.id)} />;
  }
  const open = !!openIds[node.id];
  const hasActive = (ANCESTORS[screen] || []).includes(node.id);
  const lx = lineInset(depth);
  return (
    <div>
      <TreeRow node={node} depth={depth} kind={kind} expandable open={open} hasActive={hasActive} onClick={() => onToggle(node.id)} />
      {open && (
        <div style={{ animation: 'glTreeIn 180ms ease' }}>
          {node.children.map((c, i) => {
            const childH = HEAD_H[nodeKind(c, depth + 1)];
            const last = i === node.children.length - 1;
            return (
              <div key={c.id} style={{ position: 'relative' }}>
                {/* vertical: top → child header center */}
                <span style={{ position: 'absolute', insetInlineStart: lx, top: 0, height: childH / 2, width: 1.5, background: LINE_COLOR }} />
                {/* vertical: header center → bottom (chains to next sibling) */}
                {!last && <span style={{ position: 'absolute', insetInlineStart: lx, top: childH / 2, bottom: 0, width: 1.5, background: LINE_COLOR }} />}
                {/* elbow stub */}
                <span style={{ position: 'absolute', insetInlineStart: lx, top: childH / 2, width: ELBOW, height: 1.5, background: LINE_COLOR }} />
                <TreeNode node={c} depth={depth + 1} screen={screen} openIds={openIds} onToggle={onToggle} onNavigate={onNavigate} />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function TreeRow({ node, depth, kind, expandable, open, active, hasActive, onClick }) {
  const [hover, setHover] = React.useState(false);
  const pad = contentInset(depth);
  const base = {
    position: 'relative', display: 'flex', alignItems: 'center', width: '100%',
    border: 'none', cursor: 'pointer', textAlign: 'start', fontFamily: 'var(--gl-font-body)',
    paddingInlineStart: pad, paddingInlineEnd: 10, height: HEAD_H[kind],
    transition: 'background 150ms ease', whiteSpace: 'nowrap',
  };
  const chevron = expandable && (
    <span style={{ display: 'flex', flexShrink: 0, marginInlineStart: 'auto', transform: open ? 'rotate(180deg)' : 'none', transition: 'transform 220ms ease', color: 'var(--gl-fg-3)' }}>
      <Icon name="chevDown" size={14} />
    </span>
  );

  if (kind === 'direct' || kind === 'module') {
    const tint = kind === 'direct' ? (active ? '#fff' : 'var(--gl-fg-2)') : (hasActive ? ACCENT : 'var(--gl-fg-2)');
    const meta = SCREEN_META[node.id];
    const moduleBadge = kind === 'module' && !open && subtreeHasBadge(node);
    return (
      <button onClick={onClick} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
        aria-label={node.label} aria-expanded={expandable ? open : undefined}
        style={{ ...base, gap: 12, borderRadius: 10,
          background: kind === 'direct' && active ? ACCENT : (hover ? 'var(--gl-hover)' : 'transparent'),
          color: tint, fontWeight: (active || hasActive) ? 600 : 500, fontSize: 13.5 }}>
        <span style={{ display: 'flex', flexShrink: 0 }}><Icon name={node.icon} size={ICON_TOP} /></span>
        <span style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>{node.label}</span>
        {meta && meta.badge && <NavBadge badge={meta.badge} />}
        {meta && meta.keys && hover && !active && <KeyHint keys={meta.keys} />}
        {moduleBadge && <span style={{ width: 6, height: 6, borderRadius: '50%', flexShrink: 0, background: ACCENT }} />}
        {chevron}
      </button>
    );
  }

  if (kind === 'group') {
    return (
      <button onClick={onClick} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
        aria-label={node.label} aria-expanded={open}
        style={{ ...base, gap: 9, borderRadius: 8,
          background: hover ? 'var(--gl-hover)' : 'transparent',
          color: hasActive ? ACCENT : 'var(--gl-fg-3)', fontWeight: hasActive ? 600 : 600, fontSize: 11.5,
          letterSpacing: '0.02em' }}>
        <span style={{ width: 6, height: 6, borderRadius: '50%', flexShrink: 0, background: hasActive ? ACCENT : 'var(--gl-fg-4)' }} />
        <span style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', textTransform: 'uppercase' }}>{node.label}</span>
        {chevron}
      </button>
    );
  }

  // kind === 'item' — boxed icon leaf
  const meta = SCREEN_META[node.id];
  return (
    <button onClick={onClick} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      aria-label={node.label}
      style={{ ...base, gap: 10, borderRadius: 8,
        background: active ? 'rgba(74,124,255,0.10)' : (hover ? 'var(--gl-hover)' : 'transparent'),
        color: active ? ACCENT : 'var(--gl-fg-2)', fontWeight: active ? 600 : 500, fontSize: 12.5 }}>
      <span style={{ width: ITEM_BOX, height: ITEM_BOX, borderRadius: 8, flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        border: `1px solid ${active ? ACCENT : 'var(--gl-border)'}`,
        background: active ? 'rgba(74,124,255,0.12)' : 'var(--gl-surface)',
        color: active ? ACCENT : 'var(--gl-fg-3)' }}><Icon name={node.icon} size={ICON_ITEM} /></span>
      <span style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>{node.label}</span>
      {meta && meta.badge && <NavBadge badge={meta.badge} small />}
      {meta && meta.keys && hover && !active && <KeyHint keys={meta.keys} />}
    </button>
  );
}

// ── Collapsed rail: icon-only modules; hover reveals a grouped flyout ──
function RailNav({ screen, onNavigate, rtl }) {
  const [fly, setFly] = React.useState(null); // { node, top, left }
  const closeTimer = React.useRef(null);
  const FLY_W = 248;

  const openFly = (node, el) => {
    if (closeTimer.current) clearTimeout(closeTimer.current);
    if (!node.children) { setFly(null); return; }
    const r = el.getBoundingClientRect();
    const left = rtl ? Math.max(8, r.left - FLY_W - 10) : r.right + 10;
    setFly({ node, top: Math.min(r.top, window.innerHeight - 320), left });
  };
  const scheduleClose = () => { if (closeTimer.current) clearTimeout(closeTimer.current); closeTimer.current = setTimeout(() => setFly(null), 130); };
  const cancelClose = () => { if (closeTimer.current) clearTimeout(closeTimer.current); };

  // flatten the section list to a single icon column (sections become dividers)
  return (
    <nav className="gl-nav-scroll" style={{ display: 'flex', flexDirection: 'column', gap: 5, alignItems: 'center', overflowY: 'auto', overflowX: 'visible', flex: 1, width: '100%' }}>
      {NAV_SECTIONS.map((sec, si) => (
        <React.Fragment key={sec.section}>
          {si > 0 && <span style={{ width: 26, height: 1, background: 'var(--gl-border)', margin: '5px 0' }} />}
          {sec.items.map((node) => {
            const active = node.children ? (ANCESTORS[screen] || []).includes(node.id) : screen === node.id;
            const ownBadge = !node.children && SCREEN_META[node.id] && SCREEN_META[node.id].badge;
            const hasBadge = node.children ? subtreeHasBadge(node) : !!ownBadge;
            return (
              <button key={node.id}
                onMouseEnter={(e) => openFly(node, e.currentTarget)} onMouseLeave={scheduleClose}
                onClick={() => { if (!node.children) onNavigate(node.id); }}
                title={node.children ? undefined : node.label} aria-label={node.label}
                style={{
                  width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  borderRadius: 10, border: 'none', cursor: 'pointer', flexShrink: 0, position: 'relative',
                  background: active ? (node.children ? 'rgba(74,124,255,0.12)' : ACCENT) : 'transparent',
                  color: active ? (node.children ? ACCENT : '#fff') : 'var(--gl-fg-2)', transition: 'background 150ms ease',
                }}>
                <Icon name={node.icon} size={22} />
                {hasBadge && <span style={{ position: 'absolute', insetInlineEnd: 6, top: 6, width: 7, height: 7, borderRadius: '50%', background: (ownBadge && BADGE_TONES[ownBadge.tone || 'accent'].fg) || ACCENT, border: '1.5px solid var(--gl-surface)' }} />}
                {node.children && active && !hasBadge && <span style={{ position: 'absolute', insetInlineEnd: 5, top: 5, width: 5, height: 5, borderRadius: '50%', background: ACCENT }} />}
              </button>
            );
          })}
        </React.Fragment>
      ))}

      {fly && (
        <div onMouseEnter={cancelClose} onMouseLeave={scheduleClose}
          style={{
            position: 'fixed', top: fly.top, left: fly.left, zIndex: 90, width: FLY_W, maxHeight: 360, overflowY: 'auto',
            background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)',
            borderRadius: 12, boxShadow: 'var(--gl-shadow-pop)', padding: 8,
            direction: rtl ? 'rtl' : 'ltr', animation: 'searchPop 140ms ' + EASE,
          }}
          className="gl-nav-scroll">
          <div style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '4px 8px 10px', borderBottom: '1px solid var(--gl-border)', marginBottom: 4 }}>
            <span style={{ display: 'flex', color: 'var(--gl-fg-2)' }}><Icon name={fly.node.icon} size={17} /></span>
            <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--gl-fg-1)' }}>{fly.node.label}</span>
          </div>
          {fly.node.children.map((grp) => (
            <div key={grp.id} style={{ marginBottom: 2 }}>
              <div style={{ padding: '6px 8px 3px', fontSize: 9.5, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--gl-fg-4)' }}>{grp.label}</div>
              {grp.children.map((c) => {
                const a = screen === c.id;
                return (
                  <button key={c.id} onClick={() => { onNavigate(c.id); setFly(null); }}
                    style={{
                      width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '7px 8px',
                      borderRadius: 8, border: 'none', cursor: 'pointer', textAlign: 'start',
                      background: a ? 'rgba(74,124,255,0.10)' : 'transparent',
                      color: a ? ACCENT : 'var(--gl-fg-1)', fontFamily: 'var(--gl-font-body)', fontSize: 12.5, fontWeight: a ? 600 : 500,
                    }}
                    onMouseEnter={(e) => { if (!a) e.currentTarget.style.background = 'var(--gl-hover)'; }}
                    onMouseLeave={(e) => { if (!a) e.currentTarget.style.background = 'transparent'; }}>
                    <span style={{ width: 24, height: 24, borderRadius: 7, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', border: `1px solid ${a ? ACCENT : 'var(--gl-border)'}`, color: a ? ACCENT : 'var(--gl-fg-3)' }}><Icon name={c.icon} size={13} /></span>
                    <span style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.label}</span>
                    {SCREEN_META[c.id] && SCREEN_META[c.id].badge && <NavBadge badge={SCREEN_META[c.id].badge} small />}
                    {SCREEN_META[c.id] && SCREEN_META[c.id].keys && <KeyHint keys={SCREEN_META[c.id].keys} />}
                  </button>
                );
              })}
            </div>
          ))}
        </div>
      )}
    </nav>
  );
}

// Bottom help card (mirrors the reference's "Need help?" block).
function HelpCard({ collapsed }) {
  if (collapsed) {
    return (
      <button title="Help Center" aria-label="Help Center"
        style={{ width: 44, height: 44, margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10, border: '1px solid var(--gl-border)', background: 'var(--gl-input-bg)', cursor: 'pointer', color: 'var(--gl-fg-2)' }}>
        <Icon name="info" size={18} />
      </button>
    );
  }
  return (
    <button style={{
      display: 'flex', alignItems: 'center', gap: 12, width: '100%', padding: '12px 14px',
      borderRadius: 12, border: '1px solid var(--gl-border)', background: 'var(--gl-input-bg)',
      cursor: 'pointer', textAlign: 'start',
    }}>
      <span style={{ width: 34, height: 34, borderRadius: 9, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(74,124,255,0.14)', color: ACCENT }}>
        <Icon name="info" size={18} />
      </span>
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 13, fontWeight: 600, color: 'var(--gl-fg-1)' }}>Need help?</span>
        <span style={{ display: 'block', fontSize: 11, color: 'var(--gl-fg-3)', marginTop: 1 }}>Go to Help Center →</span>
      </span>
    </button>
  );
}

function ThemeToggle({ theme, setTheme, collapsed }) {
  if (collapsed) {
    return (
      <button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
        title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`} aria-label="Toggle theme"
        style={{ width: 44, height: 44, margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border)', cursor: 'pointer' }}>
        <span style={{ width: 16, height: 16, borderRadius: '50%', border: '2px solid var(--gl-fg-2)', background: theme === 'dark' ? 'var(--gl-fg-2)' : 'transparent' }} />
      </button>
    );
  }
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4, background: 'var(--gl-input-bg)', padding: 4, borderRadius: 6, border: '1px solid var(--gl-border)' }}>
      {[{ id: 'dark', label: 'Dark' }, { id: 'light', label: 'Light' }].map((opt) => (
        <button key={opt.id} onClick={() => setTheme(opt.id)}
          style={{
            padding: '8px 12px', borderRadius: 4,
            background: theme === opt.id ? 'var(--gl-surface)' : 'transparent',
            color: theme === opt.id ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)',
            border: 'none', cursor: 'pointer', fontFamily: 'var(--gl-font-body)', fontWeight: 700,
            fontSize: 10, letterSpacing: '0.1em', textTransform: 'uppercase',
            boxShadow: theme === opt.id ? '0 1px 2px rgba(0,0,0,0.2)' : 'none', transition: 'background 150ms ease',
          }}>{opt.label}</button>
      ))}
    </div>
  );
}

/* =========================================================
   SHELL  — orchestrates AppBar + Sidebar + SearchDialog
   ========================================================= */
function NavShell({ screen, setScreen, theme, setTheme, viewportWidth, dir = 'ltr', children }) {
  const width = useViewportWidth(viewportWidth);
  const mode = getNavMode(width);
  const isMobile = mode === 'mobile';

  const [collapsed, setCollapsed] = React.useState(mode === 'tablet');
  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [searchOpen, setSearchOpen] = React.useState(false);
  const [tenantId, setTenantId] = React.useState(9);
  const prevMode = React.useRef(mode);

  React.useEffect(() => {
    if (mode === prevMode.current) return;
    if (mode === 'desktop') setCollapsed(false);
    else if (mode === 'tablet') setCollapsed(true);
    else if (mode === 'mobile') setMobileOpen(false);
    prevMode.current = mode;
  }, [mode]);

  const toggleSidebar = () => { if (isMobile) setMobileOpen((v) => !v); else setCollapsed((v) => !v); };
  const handleNav = (id) => { setScreen(id); if (isMobile) setMobileOpen(false); };
  const handleNavRef = React.useRef(handleNav);
  handleNavRef.current = handleNav;

  // Global shortcuts: F3 or ⌘/Ctrl-K (and "/") open search; Ctrl[+Shift]+key
  // jumps straight to a screen; Esc closes search / drawer.
  React.useEffect(() => {
    const onKey = (e) => {
      const t = e.target, tag = t && t.tagName;
      const typing = tag === 'INPUT' || tag === 'TEXTAREA' || (t && t.isContentEditable);
      // open search
      if (e.key === 'F3' || ((e.key === 'k' || e.key === 'K') && (e.metaKey || e.ctrlKey))) {
        e.preventDefault(); setSearchOpen(true); return;
      }
      if (e.key === 'Escape') { setSearchOpen(false); if (isMobile) setMobileOpen(false); return; }
      // real Ctrl[+Shift]+key navigation shortcuts (work even from inputs)
      if (e.ctrlKey || e.metaKey) {
        const hit = SHORTCUTS.find((s) => matchSc(e, s.sc));
        if (hit) { e.preventDefault(); setSearchOpen(false); handleNavRef.current(hit.id); return; }
      }
      // "/" is a convenience opener, but never while typing
      if (e.key === '/' && !typing && !e.metaKey && !e.ctrlKey && !e.altKey) { e.preventDefault(); setSearchOpen(true); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [isMobile]);

  return (
    <div dir={dir} style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column', overflow: 'hidden', background: 'var(--gl-bg)' }}>
      <AppBar mode={mode} onToggleSidebar={toggleSidebar} onOpenSearch={() => setSearchOpen(true)}
        tenantId={tenantId} setTenantId={setTenantId} setScreen={handleNav} dir={dir} />

      <div style={{ position: 'relative', flex: 1, minHeight: 0, display: 'flex', overflow: 'hidden' }}>
        <NavigationSidebar screen={screen} onNavigate={handleNav} theme={theme} setTheme={setTheme}
          mode={mode} collapsed={collapsed} mobileOpen={mobileOpen} onCloseDrawer={() => setMobileOpen(false)} onToggleCollapse={toggleSidebar} dir={dir} />

        {isMobile && (
          <div onClick={() => setMobileOpen(false)} aria-hidden="true"
            style={{ position: 'absolute', inset: 0, zIndex: 50, background: 'rgba(8,9,12,0.55)', backdropFilter: 'blur(1px)', opacity: mobileOpen ? 1 : 0, pointerEvents: mobileOpen ? 'auto' : 'none', transition: 'opacity 280ms ease' }} />
        )}

        <main style={{ flex: 1, minWidth: 0, overflow: 'auto' }}>{children}</main>
      </div>

      <SearchDialog open={searchOpen} onClose={() => setSearchOpen(false)} setScreen={handleNav} />
    </div>
  );
}

Object.assign(window, { NavShell, NavigationSidebar, getNavMode });
