/* global React */
// GeniusLink shared components.
// Loaded via <script type="text/babel"> AFTER React/ReactDOM/Babel.
// Exports everything to window so the per-screen files can pick them up.

const { useState, useEffect, useRef } = React;

/* =========================================================
   ICONS — outline, 1.5px, rounded. inherits currentColor.
   ========================================================= */
const ICON_PATHS = {
  edit: 'M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7|M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z',
  trash: 'M3 6h18|M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6|M10 11v6|M14 11v6|M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2',
  lock: 'M7 11V7a5 5 0 0 1 10 0v4',
  lockBody: 'M5 11h14v10H5z',
  chevDown: 'M6 9l6 6 6-6',
  chevUp: 'M6 15l6-6 6 6',
  chevRight: 'M9 6l6 6-6 6',
  back: 'M19 12H5|M12 19l-7-7 7-7',
  search: 'M21 21l-4.35-4.35',
  searchBody: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16z',
  plus: 'M12 5v14|M5 12h14',
  check: 'M20 6L9 17l-5-5',
  close: 'M18 6L6 18|M6 6l12 12',
  info: 'M12 16v-4|M12 8h.01',
  infoBody: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
  download: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4|M7 10l5 5 5-5|M12 15V3',
  paperclip: 'M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.19 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48',
  upload: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4|M17 8l-5-5-5 5|M12 3v12',
  store: 'M3 9l2-5h14l2 5|M3 9v11a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1V9|M3 9h18|M9 21V12h6v9',
  compass: 'M16.24 7.76L14.12 14.12 7.76 16.24l2.12-6.36 6.36-2.12z',
  compassBody: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z',
  scanner: 'M3 6v12|M6 6v12|M10 6v12|M14 6v12|M18 6v12|M21 6v12',
  briefcase: 'M20 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z|M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16',
  ledger: 'M4 4h13a3 3 0 0 1 3 3v14H7a3 3 0 0 1-3-3V4z|M8 8h8|M8 12h8|M8 16h5',
  building: 'M3 21h18|M5 21V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16|M9 9h.01|M13 9h.01|M9 13h.01|M13 13h.01|M9 17h.01|M13 17h.01',
  user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2|M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z',
  doc: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z|M14 2v6h6|M16 13H8|M16 17H8|M10 9H8',
  settings: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z|M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9 1.65 1.65 0 0 0 4.27 7.18l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z',
  globe: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z|M2 12h20|M12 2a15 15 0 0 1 0 20|M12 2a15 15 0 0 0 0 20',
  percent: 'M19 5L5 19|M6.5 5a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z|M17.5 16a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z',
  hash: 'M4 9h16|M4 15h16|M10 3L8 21|M16 3l-2 18',
  refresh: 'M23 4v6h-6|M1 20v-6h6|M3.5 9a9 9 0 0 1 14.85-3.36L23 10|M1 14l4.64 4.36A9 9 0 0 0 20.49 15',
  bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9|M13.7 21a2 2 0 0 1-3.4 0',
  mail: 'M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z|M22 6l-10 7L2 6',
  card: 'M3 5h18a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z|M2 10h20',
  link: 'M10 13a5 5 0 0 0 7 0l2-2a5 5 0 0 0-7-7l-1 1|M14 11a5 5 0 0 0-7 0l-2 2a5 5 0 0 0 7 7l1-1',
  database: 'M12 8c4.4 0 8-1.3 8-3s-3.6-3-8-3-8 1.3-8 3 3.6 3 8 3z|M4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5|M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6',
  plug: 'M9 2v6|M15 2v6|M6 8h12v3a6 6 0 0 1-12 0V8z|M12 17v5',
  key: 'M14 7a4 4 0 1 0-3.9 5L3 19v2h3l1-1h2v-2h2l1.1-1.1A4 4 0 0 0 14 7z|M15.5 7.5h.01',
  switch2: 'M16 3h5v5|M21 3l-7 7|M8 21H3v-5|M3 21l7-7',
  clock: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z|M12 6v6l4 2',
  chevLeft: 'M15 18l-6-6 6-6',
  pin: 'M12 17v5|M5 9l7-7 7 7-2 2-5-1-5 1-2-2z',
  copy: 'M9 9h11a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z|M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1',
  alert: 'M12 9v4|M12 17h.01|M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z',
  save: 'M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z|M17 21v-8H7v8|M7 3v5h8',
};

