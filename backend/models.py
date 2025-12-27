from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
from sqlalchemy import text

db = SQLAlchemy()

class Department(db.Model):
    """部门/科室表"""
    __tablename__ = 'department'
    
    department_id = db.Column(db.BigInteger, primary_key=True)
    department_code = db.Column(db.String(32), unique=True, nullable=False)
    department_name = db.Column(db.String(100), nullable=False)
    parent_department_id = db.Column(db.BigInteger, db.ForeignKey('department.department_id'))
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'department_id': self.department_id,
            'department_code': self.department_code,
            'department_name': self.department_name,
            'parent_department_id': self.parent_department_id,
            'is_active': self.is_active
        }


class Staff(db.Model):
    """员工/医护人员表"""
    __tablename__ = 'staff'
    
    staff_id = db.Column(db.BigInteger, primary_key=True)
    staff_no = db.Column(db.String(32), unique=True, nullable=False)
    staff_name = db.Column(db.String(100), nullable=False)
    gender = db.Column(db.Enum('M', 'F', 'U'), default='U', nullable=False)
    phone = db.Column(db.String(32))
    email = db.Column(db.String(200))
    id_card_no = db.Column(db.String(32), unique=True)
    title = db.Column(db.String(50))
    hire_date = db.Column(db.Date)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'staff_id': self.staff_id,
            'staff_no': self.staff_no,
            'staff_name': self.staff_name,
            'gender': self.gender,
            'phone': self.phone,
            'email': self.email,
            'id_card_no': self.id_card_no,
            'title': self.title,
            'hire_date': self.hire_date.isoformat() if self.hire_date else None,
            'is_active': self.is_active
        }


class Patient(db.Model):
    """患者信息表"""
    __tablename__ = 'patient'
    
    patient_id = db.Column(db.BigInteger, primary_key=True)
    patient_no = db.Column(db.String(32), unique=True, nullable=False)
    patient_name = db.Column(db.String(100), nullable=False)
    gender = db.Column(db.Enum('M', 'F', 'U'), default='U', nullable=False)
    birth_date = db.Column(db.Date)
    id_card_no = db.Column(db.String(32), unique=True)
    phone = db.Column(db.String(32))
    address = db.Column(db.String(300))
    emergency_contact_name = db.Column(db.String(100))
    emergency_contact_phone = db.Column(db.String(32))
    blood_type = db.Column(db.Enum('A', 'B', 'AB', 'O', 'U'), default='U', nullable=False)
    allergy_history = db.Column(db.String(500))
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'patient_id': self.patient_id,
            'patient_no': self.patient_no,
            'patient_name': self.patient_name,
            'gender': self.gender,
            'birth_date': self.birth_date.isoformat() if self.birth_date else None,
            'id_card_no': self.id_card_no,
            'phone': self.phone,
            'address': self.address,
            'emergency_contact_name': self.emergency_contact_name,
            'emergency_contact_phone': self.emergency_contact_phone,
            'blood_type': self.blood_type,
            'allergy_history': self.allergy_history,
            'is_active': self.is_active
        }


