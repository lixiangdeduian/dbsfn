-- =========================
-- 例程：患者相关
-- =========================

-- 功能：创建患者档案，并生成唯一 patient_no，返回 patient_id/patient_no。
-- 适用：后端注册患者/建档；不涉及账号体系（user_account 由业务另行处理）。
DROP PROCEDURE IF EXISTS sp_patient_create$$
CREATE PROCEDURE sp_patient_create(
  IN p_patient_name VARCHAR(100),
  IN p_gender ENUM('M','F','U'),
  IN p_birth_date DATE,
  IN p_id_card_no VARCHAR(32),
  IN p_phone VARCHAR(32),
  IN p_address VARCHAR(300),
  IN p_emergency_contact_name VARCHAR(100),
  IN p_emergency_contact_phone VARCHAR(32),
  IN p_blood_type ENUM('A','B','AB','O','U'),
  IN p_allergy_history VARCHAR(500),
  OUT o_patient_id BIGINT UNSIGNED,
  OUT o_patient_no VARCHAR(32)
)
BEGIN
  DECLARE v_patient_no VARCHAR(32);

  IF p_patient_name IS NULL OR LENGTH(TRIM(p_patient_name)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient_name is required';
  END IF;

  SET v_patient_no = CONCAT('p_', UUID_SHORT());

  INSERT INTO patient (
    patient_no,
    patient_name,
    gender,
    birth_date,
    id_card_no,
    phone,
    address,
    emergency_contact_name,
    emergency_contact_phone,
    blood_type,
    allergy_history,
    is_active
  )
  VALUES (
    v_patient_no,
    p_patient_name,
    IFNULL(p_gender, 'U'),
    p_birth_date,
    p_id_card_no,
    p_phone,
    p_address,
    p_emergency_contact_name,
    p_emergency_contact_phone,
    IFNULL(p_blood_type, 'U'),
    p_allergy_history,
    1
  );

  SET o_patient_id = LAST_INSERT_ID();
  SET o_patient_no = v_patient_no;
END$$

-- 功能：更新患者联系信息（电话/地址/紧急联系人），仅修改传入的非 NULL 字段。
-- 适用：后端“更新患者资料”接口；避免整行覆盖导致并发丢字段。
DROP PROCEDURE IF EXISTS sp_patient_update_contact$$
CREATE PROCEDURE sp_patient_update_contact(
  IN p_patient_id BIGINT UNSIGNED,
  IN p_phone VARCHAR(32),
  IN p_address VARCHAR(300),
  IN p_emergency_contact_name VARCHAR(100),
  IN p_emergency_contact_phone VARCHAR(32)
)
BEGIN
  IF p_patient_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient_id is required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM patient p WHERE p.patient_id = p_patient_id AND p.is_active = 1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'patient not found or inactive';
  END IF;

  UPDATE patient p
  SET
    p.phone = COALESCE(p_phone, p.phone),
    p.address = COALESCE(p_address, p.address),
    p.emergency_contact_name = COALESCE(p_emergency_contact_name, p.emergency_contact_name),
    p.emergency_contact_phone = COALESCE(p_emergency_contact_phone, p.emergency_contact_phone)
  WHERE p.patient_id = p_patient_id;
END$$

