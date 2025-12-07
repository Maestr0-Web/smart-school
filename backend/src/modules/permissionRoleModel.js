// src/modules/permissionRoleModel.js
import { pool } from "../config/db.js";

class PermissionRoleModel {
  // ربط صلاحية بدور معيّن
  static async assign(role_id, permission_id) {
    const result = await pool.query(
      `INSERT INTO role_permissions (role_id, permission_id)
       VALUES ($1, $2)
       RETURNING *`,
      [role_id, permission_id]
    );
    return result.rows[0];
  }

  // جميع العلاقات
  static async getAll() {
    const result = await pool.query(
      `SELECT * FROM role_permissions ORDER BY id ASC`
    );
    return result.rows;
  }

  // جميع العلاقات لدور معيّن
  static async getByRole(role_id) {
    const result = await pool.query(
      `SELECT * FROM role_permissions WHERE role_id = $1`,
      [role_id]
    );
    return result.rows;
  }

  // حذف علاقة
  static async delete(id) {
    const result = await pool.query(
      `DELETE FROM role_permissions WHERE id = $1
       RETURNING *`,
      [id]
    );
    return result.rows[0];
  }

  /**
   * ✅ هل الدور يملك صلاحية معيّنة (بالكود مثل "rbac.manage_users")؟
   */
  static async roleHasPermission(roleId, permissionCode) {
    const result = await pool.query(
      `
      SELECT 1
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = $1
        AND p.code     = $2
      LIMIT 1
      `,
      [roleId, permissionCode]
    );

    return result.rows.length > 0;
  }

  /**
   * ✅ هل الدور يملك "أي" صلاحية من مجموعة أكواد؟
   */
  static async roleHasAnyPermission(roleId, codes = []) {
    if (!codes || codes.length === 0) return false;

    const result = await pool.query(
      `
      SELECT 1
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = $1
        AND p.code = ANY($2::text[])
      LIMIT 1
      `,
      [roleId, codes]
    );

    return result.rows.length > 0;
  }

  /**
   * ✅ تجيب كل أكواد الصلاحيات لدور معيّن (للـ توكن / الـ middleware)
   * ترجع Array مثل:
   * ["rbac.manage_users", "admission.view_students", ...]
   */
  static async getPermissionCodesForRole(roleId) {
    const result = await pool.query(
      `
      SELECT p.code
      FROM role_permissions rp
      JOIN permissions p ON p.id = rp.permission_id
      WHERE rp.role_id = $1
      ORDER BY p.code ASC
      `,
      [roleId]
    );

    return result.rows.map((row) => row.code);
  }
}

export default PermissionRoleModel;
