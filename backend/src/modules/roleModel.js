// src/modules/roleModel.js
import { pool } from "../config/db.js";

const Role = {
  // ➕ إنشاء دور جديد
  async createRole(name, description) {
    const result = await pool.query(
      "INSERT INTO roles (name, description) VALUES ($1, $2) RETURNING id, name, description",
      [name, description]
    );
    return result.rows[0];
  },

  // 📄 جلب كل الأدوار
  async getAllRoles() {
    const result = await pool.query(
      "SELECT id, name, description FROM roles ORDER BY id ASC"
    );
    return result.rows;
  },

  // 📌 جلب دور واحد
  async getRoleById(id) {
    const result = await pool.query(
      "SELECT id, name, description FROM roles WHERE id = $1",
      [id]
    );
    return result.rows[0];
  },

  // ✏️ تحديث دور
  async updateRole(id, name, description) {
    const result = await pool.query(
      "UPDATE roles SET name = $1, description = $2 WHERE id = $3 RETURNING id, name, description",
      [name, description, id]
    );
    return result.rows[0];
  },

  // 🗑 حذف دور
  async deleteRole(id) {
    const result = await pool.query(
      "DELETE FROM roles WHERE id = $1 RETURNING id, name, description",
      [id]
    );
    return result.rows[0];
  },

  // 🔗 جلب IDs الصلاحيات المرتبطة بدور معيّن
  async getRolePermissionIds(roleId) {
    const result = await pool.query(
      "SELECT permission_id FROM role_permissions WHERE role_id = $1",
      [roleId]
    );
    return result.rows.map((r) => r.permission_id);
  },

  // 🔗 تحديث صلاحيات الدور (يحذف القديمة ويضيف الجديدة داخل ترانزاكشن)
  async setRolePermissions(roleId, permissionIds = []) {
    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      // حذف كل الصلاحيات القديمة
      await client.query(
        "DELETE FROM role_permissions WHERE role_id = $1",
        [roleId]
      );

      // إضافة الجديدة (لو فيه)
      for (const permId of permissionIds) {
        await client.query(
          "INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)",
          [roleId, permId]
        );
      }

      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  },
};

export default Role;
