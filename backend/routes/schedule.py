from flask import Blueprint, request, jsonify
from models import db, DoctorSchedule, Staff, Department
from datetime import datetime, timedelta

schedule_bp = Blueprint('schedule', __name__)


@schedule_bp.route('/', methods=['GET'])
def get_schedules():
    """获取排班列表"""
    try:
        # 获取查询参数
        department_id = request.args.get('department_id', type=int)
        doctor_id = request.args.get('doctor_id', type=int)
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # 构建查询
        query = DoctorSchedule.query.filter_by(is_active=True)
        
        if department_id:
            query = query.filter_by(department_id=department_id)
        if doctor_id:
            query = query.filter_by(doctor_id=doctor_id)
        if start_date:
            query = query.filter(DoctorSchedule.schedule_date >= datetime.fromisoformat(start_date).date())
        if end_date:
            query = query.filter(DoctorSchedule.schedule_date <= datetime.fromisoformat(end_date).date())
        
        # 分页
        pagination = query.order_by(DoctorSchedule.schedule_date, DoctorSchedule.start_time).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        # 获取每个排班已预约的数量
        schedules_data = []
        for schedule in pagination.items:
            schedule_dict = schedule.to_dict()
            # 查询已预约数量
            from models import Registration
            booked_count = Registration.query.filter_by(
                schedule_id=schedule.schedule_id,
                status='CONFIRMED'
            ).count()
            schedule_dict['booked_count'] = booked_count
            schedule_dict['available_quota'] = schedule.quota - booked_count
            schedules_data.append(schedule_dict)
        
        return jsonify({
            'schedules': schedules_data,
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@schedule_bp.route('/<int:schedule_id>', methods=['GET'])
def get_schedule(schedule_id):
    """获取排班详情"""
    try:
        schedule = DoctorSchedule.query.get_or_404(schedule_id)
        schedule_dict = schedule.to_dict()
        
        # 查询已预约数量
        from models import Registration
        booked_count = Registration.query.filter_by(
            schedule_id=schedule_id,
            status='CONFIRMED'
        ).count()
        schedule_dict['booked_count'] = booked_count
        schedule_dict['available_quota'] = schedule.quota - booked_count
        
        return jsonify(schedule_dict)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@schedule_bp.route('/', methods=['POST'])
def create_schedule():
    """创建排班"""
    try:
        data = request.get_json()
        
        # 验证医生是否存在
        doctor = Staff.query.get(data['doctor_id'])
        if not doctor:
            return jsonify({'error': '医生不存在'}), 404
        
        # 验证科室是否存在
        department = Department.query.get(data['department_id'])
        if not department:
            return jsonify({'error': '科室不存在'}), 404
        
        # 检查时间冲突
        schedule_date = datetime.fromisoformat(data['schedule_date']).date()
        start_time = datetime.strptime(data['start_time'], '%H:%M:%S').time()
        end_time = datetime.strptime(data['end_time'], '%H:%M:%S').time()
        
        existing = DoctorSchedule.query.filter_by(
            doctor_id=data['doctor_id'],
            schedule_date=schedule_date,
            is_active=True
        ).filter(
            db.or_(
                db.and_(
                    DoctorSchedule.start_time <= start_time,
                    DoctorSchedule.end_time > start_time
                ),
                db.and_(
                    DoctorSchedule.start_time < end_time,
                    DoctorSchedule.end_time >= end_time
                )
            )
        ).first()
        
        if existing:
            return jsonify({'error': '该时间段已有排班'}), 400
        
        schedule = DoctorSchedule(
            doctor_id=data['doctor_id'],
            department_id=data['department_id'],
            schedule_date=schedule_date,
            start_time=start_time,
            end_time=end_time,
            quota=data['quota'],
            registration_fee=data.get('registration_fee', 0.00)
        )
        
        db.session.add(schedule)
        db.session.commit()
        
        return jsonify(schedule.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@schedule_bp.route('/<int:schedule_id>', methods=['PUT'])
def update_schedule(schedule_id):
    """更新排班"""
    try:
        schedule = DoctorSchedule.query.get_or_404(schedule_id)
        data = request.get_json()
        
        # 更新字段
        if 'quota' in data:
            schedule.quota = data['quota']
        if 'registration_fee' in data:
            schedule.registration_fee = data['registration_fee']
        if 'is_active' in data:
            schedule.is_active = data['is_active']
        
        db.session.commit()
        
        return jsonify(schedule.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@schedule_bp.route('/<int:schedule_id>', methods=['DELETE'])
def delete_schedule(schedule_id):
    """删除排班（软删除）"""
    try:
        schedule = DoctorSchedule.query.get_or_404(schedule_id)
        
        # 检查是否有已确认的预约
        from models import Registration
        has_bookings = Registration.query.filter_by(
            schedule_id=schedule_id,
            status='CONFIRMED'
        ).count() > 0
        
        if has_bookings:
            return jsonify({'error': '该排班已有预约，无法删除'}), 400
        
        schedule.is_active = False
        db.session.commit()
        
        return jsonify({'message': '排班已删除'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

