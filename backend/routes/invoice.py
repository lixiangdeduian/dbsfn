from flask import Blueprint, request, jsonify
from models import db, Invoice, InvoiceLine, Charge, Patient, Encounter
from datetime import datetime
import random

invoice_bp = Blueprint('invoice', __name__)


@invoice_bp.route('/', methods=['GET'])
def get_invoices():
    """获取发票列表"""
    try:
        # 获取查询参数
        patient_id = request.args.get('patient_id', type=int)
        encounter_id = request.args.get('encounter_id', type=int)
        status = request.args.get('status')
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        
        # 构建查询
        query = Invoice.query
        
        if patient_id:
            query = query.filter_by(patient_id=patient_id)
        if encounter_id:
            query = query.filter_by(encounter_id=encounter_id)
        if status:
            query = query.filter_by(status=status)
        
        # 分页
        pagination = query.order_by(Invoice.issued_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'invoices': [inv.to_dict() for inv in pagination.items],
            'total': pagination.total,
            'page': page,
            'per_page': per_page,
            'pages': pagination.pages
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@invoice_bp.route('/<int:invoice_id>', methods=['GET'])
def get_invoice(invoice_id):
    """获取发票详情"""
    try:
        invoice = Invoice.query.get_or_404(invoice_id)
        invoice_dict = invoice.to_dict()
        
        # 获取发票明细
        lines = InvoiceLine.query.filter_by(invoice_id=invoice_id).all()
        charges = []
        for line in lines:
            charge = Charge.query.get(line.charge_id)
            if charge:
                charges.append(charge.to_dict())
        
        invoice_dict['charges'] = charges
        
        return jsonify(invoice_dict)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@invoice_bp.route('/', methods=['POST'])
def create_invoice():
    """创建发票（生成账单）"""
    try:
        data = request.get_json()
        
        # 验证患者是否存在
        patient = Patient.query.get(data['patient_id'])
        if not patient:
            return jsonify({'error': '患者不存在'}), 404
        
        # 如果有就诊ID，验证就诊是否存在
        encounter_id = data.get('encounter_id')
        if encounter_id:
            encounter = Encounter.query.get(encounter_id)
            if not encounter:
                return jsonify({'error': '就诊记录不存在'}), 404
        
        # 生成发票号
        invoice_no = f"INV{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(100, 999)}"
        
        # 获取费用明细
        charge_ids = data.get('charge_ids', [])
        total_amount = 0
        
        if charge_ids:
            charges = Charge.query.filter(Charge.charge_id.in_(charge_ids)).all()
            for charge in charges:
                if charge.status != 'UNBILLED':
                    return jsonify({'error': f'费用 {charge.charge_no} 状态不正确'}), 400
                total_amount += float(charge.amount)
        else:
            # 如果没有指定费用，使用手动输入的金额
            total_amount = float(data.get('total_amount', 0))
        
        # 创建发票
        invoice = Invoice(
            invoice_no=invoice_no,
            patient_id=data['patient_id'],
            encounter_id=encounter_id,
            total_amount=total_amount,
            note=data.get('note'),
            status='OPEN'
        )
        
        db.session.add(invoice)
        db.session.flush()  # 获取invoice_id
        
        # 创建发票明细并更新费用状态
        for charge_id in charge_ids:
            line = InvoiceLine(
                invoice_id=invoice.invoice_id,
                charge_id=charge_id
            )
            db.session.add(line)
            
            # 更新费用状态
            charge = Charge.query.get(charge_id)
            charge.status = 'BILLED'
        
        db.session.commit()
        
        return jsonify(invoice.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@invoice_bp.route('/<int:invoice_id>/void', methods=['POST'])
def void_invoice(invoice_id):
    """作废发票"""
    try:
        invoice = Invoice.query.get_or_404(invoice_id)
        
        if invoice.status == 'PAID':
            return jsonify({'error': '已支付的发票无法作废'}), 400
        
        invoice.status = 'VOID'
        
        # 将关联的费用状态改回未开票
        lines = InvoiceLine.query.filter_by(invoice_id=invoice_id).all()
        for line in lines:
            charge = Charge.query.get(line.charge_id)
            if charge:
                charge.status = 'UNBILLED'
        
        db.session.commit()
        
        return jsonify(invoice.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@invoice_bp.route('/encounter/<int:encounter_id>/unbilled-charges', methods=['GET'])
def get_unbilled_charges(encounter_id):
    """获取就诊未开票的费用"""
    try:
        charges = Charge.query.filter_by(
            encounter_id=encounter_id,
            status='UNBILLED'
        ).all()
        
        return jsonify({
            'charges': [c.to_dict() for c in charges],
            'total': len(charges)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

