// src/middleware/authMiddleware.js
import jwt from "jsonwebtoken";
import UserModel from "../modules/userModel.js";

export default async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization || "";

    // ✅ 1. التأكد من وجود Bearer token
    if (!authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "غير مصرح" });
    }

    const token = authHeader.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "توكن غير موجود" });
    }

    // ✅ 2. فك التوكن
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res
        .status(401)
        .json({ message: "الجلسة منتهية، الرجاء تسجيل الدخول" });
    }

    // ✅ 3. جلب المستخدم من قاعدة البيانات
    const userFromDb = await UserModel.getById(decoded.id);

    if (!userFromDb) {
      return res.status(401).json({ message: "المستخدم لم يعد موجودًا" });
    }

    // ✅ 4. التحقق من tokenVersion (تسجيل الخروج الإجباري)
    const currentVersion = userFromDb.token_version ?? 0;

    // لو التوكن قديم أو بدون tokenVersion → نرفضه
    if (
      decoded.tokenVersion == null || // ما فيه في التوكن
      decoded.tokenVersion !== currentVersion
    ) {
      return res.status(401).json({
        message: "تم تحديث صلاحياتك أو بياناتك، الرجاء تسجيل الدخول من جديد",
      });
    }

    // ✅ 5. تمرير بيانات المستخدم للراوترات التالية
    // نحافظ على نفس الشكل اللي يستخدمه checkPermission
    req.user = {
      id: userFromDb.id,
      role_id: userFromDb.role_id,
      role: userFromDb.role_name,
      permissions: decoded.permissions || [],
      tokenVersion: currentVersion,
    };

    next();
  } catch (err) {
    console.error("authMiddleware error:", err);
    return res.status(500).json({ message: "خطأ في المصادقة" });
  }
}
