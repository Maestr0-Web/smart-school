import { pool } from "./config/db.js";
import bcrypt from "bcrypt";

const createAdmin = async () => {
  try {
    // ----------------------------------------------------
    // 📝 بيانات الأدمن الجديد (يمكنك تعديلها من هنا)
    const newAdmin = {
      name: "المشرف العام",
      email: "manager@school.com", // إيميل جديد
      username: "manager",
      password: "123",             // كلمة المرور
      phone: "0555555555"
    };
    // ----------------------------------------------------

    console.log("⏳ جاري إضافة الأدمن الجديد...");

    // 1. تشفير كلمة المرور
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newAdmin.password, salt);

    // 2. التأكد من وجود دور 'admin'
    let roleRes = await pool.query("SELECT id FROM roles WHERE name = 'admin'");
    let roleId;

    if (roleRes.rows.length === 0) {
      console.log("⚠️ دور 'admin' غير موجود، سيتم إنشاؤه...");
      const newRole = await pool.query("INSERT INTO roles (name, description) VALUES ('admin', 'مدير النظام') RETURNING id");
      roleId = newRole.rows[0].id;
    } else {
      roleId = roleRes.rows[0].id;
    }

    // 3. إضافة المستخدم لجدول users
    const userRes = await pool.query(
      `INSERT INTO users (name, email, username, password, phone, status) 
       VALUES ($1, $2, $3, $4, $5, 'active') 
       RETURNING id`,
      [newAdmin.name, newAdmin.email, newAdmin.username, hashedPassword, newAdmin.phone]
    );

    const userId = userRes.rows[0].id;

    // 4. ربط المستخدم بالدور في جدول user_roles
    await pool.query(
      "INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)",
      [userId, roleId]
    );

    console.log("---------------------------------------");
    console.log("✅✅ تم إضافة الأدمن بنجاح!");
    console.log(`👤 الاسم: ${newAdmin.name}`);
    console.log(`📧 الإيميل: ${newAdmin.email}`);
    console.log(`🔑 كلمة المرور: ${newAdmin.password}`);
    console.log("---------------------------------------");

  } catch (err) {
    if (err.code === '23505') {
      console.error("❌ خطأ: هذا البريد الإلكتروني أو اسم المستخدم موجود مسبقاً!");
    } else {
      console.error("❌ حدث خطأ غير متوقع:", err);
    }
  } finally {
    process.exit();
  }
};

createAdmin();