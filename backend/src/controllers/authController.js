// src/controllers/authController.js
import UserModel from "../modules/userModel.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import PermissionRoleModel from "../modules/permissionRoleModel.js";

export const AuthController = {
  // تسجيل الدخول
  async login(req, res) {
    console.log("🔥 وصل طلب تسجيل دخول!");
    console.log("البيانات المرسلة:", req.body);

    try {
      const { email, password } = req.body;

      // 1) التحقق من المدخلات
      if (!email || !password) {
        return res
          .status(400)
          .json({ message: "الرجاء إدخال الإيميل وكلمة المرور" });
      }

      // 2) البحث عن المستخدم
      const user = await UserModel.getByEmail(email);

      if (!user) {
        return res.status(404).json({ message: "المستخدم غير موجود" });
      }

      // 3) مقارنة كلمة المرور
      const match = await bcrypt.compare(password, user.password);
      if (!match) {
        return res.status(401).json({ message: "كلمة المرور غير صحيحة" });
      }

      // 4) التحقق من وجود دور للمستخدم
      if (!user.role_name || !user.role_id) {
        return res.status(403).json({
          message: "هذا الحساب ليس لديه صلاحيات دخول (ليس له دور)",
        });
      }

      // 5) جلب أكواد الصلاحيات المرتبطة بالدور من قاعدة البيانات
      const permissionCodes =
        await PermissionRoleModel.getPermissionCodesForRole(user.role_id);

      // نحولها لاسم أوضح ونضمن أنها مصفوفة
      const permissions = Array.isArray(permissionCodes)
        ? permissionCodes
        : [];

      // 6) قراءة نسخة التوكن (لـ تسجيل الخروج الإجباري)
      // لو ما فيه قيمة في قاعدة البيانات نبدأ من 0
      const tokenVersion = user.token_version ?? 0;

      // 7) إنشاء توكن JWT
      const payload = {
        id: user.id,               // 👈 مهم: هذا اللي نستخدمه في authMiddleware
        role_id: user.role_id,
        role: user.role_name,
        permissions,               // 👈 تُستخدم في الفرونت و checkPermission
        tokenVersion,              // 👈 هذا اللي بنقارن به لاحقًا
      };

      const token = jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: "24h",
      });

      // 8) تجهيز بيانات المستخدم للواجهة (بدون كلمة المرور)
      res.json({
        message: "تم تسجيل الدخول بنجاح",
        token,
        user: {
          id: user.id,
          name: user.name || user.full_name || user.username,
          email: user.email,
          role: user.role_name,
          role_id: user.role_id,
          permissions, // تستخدمها مباشرة في الفرونت
        },
      });
    } catch (err) {
      console.error("❌ خطأ في السيرفر أثناء تسجيل الدخول:", err);
      res
        .status(500)
        .json({ message: "خطأ في السيرفر أثناء تسجيل الدخول" });
    }
  },
};
