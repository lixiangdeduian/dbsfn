"""
存储过程调用路由
演示如何调用数据库中的存储过程和游标
"""
from flask import Blueprint, request, jsonify
from models import db
from auth import require_role, get_current_role
from sqlalchemy import text

procedures_bp = Blueprint('procedures', __name__)


@procedures_bp.route('/invoice/create-for-encounter', methods=['POST'])
@require_role('admin', 'cashier')
def create_invoice_for_encounter():
    """
    调用存储过程：为就诊创建发票（使用游标）
    
    存储过程：sp_invoice_create_for_encounter
    功能：使用游标遍历未开票费用，集中生成发票
    """
    try:
        data = request.get_json()
        encounter_id = data.get('encounter_id')
        note = data.get('note', '')
        
        if not encounter_id:
            return jsonify({'error': '就诊ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_invoice_create_for_encounter(
                :p_encounter_id,
                :p_note,
                @o_invoice_id,
                @o_invoice_no,
                @o_line_count
            )
        """)
        
        db.session.execute(sql, {
            'p_encounter_id': encounter_id,
            'p_note': note
        })
        
        # 获取输出参数
        result = db.session.execute(text("""
            SELECT @o_invoice_id as invoice_id,
                   @o_invoice_no as invoice_no,
                   @o_line_count as line_count
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'invoice_id': result.invoice_id,
            'invoice_no': result.invoice_no,
            'line_count': result.line_count,
            'message': f'成功创建发票，包含{result.line_count}条费用明细'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        # 提取MySQL错误信息
        if '45000' in error_msg:
            if 'no unbilled charges' in error_msg:
                return jsonify({'error': '该就诊没有未开票的费用'}), 400
            elif 'encounter not found' in error_msg:
                return jsonify({'error': '就诊记录不存在'}), 404
        return jsonify({'error': f'创建发票失败：{error_msg}'}), 500


@procedures_bp.route('/payment/create', methods=['POST'])
@require_role('admin', 'cashier')
def create_payment_procedure():
    """
    调用存储过程：创建支付记录
    
    存储过程：sp_payment_create
    功能：创建支付并自动更新发票状态
    """
    try:
        data = request.get_json()
        invoice_id = data.get('invoice_id')
        method = data.get('method', 'CASH')
        amount = data.get('amount')
        transaction_ref = data.get('transaction_ref', '')
        
        if not invoice_id or not amount:
            return jsonify({'error': '发票ID和金额不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_payment_create(
                :p_invoice_id,
                :p_method,
                :p_amount,
                :p_transaction_ref,
                @o_payment_id,
                @o_payment_no,
                @o_invoice_status
            )
        """)
        
        db.session.execute(sql, {
            'p_invoice_id': invoice_id,
            'p_method': method,
            'p_amount': amount,
            'p_transaction_ref': transaction_ref
        })
        
        # 获取输出参数
        result = db.session.execute(text("""
            SELECT @o_payment_id as payment_id,
                   @o_payment_no as payment_no,
                   @o_invoice_status as invoice_status
        """)).fetchone()
        
        db.session.commit()
        
        status_map = {
            'OPEN': '未结清',
            'PARTIALLY_PAID': '部分已付',
            'PAID': '已付清'
        }
        
        return jsonify({
            'success': True,
            'payment_id': result.payment_id,
            'payment_no': result.payment_no,
            'invoice_status': result.invoice_status,
            'invoice_status_text': status_map.get(result.invoice_status, result.invoice_status),
            'message': f'支付成功，发票状态：{status_map.get(result.invoice_status, result.invoice_status)}'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'invoice not found' in error_msg:
                return jsonify({'error': '发票不存在'}), 404
            elif 'amount exceeds' in error_msg:
                return jsonify({'error': '支付金额超过剩余应付金额'}), 400
        return jsonify({'error': f'支付失败：{error_msg}'}), 500


@procedures_bp.route('/dispense/create', methods=['POST'])
@require_role('admin', 'pharmacist')
def dispense_create():
    """
    调用存储过程：发药
    
    存储过程：sp_dispense_create
    功能：完成一次发药并将处方状态置为DISPENSED
    """
    try:
        data = request.get_json()
        prescription_id = data.get('prescription_id')
        
        if not prescription_id:
            return jsonify({'error': '处方ID不能为空'}), 400
        
        # 获取当前用户信息（简化版，实际应从JWT中获取）
        pharmacist_id = data.get('pharmacist_id', 1)  # 默认ID
        
        sql = text("""
            CALL sp_dispense_create(
                :p_prescription_id,
                :p_pharmacist_id,
                :p_note,
                @o_dispense_id,
                @o_charge_id
            )
        """)
        
        db.session.execute(sql, {
            'p_prescription_id': prescription_id,
            'p_pharmacist_id': pharmacist_id,
            'p_note': data.get('note', '')
        })
        
        result = db.session.execute(text("""
            SELECT @o_dispense_id as dispense_id,
                   @o_charge_id as charge_id
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'dispense_id': result.dispense_id,
            'charge_id': result.charge_id,
            'message': '发药成功'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'only ISSUED' in error_msg:
                return jsonify({'error': '只能对已开立的处方发药'}), 400
            elif 'not found' in error_msg:
                return jsonify({'error': '处方不存在'}), 404
        return jsonify({'error': f'发药失败：{error_msg}'}), 500


@procedures_bp.route('/lab/result-upsert', methods=['POST'])
@require_role('admin', 'lab_tech')
def lab_result_upsert():
    """
    调用存储过程：录入或更新检验结果
    
    存储过程：sp_lab_result_upsert
    功能：录入检验结果，全部录入完成后自动更新订单状态为REPORTED
    """
    try:
        data = request.get_json()
        lab_order_item_id = data.get('lab_order_item_id')
        
        if not lab_order_item_id:
            return jsonify({'error': '检验明细ID不能为空'}), 400
        
        # 获取当前用户信息
        technician_id = data.get('technician_id', 1)
        
        sql = text("""
            CALL sp_lab_result_upsert(
                :p_lab_order_item_id,
                :p_technician_id,
                :p_result_value,
                :p_result_text,
                :p_result_flag,
                :p_result_at,
                @o_lab_result_id
            )
        """)
        
        db.session.execute(sql, {
            'p_lab_order_item_id': lab_order_item_id,
            'p_technician_id': technician_id,
            'p_result_value': data.get('result_value'),
            'p_result_text': data.get('result_text'),
            'p_result_flag': data.get('result_flag', 'NORMAL'),
            'p_result_at': data.get('result_at')
        })
        
        result = db.session.execute(text("""
            SELECT @o_lab_result_id as lab_result_id
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'lab_result_id': result.lab_result_id,
            'message': '检验结果录入成功'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'CANCELLED' in error_msg:
                return jsonify({'error': '不能为已取消的订单录入结果'}), 400
        return jsonify({'error': f'录入失败：{error_msg}'}), 500


@procedures_bp.route('/inpatient/admit', methods=['POST'])
@require_role('admin', 'nurse')
def inpatient_admit():
    """
    调用存储过程：办理入院（使用游标自动分配床位）
    
    存储过程：sp_inpatient_admit
    功能：创建住院就诊和入院记录，使用游标自动分配可用床位
    """
    try:
        data = request.get_json()
        
        sql = text("""
            CALL sp_inpatient_admit(
                :p_patient_id,
                :p_department_id,
                :p_attending_doctor_id,
                :p_ward_id,
                :p_bed_id,
                :p_note,
                @o_encounter_id,
                @o_encounter_no,
                @o_admission_id,
                @o_admission_no,
                @o_bed_assignment_id,
                @o_assigned_bed_id
            )
        """)
        
        db.session.execute(sql, {
            'p_patient_id': data.get('patient_id'),
            'p_department_id': data.get('department_id'),
            'p_attending_doctor_id': data.get('attending_doctor_id'),
            'p_ward_id': data.get('ward_id'),
            'p_bed_id': data.get('bed_id'),
            'p_note': data.get('note', '')
        })
        
        result = db.session.execute(text("""
            SELECT @o_encounter_id as encounter_id,
                   @o_encounter_no as encounter_no,
                   @o_admission_id as admission_id,
                   @o_admission_no as admission_no,
                   @o_bed_assignment_id as bed_assignment_id,
                   @o_assigned_bed_id as assigned_bed_id
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'encounter_id': result.encounter_id,
            'encounter_no': result.encounter_no,
            'admission_id': result.admission_id,
            'admission_no': result.admission_no,
            'bed_assignment_id': result.bed_assignment_id,
            'assigned_bed_id': result.assigned_bed_id,
            'message': '入院办理成功，已自动分配床位' if result.assigned_bed_id else '入院办理成功'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'no available bed' in error_msg:
                return jsonify({'error': '没有可用床位'}), 400
        return jsonify({'error': f'入院办理失败：{error_msg}'}), 500


@procedures_bp.route('/patient/create', methods=['POST'])
@require_role('admin', 'reception')
def patient_create():
    """
    调用存储过程：创建患者档案
    
    存储过程：sp_patient_create
    功能：生成唯一patient_no，创建患者档案
    """
    try:
        data = request.get_json()
        
        sql = text("""
            CALL sp_patient_create(
                :p_patient_name,
                :p_gender,
                :p_birth_date,
                :p_id_card_no,
                :p_phone,
                :p_address,
                :p_emergency_contact_name,
                :p_emergency_contact_phone,
                :p_blood_type,
                :p_allergy_history,
                @o_patient_id,
                @o_patient_no
            )
        """)
        
        db.session.execute(sql, {
            'p_patient_name': data.get('patient_name'),
            'p_gender': data.get('gender', 'U'),
            'p_birth_date': data.get('birth_date'),
            'p_id_card_no': data.get('id_card_no'),
            'p_phone': data.get('phone'),
            'p_address': data.get('address'),
            'p_emergency_contact_name': data.get('emergency_contact_name'),
            'p_emergency_contact_phone': data.get('emergency_contact_phone'),
            'p_blood_type': data.get('blood_type', 'U'),
            'p_allergy_history': data.get('allergy_history')
        })
        
        result = db.session.execute(text("""
            SELECT @o_patient_id as patient_id,
                   @o_patient_no as patient_no
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'patient_id': result.patient_id,
            'patient_no': result.patient_no,
            'message': '患者创建成功'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'required' in error_msg:
                return jsonify({'error': '必填字段缺失'}), 400
        return jsonify({'error': f'创建失败：{error_msg}'}), 500


@procedures_bp.route('/outpatient/register', methods=['POST'])
@require_role('admin', 'reception')
def outpatient_register():
    """
    调用存储过程：门诊挂号
    
    存储过程：sp_outpatient_register
    功能：完成挂号并自动创建就诊记录、生成挂号费
    """
    try:
        data = request.get_json()
        
        sql = text("""
            CALL sp_outpatient_register(
                :p_patient_id,
                :p_schedule_id,
                :p_chief_complaint,
                @o_registration_id,
                @o_registration_no,
                @o_encounter_id,
                @o_encounter_no,
                @o_charge_id
            )
        """)
        
        db.session.execute(sql, {
            'p_patient_id': data.get('patient_id'),
            'p_schedule_id': data.get('schedule_id'),
            'p_chief_complaint': data.get('chief_complaint', '')
        })
        
        result = db.session.execute(text("""
            SELECT @o_registration_id as registration_id,
                   @o_registration_no as registration_no,
                   @o_encounter_id as encounter_id,
                   @o_encounter_no as encounter_no,
                   @o_charge_id as charge_id
        """)).fetchone()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'registration_id': result.registration_id,
            'registration_no': result.registration_no,
            'encounter_id': result.encounter_id,
            'encounter_no': result.encounter_no,
            'charge_id': result.charge_id,
            'message': '挂号成功'
        })
    
    except Exception as e:
        db.session.rollback()
        error_msg = str(e)
        if '45000' in error_msg:
            if 'not found' in error_msg:
                return jsonify({'error': '患者或排班不存在'}), 404
            elif 'quota exceeded' in error_msg:
                return jsonify({'error': '该排班号源已满'}), 400
        return jsonify({'error': f'挂号失败：{error_msg}'}), 500


@procedures_bp.route('/invoice/attach-charges', methods=['POST'])
@require_role('admin', 'cashier')
def attach_unbilled_charges():
    """
    调用存储过程：附加未开票费用到发票（使用游标）
    
    存储过程：sp_invoice_attach_unbilled_charges
    功能：使用游标遍历新产生的未开票费用，追加到已有发票
    """
    try:
        data = request.get_json()
        invoice_id = data.get('invoice_id')
        
        if not invoice_id:
            return jsonify({'error': '发票ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_invoice_attach_unbilled_charges(
                :p_invoice_id,
                @o_new_line_count
            )
        """)
        
        db.session.execute(sql, {'p_invoice_id': invoice_id})
        
        # 获取输出参数
        result = db.session.execute(text("SELECT @o_new_line_count")).fetchone()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'new_line_count': result[0],
            'message': f'成功追加{result[0]}条费用明细到发票'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'追加费用失败：{str(e)}'}), 500


@procedures_bp.route('/invoice/void', methods=['POST'])
@require_role('admin', 'cashier')
def void_invoice():
    """
    调用存储过程：作废发票（使用游标）
    
    存储过程：sp_invoice_void
    功能：使用游标遍历发票行，将费用状态恢复为未开票
    """
    try:
        data = request.get_json()
        invoice_id = data.get('invoice_id')
        reason = data.get('reason', '手动作废')
        
        if not invoice_id:
            return jsonify({'error': '发票ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_invoice_void(
                :p_invoice_id,
                :p_reason
            )
        """)
        
        db.session.execute(sql, {
            'p_invoice_id': invoice_id,
            'p_reason': reason
        })
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': '发票已作废，相关费用已恢复为未开票状态'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'作废发票失败：{str(e)}'}), 500


@procedures_bp.route('/refund/create', methods=['POST'])
@require_role('admin', 'cashier')
def create_refund():
    """
    调用存储过程：创建退款
    
    存储过程：sp_refund_create
    功能：创建退款记录并更新发票状态
    """
    try:
        data = request.get_json()
        payment_id = data.get('payment_id')
        amount = data.get('amount')
        reason = data.get('reason', '')
        
        if not payment_id or not amount:
            return jsonify({'error': '支付ID和退款金额不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_refund_create(
                :p_payment_id,
                :p_amount,
                :p_reason,
                @o_refund_id,
                @o_refund_no
            )
        """)
        
        db.session.execute(sql, {
            'p_payment_id': payment_id,
            'p_amount': amount,
            'p_reason': reason
        })
        
        # 获取输出参数
        result = db.session.execute(text("""
            SELECT @o_refund_id, @o_refund_no
        """)).fetchone()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'refund_id': result[0],
            'refund_no': result[1],
            'message': '退款成功'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'退款失败：{str(e)}'}), 500


@procedures_bp.route('/bed/transfer', methods=['POST'])
@require_role('admin', 'nurse')
def transfer_bed():
    """
    调用存储过程：床位转移
    
    存储过程：sp_bed_assignment_transfer
    功能：将患者从当前床位转移到新床位
    """
    try:
        data = request.get_json()
        admission_id = data.get('admission_id')
        new_bed_id = data.get('new_bed_id')
        reason = data.get('reason', '')
        
        if not admission_id or not new_bed_id:
            return jsonify({'error': '住院ID和新床位ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_bed_assignment_transfer(
                :p_admission_id,
                :p_new_bed_id,
                :p_reason
            )
        """)
        
        db.session.execute(sql, {
            'p_admission_id': admission_id,
            'p_new_bed_id': new_bed_id,
            'p_reason': reason
        })
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': '床位转移成功'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'床位转移失败：{str(e)}'}), 500


@procedures_bp.route('/inpatient/discharge', methods=['POST'])
@require_role('admin', 'doctor', 'nurse')
def discharge_inpatient():
    """
    调用存储过程：办理出院
    
    存储过程：sp_inpatient_discharge
    功能：办理患者出院，释放床位
    """
    try:
        data = request.get_json()
        admission_id = data.get('admission_id')
        discharge_summary = data.get('discharge_summary', '')
        
        if not admission_id:
            return jsonify({'error': '住院ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_inpatient_discharge(
                :p_admission_id,
                :p_discharge_summary
            )
        """)
        
        db.session.execute(sql, {
            'p_admission_id': admission_id,
            'p_discharge_summary': discharge_summary
        })
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': '出院办理成功，床位已释放'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'办理出院失败：{str(e)}'}), 500


@procedures_bp.route('/lab/mark-collected', methods=['POST'])
@require_role('admin', 'lab_tech', 'nurse')
def mark_lab_collected():
    """
    调用存储过程：标记检验单已采样
    
    存储过程：sp_lab_order_mark_collected
    功能：标记检验单为已采样状态
    """
    try:
        data = request.get_json()
        lab_order_id = data.get('lab_order_id')
        
        if not lab_order_id:
            return jsonify({'error': '检验单ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_lab_order_mark_collected(:p_lab_order_id)
        """)
        
        db.session.execute(sql, {'p_lab_order_id': lab_order_id})
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': '检验单已标记为已采样'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'标记采样失败：{str(e)}'}), 500


@procedures_bp.route('/lab/prepare-results', methods=['POST'])
@require_role('admin', 'lab_tech')
def prepare_lab_results():
    """
    调用存储过程：准备检验结果占位（使用游标）
    
    存储过程：sp_lab_order_prepare_results
    功能：使用游标遍历检验单的所有项目，为每个项目创建结果记录占位
    """
    try:
        data = request.get_json()
        lab_order_id = data.get('lab_order_id')
        technician_id = data.get('technician_id')
        
        if not lab_order_id or not technician_id:
            return jsonify({'error': '检验单ID和技师ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_lab_order_prepare_results(
                :p_lab_order_id,
                :p_technician_id,
                @o_result_count
            )
        """)
        
        db.session.execute(sql, {
            'p_lab_order_id': lab_order_id,
            'p_technician_id': technician_id
        })
        
        # 获取输出参数
        result = db.session.execute(text("SELECT @o_result_count")).fetchone()
        db.session.commit()
        
        return jsonify({
            'success': True,
            'result_count': result[0],
            'message': f'成功为{result[0]}个检验项目创建结果占位'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'准备检验结果失败：{str(e)}'}), 500


@procedures_bp.route('/lab/verify-result', methods=['POST'])
@require_role('admin', 'lab_tech')
def verify_lab_result():
    """
    调用存储过程：审核检验结果
    
    存储过程：sp_lab_result_verify
    功能：审核检验结果，标记为已审核
    """
    try:
        data = request.get_json()
        lab_result_id = data.get('lab_result_id')
        verified_by = data.get('verified_by')
        
        if not lab_result_id or not verified_by:
            return jsonify({'error': '结果ID和审核人ID不能为空'}), 400
        
        # 调用存储过程
        sql = text("""
            CALL sp_lab_result_verify(
                :p_lab_result_id,
                :p_verified_by
            )
        """)
        
        db.session.execute(sql, {
            'p_lab_result_id': lab_result_id,
            'p_verified_by': verified_by
        })
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': '检验结果已审核'
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'审核检验结果失败：{str(e)}'}), 500


@procedures_bp.route('/list', methods=['GET'])
@require_role('admin')
def list_procedures():
    """
    列出所有可用的存储过程（仅管理员）
    """
    try:
        sql = text("""
            SELECT 
                ROUTINE_NAME as name,
                ROUTINE_TYPE as type,
                ROUTINE_COMMENT as comment
            FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = 'hospital_test'
            ORDER BY ROUTINE_NAME
        """)
        
        result = db.session.execute(sql).fetchall()
        
        procedures = []
        for row in result:
            procedures.append({
                'name': row.name,
                'type': row.type,
                'comment': row.comment
            })
        
        return jsonify({
            'procedures': procedures,
            'count': len(procedures),
            'current_role': get_current_role()
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
