/* global React */
// BrowserStyleTabBar — modern browser-style tab strip.
// Reusable, generic (no business-model coupling). Reads design tokens.
// API: <BrowserStyleTabBar tabsState /> — fully self-contained demo state.
// Features: active/inactive/hover/pressed · closable · add (+) · select · overflow scroll + chevrons ·
//           pinned tabs (icon-only, anchored) · right-click context menu (close / close others /
//           close to the right / duplicate / pin·unpin) · unsaved indicator (dirty) ·
//           close-confirmation dialog for dirty tabs · tab-list dropdown (jump to any open tab) ·
//           hover/long-press mini-page preview (thumbnail popover, varies by tab type) ·
//           long-title truncation + tooltip · drag-to-reorder · keyboard (←/→/Home/End) · dark/light · RTL.

const { useState: useStateBT, useRef: useRefBT, useEffect: useEffectBT, useCallback: useCallbackBT } = React;

function BTIcon({ name, size = 14, color = 'currentColor', stroke = 1.7 }) {
  const P = {
    close: 'M18 6L6 18|M6 6l12 12', plus: 'M12 5v14|M5 12h14',
    chevL: 'M15 18l-6-6 6-6', chevR: 'M9 18l6-6-6-6',
    globe: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z|M2 12h20|M12 2a15 15 0 0 1 0 20 15 15 0 0 1 0-20z',
    ledger: 'M4 4h13a3 3 0 0 1 3 3v14H7a3 3 0 0 1-3-3V4z|M8 8h8|M8 12h8|M8 16h5',
    store: 'M3 9l2-5h14l2 5|M3 9v11a1 1 0 0 0 1 1h16a1 1 0 0 0 1-1V9|M3 9h18',
    user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2|M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z',
    chart: 'M18 20V10|M12 20V4|M6 20v-6', doc: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z|M14 2v6h6',
    pin: 'M12 17v5|M5 9l7-7 7 7-2 2-5-1-5 1-2-2z',
    copy: 'M9 9h11a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z|M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1',
    closeRight: 'M14 6l6 6-6 6|M4 12h16',
    caret: 'M6 9l6 6 6-6',
    save: 'M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z|M17 21v-8H7v8|M7 3v5h8',
    alert: 'M12 9v4|M12 17h.01|M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z',
  };
  const raw = P[name]; if (!raw) return null;
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round">{raw.split('|').map((d, i) => <path key={i} d={d} />)}</svg>;
}

