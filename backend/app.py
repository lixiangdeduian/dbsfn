from flask import Flask, jsonify, request
from flask_cors import CORS
from config import Config
from models import db
from datetime import datetime, timedelta
import routes

def create_app():
    """创建并配置Flask应用"""
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # 初始化扩展
    db.init_app(app)
    CORS(app, origins=Config.CORS_ORIGINS)
    
    # 注册蓝图
    app.register_blueprint(routes.patient_bp, url_prefix='/api/patients')
    app.register_blueprint(routes.schedule_bp, url_prefix='/api/schedules')
    app.register_blueprint(routes.registration_bp, url_prefix='/api/registrations')
    app.register_blueprint(routes.encounter_bp, url_prefix='/api/encounters')
    app.register_blueprint(routes.invoice_bp, url_prefix='/api/invoices')
    app.register_blueprint(routes.payment_bp, url_prefix='/api/payments')
    app.register_blueprint(routes.staff_bp, url_prefix='/api/staff')
    app.register_blueprint(routes.department_bp, url_prefix='/api/departments')
    app.register_blueprint(routes.statistics_bp, url_prefix='/api/statistics')
    
    # 健康检查端点
    @app.route('/api/health', methods=['GET'])
    def health_check():
        """健康检查接口"""
        try:
            # 测试数据库连接
            db.session.execute(db.text('SELECT 1'))
            return jsonify({
                'status': 'healthy',
                'database': 'connected',
                'timestamp': datetime.utcnow().isoformat()
            })
        except Exception as e:
            return jsonify({
                'status': 'unhealthy',
                'database': 'disconnected',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }), 500
    
    # 错误处理
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)

