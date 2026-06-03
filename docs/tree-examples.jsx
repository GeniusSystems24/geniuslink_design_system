/* global React, GLIcon, Highlight, useTreeKeyboard, flattenVisible, ShortcutsHelp, IconBtn */
// GeniusLink DS — two extra Account-Tree-style examples that showcase the
// component's GENERIC VALUE TYPE. The same recursive tree + recursive search +
// keyboard model drives wildly different domains simply by changing the typed
// `value` each node carries and the row renderer:
//
//   • FileTreeLive — TreeNode<FileMeta>  { kind, size, modified }
//   • OrgTreeLive  — TreeNode<Person>    { role, dept, initials }
//
// Both reuse useTreeKeyboard / flattenVisible / Highlight from tree-component.jsx.

(function () {

/* ════════════════════════════════════════════════════════════
   MiniTree — a small generic tree shell. Owns search, expand /
   collapse, keyboard nav and the indent / twisty / highlight
   chrome; delegates the trailing cells to `renderTrailing` and
   match logic to `searchText`. One shell, any value type.
   ════════════════════════════════════════════════════════════ */
function groupKeys(nodes, maxD = Infinity, d = 0, out = []) {
  nodes.forEach((n) => { if (n.children && n.children.length) { if (d <= maxD) out.push(n.code); groupKeys(n.children, maxD, d + 1, out); } });
  return out;
}
function leaves(n) { return n.children ? n.children.reduce((s, c) => s + leaves(c), 0) : 1; }
function filterBy(nodes, q, searchText) {
  const needle = q.trim().toLowerCase();
  if (!needle) return nodes;
  const walk = (n) => {
    const self = searchText(n).toLowerCase().includes(needle);
    const kids = n.children ? n.children.map(walk).filter(Boolean) : null;
    if (self) return n;
    if (kids && kids.length) return { ...n, children: kids };
    return null;
  };
  return nodes.map(walk).filter(Boolean);
}
function countBy(nodes, q, searchText) {
  const needle = q.trim().toLowerCase();
  if (!needle) return 0;
  let n = 0;
  const walk = (node) => { if (searchText(node).toLowerCase().includes(needle)) n++; (node.children || []).forEach(walk); };
  nodes.forEach(walk);
  return n;
}

function MiniRow({ node, depth, expanded, toggle, onOpen, onFocus, forceOpen, query, focusId, selected, accent, leading, renderTrailing, searchText }) {
  const [hover, setHover] = React.useState(false);
  const hasKids = node.children && node.children.length > 0;
  const open = forceOpen || expanded.has(node.code);
  const indent = 14 + depth * 22;
  const isSel = selected === node.code;
  const isFocus = focusId === node.code;
  return (
    <div>
      <div onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
        onClick={() => { onFocus && onFocus(node.code); hasKids ? toggle(node.code) : (onOpen && onOpen(node)); }}
        style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) auto', gap: 12, alignItems: 'center',
          padding: '9px 12px', paddingLeft: indent, borderRadius: 5, cursor: 'pointer',
          background: isSel ? `color-mix(in srgb, ${accent} 12%, transparent)` : (hover ? 'var(--gl-hover)' : 'transparent'),
          boxShadow: isSel ? `inset 0 0 0 1px color-mix(in srgb, ${accent} 45%, transparent)` : (isFocus ? `inset 0 0 0 1.5px color-mix(in srgb, ${accent} 70%, transparent)` : 'none'),
          transition: 'background var(--gl-dur-fast) ease' }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0 }}>
          <span style={{ width: 14, display: 'flex', color: 'var(--gl-fg-3)', flexShrink: 0 }}>
            {hasKids ? <span style={{ display: 'inline-flex', transform: open ? 'none' : 'rotate(-90deg)', transition: 'transform var(--gl-dur-moderate) var(--gl-ease-standard)' }}><GLIcon name="chevD" size={13} /></span> : null}
          </span>
          {leading(node, { depth, open, hasKids })}
          <Highlight text={node.name} q={query} style={{ fontSize: 13, fontWeight: depth === 0 ? 700 : (depth === 1 ? 600 : 500), color: depth >= 3 ? 'var(--gl-fg-2)' : 'var(--gl-fg-1)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} />
          {hasKids && (
            <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 9.5, fontWeight: 700, color: 'var(--gl-fg-3)', background: 'var(--gl-input-bg)', border: '1px solid var(--gl-border)', borderRadius: 999, padding: '1px 7px', flexShrink: 0 }}>{leaves(node)}</span>
          )}
        </span>
        <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 12 }}>
          {renderTrailing(node, { depth, hasKids })}
          <span style={{ width: 14, display: 'flex', justifyContent: 'flex-end', color: 'var(--gl-fg-4)' }}>{!hasKids && hover && <GLIcon name="chevR" size={13} />}</span>
        </span>
      </div>
      {hasKids && open && (
        <div style={{ position: 'relative' }}>
          <div style={{ position: 'absolute', left: indent + 7, top: 0, bottom: 13, width: 1, background: 'var(--gl-border)' }} />
          {node.children.map((c) => (
            <MiniRow key={c.code} node={c} depth={depth + 1} expanded={expanded} toggle={toggle} onOpen={onOpen} onFocus={onFocus} forceOpen={forceOpen} query={query} focusId={focusId} selected={selected} accent={accent} leading={leading} renderTrailing={renderTrailing} searchText={searchText} />
          ))}
        </div>
      )}
    </div>
  );
}