function Icon({ name, size = 16, color = 'currentColor', stroke = 1.5 }) {
  const raw = ICON_PATHS[name];
  if (!raw) return null;
  const parts = raw.split('|');
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
         stroke={color} strokeWidth={stroke}
         strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
      {parts.map((p, i) =>
        p.startsWith('M') || p.startsWith('m')
          ? <path key={i} d={p} />
          : <path key={i} d={p} />
      )}
    </svg>
  );
}

/* =========================================================
   LOGO
   ========================================================= */
function Logo({ size = 24, withWordmark = true, color }) {
  const wordColor = color || 'var(--gl-fg-1)';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <img src="assets/logo-mark.png" alt="GeniusLink"
           style={{ width: size, height: size, objectFit: 'contain' }} />
      {withWordmark && (
        <span style={{
          fontFamily: 'var(--gl-font-display)',
          fontWeight: 800,
          fontSize: size * 0.66,
          letterSpacing: '-0.01em',
          color: wordColor,
        }}>GeniusLink</span>
      )}
    </div>
  );
}

/* =========================================================
   SECTION CARD — signature 4×40 marker
   ========================================================= */
const MARKER_COLORS = {
  blue: '#4A7CFF',
  green: '#1DB88A',
  orange: '#F97316',
};

function Marker({ color = 'blue' }) {
  return (
    <div style={{
      width: 4,
      alignSelf: 'stretch',
      borderRadius: 12,
      background: MARKER_COLORS[color] || color,
      flexShrink: 0,
    }} />
  );
}

function SectionHeader({ title, subtitle, marker = 'blue', right }) {
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
      <Marker color={marker} />
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: 'var(--gl-font-body)',
          fontWeight: 700,
          fontSize: 16,
          lineHeight: '20px',
          color: 'var(--gl-fg-1)',
        }}>{title}</div>
        {subtitle && (
          <div style={{
            fontFamily: 'var(--gl-font-body)',
            fontSize: 12,
            lineHeight: '18px',
            color: 'var(--gl-fg-3)',
            marginTop: 4,
          }}>{subtitle}</div>
        )}
      </div>
      {right}
    </div>
  );
}

function Card({ children, padding = 24, style }) {
  // Compact fields occupy one grid column; everything else spans the full row.
  const COMPACT = [Field, Select, LockedField, Toggle];
  // Flatten fragments/arrays so their contents participate in the grid directly.
  const flatten = (nodes, out) => {
    React.Children.forEach(nodes, (child) => {
      if (child && typeof child === 'object' && child.type === React.Fragment) {
        flatten(child.props.children, out);
      } else {
        out.push(child);
      }
    });
    return out;
  };
  const cells = flatten(children, []).map((child, i) => {
    const isEl = child && typeof child === 'object';
    const compact = isEl && COMPACT.includes(child.type);
    return (
      <div key={i} className={compact ? undefined : 'gl-col-full'}
           style={compact ? undefined : { display: 'flex', flexDirection: 'column', gap: 24 }}>
        {child}
      </div>
    );
  });
  return (
    <div className="gl-form-grid" style={{
      background: 'var(--gl-surface)',
      border: '1px solid var(--gl-border)',
      borderRadius: 8,
      boxShadow: 'var(--gl-shadow)',
      padding,
      ...style,
    }}>{cells}</div>
  );
}

/* =========================================================
   FORM FIELDS
   ========================================================= */
