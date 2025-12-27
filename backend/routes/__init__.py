from .patient import patient_bp
from .schedule import schedule_bp
from .registration import registration_bp
from .encounter import encounter_bp
from .invoice import invoice_bp
from .payment import payment_bp
from .staff import staff_bp
from .department import department_bp
from .statistics import statistics_bp

__all__ = [
    'patient_bp',
    'schedule_bp',
    'registration_bp',
    'encounter_bp',
    'invoice_bp',
    'payment_bp',
    'staff_bp',
    'department_bp',
    'statistics_bp'
]

