const state = {
  roles: [],
  role: null,
  routines: [],
  selected: null,
  example: {},
  result: null,
  notificationTimer: null
};

const dom = {
  roleDisplay: document.getElementById('roleDisplay'),
  roleOptions: document.getElementById('roleOptions'),
  routineGrid: document.getElementById('routineGrid'),
  routineTitle: document.getElementById('routineTitle'),
  routineSubtitle: document.getElementById('routineSubtitle'),
  routineCategory: document.getElementById('routineCategory'),
  paramForm: document.getElementById('paramForm'),
  routineResult: document.getElementById('routineResult'),
  notification: document.getElementById('notification'),
  refreshRoutines: document.getElementById('refreshRoutines'),
  prefillBtn: document.getElementById('prefillBtn'),
  runBtn: document.getElementById('runBtn')
};

async function fetchJson(url, options) {
  const res = await fetch(url, options);
  if (!res.ok) {
    const text = await res.text();
    try {
      const obj = JSON.parse(text);
      throw new Error(obj.message || text || '请求失败');
    } catch (_err) {
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
      state.result = null;
      state.example = {};
      await loadRoutines(true);
    });
    dom.roleOptions.appendChild(option);
  });
  dom.roleDisplay.textContent = state.role || '选择角色';
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

function renderRoutineCards() {
  dom.routineGrid.innerHTML = '';
  if (!state.routines.length) {
    dom.routineGrid.innerHTML = '<div class="empty">暂无例程可用</div>';
    return;
  }

  state.routines.forEach((routine) => {
    const card = document.createElement('div');
    card.className = 'routine-card';
    if (state.selected && state.selected.name === routine.name) {
      card.classList.add('active');
    }

    const paramPreview = routine.params
      .slice(0, 3)
      .map((p) => `<span class="chip">${p.name}${p.required ? '*' : ''}</span>`)
      .join('') || '<span class="chip muted">无</span>';
    const outputPreview =
      routine.outputs && routine.outputs.length
        ? routine.outputs.map((o) => `<span class="chip">${o}</span>`).join('')
        : '<span class="chip muted">无 OUT</span>';

    card.innerHTML = `
      <div class="card-head">
        <span class="pill subtle">${routine.category || '例程'}</span>
        <span class="routine-name">${routine.displayName}</span>
      </div>
      <div class="routine-desc">${routine.description || ''}</div>
      <div class="routine-meta">
        <div class="meta-block">
          <label>参数</label>
          <div class="chip-row">${paramPreview || '无'}</div>
        </div>
        <div class="meta-block">
          <label>输出</label>
          <div class="chip-row">${outputPreview}</div>
        </div>
      </div>
    `;

    card.addEventListener('click', () => selectRoutine(routine));
    dom.routineGrid.appendChild(card);
  });
}

function renderParamForm(values = {}) {
  if (!state.selected) {
    dom.paramForm.innerHTML = '<div class="empty">请选择一个例程</div>';
    return;
  }
  if (!state.selected.params.length) {
    dom.paramForm.innerHTML = '<div class="empty">该例程无输入参数</div>';
    return;
  }
  dom.paramForm.innerHTML = '';
  state.selected.params.forEach((p) => {
    const field = document.createElement('div');
    field.className = 'field';
    const label = document.createElement('label');
    label.textContent = `${p.label || p.name}${p.required ? ' *' : ''}`;
    const input = document.createElement('input');
    input.type = p.type === 'number' ? 'number' : 'text';
    input.placeholder = p.placeholder || '';
    input.dataset.name = p.name;
    if (values[p.name] !== undefined && values[p.name] !== null) {
      input.value = values[p.name];
    }
    field.appendChild(label);
    field.appendChild(input);
    dom.paramForm.appendChild(field);
  });
}

function applyParamsToForm(values = {}) {
  dom.paramForm.querySelectorAll('input[data-name]').forEach((input) => {
    const key = input.dataset.name;
    if (values[key] !== undefined && values[key] !== null) {
      input.value = values[key];
    }
  });
}

function renderRoutineDetail() {
  if (!state.selected) {
    dom.routineTitle.textContent = '选择下方卡片以加载参数';
    dom.routineSubtitle.textContent = '';
    dom.routineCategory.textContent = '例程';
    dom.prefillBtn.disabled = true;
    dom.runBtn.disabled = true;
    dom.paramForm.innerHTML = '<div class="empty">尚未选择例程</div>';
    dom.routineResult.className = 'routine-result empty';
    dom.routineResult.textContent = '尚未执行任何例程。';
    return;
  }
  dom.routineTitle.textContent = `${state.selected.displayName} (${state.selected.name})`;
  dom.routineSubtitle.textContent = state.selected.description || '';
  dom.routineCategory.textContent = state.selected.category || '例程';
  dom.prefillBtn.disabled = false;
  dom.runBtn.disabled = false;
  renderParamForm(state.example);
  renderResult();
}