function FieldLabel({ children, required, dir = 'ltr' }) {
  return (
    <div dir={dir} style={{
      fontFamily: 'var(--gl-font-body)',
      fontWeight: 700,
      fontSize: 11,
      lineHeight: '16.5px',
      letterSpacing: '0.05em',
      textTransform: 'uppercase',
      color: 'var(--gl-fg-2)',
      marginBottom: 8,
    }}>
      {children}{required && <span style={{ color: '#EF4444', marginLeft: 2 }}>*</span>}
    </div>
  );
}

function inputBaseStyle({ focused, mono, arabic } = {}) {
  return {
    width: '100%',
    height: 40,
    padding: '0 16px',
    background: 'var(--gl-input-bg)',
    border: `${focused ? 2 : 1}px solid ${focused ? '#4A7CFF' : 'var(--gl-border-strong)'}`,
    borderRadius: 4,
    fontFamily: mono ? 'var(--gl-font-mono)' : (arabic ? 'var(--gl-font-arabic)' : 'var(--gl-font-body)'),
    fontSize: 14,
    color: 'var(--gl-fg-1)',
    outline: 'none',
    boxSizing: 'border-box',
    transition: 'border-color 150ms ease',
  };
}

function Field({ label, required, placeholder, value, onChange, mono, dir, type = 'text' }) {
  const [focused, setFocused] = useState(false);
  return (
    <div dir={dir || 'ltr'}>
      <FieldLabel required={required} dir={dir || 'ltr'}>{label}</FieldLabel>
      <input
        type={type}
        value={value || ''}
        placeholder={placeholder}
        onChange={(e) => onChange && onChange(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={inputBaseStyle({ focused, mono, arabic: dir === 'rtl' })}
      />
    </div>
  );
}

function LockedField({ label, value, mono, dir }) {
  return (
    <div dir={dir || 'ltr'}>
      <FieldLabel dir={dir || 'ltr'}>{label}</FieldLabel>
      <div style={{
        ...inputBaseStyle({ mono, arabic: dir === 'rtl' }),
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        cursor: 'not-allowed',
      }}>
        <span>{value}</span>
        <Icon name="lock" size={13} color="var(--gl-fg-3)" />
      </div>
    </div>
  );
}

function Select({ label, value, options = [], required, onChange }) {
  return (
    <div>
      <FieldLabel required={required}>{label}</FieldLabel>
      <div style={{ position: 'relative' }}>
        <select
          value={value}
          onChange={(e) => onChange && onChange(e.target.value)}
          style={{
            ...inputBaseStyle(),
            appearance: 'none',
            paddingRight: 40,
            cursor: 'pointer',
          }}>
          {options.map((opt) => (
            <option key={opt.value || opt} value={opt.value || opt}>
              {opt.label || opt}
            </option>
          ))}
        </select>
        <div style={{
          position: 'absolute', right: 14, top: '50%',
          transform: 'translateY(-50%)', pointerEvents: 'none',
          color: 'var(--gl-fg-3)',
          display: 'flex',
        }}>
          <Icon name="chevDown" size={14} />
        </div>
      </div>
    </div>
  );
}

function Textarea({ label, placeholder, value, onChange, required, rows = 4 }) {
  const [focused, setFocused] = useState(false);
  return (
    <div>
      <FieldLabel required={required}>{label}</FieldLabel>
      <textarea
        rows={rows}
        value={value || ''}
        placeholder={placeholder}
        onChange={(e) => onChange && onChange(e.target.value)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={{
          ...inputBaseStyle({ focused }),
          height: 'auto',
          padding: '12px 16px',
          resize: 'vertical',
          lineHeight: 1.5,
          fontFamily: 'var(--gl-font-body)',
        }}
      />
    </div>
  );
}

function Toggle({ checked, onChange, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0' }}>
      <span style={{
        fontWeight: 700, fontSize: 11, letterSpacing: '0.05em',
        textTransform: 'uppercase', color: 'var(--gl-fg-2)',
      }}>{label}</span>
      <button
        type="button"
        onClick={() => onChange && onChange(!checked)}
        style={{
          width: 38, height: 22, borderRadius: 999,
          background: checked ? '#4A7CFF' : 'var(--gl-input-bg)',
          border: '1px solid var(--gl-border-strong)',
          position: 'relative', cursor: 'pointer',
          transition: 'background 150ms ease',
          padding: 0,
        }}>
        <span style={{
          position: 'absolute', top: 2, left: checked ? 18 : 2,
          width: 16, height: 16, borderRadius: 999,
          background: '#fff',
          transition: 'left 150ms ease',
          boxShadow: '0 1px 2px rgba(0,0,0,0.3)',
        }} />
      </button>
    </div>
  );
}

function BilingualPair({ enLabel, arLabel, enPlaceholder, arPlaceholder, required, values = {}, onChange }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
      <Field label={enLabel} required={required}
             placeholder={enPlaceholder}
             value={values.en}
             onChange={(v) => onChange && onChange({ ...values, en: v })} />
      <Field label={arLabel} required={required}
             placeholder={arPlaceholder}
             value={values.ar}
             dir="rtl"
             onChange={(v) => onChange && onChange({ ...values, ar: v })} />
    </div>
  );
}

/* =========================================================
   BUTTONS
   ========================================================= */
function Button({ children, variant = 'primary', icon, onClick, disabled, type = 'button' }) {
  const [hover, setHover] = useState(false);
  const [press, setPress] = useState(false);
  const variants = {
    primary: {
      background: press ? '#3D6DEB' : (hover ? '#5E8DFF' : '#4A7CFF'),
      color: '#FFFFFF',
      border: 'none',
    },
    secondary: {
      background: hover ? 'var(--gl-hover)' : 'transparent',
      color: 'var(--gl-fg-1)',
      border: '1px solid var(--gl-border-strong)',
    },
    danger: {
      background: hover ? 'rgba(239,68,68,0.08)' : 'transparent',
      color: '#EF4444',
      border: '1px solid rgba(239,68,68,0.4)',
    },
    ghost: {
      background: hover ? 'var(--gl-hover)' : 'transparent',
      color: 'var(--gl-fg-2)',
      border: 'none',
    },
  };
  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => { setHover(false); setPress(false); }}
      onMouseDown={() => setPress(true)}
      onMouseUp={() => setPress(false)}
      style={{
        ...variants[variant],
        height: 40,
        padding: '0 16px',
        borderRadius: 4,
        fontFamily: 'var(--gl-font-body)',
        fontWeight: variant === 'primary' ? 600 : 500,
        fontSize: 14,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.4 : 1,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        transform: press ? 'scale(0.98)' : 'scale(1)',
        transition: 'background 150ms ease, transform 80ms ease',
      }}>
      {icon && <Icon name={icon} size={14} />}
      {children}
    </button>
  );
}

