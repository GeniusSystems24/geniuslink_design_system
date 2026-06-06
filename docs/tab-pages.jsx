/* global React */
// TabPage — realistic, content-rich pages for each workspace tab type.
// Rendered full-size in the active tab's content surface AND scaled down inside the
// hover preview, so the thumbnail is a true miniature of the real page (not a skeleton).
// Fluid width (fills its container). Token-driven. Exposes window.TabPage.

(function () {
  const BLUE = 'var(--gl-blue-500)';
  const FG1 = 'var(--gl-fg-1)', FG2 = 'var(--gl-fg-2)', FG3 = 'var(--gl-fg-3)';
  const BORDER = 'var(--gl-border)', BORDERS = 'var(--gl-border-strong)';
  const SURFACE = 'var(--gl-surface)', BG = 'var(--gl-bg)', INPUT = 'var(--gl-input-bg)';
  const MONO = 'var(--gl-font-mono)', DISPLAY = 'var(--gl-font-display)';

  const TONES = { success: 'var(--gl-success-500)', warning: 'var(--gl-warning-500)', info: BLUE, danger: 'var(--gl-danger-500)', neutral: FG3 };
  function Pill({ tone = 'neutral', children }) {
    const c = TONES[tone] || FG3;
    return <span style={{ padding: '3px 9px', background: `color-mix(in srgb, ${c} 15%, transparent)`, color: c, borderRadius: 999, fontSize: 11, fontWeight: 700, letterSpacing: '.04em', whiteSpace: 'nowrap' }}>{children}</span>;
  }
  function Btn({ children, primary }) {
    return <span style={{ display: 'inline-flex', alignItems: 'center', height: 34, padding: '0 16px', borderRadius: 'var(--gl-radius-md)', fontSize: 13, fontWeight: 600, whiteSpace: 'nowrap', background: primary ? BLUE : 'transparent', color: primary ? '#fff' : FG1, border: primary ? '1px solid transparent' : `1px solid ${BORDERS}` }}>{children}</span>;
  }
  function Avatar({ name, hue = 230, size = 30 }) {
    const initials = name.split(' ').filter(Boolean).slice(0, 2).map((w) => w[0]).join('');
    return <span style={{ width: size, height: size, flexShrink: 0, borderRadius: 999, background: `oklch(0.42 0.09 ${hue})`, color: '#fff', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: size * 0.38, fontWeight: 700, fontFamily: DISPLAY }}>{initials}</span>;
  }
  function Header({ crumb, title, desc, actions }) {
    return (
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 20, flexWrap: 'wrap' }}>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontFamily: MONO, fontSize: 11, color: FG3, letterSpacing: '.04em', marginBottom: 7 }}>{crumb}</div>
          <h1 style={{ margin: 0, fontFamily: DISPLAY, fontWeight: 700, fontSize: 26, lineHeight: 1.15, color: FG1 }}>{title}</h1>
          {desc && <p style={{ margin: '8px 0 0', fontSize: 13.5, color: FG3, lineHeight: 1.5, maxWidth: 560 }}>{desc}</p>}
        </div>
        {actions && <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>{actions}</div>}
      </div>
    );
  }
  function Card({ children, pad = 0, style }) {
    return <div style={{ background: BG, border: `1px solid ${BORDER}`, borderRadius: 'var(--gl-radius-lg)', padding: pad, ...style }}>{children}</div>;
  }
  // generic data table
  function Table({ cols, rows }) {
    const grid = cols.map((c) => c.w || '1fr').join(' ');
    const align = (c) => (c.align === 'end' ? 'flex-end' : 'flex-start');
    return (
      <Card>
        <div style={{ display: 'grid', gridTemplateColumns: grid, gap: 0, padding: '12px 18px', borderBottom: `1px solid ${BORDER}`, fontSize: 10.5, fontWeight: 700, letterSpacing: '.06em', textTransform: 'uppercase', color: FG3 }}>
          {cols.map((c, i) => <span key={i} style={{ display: 'flex', justifyContent: align(c), fontFamily: MONO }}>{c.label}</span>)}
        </div>
        {rows.map((r, ri) => (
          <div key={ri} style={{ display: 'grid', gridTemplateColumns: grid, gap: 0, padding: '13px 18px', borderBottom: ri < rows.length - 1 ? `1px solid ${BORDER}` : 'none', alignItems: 'center', background: r.__hi ? 'color-mix(in srgb, var(--gl-blue-500) 7%, transparent)' : 'transparent' }}>
            {r.cells.map((cell, ci) => {
              const c = cols[ci];
              const tone = cell && cell.tone;
              return (
                <span key={ci} style={{ display: 'flex', justifyContent: align(c), alignItems: 'center', gap: 8, fontSize: 13, color: tone ? TONES[tone] : (cell && cell.strong ? FG1 : FG2), fontWeight: cell && cell.strong ? 600 : 500, fontFamily: cell && cell.mono ? MONO : 'inherit', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {cell && cell.pill ? <Pill tone={cell.tone}>{cell.v}</Pill> : (cell && cell.node ? cell.node : (cell && typeof cell === 'object' ? cell.v : cell))}
                </span>
              );
            })}
          </div>
        ))}
      </Card>
    );
  }
  function Stat({ label, value, delta, up }) {
    return (
      <Card pad={16} style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11.5, color: FG3, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{label}</div>
        <div style={{ fontFamily: DISPLAY, fontWeight: 700, fontSize: 23, color: FG1, marginTop: 8, whiteSpace: 'nowrap' }}>{value}</div>
        {delta && <div style={{ fontSize: 12, marginTop: 6, fontWeight: 600, color: up ? 'var(--gl-success-500)' : 'var(--gl-danger-500)' }}>{up ? '▲' : '▼'} {delta}</div>}
      </Card>
    );
  }
  const SAR = (n) => 'SAR ' + n;

  /* ── Chart of Accounts (ledger) ── */
  function PageLedger({ tab }) {
    const rows = [
      ['1000', 'Cash on Hand', 'Asset', '24,500.00'],
      ['1010', 'Bank — NCB Current', 'Asset', '318,920.45'],
      ['1200', 'Accounts Receivable', 'Asset', '87,340.00'],
      ['1400', 'Inventory', 'Asset', '156,200.00'],
      ['2000', 'Accounts Payable', 'Liability', '64,180.30'],
      ['3000', "Owner's Capital", 'Equity', '400,000.00'],
      ['4000', 'Sales Revenue', 'Income', '512,660.00'],
      ['5000', 'Cost of Goods Sold', 'Expense', '233,410.00'],
      ['6000', 'Salaries Expense', 'Expense', '96,000.00'],
    ];
    const toneFor = (t) => ({ Asset: 'info', Liability: 'warning', Equity: 'neutral', Income: 'success', Expense: 'danger' }[t] || 'neutral');
    return (
      <div>
        <Header crumb="Accounting / General Ledger" title={tab.title} desc="Every posting account in the workspace, grouped by classification with live balances."
          actions={<><Btn>Export</Btn><Btn primary>New account</Btn></>} />
        <div style={{ display: 'flex', gap: 10, margin: '20px 0 16px', flexWrap: 'wrap' }}>
          <span style={{ flex: 1, minWidth: 200, height: 38, display: 'flex', alignItems: 'center', padding: '0 14px', background: INPUT, border: `1px solid ${BORDERS}`, borderRadius: 'var(--gl-radius-md)', color: FG3, fontSize: 13 }}>Search accounts…</span>
          <span style={{ height: 38, display: 'inline-flex', alignItems: 'center', padding: '0 14px', background: 'transparent', border: `1px solid ${BORDERS}`, borderRadius: 'var(--gl-radius-md)', color: FG2, fontSize: 13 }}>All types ▾</span>
          <span style={{ height: 38, display: 'inline-flex', alignItems: 'center', padding: '0 14px', background: 'transparent', border: `1px solid ${BORDERS}`, borderRadius: 'var(--gl-radius-md)', color: FG2, fontSize: 13 }}>FY 2024 ▾</span>
        </div>
        <Table
          cols={[{ label: 'Code', w: '90px' }, { label: 'Account' }, { label: 'Type', w: '130px' }, { label: 'Balance', w: '160px', align: 'end' }]}
          rows={rows.map(([code, name, type, bal], i) => ({ __hi: i === 1, cells: [
            { v: code, mono: true }, { v: name, strong: true }, { v: type, pill: true, tone: toneFor(type) }, { v: SAR(bal), mono: true, strong: true },
          ] }))} />
      </div>
    );
  }

  /* ── Opening Journal Entry (doc) ── */
  function PageDoc({ tab }) {
    const lines = [
      ['1000', 'Cash on Hand', '120,000.00', ''],
      ['1010', 'Bank — NCB Current', '280,000.00', ''],
      ['1400', 'Inventory', '156,200.00', ''],
      ['3000', "Owner's Capital", '', '556,200.00'],
    ];
    return (
      <div>
        <Header crumb="Accounting / Journal" title={tab.title}
          actions={<><Pill tone="warning">UNSAVED</Pill><Btn>Discard</Btn><Btn primary>Post entry</Btn></>} />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, margin: '20px 0 16px' }}>
          {[['Date', '01 Jan 2024'], ['Reference', 'JV-2024-0042'], ['Period', 'FY2024 · P1'], ['Prepared by', 'M. Nasser']].map(([k, v], i) => (
            <Card key={i} pad={14}><div style={{ fontSize: 10.5, color: FG3, fontFamily: MONO, letterSpacing: '.04em', textTransform: 'uppercase' }}>{k}</div><div style={{ fontSize: 14, color: FG1, fontWeight: 600, marginTop: 6 }}>{v}</div></Card>
          ))}
        </div>
        <Table
          cols={[{ label: 'Code', w: '90px' }, { label: 'Account' }, { label: 'Debit', w: '150px', align: 'end' }, { label: 'Credit', w: '150px', align: 'end' }]}
          rows={lines.map(([code, name, dr, cr]) => ({ cells: [
            { v: code, mono: true }, { v: name, strong: true },
            { v: dr ? SAR(dr) : '—', mono: true, tone: dr ? undefined : 'neutral' },
            { v: cr ? SAR(cr) : '—', mono: true, tone: cr ? undefined : 'neutral' },
          ] }))} />
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 40, padding: '14px 18px', marginTop: 2, fontFamily: MONO }}>
          <div style={{ textAlign: 'right' }}><div style={{ fontSize: 10.5, color: FG3, textTransform: 'uppercase', letterSpacing: '.05em' }}>Total debit</div><div style={{ fontSize: 16, fontWeight: 700, color: FG1, marginTop: 4 }}>SAR 556,200.00</div></div>
          <div style={{ textAlign: 'right' }}><div style={{ fontSize: 10.5, color: FG3, textTransform: 'uppercase', letterSpacing: '.05em' }}>Total credit</div><div style={{ fontSize: 16, fontWeight: 700, color: FG1, marginTop: 4 }}>SAR 556,200.00</div></div>
          <div style={{ textAlign: 'right' }}><div style={{ fontSize: 10.5, color: FG3, textTransform: 'uppercase', letterSpacing: '.05em' }}>Difference</div><div style={{ fontSize: 16, fontWeight: 700, color: 'var(--gl-success-500)', marginTop: 4 }}>SAR 0.00</div></div>
        </div>
      </div>
    );
  }

  /* ── Store detail (store) ── */
  function PageStore({ tab }) {
    return (
      <div>
        <div style={{ height: 96, borderRadius: 'var(--gl-radius-lg)', background: `linear-gradient(120deg, oklch(0.40 0.07 250), oklch(0.34 0.06 220))`, position: 'relative', display: 'flex', alignItems: 'flex-end', padding: 18 }}>
          <div>
            <div style={{ fontFamily: MONO, fontSize: 11, color: 'rgba(255,255,255,.7)', letterSpacing: '.05em' }}>BRANCH · RYD-01</div>
            <div style={{ fontFamily: DISPLAY, fontWeight: 700, fontSize: 24, color: '#fff', marginTop: 4 }}>{tab.title}</div>
          </div>
          <span style={{ position: 'absolute', top: 16, insetInlineEnd: 16 }}><Pill tone="success">OPEN</Pill></span>
        </div>
        <div style={{ display: 'flex', gap: 12, margin: '18px 0' }}>
          <Stat label="Today's sales" value="SAR 18,420" delta="6.2% vs avg" up />
          <Stat label="Transactions" value="142" delta="12 in last hour" up />
          <Stat label="Avg basket" value="SAR 129.70" delta="1.4%" up={false} />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 16 }}>
          <Card pad={18}>
            <div style={{ fontWeight: 700, fontSize: 14, color: FG1, marginBottom: 12 }}>Store details</div>
            {[['Address', 'King Fahd Rd, Al Olaya, Riyadh'], ['Manager', 'Sara Al-Otaibi'], ['Hours', '09:00 – 23:00 · Daily'], ['Phone', '+966 11 555 0123'], ['Tax ID', '3001-4429-77']].map(([k, v], i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between', gap: 16, padding: '9px 0', borderBottom: i < 4 ? `1px solid ${BORDER}` : 'none' }}>
                <span style={{ fontSize: 13, color: FG3 }}>{k}</span><span style={{ fontSize: 13, color: FG1, fontWeight: 600, textAlign: 'right' }}>{v}</span>
              </div>
            ))}
          </Card>
          <Card pad={18}>
            <div style={{ fontWeight: 700, fontSize: 14, color: FG1, marginBottom: 12 }}>On shift</div>
            {[['Sara Al-Otaibi', 'Manager', 200], ['Lina Haddad', 'Cashier', 30], ['Khalid Faisal', 'Inventory', 140]].map(([n, role, hue], i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '8px 0' }}>
                <Avatar name={n} hue={hue} size={32} />
                <div style={{ minWidth: 0 }}><div style={{ fontSize: 13, color: FG1, fontWeight: 600 }}>{n}</div><div style={{ fontSize: 11.5, color: FG3 }}>{role}</div></div>
              </div>
            ))}
          </Card>
        </div>
      </div>
    );
  }

  /* ── Dashboard (chart) ── */
  function PageDashboard({ tab }) {
    const bars = [[ 'Jan', 58 ], [ 'Feb', 72 ], [ 'Mar', 49 ], [ 'Apr', 81 ], [ 'May', 66 ], [ 'Jun', 94 ], [ 'Jul', 77 ]];
    const max = 100;
    return (
      <div>
        <Header crumb="Overview" title={tab.title} desc="Live financial position across all branches, month to date."
          actions={<><Btn>Last 7 months ▾</Btn><Btn primary>Export report</Btn></>} />
        <div style={{ display: 'flex', gap: 12, margin: '20px 0 16px' }}>
          <Stat label="Revenue MTD" value="SAR 512,660" delta="8.4%" up />
          <Stat label="Expenses MTD" value="SAR 329,410" delta="3.1%" up={false} />
          <Stat label="Net profit" value="SAR 183,250" delta="18.2%" up />
          <Stat label="Cash position" value="SAR 343,420" delta="2.0%" up />
        </div>
        <Card pad={20}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div style={{ fontWeight: 700, fontSize: 14, color: FG1 }}>Monthly revenue</div>
            <Pill tone="success">▲ 8.4% YoY</Pill>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, height: 150, paddingTop: 8 }}>
            {bars.map(([m, v], i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, height: '100%', justifyContent: 'flex-end' }}>
                <div style={{ width: '100%', maxWidth: 46, height: `${(v / max) * 100}%`, background: i === 5 ? BLUE : 'color-mix(in srgb, var(--gl-blue-500) 28%, transparent)', borderRadius: '4px 4px 0 0' }} />
                <span style={{ fontSize: 11, color: FG3, fontFamily: MONO }}>{m}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    );
  }

  /* ── People directory (user) ── */
  function PagePeople({ tab }) {
    const people = [
      ['Sara Al-Otaibi', 'Branch Manager', 'Riyadh', 'Active', 'success', 200],
      ['Mohammed Nasser', 'Accountant', 'Head Office', 'Active', 'success', 250],
      ['Lina Haddad', 'Cashier', 'Riyadh', 'On leave', 'warning', 30],
      ['Khalid Faisal', 'Inventory Lead', 'Jeddah', 'Active', 'success', 140],
      ['Noura Saleh', 'Sales Associate', 'Riyadh', 'Invited', 'info', 320],
    ];
    return (
      <div>
        <Header crumb="Organization" title={tab.title} desc="Team members with workspace access and their current status."
          actions={<><Btn>Filter</Btn><Btn primary>Invite people</Btn></>} />
        <div style={{ marginTop: 20 }}>
          <Table
            cols={[{ label: 'Name' }, { label: 'Role', w: '170px' }, { label: 'Location', w: '140px' }, { label: 'Status', w: '120px', align: 'end' }]}
            rows={people.map(([n, role, loc, st, tone, hue]) => ({ cells: [
              { node: <span style={{ display: 'inline-flex', alignItems: 'center', gap: 11 }}><Avatar name={n} hue={hue} size={30} /><span style={{ fontWeight: 600, color: FG1 }}>{n}</span></span> },
              { v: role }, { v: loc }, { v: st, pill: true, tone },
            ] }))} />
        </div>
      </div>
    );
  }

  /* ── Generic workspace page (globe / fallback) ── */
  function PageGeneric({ tab }) {
    return (
      <div>
        <Header crumb="Workspace" title={tab.title} desc="Overview of recent activity and connected services."
          actions={<Btn primary>Settings</Btn>} />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 20 }}>
          <Card pad={18}>
            <div style={{ fontWeight: 700, fontSize: 14, color: FG1, marginBottom: 12 }}>Recent activity</div>
            {[['Posted JV-2024-0042', '2m ago'], ['Reconciled NCB account', '1h ago'], ['Added store · Jeddah North', '3h ago'], ['Invited Noura Saleh', 'Yesterday']].map(([t, when], i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 0', borderBottom: i < 3 ? `1px solid ${BORDER}` : 'none' }}>
                <span style={{ width: 7, height: 7, borderRadius: 999, background: BLUE, flexShrink: 0 }} />
                <span style={{ fontSize: 13, color: FG1, flex: 1 }}>{t}</span>
                <span style={{ fontSize: 11.5, color: FG3, fontFamily: MONO }}>{when}</span>
              </div>
            ))}
          </Card>
          <Card pad={18}>
            <div style={{ fontWeight: 700, fontSize: 14, color: FG1, marginBottom: 12 }}>Connected platforms</div>
            {[['Salla', true], ['Zid', true], ['Foodics POS', false]].map(([n, on], i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 0', borderBottom: i < 2 ? `1px solid ${BORDER}` : 'none' }}>
                <span style={{ fontSize: 13, color: FG1, fontWeight: 600, flex: 1 }}>{n}</span>
                {on ? <Pill tone="success">Connected</Pill> : <Btn>Connect</Btn>}
              </div>
            ))}
          </Card>
        </div>
      </div>
    );
  }

  function TabPage({ tab }) {
    if (!tab) return null;
    const Comp = { ledger: PageLedger, doc: PageDoc, store: PageStore, chart: PageDashboard, user: PagePeople }[tab.icon] || PageGeneric;
    return (
      <div style={{ fontFamily: 'var(--gl-font-body)', color: FG1, background: SURFACE }}>
        <Comp tab={tab} />
      </div>
    );
  }

  window.TabPage = TabPage;
})();
