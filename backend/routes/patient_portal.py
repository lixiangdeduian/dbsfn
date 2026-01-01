"""
患者自助门户路由
患者角色只能查看自己的数据（通过数据库视图自动过滤）

注意：由于应用使用root连接数据库，而非真正的角色用户切换，
我们需要在每次查询前设置SESSION变量来模拟当前用户。
"""
from flask import Blueprint, jsonify, request
from models import db
from auth import require_role, get_current_role
from sqlalchemy import text

patient_portal_bp = Blueprint('patient_portal', __name__)


def set_db_user_context(username):
    """
    设置数据库会话的用户上下文
    这允许视图使用 @current_user 而不是 USER() 来过滤数据
    """
    try:
        # 设置会话变量来模拟当前用户
        db.session.execute(text("SET @current_user = :username"), {'username': username})
        db.session.commit()
    except Exception as e:
        print(f"Warning: Failed to set DB user context: {e}")


def get_role_username():
    """根据当前角色返回对应的数据库用户名"""
    role = get_current_role()
    role_username_map = {
        'admin': 'admin_user',
        'doctor': 'doctor_user',
        'nurse': 'nurse_user',
        'pharmacist': 'pharmacist_user',
        'lab_tech': 'lab_tech_user',
        'cashier': 'cashier_user',
        'reception': 'reception_user',
        'patient': 'patient_user'
    }
    return role_username_map.get(role, 'admin_user')


