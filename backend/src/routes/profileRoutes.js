// src/routes/profileRoutes.js
import { Router } from "express";
import { changePassword, changeEmail } from "../controllers/profileController.js";
import authMiddleware from "../middleware/authMiddleware.js";

const router = Router();

// 🔒 جميع هذه المسارات تحتاج توكن صالح
router.put("/change-password", authMiddleware, changePassword);
router.put("/change-email", authMiddleware, changeEmail);

export default router;
