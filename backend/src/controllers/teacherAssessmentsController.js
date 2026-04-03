import { pool } from "../config/db.js";

function pickUserId(req) {
  return req.user?.id ?? req.user?.user_id ?? req.user?.userId ?? null;
}

function badRequest(message) {
  const err = new Error(message);
  err.status = 400;
  return err;
}

function forbidden(message) {
  const err = new Error(message);
  err.status = 403;
  return err;
}

function notFound(message) {
  const err = new Error(message);
  err.status = 404;
  return err;
}

// ✅ إضافة schoolId لضمان جلب المعلم في المدرسة الصحيحة
async function getTeacherIdByUserId(userId, schoolId) {
  const { rows } = await pool.query(
    `
    SELECT id
    FROM teachers
    WHERE user_id = $1 AND school_id = $2
      AND COALESCE(is_active, true) = true
    LIMIT 1
    `,
    [userId, schoolId]
  );
  return rows[0]?.id ?? null;
}

// ✅ إضافة schoolId لحماية التحقق من التكليف
async function assertOwnAssignment(teacherId, teacherAssignmentId, schoolId, db = pool) {
  const { rows } = await db.query(
    `
    SELECT
      id,
      teacher_id,
      academic_year_id,
      term,
      stage_id,
      grade_id,
      section_id,
      subject_id
    FROM teacher_assignments
    WHERE id = $1
      AND teacher_id = $2
      AND school_id = $3
    LIMIT 1
    `,
    [teacherAssignmentId, teacherId, schoolId]
  );

  if (!rows.length) {
    throw forbidden("نطاق التدريس غير صحيح أو لا يتبع لمدرستك.");
  }

  return rows[0];
}

// ✅ إضافة schoolId لحماية التحقق من التقييم
async function assertOwnAssessment(teacherId, assessmentId, schoolId, db = pool) {
  const { rows } = await db.query(
    `
    SELECT
      a.*,
      ta.teacher_id,
      ta.academic_year_id,
      ta.term,
      ta.stage_id,
      ta.grade_id,
      ta.section_id,
      ta.subject_id
    FROM assessments a
    JOIN teacher_assignments ta ON ta.id = a.teacher_assignment_id
    WHERE a.id = $1
      AND ta.teacher_id = $2
      AND a.school_id = $3
    LIMIT 1
    `,
    [assessmentId, teacherId, schoolId]
  );

  if (!rows.length) {
    throw forbidden("التقييم غير موجود أو غير تابع لك أو لمدرستك.");
  }

  return rows[0];
}

function normalizeMode(mode) {
  const raw = String(mode || "").trim();

  const map = {
    in_class: "in_class",
    home_submission: "home_submission",
    home_no_submission: "home_no_submission",
    live_online: "live_online",

    // توافق مع الصيغ القديمة
    submission: "home_submission",
    at_home: "home_no_submission",
    online_exam: "live_online",
  };

  return map[raw] || raw;
}

function normalizeStatus(status) {
  const raw = String(status || "draft").trim().toLowerCase();
  if (["draft", "active", "published", "closed", "reopened", "scheduled"].includes(raw)) return raw;
  return "draft";
}

function buildLatePolicy(body) {
  if (body?.late_policy_json && typeof body.late_policy_json === "object") {
    return body.late_policy_json;
  }

  return {
    submission_kind: body?.submission_kind ?? "none",
    allow_late_submission: !!body?.allow_late_submission,
    late_until: body?.late_until ?? null,
  };
}

function toLegacyAssessmentType(assessment) {
  if (!assessment) return null;

  if (assessment.type === "exam") {
    if (assessment.exam_kind === "monthly") return "monthly_exam";
    if (assessment.exam_kind === "midterm") return "midterm_exam";
    if (assessment.exam_kind === "final") return "final_exam";
    return "exam";
  }

  if (assessment.type === "aggregate") {
    if (assessment.aggregate_kind === "midterm") return "midterm_muhassala";
    if (assessment.aggregate_kind === "final") return "final_muhassala";
    return "aggregate";
  }

  return assessment.type;
}

