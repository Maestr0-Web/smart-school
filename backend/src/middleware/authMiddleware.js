  // src/middleware/authMiddleware.js
  import jwt from "jsonwebtoken";
  import UserModel from "../modules/userModel.js";

  export default async function authMiddleware(req, res, next) {
    try {
      const authHeader = req.headers.authorization || "";

      if (!authHeader.startsWith("Bearer ")) {
        return res.status(401).json({ message: "غير مصرح" });
      }

      const token = authHeader.split(" ")[1];

      if (!token) {
        return res.status(401).json({ message: "توكن غير موجود" });
      }

      let decoded;
      try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
      } catch (err) {
        return res.status(401).json({
          message: "الجلسة منتهية، الرجاء تسجيل الدخول",
        });
      }

      const userFromDb = await UserModel.getById(decoded.id);

      if (!userFromDb) {
        return res.status(401).json({ message: "المستخدم لم يعد موجودًا" });
      }

      const currentVersion = userFromDb.token_version ?? 0;

      if (
        decoded.tokenVersion == null ||
        decoded.tokenVersion !== currentVersion
      ) {
        return res.status(401).json({
          message: "تم تحديث صلاحياتك أو بياناتك، الرجاء تسجيل الدخول من جديد",
        });
      }

      if (!userFromDb.school_id) {
        return res.status(403).json({
          message: "هذا المستخدم غير مرتبط بمدرسة",
        });
      }

      const requestedSchoolSlug = String(
        req.params.slug ||
        req.headers["x-school-slug"] ||
        ""
      ).trim().toLowerCase();

      if (
        requestedSchoolSlug &&
        String(userFromDb.school_slug || "").toLowerCase() !== requestedSchoolSlug
      ) {
        return res.status(403).json({
          message: "لا يمكنك الوصول إلى بيانات مدرسة أخرى",
        });
      }

      req.user = {
        id: userFromDb.id,
        school_id: userFromDb.school_id,
        school_slug: userFromDb.school_slug,
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