/* global React */
// GeniusLink DS Kit — shared primitives + gallery shell for the V2 component galleries.
// Loaded after React/Babel; exports to window. Reads tokens from design_system/tokens.css.

const { useState: useState_, useEffect: useEffect_ } = React;

/* ── icons (1.5px outline, currentColor) ── */
const DS_ICONS = {
  plus:'M12 5v14|M5 12h14', check:'M20 6L9 17l-5-5', close:'M18 6L6 18|M6 6l12 12',
  search:'M21 21l-4.35-4.35', searchO:'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16z',
  chevD:'M6 9l6 6 6-6', chevR:'M9 6l6 6-6 6', back:'M19 12H5|M12 19l-7-7 7-7',
  edit:'M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7|M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z',
  trash:'M3 6h18|M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6|M10 11v6|M14 11v6',
  bell:'M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9|M13.7 21a2 2 0 0 1-3.4 0',
  user:'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2|M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z',
  info:'M12 16v-4|M12 8h.01', infoO:'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
  lock:'M7 11V7a5 5 0 0 1 10 0v4|M5 11h14v10H5z', dots:'M12 5h.01|M12 12h.01|M12 19h.01',
  alert:'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z|M12 9v4|M12 17h.01',
  inbox:'M22 12h-6l-2 3h-4l-2-3H2|M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z',
  ban:'M4.93 4.93l14.14 14.14|M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
  ghost:'M9 10h.01|M15 10h.01|M12 2a8 8 0 0 0-8 8v12l3-3 3 3 2-3 2 3 3-3V10a8 8 0 0 0-8-8z',
  send:'M22 2L11 13|M22 2l-7 20-4-9-9-4 20-7z', mic:'M12 2a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z|M19 10v1a7 7 0 0 1-14 0v-1|M12 18v4',
  paperclip:'M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.19 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48',
  play:'M5 3l14 9-14 9V3z', pause:'M6 4h4v16H6z|M14 4h4v16h-4z', pin:'M12 17v5|M5 9l7-7 7 7-2 2-5-1-5 1-2-2z',
  doc:'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z|M14 2v6h6', poll:'M18 20V10|M12 20V4|M6 20v-6',
  image:'M3 3h18v18H3z|M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z|M21 15l-5-5L5 21', home:'M3 11l9-8 9 8|M5 10v10h14V10',
  grid:'M3 3h7v7H3z|M14 3h7v7h-7z|M14 14h7v7h-7z|M3 14h7v7H3z', calendar:'M3 4h18v18H3z|M16 2v4|M8 2v4|M3 10h18',
  trend:'M4 18l5-6 4 3 7-9|M16 6h4v4', bars:'M4 21V10|M10 21V4|M16 21v-7|M21 21H3',
};
function GLIcon({ name, size = 18, color = 'currentColor', stroke = 1.6 }) {
  const raw = DS_ICONS[name]; if (!raw) return null;
  return (<svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>{raw.split('|').map((d, i) => <path key={i} d={d} />)}</svg>);
}

