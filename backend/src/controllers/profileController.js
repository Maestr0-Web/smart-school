// src/controllers/profileController.js
import bcrypt from "bcrypt";
import UserModel from "../modules/userModel.js";
import { pool } from "../config/db.js";

// 🔑 تغيير كلمة المرور
export const changePassword = async (req, res) => {
  try {
    // user.id يأتي من authMiddleware بعد فك التوكن
    const userId = req.user?.id;
    const { currentPassword, newPassword } = req.body;

    if (!userId) {
      return res.status(401).json({ message: "غير مصرح" });
    }

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        message: "الرجاء إدخال كلمة المرور الحالية والجديدة",
      });
    }

    // جلب المستخدم (getById يرجّع password الآن)
    const user = await UserModel.getById(userId);
    if (!user) {
      return res.status(404).json({ message: "المستخدم غير موجود" });
    }

    const ok = await bcrypt.compare(currentPassword, user.password);
    if (!ok) {
      return res
        .status(400)
        .json({ message: "كلمة المرور الحالية غير صحيحة" });
    }

    const hashed = await bcrypt.hash(newPassword, 10);

    // تحديث كلمة المرور
    await UserModel.updatePassword(userId, hashed);

    // زيادة token_version لتسجيل خروج إجباري من كل الأجهزة
    await pool.query(
      `
      UPDATE users
      SET token_version = COALESCE(token_version, 0) + 1
      WHERE id = $1
      `,
      [userId]
    );

    return res.json({
      message: "تم تغيير كلمة المرور بنجاح، الرجاء تسجيل الدخول من جديد",
    });
  } catch (err) {
    console.error("changePassword error:", err);
    return res
      .status(500)
      .json({ message: "خطأ في الخادم أثناء تغيير كلمة المرور" });
  }
};

// 📧 تغيير البريد الإلكتروني
export const changeEmail = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { newEmail } = req.body;

    if (!userId) {
      return res.status(401).json({ message: "غير مصرح" });
    }

    if (!newEmail) {
      return res.status(400).json({
        message: "الرجاء إدخال البريد الإلكتروني الجديد",
      });
    }

    // التأكد أن الإيميل غير مستخدم من قبل
    const existing = await UserModel.getByEmail(newEmail);
    if (existing && existing.id !== userId) {
      return res.status(400).json({ message: "هذا البريد مستخدم بالفعل" });
    }

    await UserModel.updateEmail(userId, newEmail);

    // ممكن نزيد token_version أيضًا لو حاب تجبره يسجل دخول
    await pool.query(
      `
      UPDATE users
      SET token_version = COALESCE(token_version, 0) + 1
      WHERE id = $1
      `,
      [userId]
    );

    return res.json({
      message: "تم تغيير البريد الإلكتروني بنجاح",
      email: newEmail,
    });
  } catch (err) {
    console.error("changeEmail error:", err);
    return res
      .status(500)
      .json({ message: "خطأ في الخادم أثناء تغيير البريد الإلكتروني" });
  }
};
