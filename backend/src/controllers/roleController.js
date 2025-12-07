import Role from "../modules/roleModel.js";
import { pool } from "../config/db.js"; // ✅ لإجبار المستخدمين على تسجيل الخروج

// ➕ إنشاء دور
export const createRole = async (req, res) => {
  try {
    const { name, description } = req.body;

    if (!name) {
      return res.status(400).json({ message: "اسم الدور مطلوب" });
    }

    const newRole = await Role.createRole(name, description || "");
    return res.status(201).json(newRole);
  } catch (error) {
    console.error("Error creating role:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// 📄 جلب كل الأدوار
export const getRoles = async (req, res) => {
  try {
    const roles = await Role.getAllRoles();
    return res.json(roles);
  } catch (error) {
    console.error("Error fetching roles:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// 📌 جلب دور واحد
export const getRole = async (req, res) => {
  try {
    const role = await Role.getRoleById(req.params.id);
    if (!role) {
      return res.status(404).json({ message: "Role not found" });
    }
    return res.json(role);
  } catch (error) {
    console.error("Error fetching role:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✏️ تحديث دور
export const updateRole = async (req, res) => {
  try {
    const { name, description } = req.body;

    const updated = await Role.updateRole(
      req.params.id,
      name,
      description || ""
    );

    if (!updated) {
      return res.status(404).json({ message: "Role not found" });
    }

    return res.json(updated);
  } catch (error) {
    console.error("Error updating role:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// 🗑 حذف دور
export const deleteRole = async (req, res) => {
  try {
    const deleted = await Role.deleteRole(req.params.id);

    if (!deleted) {
      return res.status(404).json({ message: "Role not found" });
    }

    return res.json(deleted);
  } catch (error) {
    console.error("Error deleting role:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// 🔗 جلب صلاحيات الدور
export const getRolePermissions = async (req, res) => {
  try {
    const roleId = req.params.id;

    const role = await Role.getRoleById(roleId);
    if (!role) {
      return res.status(404).json({ message: "Role not found" });
    }

    const permissions = await Role.getRolePermissionIds(roleId);
    return res.json({ permissions });
  } catch (error) {
    console.error("Error fetching role permissions:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// 🔗 تحديث صلاحيات الدور ✅✅✅
// 🔗 تحديث صلاحيات الدور ✅✅✅
export const updateRolePermissions = async (req, res) => {
  try {
    const roleId = Number(req.params.id);

    const role = await Role.getRoleById(roleId);
    if (!role) {
      return res.status(404).json({ message: "Role not found" });
    }

    const permissions = Array.isArray(req.body.permissions)
      ? req.body.permissions.map(Number)
      : [];

    // ✅ حفظ الصلاحيات في جدول role_permissions
    await Role.setRolePermissions(roleId, permissions);

    // ✅ إجبار كل المستخدمين بهذا الدور على تسجيل الدخول من جديد
    // ❌ الكود القديم (هو سبب الخطأ):
    // await pool.query(
    //   "UPDATE users SET token_version = token_version + 1 WHERE role_id = $1",
    //   [roleId]
    // );

    // ✅ الكود الصحيح (باستخدام جدول user_roles)
    await pool.query(
      `
      UPDATE users u
      SET token_version = COALESCE(u.token_version, 0) + 1
      FROM user_roles ur
      WHERE ur.user_id = u.id
        AND ur.role_id = $1
      `,
      [roleId]
    );

    return res.json({
      success: true,
      message: "تم تحديث الصلاحيات وإجبار المستخدمين على تسجيل الدخول",
    });
  } catch (error) {
    console.error("Error updating role permissions:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

// ✅ منح جميع الصلاحيات للدور ✅✅✅
export const grantAllPermissions = async (req, res) => {
  try {
    const roleId = Number(req.params.id);

    if (!roleId) {
      return res.status(400).json({ message: "Role ID غير صالح" });
    }

    const role = await Role.getRoleById(roleId);
    if (!role) {
      return res.status(404).json({ message: "الدور غير موجود" });
    }

    // ✅ جلب كل الصلاحيات
    const allPermissions = await Role.getAllPermissionIds();

    // ✅ ربط الدور بكل الصلاحيات
    await Role.setRolePermissions(roleId, allPermissions);

    // ✅ إجبار جميع مستخدمي هذا الدور على تسجيل الدخول من جديد
    await pool.query(
      "UPDATE users SET token_version = token_version + 1 WHERE role_id = $1",
      [roleId]
    );

    return res.json({
      success: true,
      message: "✅ تم منح جميع الصلاحيات وتم تسجيل خروج المستخدمين",
      permissions_count: allPermissions.length,
    });
  } catch (error) {
    console.error("grantAllPermissions error:", error);
    return res.status(500).json({
      message: "خطأ أثناء منح الصلاحيات",
    });
  }
};
