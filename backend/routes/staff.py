from flask import Blueprint, request, jsonify
from models import db, Staff, Department
from datetime import datetime
import random

staff_bp = Blueprint('staff', __name__)


# 定义StaffDepartment模型
class StaffDepartment(db.Model):
    """员工与部门多对多关系表"""
    __tablename__ = 'staff_department'
    
    staff_department_id = db.Column(db.BigInteger, primary_key=True)
    staff_id = db.Column(db.BigInteger, db.ForeignKey('staff.staff_id'), nullable=False)
    department_id = db.Column(db.BigInteger, db.ForeignKey('department.department_id'), nullable=False)
    is_primary = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


@staff_bp.route('/', methods=['GET'])
def get_staff():
    """获取员工列表"""
    try:
        # 获取查询参数
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        search = request.args.get('search', '')
        department_id = request.args.get('department_id', type=int)
        
        # 构建查询
        query = Staff.query.filter_by(is_active=True)
        
        if search:
            query = query.filter(
                db.or_(
                    Staff.staff_name.like(f'%{search}%'),
                    Staff.staff_no.like(f'%{search}%'),
                    Staff.phone.like(f'%{search}%')
                )
            )
        
        if department_id:
            # 通过关联表查询
            query = query.join(StaffDepartment).filter(
                StaffDepartment.department_id == department_id
            )
        
        # 分页
        pagination = query.order_by(Staff.staff_no).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        # 获取每个员工的科室信息
        staff_list = []
        for staff in pagination.items:
            staff_dict = staff.to_dict()
            # 获取员工的科室
            dept_relations = StaffDepartment.query.filter_by(staff_id=staff.staff_id).all()
            departments = []
            for rel in dept_relations:
                dept = Department.query.get(rel.department_id)
                if dept:
                    departments.append({
                        'department_id': dept.department_id,
                        'department_name': dept.department_name,
                        'is_primary': rel.is_primary
                    })
            staff_dict['departments'] = departments
            staff_list.append(staff_dict)
        
        return jsonify({
            'staff': staff_list,
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@staff_bp.route('/<int:staff_id>', methods=['GET'])
def get_staff_detail(staff_id):
    """获取员工详情"""
    try:
        staff = Staff.query.get_or_404(staff_id)
        staff_dict = staff.to_dict()
        
        # 获取员工的科室
        dept_relations = StaffDepartment.query.filter_by(staff_id=staff_id).all()
        departments = []
        for rel in dept_relations:
            dept = Department.query.get(rel.department_id)
            if dept:
                departments.append({
                    'department_id': dept.department_id,
                    'department_name': dept.department_name,
                    'is_primary': rel.is_primary
                })
        staff_dict['departments'] = departments
        
        return jsonify(staff_dict)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@staff_bp.route('/', methods=['POST'])
def create_staff():
    """创建员工"""
    try:
        data = request.get_json()
        
        # 生成员工工号
        staff_no = f"S{datetime.now().strftime('%Y%m%d')}{random.randint(1000, 9999)}"
        
        # 检查身份证号是否已存在
        if data.get('id_card_no'):
            existing = Staff.query.filter_by(id_card_no=data['id_card_no']).first()
            if existing:
                return jsonify({'error': '身份证号已存在'}), 400
        
        staff = Staff(
            staff_no=staff_no,
            staff_name=data['staff_name'],
            gender=data.get('gender', 'U'),
            phone=data.get('phone'),
            email=data.get('email'),
            id_card_no=data.get('id_card_no'),
            title=data.get('title'),
            hire_date=datetime.fromisoformat(data['hire_date']).date() if data.get('hire_date') else None
        )
        
        db.session.add(staff)
        db.session.flush()  # 获取staff_id
        
        # 添加科室关联
        department_ids = data.get('department_ids', [])
        for dept_id in department_ids:
            dept = Department.query.get(dept_id)
            if not dept:
                db.session.rollback()
                return jsonify({'error': f'科室 {dept_id} 不存在'}), 404
            
            relation = StaffDepartment(
                staff_id=staff.staff_id,
                department_id=dept_id,
                is_primary=(dept_id == department_ids[0])  # 第一个为主科室
            )
            db.session.add(relation)
        
        db.session.commit()
        
        return jsonify(staff.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@staff_bp.route('/<int:staff_id>', methods=['PUT'])
def update_staff(staff_id):
    """更新员工信息"""
    try:
        staff = Staff.query.get_or_404(staff_id)
        data = request.get_json()
        
        # 更新字段
        if 'staff_name' in data:
            staff.staff_name = data['staff_name']
        if 'gender' in data:
            staff.gender = data['gender']
        if 'phone' in data:
            staff.phone = data['phone']
        if 'email' in data:
            staff.email = data['email']
        if 'title' in data:
            staff.title = data['title']
        if 'is_active' in data:
            staff.is_active = data['is_active']
        
        db.session.commit()
        
        return jsonify(staff.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@staff_bp.route('/<int:staff_id>', methods=['DELETE'])
def delete_staff(staff_id):
    """删除员工（软删除）"""
    try:
        staff = Staff.query.get_or_404(staff_id)
        staff.is_active = False
        db.session.commit()
        
        return jsonify({'message': '员工已删除'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