class DoctorSchedule(db.Model):
    """医生排班表"""
    __tablename__ = 'doctor_schedule'
    
    schedule_id = db.Column(db.BigInteger, primary_key=True)
    doctor_id = db.Column(db.BigInteger, db.ForeignKey('staff.staff_id'), nullable=False)
    department_id = db.Column(db.BigInteger, db.ForeignKey('department.department_id'), nullable=False)
    schedule_date = db.Column(db.Date, nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    quota = db.Column(db.Integer, nullable=False)
    registration_fee = db.Column(db.Numeric(10, 2), default=0.00, nullable=False)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    doctor = db.relationship('Staff', backref='schedules')
    department = db.relationship('Department', backref='schedules')
    
    def to_dict(self):
        return {
            'schedule_id': self.schedule_id,
            'doctor_id': self.doctor_id,
            'doctor_name': self.doctor.staff_name if self.doctor else None,
            'doctor_title': self.doctor.title if self.doctor else None,
            'department_id': self.department_id,
            'department_name': self.department.department_name if self.department else None,
            'schedule_date': self.schedule_date.isoformat() if self.schedule_date else None,
            'start_time': str(self.start_time) if self.start_time else None,
            'end_time': str(self.end_time) if self.end_time else None,
            'quota': self.quota,
            'registration_fee': float(self.registration_fee),
            'is_active': self.is_active
        }


class Registration(db.Model):
    """门诊挂号表"""
    __tablename__ = 'registration'
    
    registration_id = db.Column(db.BigInteger, primary_key=True)
    registration_no = db.Column(db.String(40), unique=True, nullable=False)
    patient_id = db.Column(db.BigInteger, db.ForeignKey('patient.patient_id'), nullable=False)
    schedule_id = db.Column(db.BigInteger, db.ForeignKey('doctor_schedule.schedule_id'), nullable=False)
    registered_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    status = db.Column(db.Enum('CONFIRMED', 'CANCELLED', 'COMPLETED'), default='CONFIRMED', nullable=False)
    chief_complaint = db.Column(db.String(500))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    patient = db.relationship('Patient', backref='registrations')
    schedule = db.relationship('DoctorSchedule', backref='registrations')
    
    def to_dict(self):
        return {
            'registration_id': self.registration_id,
            'registration_no': self.registration_no,
            'patient_id': self.patient_id,
            'patient_name': self.patient.patient_name if self.patient else None,
            'patient_phone': self.patient.phone if self.patient else None,
            'schedule_id': self.schedule_id,
            'doctor_name': self.schedule.doctor.staff_name if self.schedule and self.schedule.doctor else None,
            'department_name': self.schedule.department.department_name if self.schedule and self.schedule.department else None,
            'schedule_date': self.schedule.schedule_date.isoformat() if self.schedule and self.schedule.schedule_date else None,
            'start_time': str(self.schedule.start_time) if self.schedule and self.schedule.start_time else None,
            'registered_at': self.registered_at.isoformat() if self.registered_at else None,
            'status': self.status,
            'chief_complaint': self.chief_complaint
        }


class Encounter(db.Model):
    """就诊记录表"""
    __tablename__ = 'encounter'
    
    encounter_id = db.Column(db.BigInteger, primary_key=True)
    encounter_no = db.Column(db.String(40), unique=True, nullable=False)
    patient_id = db.Column(db.BigInteger, db.ForeignKey('patient.patient_id'), nullable=False)
    department_id = db.Column(db.BigInteger, db.ForeignKey('department.department_id'), nullable=False)
    doctor_id = db.Column(db.BigInteger, db.ForeignKey('staff.staff_id'), nullable=False)
    registration_id = db.Column(db.BigInteger, db.ForeignKey('registration.registration_id'))
    encounter_type = db.Column(db.Enum('OUTPATIENT', 'INPATIENT'), default='OUTPATIENT', nullable=False)
    started_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    ended_at = db.Column(db.DateTime)
    status = db.Column(db.Enum('OPEN', 'CLOSED', 'CANCELLED'), default='OPEN', nullable=False)
    note = db.Column(db.String(1000))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    patient = db.relationship('Patient', backref='encounters')
    department = db.relationship('Department', backref='encounters')
    doctor = db.relationship('Staff', backref='encounters')
    registration = db.relationship('Registration', backref='encounter', uselist=False)
    
    def to_dict(self):
        return {
            'encounter_id': self.encounter_id,
            'encounter_no': self.encounter_no,
            'patient_id': self.patient_id,
            'patient_name': self.patient.patient_name if self.patient else None,
            'department_id': self.department_id,
            'department_name': self.department.department_name if self.department else None,
            'doctor_id': self.doctor_id,
            'doctor_name': self.doctor.staff_name if self.doctor else None,
            'registration_id': self.registration_id,
            'encounter_type': self.encounter_type,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'ended_at': self.ended_at.isoformat() if self.ended_at else None,
            'status': self.status,
            'note': self.note
        }


class Invoice(db.Model):
    """发票表"""
    __tablename__ = 'invoice'
    
    invoice_id = db.Column(db.BigInteger, primary_key=True)
    invoice_no = db.Column(db.String(40), unique=True, nullable=False)
    patient_id = db.Column(db.BigInteger, db.ForeignKey('patient.patient_id'), nullable=False)
    encounter_id = db.Column(db.BigInteger, db.ForeignKey('encounter.encounter_id'))
    issued_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    status = db.Column(db.Enum('OPEN', 'PARTIALLY_PAID', 'PAID', 'VOID'), default='OPEN', nullable=False)
    total_amount = db.Column(db.Numeric(12, 2), default=0.00, nullable=False)
    paid_amount = db.Column(db.Numeric(12, 2), default=0.00, nullable=False)
    note = db.Column(db.String(500))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    patient = db.relationship('Patient', backref='invoices')
    encounter = db.relationship('Encounter', backref='invoices')
    
    def to_dict(self):
        return {
            'invoice_id': self.invoice_id,
            'invoice_no': self.invoice_no,
            'patient_id': self.patient_id,
            'patient_name': self.patient.patient_name if self.patient else None,
            'encounter_id': self.encounter_id,
            'issued_at': self.issued_at.isoformat() if self.issued_at else None,
            'status': self.status,
            'total_amount': float(self.total_amount),
            'paid_amount': float(self.paid_amount),
            'remaining_amount': float(self.total_amount - self.paid_amount),
            'note': self.note
        }


class Payment(db.Model):
    """支付记录表"""
    __tablename__ = 'payment'
    
    payment_id = db.Column(db.BigInteger, primary_key=True)
    payment_no = db.Column(db.String(40), unique=True, nullable=False)
    invoice_id = db.Column(db.BigInteger, db.ForeignKey('invoice.invoice_id'), nullable=False)
    method = db.Column(db.Enum('CASH', 'CARD', 'WECHAT', 'ALIPAY', 'TRANSFER', 'OTHER'), default='CASH', nullable=False)
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    paid_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    status = db.Column(db.Enum('SUCCESS', 'FAILED', 'CANCELLED'), default='SUCCESS', nullable=False)
    transaction_ref = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    invoice = db.relationship('Invoice', backref='payments')
    
    def to_dict(self):
        return {
            'payment_id': self.payment_id,
            'payment_no': self.payment_no,
            'invoice_id': self.invoice_id,
            'method': self.method,
            'amount': float(self.amount),
            'paid_at': self.paid_at.isoformat() if self.paid_at else None,
            'status': self.status,
            'transaction_ref': self.transaction_ref
        }


class ChargeCatalog(db.Model):
    """收费项目目录表"""
    __tablename__ = 'charge_catalog'
    
    charge_item_id = db.Column(db.BigInteger, primary_key=True)
    item_code = db.Column(db.String(32), unique=True, nullable=False)
    item_name = db.Column(db.String(200), nullable=False)
    category = db.Column(db.String(100))
    unit = db.Column(db.String(20))
    unit_price = db.Column(db.Numeric(10, 2), default=0.00, nullable=False)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'charge_item_id': self.charge_item_id,
            'item_code': self.item_code,
            'item_name': self.item_name,
            'category': self.category,
            'unit': self.unit,
            'unit_price': float(self.unit_price),
            'is_active': self.is_active
        }


