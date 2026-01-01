const state = {
  roles: [],
  role: null,
  menu: [],
  selected: null,
  page: 1,
  pageSize: 20,
  total: null,
  columns: [],
  rows: [],
  pkColumns: [],
  selectedRow: null,
  objectInfo: null,
  insertExample: {},
  formMode: 'edit',
  notificationTimer: null
};

const dom = {
  roleDisplay: document.getElementById('roleDisplay'),
  roleOptions: document.getElementById('roleOptions'),
  menu: document.getElementById('menu'),
  accessFlag: document.getElementById('accessFlag'),
  columns: document.getElementById('columns'),
  tableContainer: document.getElementById('tableContainer'),
  prevPage: document.getElementById('prevPage'),
  nextPage: document.getElementById('nextPage'),
  pageInfo: document.getElementById('pageInfo'),
  notification: document.getElementById('notification'),
  editHint: document.getElementById('editHint'),
  editForm: document.getElementById('editForm'),
  saveEdit: document.getElementById('saveEdit'),
  editAccessFlag: document.getElementById('editAccessFlag'),
  editModal: document.getElementById('editModal'),
  editTitle: document.getElementById('editTitle'),
  editSubtitle: document.getElementById('editSubtitle'),
  editClose: document.getElementById('editClose'),
  pageJump: document.getElementById('pageJump'),
  jumpGo: document.getElementById('jumpGo'),
  toggleColumns: document.getElementById('toggleColumns'),
  columnsWrapper: document.getElementById('columnsWrapper'),
  insertBtn: document.getElementById('insertBtn')
};

async function fetchJson(url, options) {
  const res = await fetch(url, options);
  if (!res.ok) {
    const text = await res.text();
    try {
      const obj = JSON.parse(text);
      throw new Error(obj.message || text || '请求失败');
    } catch {
      throw new Error(text || '请求失败');
    }
  }
  return res.json();
}

function showNotification(message, options = {}) {
  if (state.notificationTimer) {
    clearTimeout(state.notificationTimer);
    state.notificationTimer = null;
  }
  if (!message) {
    dom.notification.innerHTML = '';
    return;
  }
  const type = options.type || 'alert';
  const duration = options.duration;
  const className = type === 'success' ? 'toast success' : 'alert';
  dom.notification.innerHTML = `<div class="${className}">${message}</div>`;
  if (duration && duration > 0) {
    state.notificationTimer = setTimeout(() => {
      dom.notification.innerHTML = '';
      state.notificationTimer = null;
    }, duration);
  }
}

function renderRoleOptions() {
  dom.roleOptions.innerHTML = '';
  state.roles.forEach((role) => {
    const option = document.createElement('div');
    option.className = 'role-option';
    option.textContent = role;
    option.addEventListener('click', async () => {
      state.role = role;
      toggleRoleOptions(false);
      dom.roleDisplay.textContent = role;
      state.page = 1;
      await loadMenu(state.role);
    });
    dom.roleOptions.appendChild(option);
  });
  dom.roleDisplay.textContent = state.role || '选择角色';
}

function renderMenu() {
  dom.menu.innerHTML = '';
  state.menu.forEach((item) => {
    const div = document.createElement('div');
    div.className = 'menu-item';
    if (state.selected === item.name) div.classList.add('active');

    const left = document.createElement('div');
    left.innerHTML = `<div><strong>${item.displayName || item.name}</strong></div><div class="menu-item-sub">${item.name}</div>`;

    const right = document.createElement('div');
    right.className = 'item-meta';
    const type = document.createElement('span');
    type.className = 'type-label';
    type.textContent = item.type === 'VIEW' ? 'VIEW' : 'TABLE';

    const badge = document.createElement('span');
    badge.className = `pill ${item.accessMode.toLowerCase()}`;
    badge.textContent = item.accessMode;

    right.appendChild(type);
    right.appendChild(badge);

    div.appendChild(left);
    div.appendChild(right);

    div.addEventListener('click', () => {
      state.selected = item.name;
      state.selectedRow = null;
      state.page = 1;
      renderMenu();
      loadObject(item.name);
    });

    dom.menu.appendChild(div);
  });
}

