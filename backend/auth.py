"""
认证和授权模块
"""
from flask import request, jsonify
from functools import wraps
import jwt
import datetime
from config import Config

# 角色权限配置
ROLE_PERMISSIONS = {
    'admin': {
        'name': '超级管理员',
        'permissions': ['*'],  # 所有权限
        'menus': ['dashboard', 'patients', 'staff', 'departments', 'schedules', 
                  'registrations', 'encounters', 'invoices', 'statistics', 'system'],
        'readonly_fields': []  # 无只读限制
    },
    'doctor': {
        'name': '医生',
        'permissions': ['patients.read', 'schedules.read', 'registrations.read',
                       'encounters.read', 'encounters.create', 'encounters.update',
                       'prescriptions.read', 'prescriptions.create', 'lab_orders.create'],
        'menus': ['dashboard', 'patients', 'schedules', 'registrations', 'encounters'],
        'readonly_fields': ['patient.id_card_no', 'invoice', 'payment']  # 只读字段
    },
    'nurse': {
        'name': '护士',
        'permissions': ['patients.read', 'encounters.read', 'admissions.read',
                       'admissions.create', 'admissions.update', 'beds.manage'],
        'menus': ['dashboard', 'patients', 'encounters', 'inpatients'],
        'readonly_fields': ['invoice', 'payment', 'prescription']
    },
    'pharmacist': {
        'name': '药剂师',
        'permissions': ['drugs.read', 'drugs.update', 'prescriptions.read',
                       'prescriptions.dispense'],
        'menus': ['dashboard', 'pharmacy', 'prescriptions'],
        'readonly_fields': ['patient.id_card_no', 'invoice', 'payment']
    },
    'lab_tech': {
        'name': '检验技师',
        'permissions': ['lab_orders.read', 'lab_orders.update', 'lab_results.create',
                       'lab_results.update'],
        'menus': ['dashboard', 'lab_orders', 'lab_results'],
        'readonly_fields': ['patient.id_card_no', 'invoice', 'payment']
    },
    'cashier': {
        'name': '收费员',
        'permissions': ['invoices.read', 'invoices.create', 'invoices.update',
                       'payments.read', 'payments.create', 'charges.read'],
        'menus': ['dashboard', 'invoices', 'payments', 'charges'],
        'readonly_fields': ['diagnosis', 'prescription']
    },
    'reception': {
        'name': '前台接待',
        'permissions': ['patients.read', 'patients.create', 'patients.update',
                       'schedules.read', 'registrations.read', 'registrations.create'],
        'menus': ['dashboard', 'patients', 'schedules', 'registrations'],
        'readonly_fields': ['allergy_history', 'diagnosis', 'invoice', 'payment']
    },
    'patient': {
        'name': '患者',
        'permissions': ['my_info.read', 'my_encounters.read', 'my_prescriptions.read',
                       'my_invoices.read'],
        'menus': ['dashboard', 'my_info', 'my_records'],
        'readonly_fields': ['*']  # 所有字段只读
    }
}


def generate_token(user_id, username, role):
    """生成JWT令牌"""
    payload = {
        'user_id': user_id,
        'username': username,
        'role': role,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')


def decode_token(token):
    """解码JWT令牌"""
    try:
        return jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def get_current_user():
    """从请求头获取当前用户"""
    auth_header = request.headers.get('Authorization')
    if not auth_header:
        return None
    
    try:
        token = auth_header.split(' ')[1]  # Bearer <token>
        return decode_token(token)
    except:
        return None


def require_auth(f):
    """要求登录的装饰器"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user = get_current_user()
        if not user:
            return jsonify({'error': '未登录或令牌已过期'}), 401
        request.current_user = user
        return f(*args, **kwargs)
    return decorated_function


def require_role(*roles):
    """要求特定角色的装饰器"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user = get_current_user()
            if not user:
                return jsonify({'error': '未登录或令牌已过期'}), 401
            
            if user['role'] not in roles and 'admin' not in roles:
                return jsonify({'error': '权限不足'}), 403
            
            request.current_user = user
            return f(*args, **kwargs)
        return decorated_function
    return decorator


def check_permission(permission):
    """检查用户是否有特定权限"""
    user = get_current_user()
    if not user:
        return False
    
    role = user['role']
    if role == 'admin':
        return True
    
    role_perms = ROLE_PERMISSIONS.get(role, {}).get('permissions', [])
    return permission in role_perms or '*' in role_perms


def get_user_menus(role):
    """获取用户可访问的菜单"""
    if role not in ROLE_PERMISSIONS:
        return []
    return ROLE_PERMISSIONS[role]['menus']


def get_readonly_fields(role):
    """获取角色的只读字段列表"""
    if role not in ROLE_PERMISSIONS:
        return ['*']
    return ROLE_PERMISSIONS[role]['readonly_fields']


def is_field_readonly(role, field_name):
    """检查字段是否对该角色只读"""
    readonly_fields = get_readonly_fields(role)
    if '*' in readonly_fields:
        return True
    return field_name in readonly_fields

