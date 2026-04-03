import { pool } from '../config/db.js';
import { logActivity } from '../utils/logger.js';

// 1. جلب التقييمات (للقائمة المنسدلة)
export const getAdminAssessments = async (req, res) => {
    try {
        const schoolId = req.user.school_id;
        const { section_id, subject_id } = req.query;

        if (!section_id || !subject_id) {
            return res.status(400).json({ message: "الرجاء تحديد الشعبة والمادة." });
        }

        const query = `
            SELECT 
                a.id AS assessment_id, 
                a.title, 
                a.max_score, 
                a.status,
                u.name AS teacher_name
            FROM assessments a
            JOIN teacher_assignments ta ON a.teacher_assignment_id = ta.id
            JOIN teachers t ON ta.teacher_id = t.id
            JOIN users u ON t.user_id = u.id
            WHERE a.school_id = $1 
              AND ta.section_id = $2 
              AND ta.subject_id = $3
            ORDER BY a.created_at DESC;
        `;

        const { rows } = await pool.query(query, [schoolId, section_id, subject_id]);
        res.json({ success: true, data: rows });

    } catch (error) {
        console.error("Admin Assessment Fetch Error:", error);
        res.status(500).json({ message: "خطأ في جلب بيانات التقييمات." });
    }
};

// 2. جلب درجات تقييم معين (لرسم جدول الإدارة)
export const getAssessmentGrades = async (req, res) => {
    try {
        const schoolId = req.user.school_id;
        const { assessment_id } = req.params;
        const { section_id } = req.query;

        // LEFT JOIN لضمان جلب كل الطلاب، حتى من لم تُرصد درجته بعد
        const query = `
            SELECT 
                s.id AS student_id, 
                s.full_name,
                ag.id AS grade_id,
                ag.score,
                ag.feedback,
                u.name AS grader_name
            FROM students s
            JOIN student_enrollments se ON s.id = se.student_id AND se.is_active = true
            LEFT JOIN assessment_grades ag ON s.id = ag.student_id AND ag.assessment_id = $1 AND ag.school_id = $2
            LEFT JOIN users u ON ag.graded_by = u.id -- لمعرفة من رصد الدرجة
            WHERE se.section_id = $3 AND s.school_id = $2
            ORDER BY s.full_name;
        `;

        const { rows } = await pool.query(query, [assessment_id, schoolId, section_id]);
        res.json({ success: true, data: rows });

    } catch (error) {
        console.error("Error fetching admin assessment grades:", error);
        res.status(500).json({ message: "حدث خطأ أثناء جلب قائمة الدرجات." });
    }
};

// 3. التعديل والحفظ الإداري (مع التوثيق الأمني الكامل)
export const bulkOverrideGrades = async (req, res) => {
    try {
        const schoolId = req.user.school_id;
        const adminId = req.user.id; // رقم حساب المدير
        const { assessment_id } = req.params;
        const { gradesList } = req.body; 

        if (!gradesList || !Array.isArray(gradesList) || gradesList.length === 0) {
            return res.status(400).json({ message: "لا توجد تعديلات للحفظ." });
        }

        // بدء Transaction لضمان سلامة البيانات
        await pool.query('BEGIN');

        let updatedCount = 0;
        let insertedCount = 0;
        const changesLog = [];

        // جلب اسم التقييم للتوثيق
        const assRes = await pool.query(`SELECT title FROM assessments WHERE id = $1`, [assessment_id]);
        const assessmentTitle = assRes.rows.length > 0 ? assRes.rows[0].title : `تقييم ${assessment_id}`;

        for (const item of gradesList) {
            const { student_id, score, feedback } = item;

            // التحقق هل الدرجة موجودة مسبقاً؟
            const checkRes = await pool.query(
                `SELECT id, score FROM assessment_grades WHERE assessment_id = $1 AND student_id = $2 AND school_id = $3`,
                [assessment_id, student_id, schoolId]
            );

            if (checkRes.rows.length > 0) {
                // 🎯 حالة التعديل الإداري (OVERRIDE)
                const oldScore = checkRes.rows[0].score;
                const gradeId = checkRes.rows[0].id;
                
                await pool.query(
                    `UPDATE assessment_grades 
                     SET score = $1, feedback = $2, graded_by = $3, updated_at = NOW() 
                     WHERE id = $4`,
                    [score, feedback, adminId, gradeId]
                );
                updatedCount++;

                // 🛡️ التوثيق في جدول التغييرات (Audit Trail)
                await pool.query(
                    `INSERT INTO grade_change_logs (grade_id, changed_by, old_score, new_score, reason, school_id, changed_at)
                     VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
                    [gradeId, adminId, oldScore, score, "تعديل بواسطة الإدارة (الكنترول)", schoolId]
                );

                // تجهيز بيانات اللوج اليدوي لسجل النشاطات المباشر
                changesLog.push({ student_id, old: oldScore, new: score });

            } else {
                // 🎯 حالة الإدخال الإداري لأول مرة
                if(score !== null && score !== "") { 
                    await pool.query(
                        `INSERT INTO assessment_grades (assessment_id, student_id, score, feedback, graded_by, created_at, school_id) 
                         VALUES ($1, $2, $3, $4, $5, NOW(), $6)`,
                        [assessment_id, student_id, score, feedback, adminId, schoolId]
                    );
                    insertedCount++;
                }
            }
        }

        await pool.query('COMMIT');

        // تسجيل العملية في السجل الذهبي للنشاطات
        await logActivity({
            school_id: schoolId,
            user_id: adminId,
            action: 'UPDATE',
            resource_type: 'assessment_grades',
            resource_id: assessment_id,
            description: `تعديل إداري في ( ${assessmentTitle} ) لعدد (${updatedCount + insertedCount}) طالب`,
            changes: changesLog.length > 0 ? { updates: changesLog } : null,
            req: req
        });
        res.locals.skipAutoLog = true; // منع الميدل وير الآلي من التسجيل

        res.json({ 
            success: true, 
            message: `تم اعتماد التعديلات بنجاح! (تم تعديل ${updatedCount}، وإضافة ${insertedCount})`
        });

    } catch (error) {
        await pool.query('ROLLBACK');
        console.error("Admin Bulk Override Error:", error);
        res.status(500).json({ message: "حدث خطأ في الخادم أثناء اعتماد الدرجات." });
    }
};// جلب المواد المرتبطة بصف معين (خاص بشاشة الكنترول)
export const getSubjectsByGradeId = async (req, res) => {
    try {
        const schoolId = req.user.school_id;
        const { grade_id } = req.query;

        if (!grade_id) {
            return res.status(400).json({ success: false, message: "معرف الصف مطلوب" });
        }

        const query = `
            SELECT s.id, s.name 
            FROM subjects s
            JOIN grade_subjects gs ON s.id = gs.subject_id
            WHERE gs.grade_id = $1 
              AND s.school_id = $2 
              AND s.is_active = true 
              AND gs.is_active = true
            ORDER BY s.name ASC;
        `;
        
        const { rows } = await pool.query(query, [grade_id, schoolId]);
        res.json({ success: true, data: rows });
    } catch (error) {
        console.error("Error fetching subjects by grade:", error);
        res.status(500).json({ success: false, message: "خطأ في جلب المواد" });
    }
};