function parseAssessmentClassification(body) {
  const rawType = String(body?.type || "").trim();
  const rawExamKind = String(body?.exam_kind || "").trim();
  const rawAggregateKind = String(body?.aggregate_kind || "").trim();
  const seq = body?.sequence_no == null || body?.sequence_no === "" ? null : Number(body.sequence_no);

  // دعم الشكل الجديد
  if (rawType === "exam") {
    if (!["monthly", "midterm", "final"].includes(rawExamKind)) {
      throw badRequest("نوع الاختبار غير صحيح.");
    }

    return {
      canonical_type: "exam",
      exam_kind: rawExamKind,
      aggregate_kind: null,
      sequence_no: rawExamKind === "monthly" ? (Number.isFinite(seq) && seq > 0 ? seq : 1) : null,
      is_system_generated: false,
    };
  }

  if (rawType === "aggregate") {
    if (!["midterm", "final"].includes(rawAggregateKind)) {
      throw badRequest("نوع المحصلة غير صحيح.");
    }

    return {
      canonical_type: "aggregate",
      exam_kind: null,
      aggregate_kind: rawAggregateKind,
      sequence_no: null,
      is_system_generated: false,
    };
  }

  // دعم الشكل القديم مؤقتًا
  if (rawType === "quiz" || rawType === "monthly_exam") {
    return {
      canonical_type: "exam",
      exam_kind: "monthly",
      aggregate_kind: null,
      sequence_no: Number.isFinite(seq) && seq > 0 ? seq : 1,
      is_system_generated: false,
    };
  }

  if (rawType === "midterm_exam") {
    return {
      canonical_type: "exam",
      exam_kind: "midterm",
      aggregate_kind: null,
      sequence_no: null,
      is_system_generated: false,
    };
  }

  if (rawType === "final_exam") {
    return {
      canonical_type: "exam",
      exam_kind: "final",
      aggregate_kind: null,
      sequence_no: null,
      is_system_generated: false,
    };
  }

  if (rawType === "midterm_muhassala") {
    return {
      canonical_type: "aggregate",
      exam_kind: null,
      aggregate_kind: "midterm",
      sequence_no: null,
      is_system_generated: true,
    };
  }

  if (rawType === "final_muhassala") {
    return {
      canonical_type: "aggregate",
      exam_kind: null,
      aggregate_kind: "final",
      sequence_no: null,
      is_system_generated: true,
    };
  }

  if (["classwork", "activity", "homework", "project", "oral"].includes(rawType)) {
    return {
      canonical_type: rawType,
      exam_kind: null,
      aggregate_kind: null,
      sequence_no: null,
      is_system_generated: false,
    };
  }

  // حالة قديمة/خاصة: نشاط أونلاين
  if (rawType === "live_online") {
    return {
      canonical_type: "activity",
      exam_kind: null,
      aggregate_kind: null,
      sequence_no: null,
      is_system_generated: false,
      force_mode: "live_online",
    };
  }

  throw badRequest("نوع التقييم غير صحيح.");
}

function mapExamTypeToContext(examType) {
  const raw = String(examType || "").trim().toLowerCase();

  if (["monthly", "monthly_exam", "monthly-test", "شهري", "اختبار شهري", "midyear"].includes(raw)) {
    return {
      legacy_type: "monthly_exam",
      canonical_type: "exam",
      exam_kind: "monthly",
      sequence_no: 1,
      max_score: 20,
    };
  }

  if (["midterm", "midterm_exam", "نصفي", "اختبار نصفي"].includes(raw)) {
    return {
      legacy_type: "midterm_exam",
      canonical_type: "exam",
      exam_kind: "midterm",
      sequence_no: null,
      max_score: 30,
    };
  }

  if (["final", "final_exam", "نهائي", "اختبار نهائي"].includes(raw)) {
    return {
      legacy_type: "final_exam",
      canonical_type: "exam",
      exam_kind: "final",
      sequence_no: null,
      max_score: 30,
    };
  }

  return null;
}

