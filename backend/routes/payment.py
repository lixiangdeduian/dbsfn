from flask import Blueprint, request, jsonify
from models import db, Payment, Invoice
from datetime import datetime
import random

payment_bp = Blueprint('payment', __name__)


@payment_bp.route('/', methods=['GET'])
def get_payments():
    """获取支付记录列表"""
    try:
        # 获取查询参数
        invoice_id = request.args.get('invoice_id', type=int)
        status = request.args.get('status')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # 构建查询
        query = Payment.query
        
        if invoice_id:
            query = query.filter_by(invoice_id=invoice_id)
        if status:
            query = query.filter_by(status=status)
        
        # 分页
        pagination = query.order_by(Payment.paid_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'payments': [p.to_dict() for p in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/<int:payment_id>', methods=['GET'])
def get_payment(payment_id):
    """获取支付详情"""
    try:
        payment = Payment.query.get_or_404(payment_id)
        return jsonify(payment.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/', methods=['POST'])
def create_payment():
    """创建支付记录（缴费）"""
    try:
        data = request.get_json()
        
        # 验证发票是否存在
        invoice = Invoice.query.get(data['invoice_id'])
        if not invoice:
            return jsonify({'error': '发票不存在'}), 404
        
        if invoice.status == 'VOID':
            return jsonify({'error': '发票已作废'}), 400
        
        if invoice.status == 'PAID':
            return jsonify({'error': '发票已付清'}), 400
        
        # 计算剩余金额
        remaining = float(invoice.total_amount) - float(invoice.paid_amount)
        payment_amount = float(data['amount'])
        
        if payment_amount > remaining:
            return jsonify({'error': f'支付金额超过剩余金额 {remaining:.2f}'}), 400
        
        # 生成支付单号
        payment_no = f"PAY{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"
        
        payment = Payment(
            payment_no=payment_no,
            invoice_id=data['invoice_id'],
            method=data.get('method', 'CASH'),
            amount=payment_amount,
            transaction_ref=data.get('transaction_ref'),
            status='SUCCESS'
        )
        
        db.session.add(payment)
        
        # 更新发票状态
        invoice.paid_amount = float(invoice.paid_amount) + payment_amount
        if invoice.paid_amount >= invoice.total_amount:
            invoice.status = 'PAID'
        elif invoice.paid_amount > 0:
            invoice.status = 'PARTIALLY_PAID'
        
        db.session.commit()
        
        return jsonify(payment.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@payment_bp.route('/<int:payment_id>/cancel', methods=['POST'])
def cancel_payment(payment_id):
    """取消支付"""
    try:
        payment = Payment.query.get_or_404(payment_id)
        
        if payment.status != 'SUCCESS':
            return jsonify({'error': '该支付无法取消'}), 400
        
        payment.status = 'CANCELLED'
        
        # 更新发票已付金额和状态
        invoice = Invoice.query.get(payment.invoice_id)
        invoice.paid_amount = float(invoice.paid_amount) - float(payment.amount)
        
        if invoice.paid_amount <= 0:
            invoice.status = 'OPEN'
            invoice.paid_amount = 0
        elif invoice.paid_amount < invoice.total_amount:
            invoice.status = 'PARTIALLY_PAID'
        
        db.session.commit()
        
        return jsonify(payment.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