function IconBtn({ icon, onClick, variant = 'neutral', size = 36, title }) {
  const [hover, setHover] = useState(false);
  const colors = {
    neutral: { bg: hover ? 'var(--gl-hover)' : 'var(--gl-input-bg)', fg: 'var(--gl-fg-1)' },
    danger:  { bg: hover ? 'rgba(239,68,68,0.12)' : 'var(--gl-input-bg)', fg: '#EF4444' },
  };
  const c = colors[variant];
  return (
    <button type="button"
      onClick={onClick}
      title={title}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        width: size, height: size, borderRadius: 4,
        background: c.bg, color: c.fg,
        border: '1px solid var(--gl-border)',
        cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        transition: 'background 150ms ease',
      }}>
      <Icon name={icon} size={Math.round(size * 0.45)} />
    </button>
  );
}

/* =========================================================
   STATUS PILL
   ========================================================= */
const PILL_COLORS = {
  success:  { bg: 'rgba(29,184,138,.18)',  fg: '#1DB88A' },
  info:     { bg: 'rgba(74,124,255,.18)',  fg: '#4A7CFF' },
  warning:  { bg: 'rgba(249,115,22,.18)',  fg: '#F97316' },
  danger:   { bg: 'rgba(239,68,68,.18)',   fg: '#EF4444' },
  neutral:  { bg: 'rgba(141,144,160,.18)', fg: 'var(--gl-fg-2)' },
};
function StatusPill({ children, tone = 'success', size = 'md' }) {
  const c = PILL_COLORS[tone];
  const fs = size === 'sm' ? 9 : 10;
  const py = size === 'sm' ? 3 : 4;
  return (
    <span style={{
      display: 'inline-block',
      padding: `${py}px 10px`,
      background: c.bg,
      color: c.fg,
      borderRadius: 12,
      fontFamily: 'var(--gl-font-body)',
      fontWeight: 700,
      fontSize: fs,
      letterSpacing: '0.08em',
      textTransform: 'uppercase',
      lineHeight: 1.4,
      whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}

/* =========================================================
   PAGE CHROME
   ========================================================= */
function Breadcrumb({ items = [] }) {
  return (
    <div style={{
      fontFamily: 'var(--gl-font-body)',
      fontWeight: 700,
      fontSize: 11,
      letterSpacing: '0.15em',
      textTransform: 'uppercase',
      color: '#4A7CFF',
      display: 'flex',
      gap: 10,
      alignItems: 'center',
      flexWrap: 'wrap',
    }}>
      {items.map((it, i) => {
        const obj = it && typeof it === 'object' ? it : { label: it };
        const last = i === items.length - 1;
        const clickable = obj.onClick && !last;
        return (
          <React.Fragment key={i}>
            <span
              onClick={clickable ? obj.onClick : undefined}
              style={{ opacity: last ? 1 : 0.7, cursor: clickable ? 'pointer' : 'default' }}
              onMouseEnter={clickable ? (e) => { e.currentTarget.style.opacity = 1; } : undefined}
              onMouseLeave={clickable ? (e) => { e.currentTarget.style.opacity = 0.7; } : undefined}
            >{obj.label}</span>
            {!last && <span style={{ color: 'var(--gl-fg-3)' }}>•</span>}
          </React.Fragment>
        );
      })}
    </div>
  );
}

function PageTitle({ children, arabic, right }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', gap: 16 }}>
      <h1 style={{
        fontFamily: 'var(--gl-font-display)',
        fontWeight: 700,
        fontSize: 26,
        lineHeight: 1.5,
        letterSpacing: '-0.025em',
        color: 'var(--gl-fg-1)',
        margin: 0,
        display: 'flex',
        alignItems: 'baseline',
        gap: 12,
        flexWrap: 'wrap',
      }}>
        {children}
        {arabic && (
          <span style={{
            fontFamily: 'var(--gl-font-arabic)',
            fontSize: 18,
            fontWeight: 400,
            color: '#4A7CFF',
            opacity: 0.8,
          }}>{arabic}</span>
        )}
      </h1>
      {right}
    </div>
  );
}

/* =========================================================
   TABLES
   ========================================================= */
function LedgerTable({ columns, rows, footer }) {
  const grid = columns.map((c) => c.width || '1fr').join(' ');
  return (
    <div style={{ overflow: 'hidden' }}>
      {/* head */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: grid,
        padding: '12px 0',
        borderBottom: '1px solid var(--gl-border)',
        fontFamily: 'var(--gl-font-body)',
        fontWeight: 700,
        fontSize: 10,
        letterSpacing: '0.05em',
        textTransform: 'uppercase',
        color: 'var(--gl-fg-3)',
        columnGap: 16,
      }}>
        {columns.map((c, i) => (
          <div key={i} style={{ textAlign: c.align || 'left' }}>{c.label}</div>
        ))}
      </div>
      {/* rows */}
      {rows.map((r, i) => (
        <div key={i} style={{
          display: 'grid',
          gridTemplateColumns: grid,
          padding: '14px 0',
          borderBottom: i < rows.length - 1 ? '1px solid var(--gl-border)' : 'none',
          fontFamily: 'var(--gl-font-body)',
          fontSize: 13,
          color: 'var(--gl-fg-1)',
          alignItems: 'center',
          columnGap: 16,
        }}>
          {columns.map((c, j) => (
            <div key={j} style={{
              textAlign: c.align || 'left',
              fontFamily: c.mono ? 'var(--gl-font-mono)' : undefined,
              color: c.muted ? 'var(--gl-fg-3)' : undefined,
            }}>
              {typeof r[c.key] === 'function' ? r[c.key]() : r[c.key]}
            </div>
          ))}
        </div>
      ))}
      {footer}
    </div>
  );
}

function TotalsStrip({ debits, credits, difference, currency = '$' }) {
  const diffNum = parseFloat(String(difference).replace(/,/g, '')) || 0;
  const diffColor = diffNum === 0 ? '#1DB88A' : '#EF4444';
  return (
    <div style={{
      display: 'flex', justifyContent: 'flex-end', gap: 48,
      padding: '20px 0 4px',
    }}>
      {[
        { label: 'Total Debits', value: `${currency}${debits}`, color: 'var(--gl-fg-1)' },
        { label: 'Total Credits', value: `${currency}${credits}`, color: 'var(--gl-fg-1)' },
        { label: 'Difference', value: `${currency}${difference}`, color: diffColor },
      ].map((t, i) => (
        <div key={i} style={{ textAlign: 'right' }}>
          <div style={{
            fontWeight: 700, fontSize: 10, letterSpacing: '0.08em',
            textTransform: 'uppercase', color: 'var(--gl-fg-3)',
          }}>{t.label}</div>
          <div style={{
            fontFamily: 'var(--gl-font-mono)', fontSize: 16,
            fontWeight: 600, color: t.color, marginTop: 6,
          }}>{t.value}</div>
        </div>
      ))}
    </div>
  );
}

/* =========================================================
   FOOTER
   ========================================================= */
function Footer({ left = '© 2024 GeniusLink · System Status: Operational', links = ['Privacy', 'Audit Log', 'Documentation'] }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '24px 0 40px',
      fontFamily: 'var(--gl-font-body)',
      fontWeight: 700, fontSize: 11,
      letterSpacing: '0.15em', textTransform: 'uppercase',
    }}>
      <div style={{ color: 'var(--gl-fg-4)' }}>{left}</div>
      <div style={{ display: 'flex', gap: 24, color: 'var(--gl-fg-3)' }}>
        {links.map((l, i) => (
          <a key={i} href="#"
             style={{ color: 'inherit', textDecoration: 'none', cursor: 'pointer' }}>{l}</a>
        ))}
      </div>
    </div>
  );
}

/* =========================================================
   PAGE SHELL — handles centered 680px content + footer
   ========================================================= */
function Page({ breadcrumb, title, titleArabic, titleRight, children, wide }) {
  return (
    <div style={{
      width: '100%',
      maxWidth: 1120,
      margin: '0 auto',
      padding: '64px 32px 0',
      display: 'flex',
      flexDirection: 'column',
      gap: 32,
    }}>
      {breadcrumb && <Breadcrumb items={breadcrumb} />}
      {title && <PageTitle arabic={titleArabic} right={titleRight}>{title}</PageTitle>}
      {children}
      <Footer />
    </div>
  );
}

/* =========================================================
   EXPORT TO WINDOW
   ========================================================= */
Object.assign(window, {
  Icon, Logo,
  Marker, SectionHeader, Card,
  FieldLabel, Field, LockedField, Select, Textarea, Toggle, BilingualPair,
  Button, IconBtn,
  StatusPill,
  Breadcrumb, PageTitle,
  LedgerTable, TotalsStrip,
  Footer, Page,
  MARKER_COLORS, PILL_COLORS,
});
