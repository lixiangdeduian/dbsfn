"""
简化的角色认证系统
不需要登录，通过请求头传递角色信息
"""
from functools import wraps
from flask import request, jsonify, g

def get_current_role():
    """从请求头获取当前角色"""
    return request.headers.get('X-Role', 'admin')

def require_role(*allowed_roles):
    """
    装饰器：要求特定角色才能访问
    用法：@require_role('admin', 'doctor')
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            current_role = get_current_role()
            
            # 如果没有指定允许的角色，则允许所有角色访问
            if not allowed_roles:
                g.current_role = current_role
                return f(*args, **kwargs)
            
            # 检查当前角色是否在允许的角色列表中
            if current_role not in allowed_roles:
                return jsonify({
                    'error': '权限不足',
                    'message': f'该功能需要以下角色之一：{", ".join(allowed_roles)}',
                    'current_role': current_role
                }), 403
            
            # 将当前角色存储到 g 对象中，供后续使用
            g.current_role = current_role
            return f(*args, **kwargs)
        
        return decorated_function
    return decorator

# 为了兼容性，保留旧的装饰器名称
def login_required(f):
    """兼容性装饰器：不需要登录，只是将角色信息存储到 g"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        g.current_role = get_current_role()
        return f(*args, **kwargs)
    return decorated_function

def role_required(roles):
    """兼容性装饰器：要求特定角色"""
    return require_role(*roles)