@patient_portal_bp.route('/my-info', methods=['GET'])
@require_role('admin', 'patient')
def get_my_info():
    """
    获取当前患者的基本信息
    通过 user_account 表查找当前角色对应的 patient_id
    """
    try:
        # 获取当前角色对应的用户名
        username = get_role_username()
        
        # 先从 user_account 表获取 patient_id
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': False,
                'error': '未找到患者信息，请确保已创建测试账号数据'
            }), 404
        
        patient_id = user_result.patient_id
        
        # 查询患者详细信息
        patient_sql = text("""
            SELECT 
                patient_id,
                patient_no,
                patient_name,
                gender,
                birth_date,
                phone,
                address,
                blood_type,
                allergy_history
            FROM patient
            WHERE patient_id = :patient_id AND is_active = 1
        """)
        
        result = db.session.execute(patient_sql, {'patient_id': patient_id}).fetchone()
        
        if not result:
            return jsonify({
                'success': False,
                'error': '未找到患者信息'
            }), 404
        
        return jsonify({
            'success': True,
            'data': {
                'patient_id': result.patient_id,
                'patient_no': result.patient_no,
                'patient_name': result.patient_name,
                'gender': result.gender,
                'birth_date': str(result.birth_date) if result.birth_date else None,
                'phone': result.phone,
                'address': result.address,
                'blood_type': result.blood_type,
                'allergy_history': result.allergy_history
            }
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@patient_portal_bp.route('/my-encounters', methods=['GET'])
@require_role('admin', 'patient')
def get_my_encounters():
    """
    获取我的就诊记录
    通过 user_account 查找当前患者ID，然后查询就诊记录
    """
    try:
        # 获取当前患者ID
        username = get_role_username()
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': True,
                'data': [],
                'count': 0,
                'message': '未找到患者账号'
            })
        
        patient_id = user_result.patient_id
        
        # 查询该患者的就诊记录
        sql = text("""
            SELECT *
            FROM v_encounter_summary
            WHERE patient_id = :patient_id
            ORDER BY started_at DESC
            LIMIT 50
        """)
        
        result = db.session.execute(sql, {'patient_id': patient_id}).fetchall()
        
        data = []
        for row in result:
            data.append({
                'encounter_id': row.encounter_id,
                'encounter_no': row.encounter_no,
                'encounter_type': row.encounter_type,
                'started_at': row.started_at.isoformat() if row.started_at else None,
                'ended_at': row.ended_at.isoformat() if row.ended_at else None,
                'status': row.status,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name,
                'department_name': row.department_name,
                'doctor_name': row.doctor_name
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@patient_portal_bp.route('/my-prescriptions', methods=['GET'])
@require_role('admin', 'patient')
def get_my_prescriptions():
    """
    获取我的处方记录
    """
    try:
        # 获取当前患者ID
        username = get_role_username()
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': True,
                'data': [],
                'count': 0
            })
        
        patient_id = user_result.patient_id
        
        # 查询该患者的处方记录
        sql = text("""
            SELECT pd.*
            FROM v_prescription_detail pd
            JOIN encounter e ON e.encounter_id = pd.encounter_id
            WHERE e.patient_id = :patient_id
            ORDER BY pd.issued_at DESC
            LIMIT 100
        """)
        
        result = db.session.execute(sql, {'patient_id': patient_id}).fetchall()
        
        data = []
        for row in result:
            data.append({
                'prescription_id': row.prescription_id,
                'prescription_no': row.prescription_no,
                'encounter_id': row.encounter_id,
                'doctor_id': row.doctor_id,
                'issued_at': row.issued_at.isoformat() if row.issued_at else None,
                'status': row.status,
                'total_amount': float(row.total_amount) if row.total_amount else 0,
                'prescription_item_id': row.prescription_item_id,
                'drug_id': row.drug_id,
                'drug_name': row.drug_name,
                'specification': row.specification,
                'unit': row.unit,
                'quantity': float(row.quantity) if row.quantity else 0,
                'unit_price': float(row.unit_price) if row.unit_price else 0,
                'amount': float(row.amount) if row.amount else 0,
                'usage_instructions': row.usage_instructions,
                'frequency': row.frequency,
                'days': row.days
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@patient_portal_bp.route('/my-lab-results', methods=['GET'])
@require_role('admin', 'patient')
def get_my_lab_results():
    """
    获取我的检验结果
    """
    try:
        # 获取当前患者ID
        username = get_role_username()
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': True,
                'data': [],
                'count': 0
            })
        
        patient_id = user_result.patient_id
        
        # 查询该患者的检验结果
        sql = text("""
            SELECT lrd.*
            FROM v_lab_result_detail lrd
            JOIN encounter e ON e.encounter_id = lrd.encounter_id
            WHERE e.patient_id = :patient_id
              AND lrd.lab_result_id IS NOT NULL
            ORDER BY lrd.ordered_at DESC
            LIMIT 100
        """)
        
        result = db.session.execute(sql, {'patient_id': patient_id}).fetchall()
        
        data = []
        for row in result:
            data.append({
                'lab_order_id': row.lab_order_id,
                'lab_order_no': row.lab_order_no,
                'encounter_id': row.encounter_id,
                'doctor_id': row.doctor_id,
                'ordered_at': row.ordered_at.isoformat() if row.ordered_at else None,
                'order_status': row.order_status,
                'lab_test_id': row.lab_test_id,
                'test_code': row.test_code,
                'test_name': row.test_name,
                'unit': row.unit,
                'reference_range': row.reference_range,
                'lab_result_id': row.lab_result_id,
                'result_value': row.result_value,
                'result_text': row.result_text,
                'result_flag': row.result_flag,
                'result_at': row.result_at.isoformat() if row.result_at else None,
                'verified_at': row.verified_at.isoformat() if row.verified_at else None
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@patient_portal_bp.route('/my-invoices', methods=['GET'])
@require_role('admin', 'patient')
def get_my_invoices():
    """
    获取我的账单
    """
    try:
        # 获取当前患者ID
        username = get_role_username()
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': True,
                'data': [],
                'count': 0
            })
        
        patient_id = user_result.patient_id
        
        # 查询该患者的账单
        sql = text("""
            SELECT *
            FROM v_invoice_summary
            WHERE patient_id = :patient_id
            ORDER BY issued_at DESC
            LIMIT 50
        """)
        
        result = db.session.execute(sql, {'patient_id': patient_id}).fetchall()
        
        data = []
        for row in result:
            data.append({
                'invoice_id': row.invoice_id,
                'invoice_no': row.invoice_no,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name,
                'encounter_id': row.encounter_id,
                'issued_at': row.issued_at.isoformat() if row.issued_at else None,
                'status': row.status,
                'total_amount': float(row.total_amount) if row.total_amount else 0,
                'paid_amount': float(row.paid_amount) if row.paid_amount else 0,
                'outstanding_amount': float(row.outstanding_amount) if row.outstanding_amount else 0
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@patient_portal_bp.route('/my-invoice-details/<int:invoice_id>', methods=['GET'])
@require_role('admin', 'patient')
def get_my_invoice_details(invoice_id):
    """
    获取我的账单明细
    """
    try:
        # 获取当前患者ID
        username = get_role_username()
        user_sql = text("""
            SELECT patient_id
            FROM user_account
            WHERE username = :username AND is_active = 1 AND patient_id IS NOT NULL
        """)
        user_result = db.session.execute(user_sql, {'username': username}).fetchone()
        
        if not user_result or not user_result.patient_id:
            return jsonify({
                'success': True,
                'data': [],
                'count': 0
            })
        
        patient_id = user_result.patient_id
        
        # 查询该患者的账单明细（确保账单属于该患者）
        sql = text("""
            SELECT cd.*
            FROM v_charge_detail cd
            JOIN invoice_line il ON il.charge_id = cd.charge_id
            JOIN invoice i ON i.invoice_id = il.invoice_id
            WHERE i.invoice_id = :invoice_id
              AND i.patient_id = :patient_id
            ORDER BY cd.charged_at
        """)
        
        result = db.session.execute(sql, {
            'invoice_id': invoice_id,
            'patient_id': patient_id
        }).fetchall()
        
        data = []
        for row in result:
            data.append({
                'invoice_id': row.invoice_id,
                'charge_id': row.charge_id,
                'charge_no': row.charge_no,
                'encounter_id': row.encounter_id,
                'source_type': row.source_type,
                'source_id': row.source_id,
                'charged_at': row.charged_at.isoformat() if row.charged_at else None,
                'amount': float(row.amount) if row.amount else 0,
                'item_code': row.item_code,
                'item_name': row.item_name,
                'category': row.category
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

