"""
认证路由
"""
from flask import Blueprint, request, jsonify
from models import db
from auth import generate_token, get_current_user, ROLE_PERMISSIONS
import hashlib

auth_bp = Blueprint('auth', __name__)


def hash_password(password):
    """简单的密码哈希（实际应使用bcrypt）"""
    return hashlib.sha256(password.encode()).hexdigest()


@auth_bp.route('/login', methods=['POST'])
def login():
    """
    用户登录
    请求体：
    {
        "username": "admin",
        "password": "password",
        "role": "admin"  # 用户选择的角色
    }
    """
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')
        role = data.get('role', 'reception')  # 默认前台角色
        
        if not username or not password:
            return jsonify({'error': '用户名和密码不能为空'}), 400
        
        # 验证角色是否有效
        if role not in ROLE_PERMISSIONS:
            return jsonify({'error': '无效的角色'}), 400
        
        # 超级管理员登录（直接使用root账号）
        if role == 'admin':
            # 这里应该验证MySQL root密码，为简化演示直接通过
            if username == 'admin' and password == 'admin123':
                token = generate_token(0, username, role)
                return jsonify({
                    'token': token,
                    'user': {
                        'user_id': 0,
                        'username': username,
                        'role': role,
                        'role_name': ROLE_PERMISSIONS[role]['name'],
                        'permissions': ROLE_PERMISSIONS[role]['permissions'],
                        'menus': ROLE_PERMISSIONS[role]['menus']
                    }
                })
            else:
                return jsonify({'error': '管理员用户名或密码错误'}), 401
        
        # 查询数据库中的用户账号（简化版：暂时跳过密码验证）
        # 在实际应用中应该：
        # 1. 从user_account表查询用户
        # 2. 验证密码哈希
        # 3. 检查用户关联的角色
        
        # 演示用：接受任何用户名密码，根据选择的角色登录
        if len(password) >= 6:  # 最小密码长度检查
            token = generate_token(1, username, role)
            return jsonify({
                'token': token,
                'user': {
                    'user_id': 1,
                    'username': username,
                    'role': role,
                    'role_name': ROLE_PERMISSIONS[role]['name'],
                    'permissions': ROLE_PERMISSIONS[role]['permissions'],
                    'menus': ROLE_PERMISSIONS[role]['menus']
                }
            })
        else:
            return jsonify({'error': '密码长度至少6位'}), 401
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/current-user', methods=['GET'])
def get_user_info():
    """获取当前登录用户信息"""
    user = get_current_user()
    if not user:
        return jsonify({'error': '未登录'}), 401
    
    role = user['role']
    return jsonify({
        'user': {
            'user_id': user['user_id'],
            'username': user['username'],
            'role': role,
            'role_name': ROLE_PERMISSIONS[role]['name'],
            'permissions': ROLE_PERMISSIONS[role]['permissions'],
            'menus': ROLE_PERMISSIONS[role]['menus'],
            'readonly_fields': ROLE_PERMISSIONS[role]['readonly_fields']
        }
    })


@auth_bp.route('/roles', methods=['GET'])
def get_roles():
    """获取所有可用角色列表"""
    roles = []
    for role_key, role_info in ROLE_PERMISSIONS.items():
        roles.append({
            'key': role_key,
            'name': role_info['name'],
            'menus': role_info['menus']
        })
    return jsonify({'roles': roles})


@auth_bp.route('/logout', methods=['POST'])
def logout():
    """用户登出"""
    return jsonify({'message': '登出成功'})

