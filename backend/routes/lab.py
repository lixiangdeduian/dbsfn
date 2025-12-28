"""
检验管理路由
"""
from flask import Blueprint, request, jsonify
from models import db
from sqlalchemy import text
from auth import require_role

lab_bp = Blueprint('lab', __name__)


@lab_bp.route('/worklist', methods=['GET'])
@require_role('admin', 'lab_tech')
def get_worklist():
    """
    获取检验工作台列表
    使用视图：v_lab_worklist
    """
    try:
        sql = text("""
            SELECT *
            FROM v_lab_worklist
            WHERE lab_order_status IN ('ORDERED', 'COLLECTED')
            ORDER BY ordered_at
            LIMIT 100
        """)
        
        result = db.session.execute(sql).fetchall()
        
        data = []
        for row in result:
            data.append({
                'lab_order_id': row.lab_order_id,
                'lab_order_no': row.lab_order_no,
                'lab_order_status': row.lab_order_status,
                'ordered_at': row.ordered_at.isoformat() if row.ordered_at else None,
                'encounter_id': row.encounter_id,
                'encounter_no': row.encounter_no,
                'department_id': row.department_id,
                'department_name': row.department_name,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name,
                'doctor_id': row.doctor_id,
                'doctor_name': row.doctor_name,
                'lab_order_item_id': row.lab_order_item_id,
                'lab_test_id': row.lab_test_id,
                'test_code': row.test_code,
                'test_name': row.test_name,
                'quantity': row.quantity,
                'unit_price': float(row.unit_price) if row.unit_price else 0,
                'amount': float(row.amount) if row.amount else 0,
                'lab_result_id': row.lab_result_id,
                'result_value': row.result_value,
                'result_text': row.result_text,
                'result_flag': row.result_flag,
                'result_at': row.result_at.isoformat() if row.result_at else None,
                'technician_id': row.technician_id,
                'verified_by': row.verified_by,
                'verified_at': row.verified_at.isoformat() if row.verified_at else None
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@lab_bp.route('/results', methods=['GET'])
@require_role('admin', 'lab_tech', 'doctor')
def get_lab_results():
    """
    获取检验结果列表
    使用视图：v_lab_result_detail
    """
    try:
        page = int(request.args.get('page', 1))
        page_size = int(request.args.get('page_size', 10))
        offset = (page - 1) * page_size
        
        sql = text("""
            SELECT *
            FROM v_lab_result_detail
            WHERE lab_result_id IS NOT NULL
            ORDER BY result_at DESC
            LIMIT :limit OFFSET :offset
        """)
        
        result = db.session.execute(sql, {
            'limit': page_size,
            'offset': offset
        }).fetchall()
        
        data = []
        for row in result:
            data.append({
                'lab_order_id': row.lab_order_id,
                'lab_order_no': row.lab_order_no,
                'encounter_id': row.encounter_id,
                'doctor_id': row.doctor_id,
                'ordered_at': row.ordered_at.isoformat() if row.ordered_at else None,
                'order_status': row.order_status,
                'lab_order_item_id': row.lab_order_item_id,
                'lab_test_id': row.lab_test_id,
                'test_code': row.test_code,
                'test_name': row.test_name,
                'unit': row.unit,
                'reference_range': row.reference_range,
                'quantity': row.quantity,
                'unit_price': float(row.unit_price) if row.unit_price else 0,
                'amount': float(row.amount) if row.amount else 0,
                'lab_result_id': row.lab_result_id,
                'result_value': row.result_value,
                'result_text': row.result_text,
                'result_flag': row.result_flag,
                'result_at': row.result_at.isoformat() if row.result_at else None,
                'technician_id': row.technician_id,
                'verified_by': row.verified_by,
                'verified_at': row.verified_at.isoformat() if row.verified_at else None
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'page': page,
            'page_size': page_size
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

