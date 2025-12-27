from flask import Blueprint, request, jsonify
from models import db, Registration, DoctorSchedule, Patient
from datetime import datetime
import random

registration_bp = Blueprint('registration', __name__)


@registration_bp.route('/', methods=['GET'])
def get_registrations():
    """获取挂号列表"""
    try:
        # 获取查询参数
        patient_id = request.args.get('patient_id', type=int)
        status = request.args.get('status')
        date = request.args.get('date')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # 构建查询
        query = Registration.query
        
        if patient_id:
            query = query.filter_by(patient_id=patient_id)
        if status:
            query = query.filter_by(status=status)
        if date:
            date_obj = datetime.fromisoformat(date).date()
            query = query.join(DoctorSchedule).filter(DoctorSchedule.schedule_date == date_obj)
        
        # 分页
        pagination = query.order_by(Registration.registered_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'registrations': [r.to_dict() for r in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@registration_bp.route('/<int:registration_id>', methods=['GET'])
def get_registration(registration_id):
    """获取挂号详情"""
    try:
        registration = Registration.query.get_or_404(registration_id)
        return jsonify(registration.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@registration_bp.route('/', methods=['POST'])
def create_registration():
    """创建挂号（预约）"""
    try:
        data = request.get_json()
        
        # 验证患者是否存在
        patient = Patient.query.get(data['patient_id'])
        if not patient:
            return jsonify({'error': '患者不存在'}), 404
        
        # 验证排班是否存在
        schedule = DoctorSchedule.query.get(data['schedule_id'])
        if not schedule:
            return jsonify({'error': '排班不存在'}), 404
        
        if not schedule.is_active:
            return jsonify({'error': '该排班已停用'}), 400
        
        # 检查是否已预约
        existing = Registration.query.filter_by(
            patient_id=data['patient_id'],
            schedule_id=data['schedule_id']
        ).filter(Registration.status.in_(['CONFIRMED'])).first()
        
        if existing:
            return jsonify({'error': '您已预约该排班'}), 400
        
        # 检查号源是否充足
        booked_count = Registration.query.filter_by(
            schedule_id=data['schedule_id'],
            status='CONFIRMED'
        ).count()
        
        if booked_count >= schedule.quota:
            return jsonify({'error': '号源已满'}), 400
        
        # 生成挂号单号
        registration_no = f"R{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"
        
        registration = Registration(
            registration_no=registration_no,
            patient_id=data['patient_id'],
            schedule_id=data['schedule_id'],
            chief_complaint=data.get('chief_complaint'),
            status='CONFIRMED'
        )
        
        db.session.add(registration)
        db.session.commit()
        
        return jsonify(registration.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@registration_bp.route('/<int:registration_id>/cancel', methods=['POST'])
def cancel_registration(registration_id):
    """取消挂号"""
    try:
        registration = Registration.query.get_or_404(registration_id)
        
        if registration.status != 'CONFIRMED':
            return jsonify({'error': '该挂号无法取消'}), 400
        
        registration.status = 'CANCELLED'
        db.session.commit()
        
        return jsonify(registration.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@registration_bp.route('/<int:registration_id>/complete', methods=['POST'])
def complete_registration(registration_id):
    """完成挂号"""
    try:
        registration = Registration.query.get_or_404(registration_id)
        
        if registration.status != 'CONFIRMED':
            return jsonify({'error': '该挂号状态不正确'}), 400
        
        registration.status = 'COMPLETED'
        db.session.commit()
        
        return jsonify(registration.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

