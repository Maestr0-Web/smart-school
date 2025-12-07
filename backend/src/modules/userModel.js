// src/modules/userModel.js
import { pool } from "../config/db.js";

const UserModel = {
  // ✅ إنشاء مستخدم جديد
  async create({ name, username, email, phone, password }) {
    const result = await pool.query(
      `
      INSERT INTO users (name, username, email, phone, password)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING 
        id, name, username, email, phone, status, created_at, token_version
      `,
      [name, username, email, phone, password]
    );
    return result.rows[0];
  },

  // ✅ جلب مستخدم بواسطة الإيميل (مع اسم الدور + token_version + password)
  async getByEmail(email) {
    const query = `
      SELECT 
        u.id,
        u.name,
        u.username,
        u.email,
        u.phone,
        u.password,
        u.status,
        u.created_at,
        u.token_version,          -- 👈 لتسجيل الخروج الإجباري
        r.id   AS role_id,
        r.name AS role_name
      FROM users u
      LEFT JOIN user_roles ur ON u.id = ur.user_id
      LEFT JOIN roles r       ON ur.role_id = r.id
      WHERE u.email = $1
      LIMIT 1
    `;

    const result = await pool.query(query, [email]);
    return result.rows[0] || null;
  },

  // ✅ جلب كل المستخدمين (مع الدور)
  async getAll() {
    const result = await pool.query(
      `
      SELECT 
        u.id,
        u.name,
        u.username,
        u.email,
        u.phone,
        u.status,
        u.created_at,
        r.id   AS role_id,
        r.name AS role_name
      FROM users u
      LEFT JOIN user_roles ur ON u.id = ur.user_id
      LEFT JOIN roles r       ON ur.role_id = r.id
      ORDER BY u.id ASC
      `
    );
    return result.rows;
  },

  // ✅ جلب مستخدم بواسطة ID (مع الدور + token_version + password)
  async getById(id) {
    const result = await pool.query(
      `
      SELECT 
        u.id,
        u.name,
        u.username,
        u.email,
        u.phone,
        u.password,              -- 👈 مهم لتغيير كلمة المرور
        u.status,
        u.created_at,
        u.token_version,
        r.id   AS role_id,
        r.name AS role_name
      FROM users u
      LEFT JOIN user_roles ur ON u.id = ur.user_id
      LEFT JOIN roles r       ON ur.role_id = r.id
      WHERE u.id = $1
      LIMIT 1
      `,
      [id]
    );
    return result.rows[0] || null;
  },

  // ✅ تحديث مستخدم (ديناميكي) — بدون password أو token_version
  async update(id, data) {
    const fields = [];
    const values = [];
    let index = 1;

    for (const key in data) {
      if (key === "password" || key === "token_version") continue;
      fields.push(`${key} = $${index}`);
      values.push(data[key]);
      index++;
    }

    if (fields.length === 0) return null;

    values.push(id);

    const result = await pool.query(
      `
      UPDATE users
      SET ${fields.join(", ")}, updated_at = NOW()
      WHERE id = $${index}
      RETURNING 
        id, name, username, email, phone, status, updated_at, token_version
      `,
      values
    );

    return result.rows[0];
  },

  // ✅ تحديث كلمة المرور فقط
  async updatePassword(id, hashedPassword) {
    await pool.query(
      `
      UPDATE users
      SET password = $1, updated_at = NOW()
      WHERE id = $2
      `,
      [hashedPassword, id]
    );
    return true;
  },

  // ✅ تحديث البريد الإلكتروني فقط (وترجيع بيانات أساسية)
  async updateEmail(id, newEmail) {
    const result = await pool.query(
      `
      UPDATE users
      SET email = $1, updated_at = NOW()
      WHERE id = $2
      RETURNING 
        id, name, username, email, phone, status, updated_at, token_version
      `,
      [newEmail, id]
    );
    return result.rows[0];
  },

  // ✅ حذف مستخدم
  async delete(id) {
    await pool.query(
      `DELETE FROM users WHERE id = $1`,
      [id]
    );
    return true;
  },
};

export default UserModel;
