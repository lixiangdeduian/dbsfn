from flask import Blueprint, request, jsonify
from models import db, Department

department_bp = Blueprint('department', __name__)


@department_bp.route('/', methods=['GET'])
def get_departments():
    """获取科室列表"""
    try:
        # 获取查询参数
        is_active = request.args.get('is_active', type=int)
        
        # 构建查询
        query = Department.query
        
        if is_active is not None:
            query = query.filter_by(is_active=bool(is_active))
        
        departments = query.order_by(Department.department_code).all()
        
        return jsonify({
            'departments': [d.to_dict() for d in departments],
            'total': len(departments)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@department_bp.route('/<int:department_id>', methods=['GET'])
def get_department(department_id):
    """获取科室详情"""
    try:
        department = Department.query.get_or_404(department_id)
        return jsonify(department.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@department_bp.route('/', methods=['POST'])
def create_department():
    """创建科室"""
    try:
        data = request.get_json()
        
        # 检查编码是否已存在
        existing = Department.query.filter_by(department_code=data['department_code']).first()
        if existing:
            return jsonify({'error': '科室编码已存在'}), 400
        
        department = Department(
            department_code=data['department_code'],
            department_name=data['department_name'],
            parent_department_id=data.get('parent_department_id')
        )
        
        db.session.add(department)
        db.session.commit()
        
        return jsonify(department.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@department_bp.route('/<int:department_id>', methods=['PUT'])
def update_department(department_id):
    """更新科室信息"""
    try:
        department = Department.query.get_or_404(department_id)
        data = request.get_json()
        
        # 更新字段
        if 'department_name' in data:
            department.department_name = data['department_name']
        if 'is_active' in data:
            department.is_active = data['is_active']
        if 'parent_department_id' in data:
            department.parent_department_id = data['parent_department_id']
        
        db.session.commit()
        
        return jsonify(department.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@department_bp.route('/<int:department_id>', methods=['DELETE'])
def delete_department(department_id):
    """删除科室（软删除）"""
    try:
        department = Department.query.get_or_404(department_id)
        department.is_active = False
        db.session.commit()
        
        return jsonify({'message': '科室已删除'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

