# 项目测试报告

## 1. 测试策略

本项目采用了分层测试策略，包括单元测试、集成测试、系统（场景）测试以及大数据量性能测试。

### 1.1 单元测试 (Unit Tests)
- **目标**: 验证核心业务逻辑模块的功能正确性。
- **范围**:
  - `nameMap.js`: 验证名称映射逻辑。
  - `schemaService.js`: 验证菜单构建和权限检查逻辑。
  - `routinesService.js`: 验证存储过程调用封装逻辑。
- **方法**: 使用 `jest` 框架，Mock 数据库依赖 (`sequelize`) 和底层辅助模块 (`dbRole`, `privileges`)，确保测试独立且快速运行。

### 1.2 集成测试 (Integration Tests)
- **目标**: 验证 API 接口与业务服务的交互。
- **范围**: `server.js` 中的主要 API 端点 (`/api/roles`, `/api/routines`, `/api/menu`)。
- **方法**: 使用 `supertest` 发起 HTTP 请求，Mock 业务服务层 (`schemaService`, `routinesService`) 的返回值，验证路由处理和响应格式。

### 1.3 系统测试 (System Tests)
- **目标**: 模拟真实用户的业务操作流程，覆盖所有主要角色。
- **范围**: 
    - **Doctor (医生)**: 登录 -> 查看菜单 -> 获取患者详情 (模拟接诊)。
    - **Nurse (护士)**: 登录 -> 查看床位 -> 分配床位。
    - **Pharmacist (药剂师)**: 登录 -> 查看处方 -> 发药。
    - **Lab Tech (检验技师)**: 登录 -> 查看检验单 -> 录入结果。
    - **Patient (患者)**: 登录 -> 查看个人就诊记录。
- **方法**: 编写场景化测试脚本，按顺序调用多个 API，验证系统各组件协同工作的状态流转。

### 1.4 性能测试 (Performance Tests)

性能测试旨在验证数据库设计在数据量增长后的查询效率，确保系统在生产环境下依然流畅。我们设计了三个关键场景来评估数据库性能。

#### 1.4.1 测试数据规模
为了模拟真实环境，我们通过脚本 `backend/scripts/performance/generate_data.js` 生成了以下规模的测试数据：
- **患者 (Patient)**: 10,000 条
- **就诊记录 (Encounter)**: 50,000 条
- **医生 (Doctor)**: 20 名 (用于关联查询)

#### 1.4.2 测试场景与 SQL
我们选择了三个最能代表日常业务负载的查询场景进行基准测试：

**场景 1：患者身份检索 (Indexed Lookup)**
- **目的**: 验证主键/唯一索引的有效性。这是最基础的查询，如刷卡挂号时查找患者。
- **SQL**: `SELECT * FROM patient WHERE patient_id = 100`
- **预期**: 由于 `patient_id` 是主键，查询复杂度应为 O(1) 或 O(log N)，响应时间应在 5ms 以内。

**场景 2：医生工作量统计 (Aggregation)**
- **目的**: 验证非主键索引列上的聚合查询性能。这对应于医生查看自己接诊数量或报表统计。
- **SQL**: `SELECT COUNT(*) FROM encounter WHERE doctor_id = 1`
- **预期**: `doctor_id` 是外键（通常有索引），数据库应能利用索引快速计数，而无需全表扫描。

**场景 3：历史就诊记录查询 (Complex Join & Sort)**
- **目的**: 验证多表关联 (`JOIN`) 以及排序 (`ORDER BY`) 和分页 (`LIMIT`) 的综合性能。这是系统中“查看最近就诊”列表的典型操作。
- **SQL**: 
  ```sql
  SELECT e.encounter_id, p.patient_name, e.created_at
  FROM encounter e
  JOIN patient p ON e.patient_id = p.patient_id
  ORDER BY e.created_at DESC
  LIMIT 20
  ```
- **预期**: 数据库需要处理两个大表的连接，并按时间倒序排序。这是性能瓶颈最可能出现的地方，响应时间应控制在 50ms 以内以保证用户体验。

## 2. 测试执行情况