class InvoiceLine(db.Model):
    """发票与费用关联明细表"""
    __tablename__ = 'invoice_line'
    
    invoice_line_id = db.Column(db.BigInteger, primary_key=True)
    invoice_id = db.Column(db.BigInteger, db.ForeignKey('invoice.invoice_id'), nullable=False)
    charge_id = db.Column(db.BigInteger, db.ForeignKey('charge.charge_id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Charge(db.Model):
    """费用明细表"""
    __tablename__ = 'charge'
    
    charge_id = db.Column(db.BigInteger, primary_key=True)
    charge_no = db.Column(db.String(40), unique=True, nullable=False)
    encounter_id = db.Column(db.BigInteger, db.ForeignKey('encounter.encounter_id'), nullable=False)
    source_type = db.Column(db.Enum('REGISTRATION', 'PRESCRIPTION', 'LAB', 'MANUAL'), default='MANUAL', nullable=False)
    source_id = db.Column(db.BigInteger)
    charge_item_id = db.Column(db.BigInteger, db.ForeignKey('charge_catalog.charge_item_id'), nullable=False)
    quantity = db.Column(db.Numeric(12, 2), default=1.00, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2))
    amount = db.Column(db.Numeric(12, 2), default=0.00, nullable=False)
    charged_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    status = db.Column(db.Enum('UNBILLED', 'BILLED', 'CANCELLED'), default='UNBILLED', nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 关系
    encounter = db.relationship('Encounter', backref='charges')
    charge_item = db.relationship('ChargeCatalog', backref='charges')
    
    def to_dict(self):
        return {
            'charge_id': self.charge_id,
            'charge_no': self.charge_no,
            'encounter_id': self.encounter_id,
            'source_type': self.source_type,
            'charge_item_id': self.charge_item_id,
            'item_name': self.charge_item.item_name if self.charge_item else None,
            'quantity': float(self.quantity),
            'unit_price': float(self.unit_price) if self.unit_price else 0.0,
            'amount': float(self.amount),
            'charged_at': self.charged_at.isoformat() if self.charged_at else None,
            'status': self.status
        }

