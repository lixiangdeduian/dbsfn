from flask import Blueprint, request, jsonify
from models import db, Encounter, Patient, Department, Staff, Registration
from datetime import datetime
import random

encounter_bp = Blueprint('encounter', __name__)


@encounter_bp.route('/', methods=['GET'])
def get_encounters():
    """获取就诊记录列表"""
    try:
        # 获取查询参数
        patient_id = request.args.get('patient_id', type=int)
        doctor_id = request.args.get('doctor_id', type=int)
        department_id = request.args.get('department_id', type=int)
        status = request.args.get('status')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # 构建查询
        query = Encounter.query
        
        if patient_id:
            query = query.filter_by(patient_id=patient_id)
        if doctor_id:
            query = query.filter_by(doctor_id=doctor_id)
        if department_id:
            query = query.filter_by(department_id=department_id)
        if status:
            query = query.filter_by(status=status)
        
        # 分页
        pagination = query.order_by(Encounter.started_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'encounters': [e.to_dict() for e in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@encounter_bp.route('/<int:encounter_id>', methods=['GET'])
def get_encounter(encounter_id):
    """获取就诊记录详情"""
    try:
        encounter = Encounter.query.get_or_404(encounter_id)
        return jsonify(encounter.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@encounter_bp.route('/', methods=['POST'])
def create_encounter():
    """创建就诊记录（到院登记）"""
    try:
        data = request.get_json()
        
        # 验证患者是否存在
        patient = Patient.query.get(data['patient_id'])
        if not patient:
            return jsonify({'error': '患者不存在'}), 404
        
        # 验证医生是否存在
        doctor = Staff.query.get(data['doctor_id'])
        if not doctor:
            return jsonify({'error': '医生不存在'}), 404
        
        # 验证科室是否存在
        department = Department.query.get(data['department_id'])
        if not department:
            return jsonify({'error': '科室不存在'}), 404
        
        # 生成就诊号
        encounter_no = f"E{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"
        
        # 如果有挂号ID，验证并更新挂号状态
        registration_id = data.get('registration_id')
        if registration_id:
            registration = Registration.query.get(registration_id)
            if not registration:
                return jsonify({'error': '挂号记录不存在'}), 404
            if registration.status != 'CONFIRMED':
                return jsonify({'error': '挂号状态不正确'}), 400
            # 更新挂号状态为已完成
            registration.status = 'COMPLETED'
        
        encounter = Encounter(
            encounter_no=encounter_no,
            patient_id=data['patient_id'],
            department_id=data['department_id'],
            doctor_id=data['doctor_id'],
            registration_id=registration_id,
            encounter_type=data.get('encounter_type', 'OUTPATIENT'),
            note=data.get('note'),
            status='OPEN'
        )
        
        db.session.add(encounter)
        db.session.commit()
        
        return jsonify(encounter.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@encounter_bp.route('/<int:encounter_id>', methods=['PUT'])
def update_encounter(encounter_id):
    """更新就诊记录"""
    try:
        encounter = Encounter.query.get_or_404(encounter_id)
        data = request.get_json()
        
        # 更新字段
        if 'note' in data:
            encounter.note = data['note']
        if 'status' in data:
            encounter.status = data['status']
            if data['status'] == 'CLOSED' and not encounter.ended_at:
                encounter.ended_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify(encounter.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@encounter_bp.route('/<int:encounter_id>/close', methods=['POST'])
def close_encounter(encounter_id):
    """结束就诊"""
    try:
        encounter = Encounter.query.get_or_404(encounter_id)
        
        if encounter.status != 'OPEN':
            return jsonify({'error': '该就诊记录状态不正确'}), 400
        
        encounter.status = 'CLOSED'
        encounter.ended_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify(encounter.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