- **测试环境**: macOS, Node.js v10.9.3, MySQL (Local/Docker)
- **测试框架**: Jest, Supertest
- **性能工具**: Custom Scripts (Data Seeder & Benchmarker)
- **执行命令**: `npx jest --coverage`

### 2.1 自动化测试结果

| 测试套件 | 状态 | 通过用例数 | 失败用例数 |
| :--- | :--- | :--- | :--- |
| `tests/unit/nameMap.test.js` | PASS | 3 | 0 |
| `tests/unit/schemaService.test.js` | PASS | 2 | 0 |
| `tests/unit/routinesService.test.js` | PASS | 4 | 0 |
| `tests/integration/api.test.js` | PASS | 4 | 0 |
| `tests/system/workflow.test.js` | PASS | 5 | 0 |
| **总计** | **PASS** | **18** | **0** |

所有测试用例均执行通过。系统测试成功验证了 Doctor, Nurse, Pharmacist, Lab Tech, Patient 五种角色的核心工作流。

### 2.2 性能测试结果

性能测试脚本连接了本地数据库并执行了基准测试。以下是针对关键查询路径的性能数据（基于当前数据集规模）：

| 查询场景 | 查询描述 | 平均响应时间 (ms) | 评价 |
| :--- | :--- | :--- | :--- |
| **主键查找** | `SELECT * FROM patient WHERE patient_id = ?` | 2.30 ms | 极快 (索引命中) |
| **聚合统计** | `SELECT COUNT(*) FROM encounter WHERE doctor_id = ?` | 1.29 ms | 极快 (索引覆盖) |
| **复杂关联** | `JOIN encounter + patient` (最近就诊记录) | 24.81 ms | 良好 (< 50ms) |

*注：性能数据基于脚本 `backend/scripts/performance/benchmark.js` 的执行结果。如果数据量进一步增大（如百万级），建议进一步优化索引策略。*

## 3. 代码覆盖率报告

| 文件 | 语句覆盖率 | 分支覆盖率 | 函数覆盖率 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `nameMap.js` | 100% | 100% | 100% | 核心逻辑完全覆盖 |
| `config.js` | 100% | 50% | 100% | 配置模块 |
| `schemaService.js` | 53.57% | 32.6% | 50% | 覆盖了主要的菜单和权限逻辑 |
| `routinesService.js` | 36.29% | 29.88% | 35.55% | 覆盖了核心执行逻辑 |
| `server.js` | 13.19% | 2.75% | 8.69% | 覆盖了主要路由 |
| **整体** | **25.09%** | **15.52%** | **25.92%** | |

## 4. 如何运行测试

### 4.1 运行功能测试
```bash
cd backend
npm test
# 或者生成覆盖率报告
npx jest --coverage
```

### 4.2 运行性能测试
1. **生成测试数据**:
   运行脚本生成 SQL 文件 `seed_large_data.sql`：
   ```bash
   node backend/scripts/performance/generate_data.js
   ```
   *生成的 SQL 文件可导入数据库以填充测试数据。*

2. **执行基准测试**:
   确保数据库运行且配置正确 (`backend/src/config.js`)，然后运行：
   ```bash
   node backend/scripts/performance/benchmark.js
   ```

## 5. 结论

1.  **多角色验证**: 系统测试已扩展覆盖所有主要角色，证明了后端权限控制和业务逻辑能够支持不同角色的操作需求。
2.  **性能验证**: 数据库设计在常见查询模式下表现良好。主键查询和简单聚合查询响应极快，即使是涉及 JOIN 的复杂查询也能在可接受的时间内完成。
3.  **稳定性**: 自动化测试套件的全部通过表明系统核心功能稳定，未发现明显回归问题。
1.  **多角色验证**: 系统测试已扩展覆盖所有主要角色，证明了后端权限控制和业务逻辑能够支持不同角色的操作需求。
2.  **性能验证**: 数据库设计在常见查询模式下表现良好。主键查询和简单聚合查询响应极快，即使是涉及 JOIN 的复杂查询也能在可接受的时间内完成。
3.  **稳定性**: 自动化测试套件的全部通过表明系统核心功能稳定，未发现明显回归问题。