/* ── atoms ── */
function DSButton({ children, variant = 'primary', icon, size = 'md', state, loading, onClick, title, type }) {
  const [hv, setHv] = useState_(false); const [pr, setPr] = useState_(false);
  const forced = state; const hover = forced === 'hover' || hv; const press = forced === 'pressed' || pr; const disabled = forced === 'disabled';
  const v = {
    primary: { background: press ? '#3D6DEB' : hover ? '#5E8DFF' : 'var(--gl-blue-500)', color: '#fff', border: 'none' },
    secondary: { background: hover ? 'var(--gl-hover)' : 'transparent', color: 'var(--gl-fg-1)', border: '1px solid var(--gl-border-strong)' },
    danger: { background: hover ? 'rgba(239,68,68,.1)' : 'transparent', color: 'var(--gl-danger-500)', border: '1px solid rgba(239,68,68,.4)' },
    ghost: { background: hover ? 'var(--gl-hover)' : 'transparent', color: 'var(--gl-fg-2)', border: 'none' },
  }[variant];
  const h = size === 'sm' ? 32 : 40;
  return (
    <button disabled={disabled} title={title} type={type || 'button'} onClick={disabled || loading ? undefined : onClick} onMouseEnter={() => setHv(1)} onMouseLeave={() => { setHv(0); setPr(0); }} onMouseDown={() => setPr(1)} onMouseUp={() => setPr(0)}
      style={{ ...v, height: h, padding: `0 ${size === 'sm' ? 12 : 16}px`, borderRadius: 'var(--gl-radius-sm)', fontFamily: 'var(--gl-font-body)', fontWeight: variant === 'primary' ? 600 : 500, fontSize: size === 'sm' ? 13 : 14, cursor: disabled ? 'not-allowed' : 'pointer', opacity: disabled ? 0.4 : 1, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8, transform: press ? 'scale(0.98)' : 'none', transition: 'background var(--gl-dur-base) var(--gl-ease-standard), transform 80ms' }}>
      {loading ? <DSSpinner size={15} color={variant === 'primary' ? '#fff' : 'var(--gl-fg-2)'} /> : icon && <GLIcon name={icon} size={15} />}
      {children}
    </button>
  );
}
function DSIconButton({ icon, variant = 'neutral', size = 36, state, onClick, title }) {
  const [hv, setHv] = useState_(false); const hover = state === 'hover' || hv; const disabled = state === 'disabled';
  const c = variant === 'danger' ? { fg: 'var(--gl-danger-500)', bg: hover ? 'rgba(239,68,68,.12)' : 'var(--gl-input-bg)' } : { fg: 'var(--gl-fg-1)', bg: hover ? 'var(--gl-hover)' : 'var(--gl-input-bg)' };
  return <button disabled={disabled} title={title} type="button" onClick={disabled ? undefined : onClick} onMouseEnter={() => setHv(1)} onMouseLeave={() => setHv(0)} style={{ width: size, height: size, borderRadius: 'var(--gl-radius-sm)', background: c.bg, color: c.fg, border: '1px solid var(--gl-border)', cursor: disabled ? 'not-allowed' : 'pointer', opacity: disabled ? 0.4 : 1, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', transition: 'background var(--gl-dur-base)' }}><GLIcon name={icon} size={Math.round(size * 0.46)} /></button>;
}
function DSSpinner({ size = 18, color = 'var(--gl-blue-500)' }) {
  return <span style={{ width: size, height: size, display: 'inline-block', borderRadius: '50%', border: `2px solid ${color}`, borderTopColor: 'transparent', animation: 'dsspin 0.7s linear infinite' }} />;
}
function DSField({ label, placeholder, value, mono, state, dir }) {
  const focused = state === 'focused'; const error = state === 'error'; const disabled = state === 'disabled';
  const bc = error ? 'var(--gl-danger-500)' : focused ? 'var(--gl-blue-500)' : 'var(--gl-border-strong)';
  return (
    <div dir={dir || 'ltr'} style={{ opacity: disabled ? 0.5 : 1 }}>
      {label && <div style={{ fontWeight: 700, fontSize: 11, letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--gl-fg-2)', marginBottom: 7 }}>{label}</div>}
      <div style={{ height: 40, padding: '0 14px', background: 'var(--gl-input-bg)', border: `${focused || error ? 2 : 1}px solid ${bc}`, borderRadius: 'var(--gl-radius-sm)', display: 'flex', alignItems: 'center', fontFamily: mono ? 'var(--gl-font-mono)' : (dir === 'rtl' ? 'var(--gl-font-arabic)' : 'var(--gl-font-body)'), fontSize: 14, color: value ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)' }}>{value || placeholder}</div>
      {error && <div style={{ fontSize: 11.5, color: 'var(--gl-danger-500)', marginTop: 6 }}>This field is required.</div>}
    </div>
  );
}
function DSSearch({ placeholder = 'Search…', value }) {
  return <div style={{ height: 40, padding: '0 14px', background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-sm)', display: 'flex', alignItems: 'center', gap: 10 }}><span style={{ position: 'relative', display: 'flex', color: 'var(--gl-fg-3)' }}><GLIcon name="searchO" size={15} /><span style={{ position: 'absolute', inset: 0 }}><GLIcon name="search" size={15} /></span></span><span style={{ fontSize: 14, color: value ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)', fontFamily: 'var(--gl-font-body)', flex: 1 }}>{value || placeholder}</span>{value && <GLIcon name="close" size={14} color="var(--gl-fg-3)" />}</div>;
}
function DSPill({ children, tone = 'success' }) {
  const m = { success: 'var(--gl-success-500)', info: 'var(--gl-blue-500)', warning: 'var(--gl-warning-500)', danger: 'var(--gl-danger-500)', neutral: 'var(--gl-fg-3)' };
  const c = m[tone];
  return <span style={{ padding: '3px 9px', background: `color-mix(in srgb, ${c} 16%, transparent)`, color: c, borderRadius: 'var(--gl-radius-xl)', fontSize: 10, fontWeight: 700, letterSpacing: '.06em', textTransform: 'uppercase', fontFamily: 'var(--gl-font-body)', whiteSpace: 'nowrap' }}>{children}</span>;
}
function DSBadge({ count, dot }) {
  if (dot) return <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--gl-danger-500)', display: 'inline-block' }} />;
  return <span style={{ minWidth: 18, height: 18, padding: '0 5px', borderRadius: 999, background: 'var(--gl-danger-500)', color: '#fff', fontSize: 11, fontWeight: 700, fontFamily: 'var(--gl-font-mono)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{count}</span>;
}
function DSChip({ children, selected, removable, icon }) {
  return <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7, height: 32, padding: '0 12px', borderRadius: 'var(--gl-radius-pill)', background: selected ? 'color-mix(in srgb, var(--gl-blue-500) 16%, transparent)' : 'var(--gl-input-bg)', border: `1px solid ${selected ? 'var(--gl-blue-500)' : 'var(--gl-border)'}`, color: selected ? 'var(--gl-blue-500)' : 'var(--gl-fg-2)', fontSize: 13, fontWeight: 500, fontFamily: 'var(--gl-font-body)', cursor: 'pointer' }}>{icon && <GLIcon name={icon} size={14} />}{children}{removable && <GLIcon name="close" size={13} />}</span>;
}
function DSAvatar({ name = 'GL', size = 36, color }) {
  const init = name.split(' ').map(w => w[0]).slice(0, 2).join('');
  return <div style={{ width: size, height: size, borderRadius: 999, background: color || 'var(--gl-input-bg)', border: color ? 'none' : '1px solid var(--gl-border-strong)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--gl-font-display)', fontWeight: 700, fontSize: size * 0.36, color: color ? '#fff' : 'var(--gl-fg-2)', flexShrink: 0 }}>{init}</div>;
}
function DSCard({ children, pad = 16 }) {
  return <div style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow)', padding: pad }}>{children}</div>;
}
function DSListTile({ icon, title, sub, trailing, avatar }) {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 4px' }}>{avatar ? <DSAvatar name={avatar} /> : icon && <span style={{ color: 'var(--gl-fg-2)', display: 'flex' }}><GLIcon name={icon} size={20} /></span>}<div style={{ flex: 1, minWidth: 0 }}><div style={{ fontSize: 14, fontWeight: 600, color: 'var(--gl-fg-1)' }}>{title}</div>{sub && <div style={{ fontSize: 12, color: 'var(--gl-fg-3)', marginTop: 2 }}>{sub}</div>}</div>{trailing}</div>;
}
function DSDivider() { return <div style={{ height: 1, background: 'var(--gl-border)' }} />; }

/* ── gallery shell ── */
function Shell({ title, subtitle, sections, children }) {
  const [theme, setTheme] = useState_(() => localStorage.getItem('ds-theme') || 'dark');
  useEffect_(() => { document.body.dataset.theme = theme === 'light' ? 'light' : ''; localStorage.setItem('ds-theme', theme); }, [theme]);
  return (
    <div style={{ minHeight: '100vh', background: 'var(--gl-bg)', color: 'var(--gl-fg-1)' }}>
      <div style={{ position: 'sticky', top: 0, zIndex: 100, background: 'color-mix(in srgb, var(--gl-bg) 88%, transparent)', backdropFilter: 'blur(12px)', borderBottom: '1px solid var(--gl-border)', padding: '18px 40px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <img src="assets/logo-mark.png" style={{ width: 26, height: 26 }} alt="" />
          <div><div style={{ fontFamily: 'var(--gl-font-display)', fontWeight: 800, fontSize: 18, letterSpacing: '-0.01em' }}>{title}</div><div style={{ fontSize: 12, color: 'var(--gl-fg-3)' }}>{subtitle}</div></div>
        </div>
        <div style={{ display: 'flex', gap: 4, background: 'var(--gl-input-bg)', padding: 4, borderRadius: 6, border: '1px solid var(--gl-border)' }}>
          {['dark', 'light'].map(t => <button key={t} onClick={() => setTheme(t)} style={{ padding: '7px 14px', borderRadius: 4, background: theme === t ? 'var(--gl-surface)' : 'transparent', color: theme === t ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)', border: 'none', cursor: 'pointer', fontFamily: 'var(--gl-font-body)', fontWeight: 700, fontSize: 10, letterSpacing: '.1em', textTransform: 'uppercase' }}>{t}</button>)}
        </div>
      </div>
      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '40px 40px 120px' }}>{children}</div>
    </div>
  );
}
function Section({ title, desc, children, cols = 'repeat(auto-fill, minmax(240px, 1fr))' }) {
  return (
    <section style={{ marginBottom: 56 }}>
      <div style={{ display: 'flex', gap: 12, alignItems: 'baseline', marginBottom: 6 }}>
        <div style={{ width: 4, height: 20, borderRadius: 12, background: 'var(--gl-blue-500)' }} />
        <h2 style={{ fontFamily: 'var(--gl-font-body)', fontWeight: 700, fontSize: 18, margin: 0, color: 'var(--gl-fg-1)' }}>{title}</h2>
      </div>
      {desc && <p style={{ fontSize: 13, color: 'var(--gl-fg-3)', margin: '0 0 20px 16px', maxWidth: 620, lineHeight: 1.5 }}>{desc}</p>}
      <div style={{ display: 'grid', gridTemplateColumns: cols, gap: 16 }}>{children}</div>
    </section>
  );
}
function Spec({ label, children, span }) {
  return (
    <div style={{ gridColumn: span ? `span ${span}` : undefined, background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', padding: 18, display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div style={{ fontWeight: 700, fontSize: 10, letterSpacing: '.08em', textTransform: 'uppercase', color: 'var(--gl-fg-3)' }}>{label}</div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, alignItems: 'center' }}>{children}</div>
    </div>
  );
}

if (!document.getElementById('ds-kf')) { const s = document.createElement('style'); s.id = 'ds-kf'; s.textContent = '@keyframes dsspin{to{transform:rotate(360deg)}}@keyframes dsshimmer{100%{transform:translateX(100%)}}'; document.head.appendChild(s); }

Object.assign(window, { GLIcon, DSButton, DSIconButton, DSSpinner, DSField, DSSearch, DSPill, DSBadge, DSChip, DSAvatar, DSCard, DSListTile, DSDivider, Shell, Section, Spec });