function MiniTree({ roots, accent, title, subtitle, badgeIcon, columnLabel, searchText, leading, renderTrailing, samples, placeholder, defaultDepth = 0 }) {
  const [expanded, setExpanded] = React.useState(() => new Set(groupKeys(roots, defaultDepth)));
  const [query, setQuery] = React.useState('');
  const [focusId, setFocusId] = React.useState(null);
  const [selected, setSelected] = React.useState(null);
  const [searchFocus, setSearchFocus] = React.useState(false);
  const [help, setHelp] = React.useState(false);
  const inputRef = React.useRef(null);

  const toggle = (code) => setExpanded((p) => { const n = new Set(p); n.has(code) ? n.delete(code) : n.add(code); return n; });
  const expandAll = () => setExpanded(new Set(groupKeys(roots)));
  const collapseAll = () => setExpanded(new Set());
  const runQuery = (q) => { setQuery(q); if (inputRef.current) inputRef.current.focus(); };
  const openLeaf = (node) => { setSelected(node.code); setFocusId(node.code); };

  const searching = query.trim().length > 0;
  const visible = filterBy(roots, query, searchText);
  const matchCount = countBy(roots, query, searchText);
  const total = roots.reduce((s, n) => s + leaves(n), 0);
  const vis = visible.reduce((s, n) => s + leaves(n), 0);

  const onKeyDown = useTreeKeyboard({ roots: visible, expanded, setExpanded, searching, focusId, setFocusId, onOpen: openLeaf, searchRef: inputRef, expandAll, collapseAll, clearQuery: () => runQuery(''), openHelp: () => setHelp(true) });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
      {/* toolbar */}
      <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: '1 1 280px', minWidth: 220, height: 38, display: 'flex', alignItems: 'center',
          background: 'var(--gl-input-bg)', borderRadius: 'var(--gl-radius-sm)',
          border: `${searchFocus ? 2 : 1}px solid ${searchFocus ? accent : 'var(--gl-border-strong)'}`, padding: `0 ${searchFocus ? 11 : 12}px` }}>
          <GLIcon name="search" size={15} color="var(--gl-fg-3)" />
          <input ref={inputRef} value={query} onChange={(e) => setQuery(e.target.value)} onFocus={() => setSearchFocus(true)} onBlur={() => setSearchFocus(false)}
            onKeyDown={(e) => { if (e.key === 'Escape') runQuery(''); }}
            placeholder={placeholder}
            style={{ flex: 1, height: '100%', border: 'none', outline: 'none', background: 'transparent', color: 'var(--gl-fg-1)', fontFamily: 'var(--gl-font-body)', fontSize: 13, padding: '0 9px' }} />
          {searching && <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 11, color: 'var(--gl-fg-3)', flexShrink: 0, marginInlineEnd: 6 }}>{matchCount}</span>}
          {query && <button type="button" onClick={() => runQuery('')} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', display: 'flex', padding: 4 }}><GLIcon name="close" size={13} /></button>}
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          {samples.map((q) => {
            const on = query === q;
            return (
              <button key={q} type="button" onClick={() => runQuery(q)}
                style={{ height: 26, padding: '0 10px', borderRadius: 999, cursor: 'pointer', fontFamily: 'var(--gl-font-mono)', fontSize: 11.5,
                  background: on ? `color-mix(in srgb, ${accent} 18%, transparent)` : 'var(--gl-input-bg)',
                  border: `1px solid ${on ? accent : 'var(--gl-border)'}`, color: on ? accent : 'var(--gl-fg-2)' }}>{q}</button>
            );
          })}
          <IconBtn name="keyboard" title="Keyboard shortcuts  ·  ?" onClick={() => setHelp(true)} />
        </div>
      </div>

      {/* tree */}
      <div tabIndex={0} onKeyDown={onKeyDown} role="tree" aria-label={title}
        style={{ background: 'var(--gl-surface)', border: '1px solid var(--gl-border)', borderRadius: 'var(--gl-radius-lg)', boxShadow: 'var(--gl-shadow)', overflow: 'hidden', outline: 'none' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 12, padding: '16px 22px 0' }}>
          <div style={{ display: 'flex', gap: 11, alignItems: 'center' }}>
            <div style={{ width: 4, height: 18, borderRadius: 12, background: accent }} />
            <div>
              <div style={{ fontWeight: 700, fontSize: 14.5, color: 'var(--gl-fg-1)', display: 'flex', alignItems: 'center', gap: 8 }}>
                <GLIcon name={badgeIcon} size={15} color={accent} />{title}
              </div>
              <div style={{ fontSize: 11.5, color: 'var(--gl-fg-3)', marginTop: 2 }}>{subtitle}</div>
            </div>
          </div>
          <span style={{ fontWeight: 700, fontSize: 10, letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--gl-fg-3)', whiteSpace: 'nowrap' }}>{searching ? `${vis} of ${total}` : `${total} items`}</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) auto', gap: 12, alignItems: 'center', padding: '12px 26px 10px', margin: '12px 14px 0', borderBottom: '1px solid var(--gl-border)', fontWeight: 700, fontSize: 9.5, letterSpacing: '.08em', textTransform: 'uppercase', color: 'var(--gl-fg-3)' }}>
          <span>Name</span>
          <span style={{ textAlign: 'right' }}>{columnLabel}</span>
        </div>
        <div style={{ padding: '8px 14px 16px' }}>
          {visible.length === 0 ? (
            <div style={{ padding: '40px 16px', textAlign: 'center', color: 'var(--gl-fg-3)' }}>
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 10, color: 'var(--gl-fg-4)' }}><GLIcon name="searchO" size={24} /></div>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: 'var(--gl-fg-2)' }}>No matches for “{query}”</div>
            </div>
          ) : visible.map((n) => (
            <MiniRow key={n.code} node={n} depth={0} expanded={expanded} toggle={toggle} onOpen={openLeaf} onFocus={setFocusId} forceOpen={searching} query={query} focusId={focusId} selected={selected} accent={accent} leading={leading} renderTrailing={renderTrailing} searchText={searchText} />
          ))}
        </div>
        {selected && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '11px 22px', borderTop: '1px solid var(--gl-border)', background: `color-mix(in srgb, ${accent} 7%, transparent)` }}>
            <GLIcon name="check" size={14} color={accent} />
            <span style={{ fontSize: 12.5, color: 'var(--gl-fg-2)' }}>Selected <strong style={{ fontFamily: 'var(--gl-font-mono)', color: 'var(--gl-fg-1)' }}>{selected}</strong></span>
            <span style={{ flex: 1 }} />
            <button type="button" onClick={() => setSelected(null)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--gl-fg-3)', display: 'flex', padding: 4 }}><GLIcon name="close" size={13} /></button>
          </div>
        )}
      </div>
      {help && <ShortcutsHelp onClose={() => setHelp(false)} />}
    </div>
  );
}

