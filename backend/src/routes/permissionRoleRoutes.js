import { Router } from "express";
import { PermissionRoleController } from "../controllers/permissionRoleController.js";
import adminOnly from "../middleware/adminOnly.js";

const router = Router();

// إنشاء علاقة
router.post("/assign", PermissionRoleController.assign);

// كل العلاقات
router.get("/", PermissionRoleController.getAll);

// حسب الدور
router.get("/:role_id", PermissionRoleController.getByRole);

// حذف علاقة
router.delete("/:id", PermissionRoleController.delete);

export default router;