function renderColumns(columns) {
  dom.columns.innerHTML = '';
  if (!columns || !columns.length) {
    dom.columns.innerHTML = '<div class="empty">无列信息</div>';
    return;
  }
  columns.forEach((col) => {
    const label = col.columnComment && col.columnComment.trim() ? col.columnComment : col.name;
    const chip = document.createElement('div');
    chip.className = 'column-chip';
    chip.innerHTML = `<strong>${label}</strong><span>${col.name} · ${col.dataType}${col.isNullable === 'NO' ? '' : ' (nullable)'}</span>`;
    dom.columns.appendChild(chip);
  });
}

function renderTable(columns, rows) {
  if (!rows || rows.length === 0) {
    dom.tableContainer.innerHTML = '<div class="empty">没有可展示的数据</div>';
    return;
  }
  const headers = columns.map((c) => c.name);
  const table = document.createElement('table');
  const thead = document.createElement('thead');
  const headRow = document.createElement('tr');
  headers.forEach((h, idx) => {
    const th = document.createElement('th');
    const col = columns[idx];
    const label = col.columnComment && col.columnComment.trim() ? col.columnComment : h;
    th.innerHTML = `<div>${label}</div><div class="th-sub">${h}</div>`;
    headRow.appendChild(th);
  });
  thead.appendChild(headRow);
  table.appendChild(thead);

  const tbody = document.createElement('tbody');
  rows.forEach((row) => {
    const tr = document.createElement('tr');
    headers.forEach((h) => {
      const td = document.createElement('td');
      const value = row[h];
      td.textContent = value === null || value === undefined ? '' : value;
      tr.appendChild(td);
    });
    if (state.objectInfo && state.objectInfo.writable && state.pkColumns.length) {
      tr.classList.add('clickable');
      tr.addEventListener('click', () => {
        state.selectedRow = row;
        openEditModal();
      });
    }
    tbody.appendChild(tr);
  });
  table.appendChild(tbody);
  dom.tableContainer.innerHTML = '';
  dom.tableContainer.appendChild(table);
}

function renderObjectView(data) {
  dom.accessFlag.textContent = data.object.writable ? '✏️ 具备写权限 (RW)' : '只读 (R)';
  dom.accessFlag.className = `access-flag ${data.object.writable ? '' : 'readonly'}`;

  state.objectInfo = data.object;
  state.columns = data.columns || [];
  state.rows = data.rows || [];
  state.insertExample = {};
  state.pkColumns = state.columns.filter((c) => c.columnKey === 'PRI').map((c) => c.name);
  if (!state.pkColumns.length && state.columns.length) {
    // 回退：无主键时用首列做定位（仅用于演示环境）
    state.pkColumns = [state.columns[0].name];
  }

  if (dom.insertBtn) {
    dom.insertBtn.style.display = data.object.insertable ? 'inline-flex' : 'none';
    dom.insertBtn.disabled = !data.object.insertable;
    dom.insertBtn.title = data.object.insertable ? '插入示例数据' : '当前角色无插入权限';
  }

  renderColumns(data.columns || []);
  renderTable(data.columns || [], data.rows || []);

  const total = data.pagination.total;
  const totalPages = total ? Math.max(1, Math.ceil(total / data.pagination.pageSize)) : null;
  dom.pageInfo.textContent = totalPages
    ? `第 ${data.pagination.page} 页 / 共 ${totalPages} 页`
    : `第 ${data.pagination.page} 页`;
  dom.prevPage.disabled = data.pagination.page <= 1;
  dom.nextPage.disabled = totalPages ? data.pagination.page >= totalPages : false;
}

async function loadRoles() {
  try {
    const data = await fetchJson('/api/roles');
    state.roles = data.roles || [];
    state.role = state.roles.includes('super_admin') ? 'super_admin' : state.roles[0];
    renderRoleOptions();
    await loadMenu(state.role);
  } catch (err) {
    showNotification(err.message);
  }
}