/* ════════════════════════════════════════════════════════════
   EXAMPLE 2 — File explorer.  value: FileMeta { kind, size, modified }
   ════════════════════════════════════════════════════════════ */
const FILE_KIND = {
  dir: { icon: 'folder', color: 'var(--gl-blue-500)' },
  code: { icon: 'fileCode', color: 'var(--gl-success-500)' },
  img: { icon: 'fileImg', color: 'var(--gl-warning-500)' },
  doc: { icon: 'doc', color: 'var(--gl-fg-3)' },
};
function f(code, name, kind, opts = {}) {
  return { code, name, value: { kind, size: opts.size, modified: opts.modified }, children: opts.children };
}
const FILE_TREE = [
  f('lib', 'lib', 'dir', { children: [
    f('lib/ds', 'design_system', 'dir', { children: [
      f('lib/ds/tree.dart', 'tree.dart', 'code', { size: '33 KB', modified: 'today' }),
      f('lib/ds/tree_controller.dart', 'tree_controller.dart', 'code', { size: '14 KB', modified: 'today' }),
      f('lib/ds/tree_models.dart', 'tree_models.dart', 'code', { size: '8.8 KB', modified: 'today' }),
      f('lib/ds/tree_theme.dart', 'tree_theme.dart', 'code', { size: '5.5 KB', modified: '2 d' }),
    ] }),
    f('lib/barrel.dart', 'geniuslink_tree.dart', 'code', { size: '0.8 KB', modified: '2 d' }),
  ] }),
  f('example', 'example', 'dir', { children: [
    f('ex/lib', 'lib', 'dir', { children: [
      f('ex/lib/tree_demo.dart', 'tree_demo.dart', 'code', { size: '44 KB', modified: 'today' }),
      f('ex/lib/account_tree_data.dart', 'account_tree_data.dart', 'code', { size: '9.8 KB', modified: 'today' }),
      f('ex/lib/main.dart', 'main.dart', 'code', { size: '21 KB', modified: '1 h' }),
    ] }),
  ] }),
  f('docs', 'docs', 'dir', { children: [
    f('docs/tree.html', 'components-tree.html', 'doc', { size: '24 KB', modified: 'today' }),
    f('docs/logo', 'logo-mark.png', 'img', { size: '12 KB', modified: '4 d' }),
  ] }),
  f('readme', 'README.md', 'doc', { size: '18 KB', modified: '1 h' }),
];
function FileTreeLive() {
  return (
    <MiniTree
      roots={FILE_TREE}
      accent="var(--gl-blue-500)"
      title="Project files"
      subtitle="TreeNode<FileMeta> · folders roll up a child count, files show size + modified"
      badgeIcon="folderOpen"
      columnLabel="Size · Modified"
      placeholder="Search files…   ( / )"
      samples={['tree', '.dart', 'docs', 'README']}
      defaultDepth={0}
      searchText={(n) => n.name}
      leading={(n, { open }) => {
        const k = FILE_KIND[n.value.kind] || FILE_KIND.doc;
        const icon = n.value.kind === 'dir' ? (open ? 'folderOpen' : 'folder') : k.icon;
        return <span style={{ display: 'flex', color: k.color, flexShrink: 0 }}><GLIcon name={icon} size={15} /></span>;
      }}
      renderTrailing={(n) => n.value.kind === 'dir' ? null : (
        <span style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
          <span style={{ fontFamily: 'var(--gl-font-mono)', fontSize: 11.5, color: 'var(--gl-fg-2)' }}>{n.value.size}</span>
          <span style={{ fontSize: 11, color: 'var(--gl-fg-4)', minWidth: 42, textAlign: 'right' }}>{n.value.modified}</span>
        </span>
      )}
    />
  );
}

