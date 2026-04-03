import { exec } from 'child_process';
import { env as processEnv } from 'process';
import fs from 'fs';
import path from 'path';

// 1. تحديد المسارات
const pgDumpPath = `"C:\\Program Files\\PostgreSQL\\13\\bin\\pg_dump.exe"`;
const backupDir = path.join(process.cwd(), 'backups');

// 2. التأكد من وجود مجلد النسخ الاحتياطية (إن لم يوجد سيقوم بإنشائه)
if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir);
}

// 3. إنشاء اسم ملف يحتوي على التاريخ والوقت بدقة
// النتيجة ستكون مثل: backup_2026-03-29_14-30-05.sql
const now = new Date();
const timestamp = now.toISOString().replace(/[:.]/g, '-').split('T');
const fileName = `backup_${timestamp[0]}_${timestamp[1].slice(0, 8)}.sql`;
const backupPath = path.join(backupDir, fileName);

// إعدادات قاعدة البيانات
const dbEnv = {
    PGPASSWORD: 'abd770020496',
    DB_USER: 'postgres',
    DB_NAME: 'school_system',
    DB_HOST: '127.0.0.1',
    DB_PORT: '5432'
};

// 4. بناء الأمر البرمجي مع المسار الجديد
const cmd = `${pgDumpPath} -h ${dbEnv.DB_HOST} -p ${dbEnv.DB_PORT} -U ${dbEnv.DB_USER} -d ${dbEnv.DB_NAME} > "${backupPath}"`;

console.log(`⏳ جاري بدء النسخ الاحتياطي إلى: ${fileName}...`);

exec(cmd, { env: { ...processEnv, PGPASSWORD: dbEnv.PGPASSWORD } }, (error, stdout, stderr) => {
    if (error) {
        console.error(`❌ خطأ أثناء التنفيذ: ${error.message}`);
        return;
    }
    // ملاحظة: pg_dump غالباً ما يرسل تنبيهات عادية في stderr
    if (stderr && !stderr.includes('done')) {
        console.warn(`⚠️ ملاحظة: ${stderr}`);
    }
    console.log(`✅ تمت العملية بنجاح!`);
    console.log(`📂 الملف موجود في: ${backupPath}`);
});