async function loadMenu(role) {
  try {
    const data = await fetchJson(`/api/menu?role=${encodeURIComponent(role)}`);
    state.menu = data.items || [];
    if (!state.menu.length) {
      showNotification('该角色没有可见对象');
    } else {
      showNotification('');
    }
    renderMenu();
    if (state.menu.length) {
      state.selected = state.menu[0].name;
      loadObject(state.selected);
    } else {
      dom.tableContainer.innerHTML = '';
      dom.columns.innerHTML = '';
      dom.accessFlag.textContent = '只读';
    }
  } catch (err) {
    showNotification(err.message);
  }
}

async function loadObject(objectName, page = state.page) {
  try {
    state.selectedRow = null;
    dom.tableContainer.innerHTML = '<div class="empty">加载中...</div>';
    const data = await fetchJson(
      `/api/objects/${encodeURIComponent(objectName)}?role=${encodeURIComponent(state.role)}&page=${page}&pageSize=${state.pageSize}`
    );
    state.page = page;
    state.total = data.pagination.total;
    renderObjectView(data);
  } catch (err) {
    showNotification(err.message);
    dom.tableContainer.innerHTML = '<div class="empty">加载失败</div>';
  }
}

function toggleRoleOptions(show) {
  dom.roleOptions.style.display = show ? 'block' : 'none';
}

dom.roleDisplay.addEventListener('click', () => {
  const visible = dom.roleOptions.style.display === 'block';
  toggleRoleOptions(!visible);
});

document.addEventListener('click', (e) => {
  if (!dom.roleDisplay.contains(e.target) && !dom.roleOptions.contains(e.target)) {
    toggleRoleOptions(false);
  }
});

dom.prevPage.addEventListener('click', () => {
  if (state.page > 1 && state.selected) {
    loadObject(state.selected, state.page - 1);
  }
});

dom.nextPage.addEventListener('click', () => {
  if (state.selected) {
    loadObject(state.selected, state.page + 1);
  }
});

dom.jumpGo.addEventListener('click', () => {
  let target = Number(dom.pageJump.value);
  if (!state.selected || !target || target < 1) return;
  if (state.total) {
    const maxPage = Math.max(1, Math.ceil(state.total / state.pageSize));
    target = Math.min(target, maxPage);
  }
  loadObject(state.selected, target);
});

dom.toggleColumns.addEventListener('click', () => {
  const closed = dom.columnsWrapper.classList.contains('closed');
  if (closed) {
    dom.columnsWrapper.classList.remove('closed');
    dom.columnsWrapper.classList.add('open');
    dom.toggleColumns.textContent = '收起';
  } else {
    dom.columnsWrapper.classList.add('closed');
    dom.columnsWrapper.classList.remove('open');
    dom.toggleColumns.textContent = '展开';
  }
});

if (dom.insertBtn) {
  dom.insertBtn.addEventListener('click', async () => {
    if (!state.objectInfo || !state.objectInfo.insertable) return;
    dom.insertBtn.disabled = true;
    state.selectedRow = null;
    try {
      const resp = await fetchJson(
        `/api/objects/${encodeURIComponent(state.selected)}/example?role=${encodeURIComponent(state.role)}`
      );
      state.insertExample = resp.example || {};
    } catch (err) {
      showNotification(err.message);
      state.insertExample = buildInsertExampleLocal();
    } finally {
      dom.insertBtn.disabled = false;
    }
    openEditModal('insert');
  });
}

