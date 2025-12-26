## 大量初始化数据（seed.sql）

执行顺序（建议）：

```sql
mysql -u root -p < schema.sql
mysql -u root -p < triggers.sql
mysql -u root -p < seed.sql
mysql -u root -p < security.sql
```

说明：
- `seed.sql` 会 `TRUNCATE` 业务表并重新生成模拟数据（可重复执行）。
- 数据规模在 `seed.sql` 顶部参数区调整（如 `@patient_count`、`@reg_per_schedule` 等）。

