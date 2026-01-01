const { QueryTypes } = require('sequelize');
const sequelize = require('./db');
const { sanitizeIdentifier, setRole } = require('./dbRole');

function randomPhone() {
  return `13${Math.floor(100000000 + Math.random() * 900000000)}`;
}

function randomId(prefix) {
  return `${prefix}_${Date.now().toString(36)}_${Math.floor(Math.random() * 1000)}`;
}

function dateRangeExample(daysBack = 6) {
  const end = new Date();
  const start = new Date();
  start.setDate(end.getDate() - daysBack);
  const format = (d) => d.toISOString().slice(0, 10);
  return { start: format(start), end: format(end) };
}

function normalizeOutputs(outputs) {
  return (outputs || []).map((o) => (typeof o === 'string' ? { name: o, label: o } : o));
}

async function pickActivePatient(transaction) {
  const rows = await sequelize.query(
    `SELECT patient_id AS id
     FROM patient
     WHERE is_active = 1
     ORDER BY patient_id DESC
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.id || null;
}

async function pickScheduleWithQuota(transaction) {
  const rows = await sequelize.query(
    `SELECT s.schedule_id AS id
     FROM doctor_schedule s
     LEFT JOIN registration r
       ON r.schedule_id = s.schedule_id
       AND r.status IN ('CONFIRMED','COMPLETED')
     WHERE s.is_active = 1
     GROUP BY s.schedule_id, s.quota
     HAVING COUNT(r.registration_id) < s.quota
     ORDER BY s.schedule_date DESC, s.schedule_id DESC
     LIMIT 5`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows.map((r) => r.id);
}

async function pickPatientForSchedule(scheduleId, transaction) {
  const rows = await sequelize.query(
    `SELECT p.patient_id AS id
     FROM patient p
     WHERE p.is_active = 1
       AND NOT EXISTS (
         SELECT 1 FROM registration r WHERE r.schedule_id = :scheduleId AND r.patient_id = p.patient_id
       )
     ORDER BY p.patient_id DESC
     LIMIT 1`,
    { replacements: { scheduleId }, type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.id || null;
}

async function pickEncounterWithUnbilledCharges(transaction) {
  const rows = await sequelize.query(
    `SELECT c.encounter_id AS id, MIN(c.charged_at) AS firstChargedAt
     FROM charge c
     WHERE c.status = 'UNBILLED'
       AND c.encounter_id IS NOT NULL
     GROUP BY c.encounter_id
     ORDER BY firstChargedAt DESC, c.encounter_id DESC
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.id || null;
}

async function pickInvoiceForPayment(transaction) {
  const rows = await sequelize.query(
    `SELECT i.invoice_id AS id, i.total_amount AS totalAmount, i.paid_amount AS paidAmount
     FROM invoice i
     WHERE i.status IN ('OPEN','PARTIALLY_PAID')
       AND IFNULL(i.total_amount, 0.00) > IFNULL(i.paid_amount, 0.00)
     ORDER BY i.invoice_id DESC
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0] || null;
}

async function pickInvoiceForVoid(transaction) {
  const rows = await sequelize.query(
    `SELECT i.invoice_id AS id
     FROM invoice i
     WHERE i.status <> 'VOID'
       AND IFNULL(i.paid_amount, 0.00) = 0.00
     ORDER BY i.invoice_id DESC
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0]?.id || null;
}

async function pickRefundablePayment(transaction) {
  const rows = await sequelize.query(
    `SELECT p.payment_id AS id,
            p.amount AS amount,
            (SELECT IFNULL(SUM(r.amount), 0.00)
             FROM refund r
             WHERE r.payment_id = p.payment_id
               AND r.status = 'SUCCESS') AS refunded
     FROM payment p
     WHERE p.status = 'SUCCESS'
     HAVING p.amount > refunded
     ORDER BY p.payment_id DESC
     LIMIT 1`,
    { type: QueryTypes.SELECT, transaction }
  );
  return rows?.[0] || null;
}

function defaultExampleFromParams(params) {
  const example = {};
  params.forEach((p) => {
    example[p.name] = p.required ? p.placeholder || '' : null;
  });
  return example;
}

const routineDefinitions = [
  {
    name: 'sp_patient_create',
    displayName: '创建患者档案',
    category: '患者',
    description: '创建患者档案并生成唯一 patient_no。',
    params: [
      { name: 'p_patient_name', label: '患者姓名', required: true, placeholder: '李雷' },
      { name: 'p_gender', label: '性别', required: false, placeholder: 'F/M/U' },
      { name: 'p_birth_date', label: '出生日期', required: false, placeholder: '1995-05-20' },
      { name: 'p_id_card_no', label: '证件号', required: false, placeholder: 'ID_xxx' },
      { name: 'p_phone', label: '电话', required: false, placeholder: '13xxxxxxxxx' },
      { name: 'p_address', label: '地址', required: false, placeholder: '示例地址' },
      { name: 'p_emergency_contact_name', label: '紧急联系人', required: false, placeholder: '王五' },
      { name: 'p_emergency_contact_phone', label: '紧急联系人电话', required: false, placeholder: '139xxxx' },
      { name: 'p_blood_type', label: '血型', required: false, placeholder: 'A/B/AB/O/U' },
      { name: 'p_allergy_history', label: '过敏史', required: false, placeholder: '过敏史备注' }
    ],
    outputs: [
      { name: 'o_patient_id', label: '患者ID' },
      { name: 'o_patient_no', label: '患者编号' }
    ],
    exampleBuilder: async () => {
      const now = new Date();
      const year = now.getFullYear() - 25;
      return {
        p_patient_name: `示例患者_${now.getSeconds()}`,
        p_gender: 'F',
        p_birth_date: `${year}-01-01`,
        p_id_card_no: randomId('ID'),
        p_phone: randomPhone(),
        p_address: '示例路 88 号',
        p_emergency_contact_name: '示例联系人',
        p_emergency_contact_phone: randomPhone(),
        p_blood_type: 'O',
        p_allergy_history: '无明显过敏史'
      };
    }
  },
  {
    name: 'sp_patient_update_contact',
    displayName: '更新患者联系信息',
    category: '患者',
    description: '仅更新非 NULL 的电话/地址/紧急联系人字段。',
    params: [
      { name: 'p_patient_id', label: '患者ID', required: true, type: 'number' },
      { name: 'p_phone', label: '电话', required: false, placeholder: '13xxxxxxxxx' },
      { name: 'p_address', label: '地址', required: false, placeholder: '示例地址' },
      { name: 'p_emergency_contact_name', label: '紧急联系人', required: false },
      { name: 'p_emergency_contact_phone', label: '紧急联系人电话', required: false }
    ],
    outputs: [],
    exampleBuilder: async (transaction) => {
      const patientId = await pickActivePatient(transaction);
      if (!patientId) throw new Error('未找到可用患者，请先创建患者');
      return {
        p_patient_id: patientId,
        p_phone: randomPhone(),
        p_address: '更新地址：示例小区 3-2-201',
        p_emergency_contact_name: '新的联系人',
        p_emergency_contact_phone: randomPhone()
      };
    }
  },
  {
    name: 'sp_outpatient_register',
    displayName: '门诊挂号',
    category: '门诊',
    description: '完成挂号并自动创建就诊、费用（含游标校验号源）。',
    params: [
      { name: 'p_patient_id', label: '患者ID', required: true, type: 'number' },
      { name: 'p_schedule_id', label: '排班ID', required: true, type: 'number' },
      { name: 'p_chief_complaint', label: '主诉', required: false, placeholder: '发热三天' }
    ],
    outputs: [
      { name: 'o_registration_id', label: '挂号ID' },
      { name: 'o_registration_no', label: '挂号单号' },
      { name: 'o_encounter_id', label: '就诊ID' },
      { name: 'o_encounter_no', label: '就诊号' },
      { name: 'o_charge_id', label: '费用ID' }
    ],
    exampleBuilder: async (transaction) => {
      const schedules = await pickScheduleWithQuota(transaction);
      for (const scheduleId of schedules) {
        const patientId = await pickPatientForSchedule(scheduleId, transaction);
        if (patientId) {
          return {
            p_patient_id: patientId,
            p_schedule_id: scheduleId,
            p_chief_complaint: '自动示例主诉：发热三天'
          };
        }
      }
      throw new Error('未找到有剩余号源的排班或可用患者，请先创建患者/排班');
    }
  },
  {
    name: 'sp_invoice_create_for_encounter',
    displayName: '生成发票（游标）',
    category: '收费',
    description: '为就诊集中开票，将所有 UNBILLED 费用写入一张发票（游标遍历费用）。',
    params: [
      { name: 'p_encounter_id', label: '就诊ID', required: true, type: 'number' },
      { name: 'p_note', label: '备注', required: false, placeholder: '集中开票示例' }
    ],
    outputs: [
      { name: 'o_invoice_id', label: '发票ID' },
      { name: 'o_invoice_no', label: '发票号' },
      { name: 'o_line_count', label: '明细行数' }
    ],
    exampleBuilder: async (transaction) => {
      const encounterId = await pickEncounterWithUnbilledCharges(transaction);
      if (!encounterId) throw new Error('未找到存在未开票费用的就诊，请先产生费用');
      return {
        p_encounter_id: encounterId,
        p_note: '集中开票示例'
      };
    }
  },
  {
    name: 'sp_invoice_void',
    displayName: '作废发票（游标）',
    category: '收费',
    description: '作废发票并释放费用（游标删除发票明细）。仅支持未支付发票。',
    params: [
      { name: 'p_invoice_id', label: '发票ID', required: true, type: 'number' },
      { name: 'p_reason', label: '作废原因', required: false, placeholder: '示例原因：信息错误' }
    ],
    outputs: [{ name: 'o_detached_count', label: '释放费用条数' }],
    exampleBuilder: async (transaction) => {
      const invoiceId = await pickInvoiceForVoid(transaction);
      if (!invoiceId) throw new Error('未找到可作废的发票（需未支付），请先创建发票');
      return {
        p_invoice_id: invoiceId,
        p_reason: '示例原因：信息错误'
      };
    }
  },
  {
    name: 'sp_payment_create',
    displayName: '创建支付',
    category: '支付',
    description: '创建支付并联动更新发票已付金额。',
    params: [
      { name: 'p_invoice_id', label: '发票ID', required: true, type: 'number' },
      { name: 'p_method', label: '支付方式', required: false, placeholder: 'CASH/CARD/WECHAT/ALIPAY/TRANSFER/OTHER' },
      { name: 'p_amount', label: '金额', required: true, type: 'number' },
      { name: 'p_transaction_ref', label: '交易参考号', required: false, placeholder: 'pay_xxx' }
    ],
    outputs: [
      { name: 'o_payment_id', label: '支付ID' },
      { name: 'o_payment_no', label: '支付单号' }
    ],
    exampleBuilder: async (transaction) => {
      const invoice = await pickInvoiceForPayment(transaction);
      if (!invoice) throw new Error('未找到待支付的发票，请先创建发票');
      const remaining = Math.max(
        0.01,
        Number((Number(invoice.totalAmount || 0) - Number(invoice.paidAmount || 0)).toFixed(2))
      );
      return {
        p_invoice_id: invoice.id,
        p_method: 'CASH',
        p_amount: Math.min(remaining, Math.max(1, Number(remaining.toFixed(2)))),
        p_transaction_ref: randomId('pay')
      };
    }
  },
  {
    name: 'sp_refund_create',
    displayName: '创建退款',
    category: '支付',
    description: '创建退款并联动更新发票已付金额。',
    params: [
      { name: 'p_payment_id', label: '支付ID', required: true, type: 'number' },
      { name: 'p_amount', label: '退款金额', required: true, type: 'number' },
      { name: 'p_reason', label: '退款原因', required: false, placeholder: '示例原因：重复收费' }
    ],
    outputs: [
      { name: 'o_refund_id', label: '退款ID' },
      { name: 'o_refund_no', label: '退款单号' }
    ],
    exampleBuilder: async (transaction) => {
      const payment = await pickRefundablePayment(transaction);
      if (!payment) throw new Error('未找到可退款的支付记录，请先创建支付');
      const remaining = Math.max(0.01, Number(payment.amount || 0) - Number(payment.refunded || 0));
      const suggested = Math.min(remaining, Math.max(0.01, Number((remaining / 2).toFixed(2))));
      return {
        p_payment_id: payment.id,
        p_amount: suggested,
        p_reason: '示例原因：重复收费'
      };
    }
  },
  {
    name: 'sp_stats_department_overview',
    displayName: '科室经营总览（游标）',
    category: '统计',
    description: '按科室聚合挂号/就诊/开票/费用，游标遍历科室写入临时表。',
    params: [
      { name: 'p_start_date', label: '开始日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' },
      { name: 'p_end_date', label: '结束日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' }
    ],
    outputs: [
      { name: 'o_department_count', label: '科室数' },
      { name: 'o_total_encounters', label: '总就诊数' },
      { name: 'o_total_charge_amount', label: '费用总额' }
    ],
    exampleBuilder: async () => {
      const range = dateRangeExample(6);
      return {
        p_start_date: range.start,
        p_end_date: range.end
      };
    }
  },
  {
    name: 'sp_stats_billing_trend',
    displayName: '收费日报（游标）',
    category: '统计',
    description: '按日输出开票数、支付/退款与净额，游标遍历日期集合。',
    params: [
      { name: 'p_start_date', label: '开始日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' },
      { name: 'p_end_date', label: '结束日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' }
    ],
    outputs: [
      { name: 'o_day_count', label: '天数' },
      { name: 'o_total_net_payment', label: '净收款汇总' }
    ],
    exampleBuilder: async () => {
      const range = dateRangeExample(6);
      return {
        p_start_date: range.start,
        p_end_date: range.end
      };
    }
  },
  {
    name: 'sp_stats_doctor_workload',
    displayName: '医生工作量（游标）',
    category: '统计',
    description: '按医生汇总就诊、处方、检验开单次数，游标遍历医生列表。',
    params: [
      { name: 'p_start_date', label: '开始日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' },
      { name: 'p_end_date', label: '结束日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' }
    ],
    outputs: [
      { name: 'o_doctor_count', label: '医生数' },
      { name: 'o_total_encounters', label: '总就诊数' },
      { name: 'o_total_prescriptions', label: '总处方数' },
      { name: 'o_total_lab_orders', label: '总检验单数' }
    ],
    exampleBuilder: async () => {
      const range = dateRangeExample(6);
      return {
        p_start_date: range.start,
        p_end_date: range.end
      };
    }
  },
  {
    name: 'sp_stats_patient_outstanding',
    displayName: '患者应收（游标）',
    category: '统计',
    description: '按患者遍历未结清发票，汇总欠款金额与发票数量。',
    params: [
      { name: 'p_start_date', label: '开始日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' },
      { name: 'p_end_date', label: '结束日期', required: false, placeholder: 'YYYY-MM-DD', type: 'date' }
    ],
    outputs: [
      { name: 'o_patient_count', label: '患者数' },
      { name: 'o_total_outstanding', label: '欠款总额' }
    ],
    exampleBuilder: async () => {
      const range = dateRangeExample(6);
      return {
        p_start_date: range.start,
        p_end_date: range.end
      };
    }
  }
];

function getRoutine(name) {
  const safe = sanitizeIdentifier(name);
  if (!safe) return null;
  return routineDefinitions.find((r) => r.name === safe) || null;
}

function normalizeParamValue(def, value) {
  if (value === undefined) return null;
  if (def.type === 'number') {
    const num = Number(value);
    if (Number.isNaN(num)) {
      throw new Error(`参数 ${def.label || def.name} 需要数字`);
    }
    return num;
  }
  return value;
}

function validateParams(routine, payload) {
  const params = {};
  routine.params.forEach((p) => {
    const raw = payload ? payload[p.name] : undefined;
    const value = normalizeParamValue(p, raw);
    if (p.required && (value === null || value === undefined || value === '')) {
      throw new Error(`参数 ${p.label || p.name} 为必填项`);
    }
    params[p.name] = value;
  });
  return params;
}

function cleanResultSets(callResult) {
  if (!Array.isArray(callResult)) return [];
  if (Array.isArray(callResult[0])) {
    return callResult.filter((r) => Array.isArray(r)).map((rows) => rows);
  }
  if (callResult.length && typeof callResult[0] === 'object') {
    return [callResult];
  }
  return [];
}

async function listRoutines() {
  return routineDefinitions.map((r) => ({
    name: r.name,
    displayName: r.displayName,
    category: r.category,
    description: r.description,
    params: r.params,
    outputs: normalizeOutputs(r.outputs)
  }));
}

async function buildRoutineExample(name, roleName) {
  const routine = getRoutine(name);
  if (!routine) {
    throw new Error('未知的例程名称');
  }
  return sequelize.transaction(async (transaction) => {
    await setRole(roleName || 'super_admin', transaction);
    if (!routine.exampleBuilder) {
      return { params: defaultExampleFromParams(routine.params) };
    }
    const params = await routine.exampleBuilder(transaction);
    return { params };
  });
}

async function executeRoutine(name, roleName, payload) {
  const routine = getRoutine(name);
  if (!routine) {
    throw new Error('未知的例程名称');
  }
  const params = validateParams(routine, payload);
  const outParams = normalizeOutputs(routine.outputs).map((o) => o.name);

  return sequelize.transaction(async (transaction) => {
    await setRole(roleName || 'super_admin', transaction);
    const placeholders = [
      ...routine.params.map((p) => `:${p.name}`),
      ...outParams.map((o) => `@${o}`)
    ].join(', ');
    const callSql = `CALL \`${routine.name}\`(${placeholders})`;
    const callResult = await sequelize.query(callSql, {
      replacements: params,
      transaction,
      type: QueryTypes.RAW
    });

    let outputs = {};
    if (outParams.length) {
      const selectSql = `SELECT ${outParams.map((o) => `@${o} AS ${o}`).join(', ')}`;
      const outRows = await sequelize.query(selectSql, { type: QueryTypes.SELECT, transaction });
      outputs = outRows?.[0] || {};
    }

    return {
      outputs,
      resultSets: cleanResultSets(callResult)
    };
  });
}

module.exports = {
  listRoutines,
  buildRoutineExample,
  executeRoutine
};