function Tab({ tab, active, compact, onSelect, onClose, onContextMenu, onPreview, first, drag }) {
  const [hover, setHover] = useStateBT(false);
  const [closeHover, setCloseHover] = useStateBT(false);
  const tabRef = useRefBT(null);
  const previewTimer = useRefBT(null);
  const dragging = drag && drag.dragId === tab.id;
  const isOver = drag && drag.overId === tab.id && drag.dragId !== tab.id;
  // ── hover-intent: surface the mini-page preview only after the pointer rests ──
  const clearPreviewTimer = () => { if (previewTimer.current) { clearTimeout(previewTimer.current); previewTimer.current = null; } };
  const armPreview = () => {
    if (!onPreview) return;
    clearPreviewTimer();
    previewTimer.current = setTimeout(() => {
      if (tabRef.current) onPreview(tab.id, tabRef.current.getBoundingClientRect(), getComputedStyle(tabRef.current).direction);
    }, 480);
  };
  const dropPreview = () => { clearPreviewTimer(); if (onPreview) onPreview(null); };
  useEffectBT(() => clearPreviewTimer, []);
  return (
    <div
      ref={tabRef}
      role="tab" aria-selected={active} aria-label={tab.title} tabIndex={active ? 0 : -1}
      draggable={!!drag}
      onDragStart={(e) => { dropPreview(); if (drag) { drag.onDragStart(tab.id); e.dataTransfer.effectAllowed = 'move'; } }}
      onDragOver={(e) => { if (drag) { e.preventDefault(); drag.onDragOver(tab.id); } }}
      onDrop={(e) => { if (drag) { e.preventDefault(); drag.onDrop(tab.id); } }}
      onDragEnd={() => drag && drag.onDragEnd()}
      onMouseEnter={() => { setHover(true); armPreview(); }} onMouseLeave={() => { setHover(false); dropPreview(); }}
      onClick={() => { dropPreview(); onSelect(tab.id); }}
      onContextMenu={(e) => { e.preventDefault(); dropPreview(); onContextMenu(e, tab.id); }}
      style={{
        position: 'relative', display: 'flex', alignItems: 'center', gap: compact ? 0 : 8,
        height: 36, paddingInline: compact ? '0' : '12px 8px',
        width: compact ? 40 : undefined, maxWidth: 200, minWidth: compact ? 40 : 120, flexShrink: 0,
        justifyContent: compact ? 'center' : 'flex-start',
        borderRadius: '9px 9px 0 0', cursor: dragging ? 'grabbing' : 'pointer', userSelect: 'none',
        background: active ? 'var(--gl-surface)' : (hover ? 'var(--gl-hover)' : 'transparent'),
        color: active ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)',
        opacity: dragging ? 0.4 : 1,
        transition: 'background var(--gl-dur-base) var(--gl-ease-standard), color var(--gl-dur-base), opacity var(--gl-dur-fast)',
      }}>
      {/* drop-insertion indicator */}
      {isOver && <span style={{ position: 'absolute', insetInlineStart: -1, top: 6, bottom: 6, width: 2, borderRadius: 2, background: 'var(--gl-blue-500)' }} />}
      {/* subtle separator before inactive tabs */}
      {!active && !first && !isOver && <span style={{ position: 'absolute', insetInlineStart: 0, top: 9, bottom: 9, width: 1, background: 'var(--gl-border)' }} />}
      <span style={{ display: 'flex', color: active ? 'var(--gl-blue-500)' : 'var(--gl-fg-3)', flexShrink: 0 }}><BTIcon name={tab.icon || 'globe'} size={14} /></span>
      {!compact && <span style={{ flex: 1, fontSize: 13, fontWeight: active ? 600 : 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontFamily: 'var(--gl-font-body)' }}>{tab.title}</span>}
      {/* compact (pinned) tab: tiny dirty dot in corner, no close button */}
      {compact
        ? (tab.dirty && <span title="Unsaved changes" style={{ position: 'absolute', top: 7, insetInlineEnd: 7, width: 6, height: 6, borderRadius: 999, background: 'var(--gl-warning-500)' }} />)
        : (tab.dirty && !hover
          ? <span title="Unsaved changes" style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--gl-warning-500)', flexShrink: 0, marginInlineEnd: 4 }} />
          : <span role="button" aria-label="Close tab"
              onMouseEnter={() => setCloseHover(true)} onMouseLeave={() => setCloseHover(false)}
              onClick={(e) => { e.stopPropagation(); onClose(tab.id); }}
              style={{ width: 18, height: 18, borderRadius: 5, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, background: closeHover ? 'var(--gl-input-bg)' : 'transparent', color: closeHover ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)', visibility: (hover || active) ? 'visible' : 'hidden' }}>
              <BTIcon name="close" size={12} />
            </span>)}
    </div>
  );
}

/* right-click context menu */
function TabMenu({ menu, onClose, items }) {
  useEffectBT(() => {
    if (!menu) return;
    const dismiss = () => onClose();
    const onKey = (e) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('mousedown', dismiss);
    window.addEventListener('scroll', dismiss, true);
    window.addEventListener('keydown', onKey);
    return () => { window.removeEventListener('mousedown', dismiss); window.removeEventListener('scroll', dismiss, true); window.removeEventListener('keydown', onKey); };
  }, [menu, onClose]);
  if (!menu) return null;
  const W = 220;
  const left = Math.min(menu.x, window.innerWidth - W - 8);
  const top = Math.min(menu.y, window.innerHeight - (items.length * 36 + 12));
  return (
    <div role="menu" onMouseDown={(e) => e.stopPropagation()}
      style={{ position: 'fixed', left, top, width: W, zIndex: 'var(--gl-z-dropdown)', background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-md)', boxShadow: 'var(--gl-shadow-pop)', padding: 6, fontFamily: 'var(--gl-font-body)' }}>
      {items.map((it, i) => it.divider
        ? <div key={i} style={{ height: 1, background: 'var(--gl-border)', margin: '6px 4px' }} />
        : <button key={i} role="menuitem" disabled={it.disabled}
            onClick={() => { if (!it.disabled) { it.run(); onClose(); } }}
            onMouseEnter={(e) => { if (!it.disabled) e.currentTarget.style.background = 'var(--gl-hover)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent'; }}
            style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 10, height: 32, padding: '0 10px', border: 'none', background: 'transparent', borderRadius: 6, cursor: it.disabled ? 'not-allowed' : 'pointer', color: it.danger ? 'var(--gl-danger-500)' : 'var(--gl-fg-1)', opacity: it.disabled ? 0.4 : 1, fontSize: 13, textAlign: 'start' }}>
            <span style={{ display: 'flex', color: 'inherit', flexShrink: 0 }}><BTIcon name={it.icon} size={15} stroke={1.6} /></span>
            <span style={{ flex: 1, textAlign: 'start' }}>{it.label}</span>
            {it.hint && <span style={{ fontSize: 11, color: 'var(--gl-fg-3)', fontFamily: 'var(--gl-font-mono)' }}>{it.hint}</span>}
          </button>)}
    </div>
  );
}