/* ════════════════════════════════════════════════════════════
   EXAMPLE 3 — Org chart.  value: Person { role, dept, initials }
   ════════════════════════════════════════════════════════════ */
const DEPT_COLOR = { Exec: 'var(--gl-blue-500)', Eng: 'var(--gl-success-500)', Design: 'var(--gl-warning-500)', Finance: '#A855F7' };
function p(code, name, role, dept, initials, children) {
  return { code, name, value: { role, dept, initials }, children };
}
const ORG_TREE = [
  p('ceo', 'Layla Al-Saud', 'Chief Executive', 'Exec', 'LS', [
    p('cto', 'Omar Khalid', 'CTO', 'Eng', 'OK', [
      p('eng-lead', 'Sara Nasser', 'Eng Lead', 'Eng', 'SN', [
        p('eng-1', 'Yousef Amin', 'Senior Engineer', 'Eng', 'YA'),
        p('eng-2', 'Huda Faris', 'Engineer', 'Eng', 'HF'),
        p('eng-3', 'Tariq Saleh', 'Engineer', 'Eng', 'TS'),
      ]),
      p('design-lead', 'Nora Habib', 'Design Lead', 'Design', 'NH', [
        p('des-1', 'Mariam Adel', 'Product Designer', 'Design', 'MA'),
        p('des-2', 'Faisal Rashid', 'Brand Designer', 'Design', 'FR'),
      ]),
    ]),
    p('cfo', 'Aisha Mansour', 'CFO', 'Finance', 'AM', [
      p('fin-lead', 'Khalid Omar', 'Finance Manager', 'Finance', 'KO', [
        p('fin-1', 'Lina Saad', 'Accountant', 'Finance', 'LS'),
        p('fin-2', 'Bilal Hadi', 'Analyst', 'Finance', 'BH'),
      ]),
    ]),
  ]),
];
function OrgTreeLive() {
  return (
    <MiniTree
      roots={ORG_TREE}
      accent="#A855F7"
      title="Org chart"
      subtitle="TreeNode<Person> · managers roll up a headcount, everyone shows role + dept"
      badgeIcon="people"
      columnLabel="Role · Dept"
      placeholder="Search people…   ( / )"
      samples={['Lead', 'Eng', 'Sara', 'Finance']}
      defaultDepth={1}
      searchText={(n) => `${n.name} ${n.value.role} ${n.value.dept}`}
      leading={(n) => {
        const c = DEPT_COLOR[n.value.dept] || 'var(--gl-fg-3)';
        return (
          <span style={{ width: 24, height: 24, borderRadius: 999, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--gl-font-mono)', fontSize: 10, fontWeight: 700, color: c, background: `color-mix(in srgb, ${c} 16%, transparent)`, border: `1px solid color-mix(in srgb, ${c} 35%, transparent)` }}>{n.value.initials}</span>
        );
      }}
      renderTrailing={(n) => {
        const c = DEPT_COLOR[n.value.dept] || 'var(--gl-fg-3)';
        return (
          <span style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 12, color: 'var(--gl-fg-2)' }}>{n.value.role}</span>
            <span style={{ height: 19, padding: '0 8px', display: 'inline-flex', alignItems: 'center', borderRadius: 999, fontSize: 10, fontWeight: 700, letterSpacing: '.04em', color: c, background: `color-mix(in srgb, ${c} 15%, transparent)`, border: `1px solid color-mix(in srgb, ${c} 35%, transparent)` }}>{n.value.dept}</span>
          </span>
        );
      }}
    />
  );
}

Object.assign(window, { MiniTree, FileTreeLive, OrgTreeLive });
})();