export async function listAssessments(req, res) {
  try {
    const userId = pickUserId(req);
    const schoolId = req.user?.school_id;
    if (!userId || !schoolId) return res.status(401).json({ message: "غير مصرح." });

    const teacherId = await getTeacherIdByUserId(userId, schoolId);
    if (!teacherId) return res.status(403).json({ message: "حساب المعلم غير موجود." });

    const teacherAssignmentId = Number(req.query.teacher_assignment_id);
    const status = String(req.query.status || "all").trim();
    const typeFilter = String(req.query.type || "all").trim();
    const q = String(req.query.q || "").trim();

    if (!teacherAssignmentId) {
      return res.status(400).json({ message: "teacher_assignment_id مطلوب." });
    }

    await assertOwnAssignment(teacherId, teacherAssignmentId, schoolId);

    const params = [teacherAssignmentId, schoolId];
    const where = [`a.teacher_assignment_id = $1`, `a.school_id = $2`];
    let idx = 3;

    if (status !== "all") {
      params.push(status);
      where.push(`a.status = $${idx++}`);
    }

    if (q) {
      params.push(`%${q}%`);
      where.push(`(a.title ILIKE $${idx} OR COALESCE(a.description, '') ILIKE $${idx})`);
      idx += 1;
    }

    const { rows } = await pool.query(
      `
      SELECT
        a.id,
        a.teacher_assignment_id,
        ta.term,

        a.type,
        a.exam_kind,
        a.aggregate_kind,
        a.sequence_no,
        a.is_system_generated,
        a.title_short,

        a.mode,
        a.status,
        a.title,
        a.description,
        a.max_score,
        a.starts_at,
        a.due_at,
        a.duration_minutes,
        a.late_policy_json,
        a.published_at,
        a.closed_at,
        a.created_at,
        a.updated_at,

        ay.name AS academic_year_name,
        st.name AS stage_name,
        COALESCE(g.grade_name, g.name) AS grade_name,
        s.name AS section_name,
        subj.name AS subject_name,

        (
          SELECT COUNT(*)
          FROM student_enrollments se
          WHERE se.academic_year_id = ta.academic_year_id
            AND se.term = ta.term
            AND se.school_id = a.school_id
            AND (se.section_id = ta.section_id OR (ta.section_id IS NULL AND se.grade_id = ta.grade_id))
            AND COALESCE(se.status, 'enrolled') = 'enrolled'
        )::int AS students_count,

        (
          SELECT COUNT(*)
          FROM submissions sub
          WHERE sub.assessment_id = a.id
        )::int AS submissions_count

      FROM assessments a
      JOIN teacher_assignments ta ON ta.id = a.teacher_assignment_id
      LEFT JOIN academic_years ay ON ay.id = ta.academic_year_id
      LEFT JOIN stages st ON st.id = ta.stage_id
      LEFT JOIN grades g ON g.id = ta.grade_id
      LEFT JOIN sections s ON s.id = ta.section_id
      LEFT JOIN subjects subj ON subj.id = ta.subject_id

      WHERE ${where.join(" AND ")}
      ORDER BY a.created_at DESC
      LIMIT 300
      `,
      params
    );

    let items = rows.map((r) => ({
      ...r,
      canonical_type: r.type,
      type: toLegacyAssessmentType(r),
      scope_label: [r.stage_name, r.grade_name, r.section_name ? `شعبة: ${r.section_name}` : null, r.subject_name ? `مادة: ${r.subject_name}` : null]
        .filter(Boolean)
        .join(" • "),
    }));

    if (typeFilter !== "all") {
      items = items.filter((item) => {
        if (typeFilter === "exam") return item.canonical_type === "exam";
        if (typeFilter === "aggregate") return item.canonical_type === "aggregate";
        return item.type === typeFilter || item.canonical_type === typeFilter;
      });
    }

    return res.json({ items });
  } catch (e) {
    console.error("listAssessments error:", e);
    return res.status(e.status || 500).json({ message: e.message || "خطأ في السيرفر" });
  }
}

