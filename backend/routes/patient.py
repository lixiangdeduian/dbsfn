from flask import Blueprint, request, jsonify
from models import db, Patient
from datetime import datetime
import random

patient_bp = Blueprint('patient', __name__)


@patient_bp.route('/', methods=['GET'])
def get_patients():
    """获取患者列表"""
    try:
        # 获取查询参数
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        search = request.args.get('search', '')
        
        # 构建查询
        query = Patient.query.filter_by(is_active=True)
        
        if search:
            query = query.filter(
                db.or_(
                    Patient.patient_name.like(f'%{search}%'),
                    Patient.patient_no.like(f'%{search}%'),
                    Patient.phone.like(f'%{search}%'),
                    Patient.id_card_no.like(f'%{search}%')
                )
            )
        
        # 分页
        pagination = query.order_by(Patient.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'patients': [p.to_dict() for p in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@patient_bp.route('/<int:patient_id>', methods=['GET'])
def get_patient(patient_id):
    """获取患者详情"""
    try:
        patient = Patient.query.get_or_404(patient_id)
        return jsonify(patient.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@patient_bp.route('/', methods=['POST'])
def create_patient():
    """创建患者"""
    try:
        data = request.get_json()
        
        # 生成患者编号
        patient_no = f"P{datetime.now().strftime('%Y%m%d')}{random.randint(1000, 9999)}"
        
        # 检查身份证号是否已存在
        if data.get('id_card_no'):
            existing = Patient.query.filter_by(id_card_no=data['id_card_no']).first()
            if existing:
                return jsonify({'error': '身份证号已存在'}), 400
        
        patient = Patient(
            patient_no=patient_no,
            patient_name=data['patient_name'],
            gender=data.get('gender', 'U'),
            birth_date=datetime.fromisoformat(data['birth_date']) if data.get('birth_date') else None,
            id_card_no=data.get('id_card_no'),
            phone=data.get('phone'),
            address=data.get('address'),
            emergency_contact_name=data.get('emergency_contact_name'),
            emergency_contact_phone=data.get('emergency_contact_phone'),
            blood_type=data.get('blood_type', 'U'),
            allergy_history=data.get('allergy_history')
        )
        
        db.session.add(patient)
        db.session.commit()
        
        return jsonify(patient.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@patient_bp.route('/<int:patient_id>', methods=['PUT'])
def update_patient(patient_id):
    """更新患者信息"""
    try:
        patient = Patient.query.get_or_404(patient_id)
        data = request.get_json()
        
        # 更新字段
        if 'patient_name' in data:
            patient.patient_name = data['patient_name']
        if 'gender' in data:
            patient.gender = data['gender']
        if 'birth_date' in data:
            patient.birth_date = datetime.fromisoformat(data['birth_date']) if data['birth_date'] else None
        if 'phone' in data:
            patient.phone = data['phone']
        if 'address' in data:
            patient.address = data['address']
        if 'emergency_contact_name' in data:
            patient.emergency_contact_name = data['emergency_contact_name']
        if 'emergency_contact_phone' in data:
            patient.emergency_contact_phone = data['emergency_contact_phone']
        if 'blood_type' in data:
            patient.blood_type = data['blood_type']
        if 'allergy_history' in data:
            patient.allergy_history = data['allergy_history']
        
        db.session.commit()
        
        return jsonify(patient.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@patient_bp.route('/<int:patient_id>', methods=['DELETE'])
def delete_patient(patient_id):
    """删除患者（软删除）"""
    try:
        patient = Patient.query.get_or_404(patient_id)
        patient.is_active = False
        db.session.commit()
        
        return jsonify({'message': '患者已删除'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