function buildInsertExampleLocal() {
  if (!state.columns || !state.columns.length) return {};
  const sampleRow = state.rows && state.rows.length ? state.rows[0] : {};
  const now = new Date();
  const pad = (n) => (n < 10 ? `0${n}` : `${n}`);
  const dateStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  const timeStr = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  const uniqueSuffix = Date.now().toString(36);
  const example = {};

  state.columns.forEach((col) => {
    const type = (col.dataType || '').toLowerCase();
    const comment = (col.columnComment || '').toLowerCase();
    const autoIncrement = (col.extra || '').toLowerCase().includes('auto_increment');
    const maxLength = col.maxLength || 64;
    const sample = sampleRow ? sampleRow[col.name] : undefined;
    let val = col.columnDefault;
    if (val === null || val === undefined) {
      val = sample;
    }
    if (typeof val === 'string' && val.toUpperCase() === 'CURRENT_TIMESTAMP') {
      val = `${dateStr} ${timeStr}`;
    }

    if (autoIncrement) {
      val = '';
    } else if (col.columnKey === 'PRI') {
      if (type.includes('int') || type.includes('decimal') || type.includes('numeric')) {
        val = Number(Date.now() % 100000);
      } else {
        val = `${col.name}_${uniqueSuffix}`;
      }
    } else if (type.includes('datetime') || type.includes('timestamp')) {
      val = `${dateStr} ${timeStr}`;
    } else if (type === 'date') {
      val = dateStr;
    } else if (type === 'time') {
      val = timeStr;
    } else if (comment.includes('日期') || comment.includes('时间')) {
      val = `${dateStr} ${timeStr}`;
    } else if (type.includes('int') || type.includes('decimal') || type.includes('numeric') || type.includes('float')) {
      val = val !== undefined && val !== null ? val : 1;
    } else if (type.includes('char') || type.includes('text') || type.includes('enum')) {
      const base = val !== undefined && val !== null ? String(val) : `${col.name}_${uniqueSuffix}`;
      val = base.slice(0, maxLength);
    } else {
      val = val !== undefined && val !== null ? val : `${col.name}_${uniqueSuffix}`;
    }

    example[col.name] = val ?? '';
  });

  return example;
}

function buildForm(mode = 'edit') {
  const writable = state.objectInfo && state.objectInfo.writable;
  const insertable = state.objectInfo && state.objectInfo.insertable;
  const isInsert = mode === 'insert';

  dom.editAccessFlag.textContent = isInsert ? (insertable ? '🆕 可插入' : '插入受限') : writable ? '✏️ 可写' : '只读';
  dom.editAccessFlag.className = `access-flag ${
    isInsert ? (insertable ? '' : 'readonly') : writable ? '' : 'readonly'
  }`;

  if (!state.selected || !state.objectInfo) {
    dom.editHint.textContent = '选择左侧对象后可操作。';
    dom.editForm.innerHTML = '';
    dom.saveEdit.disabled = true;
    return false;
  }

  if (isInsert) {
    if (!insertable) {
      dom.editHint.textContent = '当前对象无插入权限。';
      dom.editForm.innerHTML = '';
      dom.saveEdit.disabled = true;
      return false;
    }
  } else {
    if (!writable) {
      dom.editHint.textContent = '当前对象只读，无法修改。';
      dom.editForm.innerHTML = '';
      dom.saveEdit.disabled = true;
      return false;
    }
    if (!state.pkColumns.length) {
      dom.editHint.textContent = '未发现主键，无法定位行进行修改。';
      dom.editForm.innerHTML = '';
      dom.saveEdit.disabled = true;
      return false;
    }
    if (!state.selectedRow) {
      dom.editHint.textContent = '点击数据行以加载编辑表单。';
      dom.editForm.innerHTML = '';
      dom.saveEdit.disabled = true;
      return false;
    }
  }

  const initialData =
    isInsert && state.insertExample && Object.keys(state.insertExample).length
      ? state.insertExample
      : isInsert
      ? buildInsertExampleLocal()
      : state.selectedRow || {};
  dom.editHint.textContent = isInsert
    ? '预填一组可用示例，可直接提交或按需修改。'
    : `编辑 ${state.objectInfo.displayName || state.objectInfo.name}（主键：${state.pkColumns.join(', ')}）`;
  dom.editForm.innerHTML = '';

  state.columns.forEach((col) => {
    const wrapper = document.createElement('div');
    wrapper.className = 'field';
    const label = document.createElement('label');
    label.textContent = (col.columnComment && col.columnComment.trim()) || col.name;
    if (!isInsert && col.columnKey === 'PRI') {
      label.textContent += ' (主键)';
    }
    const input = document.createElement('input');
    input.type = 'text';
    input.value = initialData[col.name] ?? '';
    input.dataset.col = col.name;

    const autoIncrement = (col.extra || '').toLowerCase().includes('auto_increment');
    if (autoIncrement) {
      input.placeholder = '自动生成';
    }

    if (!isInsert && col.columnKey === 'PRI') {
      input.readOnly = true;
      input.classList.add('readonly');
    }

    input.dataset.autoincrement = autoIncrement ? 'true' : 'false';
    wrapper.appendChild(label);
    wrapper.appendChild(input);
    dom.editForm.appendChild(wrapper);
  });

  dom.saveEdit.disabled = false;
  return true;
}

