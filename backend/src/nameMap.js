// 手工中文名映射，优先用于无表注释的视图
const objectNameMap = {
  v_patient_public: '患者公开信息',
  v_schedule_public: '医生排班公开',
  v_encounter_summary: '就诊概要',
  v_prescription_detail: '处方明细',
  v_lab_result_detail: '检验结果明细',
  v_invoice_summary: '发票概要',
  v_invoice_detail: '发票明细',
  v_current_staff: '当前员工信息',
  v_current_staff_departments: '当前员工科室列表',
  v_patient_reception: '患者信息（前台）',
  v_patient_clinical: '患者临床信息',
  v_drug_catalog_active: '药品目录（启用）',
  v_lab_test_catalog_active: '检验项目目录（启用）',
  v_charge_catalog_active: '收费项目目录',
  v_registration_detail: '挂号详情',
  v_encounter_detail: '就诊详情',
  v_encounter_diagnosis_detail: '就诊诊断详情',
  v_inpatient_current: '在院住院清单',
  v_bed_occupancy: '床位占用概览',
  v_pharmacy_dispense_queue: '药房待发药队列',
  v_pharmacy_dispense_detail: '药房发药记录',
  v_lab_worklist: '检验工作台',
  v_payment_refund_detail: '支付/退款流水',
  v_doctor_my_schedule: '我的排班',
  v_doctor_my_registrations: '我的挂号',
  v_doctor_my_encounters: '我的就诊',
  v_doctor_my_encounter_diagnoses: '我的诊断',
  v_doctor_my_prescriptions_detail: '我的处方明细',
  v_doctor_my_lab_results: '我的检验结果',
  v_nurse_my_inpatients: '护士-我的在院病人',
  v_lab_my_items: '检验-我的项目',
  v_cashier_unbilled_charges: '收银-未开票费用',
  v_current_patient: '当前患者',
  v_patient_my_encounters: '患者-我的就诊',
  v_patient_my_prescriptions: '患者-我的处方',
  v_patient_my_lab_results: '患者-我的检验结果',
  v_patient_my_invoices: '患者-我的发票',
  v_patient_my_invoice_details: '患者-我的发票明细'
};

function resolveDisplayName(objectName, fallbackComment) {
  if (objectNameMap[objectName]) return objectNameMap[objectName];
  if (fallbackComment && fallbackComment.trim()) return fallbackComment.trim();
  return objectName;
}

module.exports = { resolveDisplayName };
