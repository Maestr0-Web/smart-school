import { Router } from "express";
import { PermissionController } from "../controllers/permissionController.js";
import adminOnly from "../middleware/adminOnly.js";

const router = Router();

// إنشاء صلاحية
router.post("/", PermissionController.createPermission);

// عرض كل الصلاحيات
router.get("/", PermissionController.getPermissions);

// عرض صلاحية واحدة
router.get("/:id", PermissionController.getPermission);

// تعديل صلاحية
router.put("/:id", PermissionController.updatePermission);

// حذف صلاحية
router.delete("/:id", PermissionController.deletePermission);

export default router;
