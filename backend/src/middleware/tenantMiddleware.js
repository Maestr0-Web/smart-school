// src/middleware/tenantMiddleware.js
import { pool } from "../config/db.js";

export const tenantMiddleware = async (req, res, next) => {
  const slug = String(
    req.params.slug ||
    req.headers["x-school-slug"] ||
    req.body.slug ||
    ""
  ).trim().toLowerCase();

  if (!slug) {
    return res.status(400).json({
      error: "يجب تحديد المدرسة أولًا",
    });
  }

  try {
    const result = await pool.query(
      `
      SELECT id, name_ar, name_en, slug, is_active
      FROM schools
      WHERE LOWER(slug) = LOWER($1)
      LIMIT 1
      `,
      [slug]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "المدرسة غير مسجلة في النظام",
      });
    }

    const school = result.rows[0];

    if (!school.is_active) {
      return res.status(403).json({
        error: "المدرسة غير مفعلة",
      });
    }

    req.school = school;
    next();
  } catch (error) {
    console.error("خطأ في التحقق من المدرسة:", error);
    return res.status(500).json({
      error: "خطأ داخلي في الخادم",
    });
  }
};