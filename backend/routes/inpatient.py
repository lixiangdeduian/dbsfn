"""
住院管理路由
"""
from flask import Blueprint, request, jsonify
from models import db
from sqlalchemy import text
from auth import require_role

inpatient_bp = Blueprint('inpatient', __name__)


@inpatient_bp.route('/', methods=['GET'])
@require_role('admin', 'nurse', 'doctor')
def get_inpatients():
    """
    获取在院患者列表
    使用视图：v_inpatient_current
    """
    try:
        sql = text("""
            SELECT *
            FROM v_inpatient_current
            ORDER BY admitted_at DESC
            LIMIT 100
        """)
        
        result = db.session.execute(sql).fetchall()
        
        data = []
        for row in result:
            data.append({
                'admission_id': row.admission_id,
                'admission_no': row.admission_no,
                'status': row.status,
                'patient_id': row.patient_id,
                'patient_no': row.patient_no,
                'patient_name': row.patient_name,
                'department_id': row.department_id,
                'department_name': row.department_name,
                'attending_doctor_id': row.attending_doctor_id,
                'attending_doctor_name': row.attending_doctor_name,
                'admitted_at': row.admitted_at.isoformat() if row.admitted_at else None,
                'discharged_at': row.discharged_at.isoformat() if row.discharged_at else None,
                'admission_note': row.admission_note,
                'bed_assignment_id': row.bed_assignment_id,
                'bed_start_at': row.bed_start_at.isoformat() if row.bed_start_at else None,
                'bed_end_at': row.bed_end_at.isoformat() if row.bed_end_at else None,
                'bed_id': row.bed_id,
                'bed_no': row.bed_no,
                'ward_id': row.ward_id,
                'ward_name': row.ward_name
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@inpatient_bp.route('/beds', methods=['GET'])
@require_role('admin', 'nurse')
def get_bed_occupancy():
    """
    获取床位占用情况
    使用视图：v_bed_occupancy
    """
    try:
        sql = text("""
            SELECT *
            FROM v_bed_occupancy
            ORDER BY ward_name, bed_no
            LIMIT 200
        """)
        
        result = db.session.execute(sql).fetchall()
        
        data = []
        for row in result:
            data.append({
                'bed_id': row.bed_id,
                'bed_no': row.bed_no,
                'bed_status': row.bed_status,
                'ward_id': row.ward_id,
                'ward_name': row.ward_name,
                'department_id': row.department_id,
                'department_name': row.department_name,
                'bed_assignment_id': row.bed_assignment_id,
                'start_at': row.start_at.isoformat() if row.start_at else None,
                'end_at': row.end_at.isoformat() if row.end_at else None,
                'admission_id': row.admission_id,
                'admission_no': row.admission_no,
                'admission_status': row.admission_status,
                'patient_id': row.patient_id,
                'patient_name': row.patient_name
            })
        
        return jsonify({
            'success': True,
            'data': data,
            'count': len(data)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

