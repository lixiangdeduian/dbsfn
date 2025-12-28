"""
药房管理路由
"""
from flask import Blueprint, request, jsonify
from models import db
from sqlalchemy import text
from auth import require_role

pharmacy_bp = Blueprint('pharmacy', __name__)


@pharmacy_bp.route('/queue', methods=['GET'])
@require_role('admin', 'pharmacist')
def get_dispense_queue():
    """
    获取待发药队列
    使用视图：v_pharmacy_dispense_queue
    """
    try:
        sql = text("""
            SELECT *
            FROM v_pharmacy_dispense_queue
            ORDER BY issued_at
            LIMIT 100
        """)
        
        result = db.session.execute(sql).fetchall()
        
        data = []
        for row in result:
            data.append({
                'prescription_id': row.prescription_id,
                'prescription_no': row.prescription_no,
                'encounter_id': row.encounter_id,
                'encounter_no': row.encounter_no,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name,
                'doctor_id': row.doctor_id,
                'doctor_name': row.doctor_name,
                'issued_at': row.issued_at.isoformat() if row.issued_at else None,
                'status': row.status,
                'total_amount': float(row.total_amount) if row.total_amount else 0,
                'item_count': row.item_count
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@pharmacy_bp.route('/history', methods=['GET'])
@require_role('admin', 'pharmacist')
def get_dispense_history():
    """
    获取发药历史记录
    使用视图：v_pharmacy_dispense_detail
    """
    try:
        page = int(request.args.get('page', 1))
        page_size = int(request.args.get('page_size', 10))
        offset = (page - 1) * page_size
        
        sql = text("""
            SELECT *
            FROM v_pharmacy_dispense_detail
            ORDER BY dispensed_at DESC
            LIMIT :limit OFFSET :offset
        """)
        
        result = db.session.execute(sql, {
            'limit': page_size,
            'offset': offset
        }).fetchall()
        
        data = []
        for row in result:
            data.append({
                'dispense_id': row.dispense_id,
                'dispense_status': row.dispense_status,
                'dispensed_at': row.dispensed_at.isoformat() if row.dispensed_at else None,
                'pharmacist_id': row.pharmacist_id,
                'pharmacist_name': row.pharmacist_name,
                'prescription_id': row.prescription_id,
                'prescription_no': row.prescription_no,
                'prescription_status': row.prescription_status,
                'total_amount': float(row.total_amount) if row.total_amount else 0,
                'encounter_id': row.encounter_id,
                'encounter_no': row.encounter_no,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'page': page,
            'page_size': page_size
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