/* tab-list dropdown — jump to any open tab (anchored to its trigger button) */
function TabListMenu({ open, anchorRef, tabs, active, onPick, onClose }) {
  useEffectBT(() => {
    if (!open) return;
    const dismiss = () => onClose();
    const onKey = (e) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('mousedown', dismiss);
    window.addEventListener('scroll', dismiss, true);
    window.addEventListener('keydown', onKey);
    return () => { window.removeEventListener('mousedown', dismiss); window.removeEventListener('scroll', dismiss, true); window.removeEventListener('keydown', onKey); };
  }, [open, onClose]);
  if (!open || !anchorRef.current) return null;
  const r = anchorRef.current.getBoundingClientRect();
  const W = 280;
  const rtl = getComputedStyle(anchorRef.current).direction === 'rtl';
  const left = Math.max(8, Math.min(rtl ? r.left : r.right - W, window.innerWidth - W - 8));
  const top = Math.min(r.bottom + 6, window.innerHeight - 8);
  const maxH = Math.max(160, window.innerHeight - top - 16);
  return (
    <div role="menu" onMouseDown={(e) => e.stopPropagation()}
      style={{ position: 'fixed', left, top, width: W, maxHeight: maxH, overflowY: 'auto', zIndex: 'var(--gl-z-dropdown)', background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-md)', boxShadow: 'var(--gl-shadow-pop)', padding: 6, fontFamily: 'var(--gl-font-body)' }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '.08em', textTransform: 'uppercase', color: 'var(--gl-fg-3)', padding: '4px 10px 6px', fontFamily: 'var(--gl-font-mono)' }}>Open tabs · {tabs.length}</div>
      {tabs.map((t) => (
        <button key={t.id} role="menuitemradio" aria-checked={t.id === active}
          onClick={() => { onPick(t.id); onClose(); }}
          onMouseEnter={(e) => { if (t.id !== active) e.currentTarget.style.background = 'var(--gl-hover)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.background = t.id === active ? 'var(--gl-input-bg)' : 'transparent'; }}
          style={{ width: '100%', display: 'flex', alignItems: 'center', gap: 10, minHeight: 34, padding: '0 10px', border: 'none', background: t.id === active ? 'var(--gl-input-bg)' : 'transparent', borderRadius: 6, cursor: 'pointer', color: t.id === active ? 'var(--gl-fg-1)' : 'var(--gl-fg-2, var(--gl-fg-1))', fontSize: 13, textAlign: 'start' }}>
          <span style={{ display: 'flex', color: t.id === active ? 'var(--gl-blue-500)' : 'var(--gl-fg-3)', flexShrink: 0 }}><BTIcon name={t.icon || 'globe'} size={15} /></span>
          <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', textAlign: 'start', fontWeight: t.id === active ? 600 : 500 }}>{t.title}</span>
          {t.pinned && <span style={{ display: 'flex', color: 'var(--gl-fg-3)', flexShrink: 0 }} title="Pinned"><BTIcon name="pin" size={13} /></span>}
          {t.dirty && <span title="Unsaved changes" style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--gl-warning-500)', flexShrink: 0 }} />}
        </button>
      ))}
    </div>
  );
}

/* close-confirmation dialog for tabs with unsaved changes */
function ConfirmDialog({ data, onDiscard, onSave, onCancel }) {
  useEffectBT(() => {
    if (!data) return;
    const onKey = (e) => { if (e.key === 'Escape') onCancel(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [data, onCancel]);
  if (!data) return null;
  return (
    <div role="presentation" onMouseDown={onCancel}
      style={{ position: 'fixed', inset: 0, zIndex: 'var(--gl-z-modal, 1000)', background: 'color-mix(in srgb, var(--gl-fg-1) 38%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24, fontFamily: 'var(--gl-font-body)' }}>
      <div role="alertdialog" aria-modal="true" aria-labelledby="bt-dlg-title" onMouseDown={(e) => e.stopPropagation()}
        style={{ width: 'min(420px, 100%)', background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow-pop)', padding: 22 }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
          <span style={{ display: 'flex', flexShrink: 0, color: 'var(--gl-warning-500)', background: 'color-mix(in srgb, var(--gl-warning-500) 14%, transparent)', width: 36, height: 36, borderRadius: 999, alignItems: 'center', justifyContent: 'center' }}><BTIcon name="alert" size={18} /></span>
          <div style={{ flex: 1 }}>
            <div id="bt-dlg-title" style={{ fontFamily: 'var(--gl-font-display)', fontWeight: 700, fontSize: 16, color: 'var(--gl-fg-1)' }}>Discard unsaved changes?</div>
            <div style={{ fontSize: 13, color: 'var(--gl-fg-3)', marginTop: 6, lineHeight: 1.5 }}>“{data.title}” has edits that haven’t been saved. Closing it now will lose them.</div>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 20, flexWrap: 'wrap' }}>
          <button onClick={onCancel}
            style={{ height: 36, padding: '0 14px', borderRadius: 'var(--gl-radius-md)', border: '1px solid var(--gl-border-strong)', background: 'transparent', color: 'var(--gl-fg-1)', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit' }}>Cancel</button>
          <button onClick={onSave}
            style={{ height: 36, padding: '0 14px', borderRadius: 'var(--gl-radius-md)', border: '1px solid var(--gl-border-strong)', background: 'transparent', color: 'var(--gl-fg-1)', fontSize: 13, fontWeight: 600, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 6, fontFamily: 'inherit' }}><BTIcon name="save" size={14} /> Save &amp; close</button>
          <button onClick={onDiscard} autoFocus
            style={{ height: 36, padding: '0 14px', borderRadius: 'var(--gl-radius-md)', border: '1px solid transparent', background: 'var(--gl-danger-500)', color: '#fff', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit' }}>Discard &amp; close</button>
        </div>
      </div>
    </div>
  );
}

/* ── mini-page thumbnail ── a faux, low-fidelity render of the page a tab holds.
   Skeleton blocks sit on a recessed "viewport" (--gl-bg); fills use input-bg /
   hover, with a single blue accent per layout. Varies by tab.icon. */
function MBar({ w = '100%', h = 6, r = 3, c = 'var(--gl-input-bg)', style }) {
  return <div style={{ width: w, height: h, borderRadius: r, background: c, flexShrink: 0, ...style }} />;
}
function MiniPage({ icon }) {
  const ACC = 'var(--gl-blue-500)', FILL = 'var(--gl-input-bg)', FAINT = 'var(--gl-hover)', LINE = 'var(--gl-border)';
  const pad = { padding: 12, display: 'flex', flexDirection: 'column', gap: 8, height: '100%', boxSizing: 'border-box' };
  if (icon === 'ledger') {
    return (
      <div style={pad}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <MBar w={64} h={9} c={ACC} /><div style={{ flex: 1 }} /><MBar w={22} h={9} c={FILL} /><MBar w={22} h={9} c={FILL} />
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <MBar w="34%" h={8} c={FAINT} /><MBar w="22%" h={8} c={FAINT} /><MBar w="20%" h={8} c={FAINT} /><MBar w="16%" h={8} c={FAINT} />
        </div>
        {[0, 1, 2, 3, 4].map((i) => (
          <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <MBar w="34%" h={7} c={FILL} /><MBar w="22%" h={7} c={FILL} /><MBar w="20%" h={7} c={FILL} /><MBar w="16%" h={7} c={i === 2 ? ACC : FILL} />
          </div>
        ))}
      </div>
    );
  }
  if (icon === 'doc') {
    return (
      <div style={pad}>
        <MBar w="62%" h={12} r={4} c={ACC} />
        <div style={{ display: 'flex', gap: 6 }}><MBar w={42} h={6} c={FAINT} /><MBar w={56} h={6} c={FAINT} /></div>
        <div style={{ height: 1, background: LINE, margin: '2px 0' }} />
        {['100%', '100%', '88%'].map((w, i) => <MBar key={i} w={w} h={6} c={FILL} />)}
        <div style={{ height: 4 }} />
        {['100%', '94%', '100%', '70%'].map((w, i) => <MBar key={i} w={w} h={6} c={FILL} />)}
      </div>
    );
  }
  if (icon === 'store') {
    return (
      <div style={{ ...pad, gap: 8 }}>
        <div style={{ height: 30, borderRadius: 6, background: FAINT, position: 'relative', flexShrink: 0 }}>
          <MBar w={48} h={8} c={ACC} style={{ position: 'absolute', insetInlineStart: 8, bottom: 8 }} />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6, flex: 1 }}>
          {[0, 1, 2, 3].map((i) => (
            <div key={i} style={{ background: FILL, borderRadius: 5, padding: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
              <div style={{ height: 16, background: FAINT, borderRadius: 3 }} />
              <MBar w="72%" h={5} c={LINE} /><MBar w="44%" h={5} c={ACC} />
            </div>
          ))}
        </div>
      </div>
    );
  }
  if (icon === 'chart') {
    const bars = [42, 64, 38, 78, 52, 88, 60];
    return (
      <div style={pad}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[0, 1, 2].map((i) => (
            <div key={i} style={{ flex: 1, background: FILL, borderRadius: 5, padding: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
              <MBar w="58%" h={5} c={LINE} /><MBar w="82%" h={9} c={i === 0 ? ACC : FAINT} />
            </div>
          ))}
        </div>
        <div style={{ flex: 1, background: FILL, borderRadius: 6, padding: 8, display: 'flex', alignItems: 'flex-end', gap: 5 }}>
          {bars.map((h, i) => <div key={i} style={{ flex: 1, height: `${h}%`, background: i === 5 ? ACC : FAINT, borderRadius: '2px 2px 0 0' }} />)}
        </div>
      </div>
    );
  }
  if (icon === 'user') {
    return (
      <div style={pad}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 28, height: 28, borderRadius: 999, background: FAINT, flexShrink: 0 }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}><MBar w="55%" h={8} c={ACC} /><MBar w="38%" h={6} c={FAINT} /></div>
        </div>
        <div style={{ height: 1, background: LINE, margin: '2px 0' }} />
        {[0, 1, 2, 3].map((i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
            <div style={{ width: 16, height: 16, borderRadius: 999, background: FILL, flexShrink: 0 }} />
            <MBar w={`${70 - i * 8}%`} h={6} c={FILL} /><div style={{ flex: 1 }} /><MBar w={20} h={6} c={i === 1 ? ACC : FAINT} />
          </div>
        ))}
      </div>
    );
  }
  // globe / generic web page
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '7px 9px', borderBottom: `1px solid ${LINE}`, flexShrink: 0 }}>
        {[0, 1, 2].map((i) => <span key={i} style={{ width: 5, height: 5, borderRadius: 999, background: FAINT }} />)}
        <MBar w="62%" h={8} r={999} c={FAINT} style={{ marginInlineStart: 4 }} />
      </div>
      <div style={{ ...pad, paddingTop: 11 }}>
        <MBar w="70%" h={11} c={ACC} />
        {['100%', '100%', '90%'].map((w, i) => <MBar key={i} w={w} h={6} c={FILL} />)}
        <div style={{ height: 3 }} />
        <div style={{ display: 'flex', gap: 6 }}><MBar w="48%" h={26} r={5} c={FAINT} /><MBar w="48%" h={26} r={5} c={FAINT} /></div>
      </div>
    </div>
  );
}

const PREVIEW_META = {
  ledger: 'Accounting · Ledger', doc: 'Journal · Document', store: 'Branch · Storefront',
  chart: 'Analytics · Dashboard', user: 'Directory · People', globe: 'Workspace · Page',
};

/* hover/long-press preview popover — anchored to the hovered tab, non-interactive */
function TabPreview({ data, onClose }) {
  const [show, setShow] = useStateBT(false);
  const CARD_W = 268, CARD_H = 200;
  useEffectBT(() => {
    if (!data) return;
    const t = setTimeout(() => setShow(true), 16);   // robust even when rAF is throttled
    const dismiss = () => onClose && onClose();
    window.addEventListener('scroll', dismiss, true);
    window.addEventListener('resize', dismiss);
    return () => { clearTimeout(t); window.removeEventListener('scroll', dismiss, true); window.removeEventListener('resize', dismiss); };
  }, []);
  if (!data || !data.tab) return null;
  const { tab, rect, dir } = data;
  const rtl = dir === 'rtl';
  const left = Math.max(8, Math.min(rect.left, window.innerWidth - CARD_W - 8));
  let top = rect.bottom + 9, above = false;
  if (top + CARD_H > window.innerHeight - 8) { top = rect.top - CARD_H - 9; above = true; }
  const arrowX = Math.max(16, Math.min(rect.left + rect.width / 2 - left, CARD_W - 16));
  return (
    <div style={{
      position: 'fixed', left, top, width: CARD_W, zIndex: 'var(--gl-z-tooltip)', pointerEvents: 'none',
      opacity: show ? 1 : 0, transform: show ? 'translateY(0)' : `translateY(${above ? 5 : -5}px)`,
      transition: 'opacity var(--gl-dur-base) var(--gl-ease-out), transform var(--gl-dur-base) var(--gl-ease-out)',
      fontFamily: 'var(--gl-font-body)',
    }}>
      <div style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border-strong)', borderRadius: 'var(--gl-radius-md)', boxShadow: 'var(--gl-shadow-pop)', overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '9px 11px', borderBottom: '1px solid var(--gl-border)' }}>
          <span style={{ display: 'flex', color: 'var(--gl-blue-500)', flexShrink: 0 }}><BTIcon name={tab.icon || 'globe'} size={15} /></span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{tab.title}</div>
            <div style={{ fontSize: 10.5, color: 'var(--gl-fg-3)', fontFamily: 'var(--gl-font-mono)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginTop: 1 }}>{PREVIEW_META[tab.icon] || PREVIEW_META.globe}</div>
          </div>
          {tab.pinned && <span style={{ display: 'flex', color: 'var(--gl-fg-3)', flexShrink: 0 }} title="Pinned"><BTIcon name="pin" size={12} /></span>}
          {tab.dirty && <span title="Unsaved changes" style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--gl-warning-500)', flexShrink: 0 }} />}
        </div>
        {/* live miniature: a real, scaled-down render of the page this tab holds */}
        <div style={{ position: 'relative', width: CARD_W, height: 150, overflow: 'hidden', background: 'var(--gl-surface)', borderTop: '1px solid var(--gl-border)' }}>
          {window.TabPage
            ? <div style={{ position: 'absolute', top: 0, [rtl ? 'right' : 'left']: 0, width: 940, padding: 20, boxSizing: 'border-box', transform: `scale(${CARD_W / 940})`, transformOrigin: rtl ? 'top right' : 'top left', direction: rtl ? 'rtl' : 'ltr', pointerEvents: 'none' }}>
                {React.createElement(window.TabPage, { tab })}
              </div>
            : <div style={{ height: '100%', background: 'var(--gl-bg)' }}><MiniPage icon={tab.icon} /></div>}
          {/* sheen so the crop reads as a thumbnail, not a clipped page */}
          <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', background: 'linear-gradient(to bottom, transparent 78%, color-mix(in srgb, var(--gl-surface) 70%, transparent))' }} />
        </div>
      </div>
      <span style={{
        position: 'absolute', insetInlineStart: arrowX - 5, width: 9, height: 9, background: 'var(--gl-surface)',
        transform: 'rotate(45deg)',
        ...(above
          ? { bottom: -5, borderRight: '1px solid var(--gl-border-strong)', borderBottom: '1px solid var(--gl-border-strong)' }
          : { top: -5, borderLeft: '1px solid var(--gl-border-strong)', borderTop: '1px solid var(--gl-border-strong)' }),
      }} />
    </div>
  );
}

function BrowserStyleTabBar({ tabsState }) {
  const seedRef = useRefBT(10);
  const [tabs, setTabs] = useStateBT(tabsState || [
    { id: 1, title: 'Chart of Accounts', icon: 'ledger', pinned: true },
    { id: 2, title: 'Opening Journal Entry — JV-2024-0042', icon: 'doc', dirty: true },
    { id: 3, title: 'Downtown Central Store', icon: 'store' },
    { id: 4, title: 'Dashboard', icon: 'chart' },
    { id: 5, title: 'Trial Balance — FY2024 Q3', icon: 'ledger' },
  ]);
  const [active, setActive] = useStateBT(2);
  const [dragId, setDragId] = useStateBT(null);
  const [overId, setOverId] = useStateBT(null);
  const [menu, setMenu] = useStateBT(null);            // { id, x, y }
  const [chev, setChev] = useStateBT({ start: false, end: false });
  const [confirm, setConfirm] = useStateBT(null);      // { id, title } — dirty-close guard
  const [listOpen, setListOpen] = useStateBT(false);   // tab-list dropdown
  const [preview, setPreview] = useStateBT(null);      // { id, rect } — hover mini-page preview
  const stripRef = useRefBT(null);
  const listBtnRef = useRefBT(null);

  const pinned = tabs.filter((t) => t.pinned);
  const unpinned = tabs.filter((t) => !t.pinned);
  const ordered = [...pinned, ...unpinned];

  /* ── overflow chevrons ── */
  const measure = useCallbackBT(() => {
    const el = stripRef.current; if (!el) return;
    const max = el.scrollWidth - el.clientWidth;
    const sl = Math.abs(el.scrollLeft);
    setChev({ start: max > 2 && sl > 2, end: max > 2 && sl < max - 2 });
  }, []);
  useEffectBT(() => {
    measure();
    const el = stripRef.current; if (!el) return;
    el.addEventListener('scroll', measure, { passive: true });
    const ro = new ResizeObserver(measure); ro.observe(el);
    return () => { el.removeEventListener('scroll', measure); ro.disconnect(); };
  }, [measure, tabs.length]);
  const scrollByDir = (towardEnd) => {
    const el = stripRef.current; if (!el) return;
    const rtl = getComputedStyle(el).direction === 'rtl';
    el.scrollBy({ left: 220 * (towardEnd ? 1 : -1) * (rtl ? -1 : 1), behavior: 'smooth' });
  };

  /* ── tab ops ── */
  const reorder = (fromId, toId) => {
    if (fromId == null || toId == null || fromId === toId) return;
    setTabs((prev) => {
      const arr = [...prev];
      const from = arr.findIndex((t) => t.id === fromId);
      const to = arr.findIndex((t) => t.id === toId);
      if (from < 0 || to < 0) return prev;
      const [moved] = arr.splice(from, 1);
      arr.splice(to, 0, moved);
      return arr;
    });
  };
  const drag = {
    dragId, overId,
    onDragStart: (id) => setDragId(id),
    onDragOver: (id) => setOverId(id),
    onDrop: (id) => { reorder(dragId, id); setDragId(null); setOverId(null); },
    onDragEnd: () => { setDragId(null); setOverId(null); },
  };

  const select = (id) => setActive(id);
  // hover preview: ignore while dragging or with a menu/dialog already open
  const handlePreview = (id, rect, dir) => {
    if (id == null || dragId || menu || confirm) { setPreview(null); return; }
    setPreview({ id, rect, dir });
  };
  const refocusActive = (closedId, list) => {
    if (active !== closedId || !list.length) return;
    const oi = ordered.findIndex((t) => t.id === closedId);
    const candidates = ordered.filter((t) => t.id !== closedId && list.some((l) => l.id === t.id));
    const next = candidates[Math.min(oi, candidates.length - 1)] || candidates[candidates.length - 1] || list[0];
    if (next) setActive(next.id);
  };
  const close = (id) => setTabs((prev) => { const next = prev.filter((t) => t.id !== id); refocusActive(id, next); return next; });
  // gate single-tab close: dirty tabs prompt before discarding
  const requestClose = (id) => { const t = tabs.find((x) => x.id === id); if (t && t.dirty) setConfirm({ id, title: t.title }); else close(id); };
  const confirmDiscard = () => { if (confirm) close(confirm.id); setConfirm(null); };
  const confirmSave = () => { if (confirm) { setTabs((prev) => prev.map((t) => t.id === confirm.id ? { ...t, dirty: false } : t)); close(confirm.id); } setConfirm(null); };
  const closeOthers = (id) => setTabs((prev) => { const next = prev.filter((t) => t.id === id || t.pinned); setActive(id); return next; });
  const closeToRight = (id) => setTabs((prev) => {
    const oi = ordered.findIndex((t) => t.id === id);
    const killSet = new Set(ordered.slice(oi + 1).filter((t) => !t.pinned).map((t) => t.id));
    const next = prev.filter((t) => !killSet.has(t.id));
    if (killSet.has(active)) setActive(id);
    return next;
  });
  const duplicate = (id) => setTabs((prev) => {
    const i = prev.findIndex((t) => t.id === id); if (i < 0) return prev;
    const nid = ++seedRef.current;
    const clone = { ...prev[i], id: nid, dirty: false, pinned: false };
    const arr = [...prev]; arr.splice(i + 1, 0, clone); setActive(nid); return arr;
  });
  const togglePin = (id) => setTabs((prev) => prev.map((t) => t.id === id ? { ...t, pinned: !t.pinned } : t));
  const add = () => {
    const id = ++seedRef.current;
    const icons = ['globe', 'user', 'store', 'chart', 'doc'];
    setTabs((prev) => [...prev, { id, title: 'New Tab', icon: icons[id % icons.length] }]); setActive(id);
    setTimeout(() => { if (stripRef.current) stripRef.current.scrollLeft = stripRef.current.scrollWidth; }, 0);
  };

  /* ── keyboard ←/→/Home/End ── */
  const onKey = (e) => {
    const keys = ['ArrowRight', 'ArrowLeft', 'Home', 'End'];
    if (!keys.includes(e.key)) return;
    e.preventDefault();
    const i = ordered.findIndex((t) => t.id === active);
    let ni = i;
    if (e.key === 'ArrowRight') ni = Math.min(i + 1, ordered.length - 1);
    else if (e.key === 'ArrowLeft') ni = Math.max(i - 1, 0);
    else if (e.key === 'Home') ni = 0;
    else if (e.key === 'End') ni = ordered.length - 1;
    if (ordered[ni]) setActive(ordered[ni].id);
  };

  const activeTab = tabs.find((t) => t.id === active);
  const openMenu = (e, id) => { setPreview(null); setMenu({ id, x: e.clientX, y: e.clientY }); };
  const menuTab = menu && tabs.find((t) => t.id === menu.id);
  const menuItems = menuTab ? [
    { icon: 'closeRight', label: 'Close tab', hint: 'Del', danger: true, run: () => requestClose(menuTab.id) },
    { icon: 'close', label: 'Close other tabs', disabled: unpinned.length <= 1, run: () => closeOthers(menuTab.id) },
    { icon: 'closeRight', label: 'Close tabs to the right', disabled: ordered.slice(ordered.findIndex((t) => t.id === menuTab.id) + 1).every((t) => t.pinned), run: () => closeToRight(menuTab.id) },
    { divider: true },
    { icon: 'copy', label: 'Duplicate tab', run: () => duplicate(menuTab.id) },
    { icon: 'pin', label: menuTab.pinned ? 'Unpin tab' : 'Pin tab', run: () => togglePin(menuTab.id) },
  ] : [];

  const chevBtn = (towardEnd, show) => (
    <button aria-label={towardEnd ? 'Scroll tabs forward' : 'Scroll tabs back'} onClick={() => scrollByDir(towardEnd)}
      style={{ width: show ? 26 : 0, height: 32, marginBottom: 2, padding: 0, overflow: 'hidden', border: 'none', background: 'transparent', color: 'var(--gl-fg-3)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, opacity: show ? 1 : 0, transition: 'width var(--gl-dur-base), opacity var(--gl-dur-fast)' }}
      onMouseEnter={(e) => { e.currentTarget.style.color = 'var(--gl-fg-1)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--gl-fg-3)'; }}>
      <BTIcon name={towardEnd ? 'chevR' : 'chevL'} size={16} />
    </button>
  );

  return (
    <div onKeyDown={onKey} style={{ borderRadius: 'var(--gl-radius-lg)', overflow: 'hidden', border: '1px solid var(--gl-border)', background: 'var(--gl-bg)' }}>
      {/* strip — sits on the darker top container */}
      <div role="tablist" style={{ display: 'flex', alignItems: 'flex-end', gap: 0, padding: '8px 8px 0', background: 'var(--gl-bg)', minHeight: 44 }}>
        {/* pinned tabs — anchored, do not scroll */}
        {pinned.length > 0 && (
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 2, flexShrink: 0, marginInlineEnd: 4 }}>
            {pinned.map((t, i) => <Tab key={t.id} tab={t} first={i === 0} compact active={t.id === active} onSelect={select} onClose={requestClose} onContextMenu={openMenu} onPreview={handlePreview} drag={null} />)}
            <span style={{ width: 1, alignSelf: 'stretch', margin: '8px 4px 0', background: 'var(--gl-border-strong)' }} />
          </div>
        )}
        {chevBtn(false, chev.start)}
        <div ref={stripRef} style={{ display: 'flex', alignItems: 'flex-end', gap: 2, overflowX: 'auto', flex: 1, scrollbarWidth: 'none' }}>
          {unpinned.map((t, i) => <Tab key={t.id} tab={t} first={i === 0 && pinned.length === 0} active={t.id === active} onSelect={select} onClose={requestClose} onContextMenu={openMenu} onPreview={handlePreview} drag={drag} />)}
        </div>
        {chevBtn(true, chev.end)}
        <button aria-label="New tab" onClick={add} title="New tab"
          style={{ width: 32, height: 32, marginInlineStart: 4, marginBottom: 2, borderRadius: 7, border: 'none', background: 'transparent', color: 'var(--gl-fg-3)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--gl-hover)'; e.currentTarget.style.color = 'var(--gl-fg-1)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--gl-fg-3)'; }}>
          <BTIcon name="plus" size={16} />
        </button>
        <button ref={listBtnRef} aria-label="Show all tabs" aria-haspopup="menu" aria-expanded={listOpen} title="Show all tabs"
          onMouseDown={(e) => e.stopPropagation()}
          onClick={() => { setPreview(null); setListOpen((v) => !v); }}
          style={{ width: 32, height: 32, marginInlineStart: 2, marginBottom: 2, borderRadius: 7, border: 'none', background: listOpen ? 'var(--gl-hover)' : 'transparent', color: listOpen ? 'var(--gl-fg-1)' : 'var(--gl-fg-3)', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--gl-hover)'; e.currentTarget.style.color = 'var(--gl-fg-1)'; }}
          onMouseLeave={(e) => { if (!listOpen) { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = 'var(--gl-fg-3)'; } }}>
          <BTIcon name="caret" size={16} />
        </button>
      </div>
      {/* content surface merges with active tab — renders the real page this tab holds */}
      <div style={{ background: 'var(--gl-surface)', borderTop: '1px solid var(--gl-border)' }}>
        {activeTab
          ? <div style={{ maxHeight: 440, overflow: 'auto', padding: '24px' }}>{window.TabPage ? React.createElement(window.TabPage, { tab: activeTab }) : null}</div>
          : <div style={{ padding: '28px 24px', fontSize: 13, color: 'var(--gl-fg-3)' }}>No open tabs — press + to start.</div>}
      </div>
      <TabMenu menu={menu} items={menuItems} onClose={() => setMenu(null)} />
      <TabListMenu open={listOpen} anchorRef={listBtnRef} tabs={ordered} active={active}
        onPick={(id) => { select(id); }} onClose={() => setListOpen(false)} />
      <ConfirmDialog data={confirm} onDiscard={confirmDiscard} onSave={confirmSave} onCancel={() => setConfirm(null)} />
      <TabPreview key={preview && preview.id} data={preview ? { tab: tabs.find((t) => t.id === preview.id), rect: preview.rect, dir: preview.dir } : null} onClose={() => setPreview(null)} />
    </div>
  );
}

window.BrowserStyleTabBar = BrowserStyleTabBar;
