"""
角色切换路由
"""
from flask import Blueprint, request, jsonify

auth_bp = Blueprint('auth', __name__)

# 角色配置（与数据库 role_* 对应）
ROLES = {
    'admin': {
        'name': '超级管理员',
        'db_user': 'admin_user',
        'color': '#f50'
    },
    'doctor': {
        'name': '医生',
        'db_user': 'doctor_user',
        'color': '#2db7f5'
    },
    'nurse': {
        'name': '护士',
        'db_user': 'nurse_user',
        'color': '#87d068'
    },
    'pharmacist': {
        'name': '药剂师',
        'db_user': 'pharmacist_user',
        'color': '#108ee9'
    },
    'lab_tech': {
        'name': '检验技师',
        'db_user': 'lab_tech_user',
        'color': '#722ed1'
    },
    'cashier': {
        'name': '收费员',
        'db_user': 'cashier_user',
        'color': '#eb2f96'
    },
    'reception': {
        'name': '前台接待',
        'db_user': 'reception_user',
        'color': '#13c2c2'
    },
    'patient': {
        'name': '患者',
        'db_user': 'patient_user',
        'color': '#52c41a'
    }
}

@auth_bp.route('/roles', methods=['GET'])
def get_roles():
    """获取所有可用角色列表"""
    return jsonify({
        'success': True,
        'data': [
            {
                'key': key,
                'name': info['name'],
                'color': info['color'],
                'db_user': info['db_user']
            }
            for key, info in ROLES.items()
        ]
    })

@auth_bp.route('/switch-role', methods=['POST'])
def switch_role():
    """
    切换角色
    请求体：{ "role": "admin" }
    """
    data = request.get_json()
    role = data.get('role', 'admin')
    
    if role not in ROLES:
        return jsonify({
            'success': False,
            'error': '无效的角色'
        }), 400
    
    role_info = ROLES[role]
    
    return jsonify({
        'success': True,
        'data': {
            'role': role,
            'role_name': role_info['name'],
            'db_user': role_info['db_user'],
            'color': role_info['color']
        }
    })

@auth_bp.route('/current', methods=['GET'])
def get_current_role():
    """获取当前角色信息"""
    current_role = request.headers.get('X-Role', 'admin')
    
    if current_role not in ROLES:
        current_role = 'admin'
    
    role_info = ROLES[current_role]
    
    return jsonify({
        'success': True,
        'data': {
            'role': current_role,
            'role_name': role_info['name'],
            'db_user': role_info['db_user'],
            'color': role_info['color']
        }
    })