function openEditModal(mode = 'edit') {
  state.formMode = mode;
  if (!buildForm(mode)) return;
  dom.editTitle.textContent =
    mode === 'insert' ? `插入 ${state.objectInfo.displayName || state.objectInfo.name}` : state.objectInfo.displayName || state.objectInfo.name;
  dom.editSubtitle.textContent = `${state.objectInfo.name} · ${mode === 'insert' ? 'INSERT' : 'EDIT'} · ${state.objectInfo.type}`;
  dom.saveEdit.textContent = mode === 'insert' ? '提交插入' : '保存修改';
  dom.editModal.classList.remove('hidden');
}

function closeEditModal() {
  dom.editModal.classList.add('hidden');
}

dom.editClose.addEventListener('click', closeEditModal);
dom.editModal.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal-backdrop')) {
    closeEditModal();
  }
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeEditModal();
});

function normalizeValue(val) {
  if (val === '' || val === undefined) return null;
  // If ISO string with Z, convert to MySQL compatible datetime
  if (typeof val === 'string' && /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d+Z/.test(val)) {
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      const pad = (n) => (n < 10 ? `0${n}` : `${n}`);
      return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(
        d.getMinutes()
      )}:${pad(d.getSeconds())}`;
    }
  }
  return val;
}

function collectFormData() {
  const data = {};
  dom.editForm.querySelectorAll('input[data-col]').forEach((input) => {
    const key = input.dataset.col;
    const val = normalizeValue(input.value);
    const isAuto = input.dataset.autoincrement === 'true';
    if (state.formMode === 'insert' && isAuto && (val === null || val === undefined || val === '')) {
      return;
    }
    data[key] = val;
  });
  return data;
}

async function submitUpdate() {
  if (!state.objectInfo || !state.objectInfo.writable || !state.selectedRow || !state.pkColumns.length) return;
  const data = collectFormData();
  const where = {};
  state.pkColumns.forEach((pk) => {
    where[pk] = state.selectedRow[pk];
  });
  if (!Object.keys(data).length) {
    showNotification('没有可提交的数据');
    return;
  }
  try {
    await fetchJson(`/api/objects/${encodeURIComponent(state.selected)}?role=${encodeURIComponent(state.role)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data, where })
    });
    showNotification('更新成功', { type: 'success', duration: 1000 });
    closeEditModal();
    loadObject(state.selected, state.page);
  } catch (err) {
    showNotification(err.message);
  }
}

async function submitInsert() {
  if (!state.objectInfo || !state.objectInfo.insertable) return;
  const data = collectFormData();
  if (!Object.keys(data).length) {
    showNotification('请填写至少一列数据');
    return;
  }
  try {
    await fetchJson(`/api/objects/${encodeURIComponent(state.selected)}?role=${encodeURIComponent(state.role)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data })
    });
    showNotification('插入成功', { type: 'success', duration: 1000 });
    closeEditModal();
    loadObject(state.selected, state.page);
  } catch (err) {
    showNotification(err.message);
  }
}

dom.saveEdit.addEventListener('click', () => {
  if (state.formMode === 'insert') {
    submitInsert();
  } else {
    submitUpdate();
  }
});

loadRoles();
