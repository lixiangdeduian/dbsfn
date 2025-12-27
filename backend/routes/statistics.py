from flask import Blueprint, request, jsonify
from models import db, Invoice, Payment, Registration, Encounter, Department, Staff
from sqlalchemy import func
from datetime import datetime, timedelta

statistics_bp = Blueprint('statistics', __name__)


@statistics_bp.route('/revenue', methods=['GET'])
def get_revenue_statistics():
    """获取收入统计"""
    try:
        # 获取查询参数
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        department_id = request.args.get('department_id', type=int)
        
        # 构建查询
        query = db.session.query(
            func.date(Payment.paid_at).label('date'),
            func.sum(Payment.amount).label('total_revenue'),
            func.count(Payment.payment_id).label('payment_count')
        ).filter(Payment.status == 'SUCCESS')
        
        if start_date:
            query = query.filter(Payment.paid_at >= datetime.fromisoformat(start_date))
        if end_date:
            query = query.filter(Payment.paid_at <= datetime.fromisoformat(end_date))
        
        # 如果指定科室，需要通过invoice->encounter->department关联
        if department_id:
            query = query.join(Invoice).join(Encounter).filter(
                Encounter.department_id == department_id
            )
        
        results = query.group_by(func.date(Payment.paid_at)).order_by(func.date(Payment.paid_at).desc()).all()
        
        return jsonify({
            'statistics': [{
                'date': str(r.date),
                'total_revenue': float(r.total_revenue),
                'payment_count': r.payment_count
            } for r in results]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@statistics_bp.route('/encounters', methods=['GET'])
def get_encounter_statistics():
    """获取就诊统计"""
    try:
        # 获取查询参数
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        department_id = request.args.get('department_id', type=int)
        doctor_id = request.args.get('doctor_id', type=int)
        
        # 构建查询
        query = db.session.query(
            func.date(Encounter.started_at).label('date'),
            func.count(Encounter.encounter_id).label('encounter_count')
        )
        
        if start_date:
            query = query.filter(Encounter.started_at >= datetime.fromisoformat(start_date))
        if end_date:
            query = query.filter(Encounter.started_at <= datetime.fromisoformat(end_date))
        if department_id:
            query = query.filter(Encounter.department_id == department_id)
        if doctor_id:
            query = query.filter(Encounter.doctor_id == doctor_id)
        
        results = query.group_by(func.date(Encounter.started_at)).order_by(func.date(Encounter.started_at).desc()).all()
        
        return jsonify({
            'statistics': [{
                'date': str(r.date),
                'encounter_count': r.encounter_count
            } for r in results]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@statistics_bp.route('/department-revenue', methods=['GET'])
def get_department_revenue():
    """获取各科室收入统计"""
    try:
        # 获取查询参数
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        # 构建查询
        query = db.session.query(
            Department.department_name,
            func.sum(Payment.amount).label('total_revenue'),
            func.count(distinct=Encounter.encounter_id).label('encounter_count')
        ).join(Encounter, Encounter.department_id == Department.department_id) \
         .join(Invoice, Invoice.encounter_id == Encounter.encounter_id) \
         .join(Payment, Payment.invoice_id == Invoice.invoice_id) \
         .filter(Payment.status == 'SUCCESS')
        
        if start_date:
            query = query.filter(Payment.paid_at >= datetime.fromisoformat(start_date))
        if end_date:
            query = query.filter(Payment.paid_at <= datetime.fromisoformat(end_date))
        
        results = query.group_by(Department.department_id, Department.department_name) \
                      .order_by(func.sum(Payment.amount).desc()).all()
        
        return jsonify({
            'statistics': [{
                'department_name': r.department_name,
                'total_revenue': float(r.total_revenue),
                'encounter_count': r.encounter_count
            } for r in results]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@statistics_bp.route('/doctor-workload', methods=['GET'])
def get_doctor_workload():
    """获取医生工作量统计"""
    try:
        # 获取查询参数
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        department_id = request.args.get('department_id', type=int)
        
        # 构建查询
        query = db.session.query(
            Staff.staff_name,
            Staff.title,
            Department.department_name,
            func.count(Encounter.encounter_id).label('encounter_count')
        ).join(Encounter, Encounter.doctor_id == Staff.staff_id) \
         .join(Department, Department.department_id == Encounter.department_id)
        
        if start_date:
            query = query.filter(Encounter.started_at >= datetime.fromisoformat(start_date))
        if end_date:
            query = query.filter(Encounter.started_at <= datetime.fromisoformat(end_date))
        if department_id:
            query = query.filter(Encounter.department_id == department_id)
        
        results = query.group_by(Staff.staff_id, Staff.staff_name, Staff.title, Department.department_name) \
                      .order_by(func.count(Encounter.encounter_id).desc()).all()
        
        return jsonify({
            'statistics': [{
                'doctor_name': r.staff_name,
                'title': r.title,
                'department_name': r.department_name,
                'encounter_count': r.encounter_count
            } for r in results]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@statistics_bp.route('/dashboard', methods=['GET'])
def get_dashboard_statistics():
    """获取仪表盘统计数据"""
    try:
        # 今日统计
        today = datetime.now().date()
        today_start = datetime.combine(today, datetime.min.time())
        today_end = datetime.combine(today, datetime.max.time())
        
        # 今日就诊人次
        today_encounters = Encounter.query.filter(
            Encounter.started_at >= today_start,
            Encounter.started_at <= today_end
        ).count()
        
        # 今日挂号数
        today_registrations = Registration.query.filter(
            Registration.registered_at >= today_start,
            Registration.registered_at <= today_end,
            Registration.status == 'CONFIRMED'
        ).count()
        
        # 今日收入
        today_revenue = db.session.query(func.sum(Payment.amount)).filter(
            Payment.paid_at >= today_start,
            Payment.paid_at <= today_end,
            Payment.status == 'SUCCESS'
        ).scalar() or 0
        
        # 待缴费发票数
        unpaid_invoices = Invoice.query.filter(
            Invoice.status.in_(['OPEN', 'PARTIALLY_PAID'])
        ).count()
        
        # 本月统计
        month_start = datetime(today.year, today.month, 1)
        month_encounters = Encounter.query.filter(
            Encounter.started_at >= month_start
        ).count()
        
        month_revenue = db.session.query(func.sum(Payment.amount)).filter(
            Payment.paid_at >= month_start,
            Payment.status == 'SUCCESS'
        ).scalar() or 0
        
        return jsonify({
            'today': {
                'encounters': today_encounters,
                'registrations': today_registrations,
                'revenue': float(today_revenue)
            },
            'month': {
                'encounters': month_encounters,
                'revenue': float(month_revenue)
            },
            'unpaid_invoices': unpaid_invoices
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

