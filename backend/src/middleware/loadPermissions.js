// src/middleware/loadPermissions.js
import PermissionRoleModel from "../modules/permissionRoleModel.js";

export default async function loadPermissions(req, res, next) {
  try {
    // لو مافي مستخدم (مثلاً راوت عام) نكمّل عادي
    if (!req.user) {
      return next();
    }

    // لو التوكِن يحتوي مصفوفة صلاحيات جاهزة ✅
    if (Array.isArray(req.user.permissions)) {
      // تقدر تحط هنا لوج للتجربة لو حاب:
      // console.log("permissions from token:", req.user.permissions);
      return next();
    }

    // 🔁 حالة احتياطية: نجيب الصلاحيات من قاعدة البيانات
    const codes = await PermissionRoleModel.getPermissionCodesForRole(
      req.user.role_id
    );

    req.user.permissions = codes; // حتى checkPermission يشتغل على المصفوفة
    // console.log("permissions loaded from DB:", codes);

    return next();
  } catch (err) {
    console.error("loadPermissions error:", err);
    return res
      .status(500)
      .json({ message: "خطأ في تحميل صلاحيات المستخدم" });
  }
}