export async function createAssessment(req, res) {
  const client = await pool.connect();
  try {
    const userId = pickUserId(req);
    const schoolId = req.user?.school_id;
    if (!userId || !schoolId) return res.status(401).json({ message: "غير مصرح." });

    const teacherId = await getTeacherIdByUserId(userId, schoolId);
    if (!teacherId) return res.status(403).json({ message: "حساب المعلم غير موجود." });

    const teacherAssignmentId = Number(req.body.teacher_assignment_id);
    const title = String(req.body.title || "").trim();
    const description = String(req.body.description || "").trim();
    const starts_at = req.body.starts_at || null;
    const due_at = req.body.due_at || null;
    const maxScore = Number(req.body.max_score);
    const durationMinutes = req.body.duration_minutes ? Number(req.body.duration_minutes) : null;

    if (!teacherAssignmentId) throw badRequest("teacher_assignment_id مطلوب.");
    if (!title) throw badRequest("عنوان التقييم مطلوب.");
    if (!Number.isFinite(maxScore) || maxScore <= 0) throw badRequest("max_score غير صحيح.");

    const assignment = await assertOwnAssignment(teacherId, teacherAssignmentId, schoolId, client);
    const classification = parseAssessmentClassification(req.body);

    let mode = normalizeMode(req.body.mode);

    // فرض الوضع الصحيح حسب النوع
    if (classification.canonical_type === "classwork") {
      mode = "in_class";
    }

    if (classification.canonical_type === "exam") {
      mode = "in_class";
    }

    if (classification.force_mode) {
      mode = classification.force_mode;
    }

    if (!["in_class", "home_submission", "home_no_submission", "live_online"].includes(mode)) {
      throw badRequest("mode غير صحيح.");
    }

    await client.query("BEGIN");

    const assessmentRes = await client.query(
      `
      INSERT INTO assessments (
        school_id, -- ✅ تمت الإضافة
        teacher_assignment_id,
        type,
        exam_kind,
        aggregate_kind,
        sequence_no,
        is_system_generated,
        mode,
        status,
        title,
        title_short,
        description,
        max_score,
        starts_at,
        due_at,
        duration_minutes,
        late_policy_json,
        created_at,
        updated_at
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,NOW(),NOW()
      )
      RETURNING id, created_at
      `,
      [
        schoolId, // $1
        teacherAssignmentId,
        classification.canonical_type,
        classification.exam_kind,
        classification.aggregate_kind,
        classification.sequence_no,
        classification.is_system_generated,
        mode,
        "draft",
        title,
        title,
        description || null,
        maxScore,
        starts_at,
        due_at,
        durationMinutes,
        JSON.stringify(buildLatePolicy(req.body)),
      ]
    );

    const assessmentId = assessmentRes.rows[0].id;

    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        await client.query(
          `
          INSERT INTO assessment_attachments
            (assessment_id, file_url, file_name, file_type, file_size, created_at)
          VALUES
            ($1, $2, $3, $4, $5, NOW())
          `,
          [
            assessmentId,
            `/uploads/assessments/${file.filename}`,
            file.originalname,
            file.mimetype,
            file.size,
          ]
        );
      }
    }

    await client.query("COMMIT");

    return res.status(201).json({
      id: assessmentId,
      created_at: assessmentRes.rows[0].created_at,
      message: "تم إنشاء التقييم مع المرفقات بنجاح",
      canonical_type: classification.canonical_type,
      exam_kind: classification.exam_kind,
      aggregate_kind: classification.aggregate_kind,
      sequence_no: classification.sequence_no,
    });
  } catch (e) {
    await client.query("ROLLBACK");
    console.error("createAssessment error:", e);
    return res.status(e.status || 500).json({ message: e.message || "خطأ في السيرفر" });
  } finally {
    client.release();
  }
}

export async function publishAssessment(req, res) {
  try {
    const userId = pickUserId(req);
    const schoolId = req.user?.school_id;
    if (!userId || !schoolId) return res.status(401).json({ message: "غير مصرح." });

    const teacherId = await getTeacherIdByUserId(userId, schoolId);
    if (!teacherId) return res.status(403).json({ message: "حساب المعلم غير موجود." });

    const assessmentId = Number(req.params.id);
    if (!assessmentId) throw badRequest("id غير صحيح.");

    const assessment = await assertOwnAssessment(teacherId, assessmentId, schoolId);

    if (assessment.status === "closed") {
      throw badRequest("لا يمكن نشر تقييم مغلق.");
    }

    if (assessment.status === "published") {
      throw badRequest("تم نشر هذا التقييم بالفعل.");
    }

    if (assessment.status === "scheduled") {
      throw badRequest("هذا تقييم رسمي مجدول ولا يتم نشره يدويًا من هنا.");
    }

    await pool.query(
      `
      UPDATE assessments
      SET status = 'published',
          published_at = COALESCE(published_at, NOW()),
          updated_at = NOW()
      WHERE id = $1 AND school_id = $2
      `,
      [assessmentId, schoolId]
    );

    return res.status(204).send();
  } catch (e) {
    console.error("publishAssessment error:", e);
    return res.status(e.status || 500).json({ message: e.message || "خطأ في السيرفر" });
  }
}

