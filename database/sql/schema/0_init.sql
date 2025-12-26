-- 医院管理系统（MySQL 9.x）- 数据库结构设计
-- 建议执行顺序：schema.sql -> triggers.sql -> security.sql

CREATE DATABASE IF NOT EXISTS hospital_test
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE hospital_test;

SET sql_safe_updates = 0;
SET time_zone = '+00:00';