function collectParams() {
  const data = {};
  if (!state.selected) return data;
  dom.paramForm.querySelectorAll('input[data-name]').forEach((input) => {
    const key = input.dataset.name;
    const def = state.selected.params.find((p) => p.name === key) || {};
    let val = input.value;
    if (val === '' || val === undefined) {
      val = null;
    }
    if (def.type === 'number' && val !== null) {
      const num = Number(val);
      if (Number.isNaN(num)) {
        throw new Error(`参数 ${def.label || def.name} 需要数字`);
      }
      data[key] = num;
    } else {
      data[key] = val;
    }
  });
  return data;
}

function ensureRequired(params) {
  if (!state.selected) return;
  const missing = state.selected.params.filter(
    (p) => p.required && (params[p.name] === null || params[p.name] === undefined || params[p.name] === '')
  );
  if (missing.length) {
    throw new Error(`请填写必填参数：${missing.map((m) => m.label || m.name).join(', ')}`);
  }
}

function renderOutputs(outputs) {
  return '';
}

function renderResultSets(resultSets) {
  return '';
}

function renderResult() {
  if (!state.result) {
    dom.routineResult.className = 'routine-result empty';
    dom.routineResult.textContent = '尚未执行任何例程。';
    return;
  }
  dom.routineResult.className = 'routine-result';
  dom.routineResult.innerHTML = `<div class="result-block"><div class="result-title">执行状态</div><div class="muted">调用已完成，具体 OUT 参数和结果集不在此展示。</div></div>`;
}

async function fetchExample() {
  if (!state.selected) return;
  dom.prefillBtn.disabled = true;
  try {
    const resp = await fetchJson(
      `/api/routines/${encodeURIComponent(state.selected.name)}/example?role=${encodeURIComponent(state.role)}`
    );
    state.example = resp.params || {};
    applyParamsToForm(state.example);
    showNotification('已预填示例参数', { type: 'success', duration: 1200 });
  } catch (err) {
    showNotification(err.message);
  } finally {
    dom.prefillBtn.disabled = false;
  }
}

async function runRoutine() {
  if (!state.selected) return;
  dom.runBtn.disabled = true;
  try {
    const params = collectParams();
    ensureRequired(params);
    const resp = await fetchJson(
      `/api/routines/${encodeURIComponent(state.selected.name)}/execute?role=${encodeURIComponent(state.role)}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ params })
      }
    );
    state.result = resp;
    renderResult();
    showNotification('执行成功', { type: 'success', duration: 1200 });
  } catch (err) {
    showNotification(err.message);
  } finally {
    dom.runBtn.disabled = false;
  }
}

async function selectRoutine(routine) {
  state.selected = routine;
  state.example = {};
  state.result = null;
  renderRoutineCards();
  renderRoutineDetail();
  await fetchExample();
}

async function loadRoutines(refillExample = false) {
  try {
    const data = await fetchJson('/api/routines');
    state.routines = data.routines || [];
    renderRoutineCards();
    if (!state.routines.length) {
      state.selected = null;
      renderRoutineDetail();
      return;
    }
    if (!state.selected && state.routines.length) {
      await selectRoutine(state.routines[0]);
    } else if (state.selected) {
      // 保持选中项在列表中更新样式
      const existing = state.routines.find((r) => r.name === state.selected.name);
      if (!existing && state.routines.length) {
        await selectRoutine(state.routines[0]);
      } else if (refillExample) {
        await fetchExample();
      }
    }
  } catch (err) {
    showNotification(err.message);
    dom.routineGrid.innerHTML = '<div class="empty">例程列表加载失败</div>';
  }
}

async function loadRoles() {
  try {
    const data = await fetchJson('/api/roles');
    state.roles = data.roles || [];
    state.role = state.roles.includes('super_admin') ? 'super_admin' : state.roles[0];
    renderRoleOptions();
    await loadRoutines();
  } catch (err) {
    showNotification(err.message);
  }
}

dom.refreshRoutines.addEventListener('click', () => loadRoutines(false));
dom.prefillBtn.addEventListener('click', fetchExample);
dom.runBtn.addEventListener('click', runRoutine);

renderRoutineDetail();
loadRoles();