export async function closeAssessment(req, res) {
  try {
    const userId = pickUserId(req);
    const schoolId = req.user?.school_id;
    if (!userId || !schoolId) return res.status(401).json({ message: "غير مصرح." });

    const teacherId = await getTeacherIdByUserId(userId, schoolId);
    if (!teacherId) return res.status(403).json({ message: "حساب المعلم غير موجود." });

    const assessmentId = Number(req.params.id);
    if (!assessmentId) throw badRequest("id غير صحيح.");

    const assessment = await assertOwnAssessment(teacherId, assessmentId, schoolId);

    if (assessment.status !== "published") {
      throw badRequest("لا يمكن إغلاق التقييم إلا بعد نشره.");
    }

    await pool.query(
      `
      UPDATE assessments
      SET status = 'closed',
          closed_at = NOW(),
          updated_at = NOW()
      WHERE id = $1 AND school_id = $2
      `,
      [assessmentId, schoolId]
    );

    return res.status(204).send();
  } catch (e) {
    console.error("closeAssessment error:", e);
    return res.status(e.status || 500).json({ message: e.message || "خطأ في السيرفر" });
  }
}

export async function getOfficialAssessmentContext(req, res) {
  try {
    const userId = pickUserId(req);
    const schoolId = req.user?.school_id;
    if (!userId || !schoolId) return res.status(401).json({ matched: false });

    const teacherId = await getTeacherIdByUserId(userId, schoolId);
    if (!teacherId) return res.status(403).json({ matched: false });

    const teacherAssignmentId = Number(req.query.teacher_assignment_id);
    const term = Number(req.query.term);

    if (!teacherAssignmentId || !term) {
      return res.json({ matched: false });
    }

    const assignment = await assertOwnAssignment(teacherId, teacherAssignmentId, schoolId);

    const now = new Date();
    const today = now.toLocaleDateString("en-CA");

    const yesterdayDate = new Date(now);
    yesterdayDate.setDate(yesterdayDate.getDate() - 1);
    const yesterday = yesterdayDate.toLocaleDateString("en-CA");

    const tomorrowDate = new Date(now);
    tomorrowDate.setDate(tomorrowDate.getDate() + 1);
    const tomorrow = tomorrowDate.toLocaleDateString("en-CA");

    const examQ = await pool.query(
      `
      SELECT
        ete.id AS source_id,
        et.exam_type,
        ete.exam_date,
        ete.start_time
      FROM exam_timetable_entries ete
      JOIN exam_timetables et ON et.id = ete.exam_timetable_id
      WHERE et.academic_year_id = $1
        AND et.school_id = $8 -- ✅ حماية التعدد
        AND ((et.section_id = $2) OR (et.section_id IS NULL AND et.grade_id = $3))
        AND ete.subject_id = $4
        AND ete.exam_date::date IN ($5::date, $6::date, $7::date)
      ORDER BY
        CASE
          WHEN ete.exam_date::date = $6::date THEN 0
          ELSE 1
        END,
        ete.start_time ASC
      LIMIT 1
      `,
      [
        assignment.academic_year_id,
        assignment.section_id,
        assignment.grade_id,
        assignment.subject_id,
        yesterday,
        today,
        tomorrow,
        schoolId // $8
      ]
    );

    if (!examQ.rows.length) {
      return res.json({ matched: false });
    }

    const exam = examQ.rows[0];
    const mapped = mapExamTypeToContext(exam.exam_type);

    if (!mapped) {
      return res.json({ matched: false });
    }

    return res.json({
      matched: true,
      source_type: "exam_timetable_entry",
      source_id: exam.source_id,

      // للتوافق مع الواجهة القديمة
      type: mapped.legacy_type,
      legacy_type: mapped.legacy_type,

      // للشكل الجديد
      canonical_type: mapped.canonical_type,
      exam_kind: mapped.exam_kind,
      sequence_no: mapped.sequence_no,

      mode: "in_class",
      max_score: mapped.max_score,
      starts_at: `${today}T${exam.start_time}`,
      message: "تم اكتشاف اختبار رسمي لهذا النطاق.",
    });
  } catch (e) {
    console.error("getOfficialAssessmentContext error:", e);
    return res.status(500).json({ matched: false });
  }
}