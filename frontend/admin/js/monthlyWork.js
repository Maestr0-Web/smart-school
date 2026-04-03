/**
 * =================================================================
 * ملف: monthlyWork.js
 * الوظيفة: إدارة شاشة "تسجيل الأعمال الشهرية" الخاصة بالكنترول (الإدارة)
 * =================================================================
 */

// متغيرات عامة لحفظ حالة الشاشة
let currentAdminGrades = [];
let selectedAssessmentMaxScore = 0;
let currentMwAssessmentId = null;

// دالة الهيدرز (محلياً)
function authHeaders() {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
}

// 1️⃣ التهيئة الأولية: تُستدعى بمجرد فتح الشاشة (لجلب المراحل الدراسية)
async function initMonthlyWorkScreen() {
    await loadMwStages();
}

// ==========================================
// 🎯 دوال الفلاتر المترابطة (بنظام تفويض الأحداث للـ HTML الديناميكي)
// ==========================================

// جلب المراحل الدراسية
async function loadMwStages() {
    try {
        const res = await fetch(`${window.API_BASE}/stages`, { headers: authHeaders() });
        const result = await res.json();
        const stages = result.data || result; 
        
        const stageSelect = document.getElementById('mw-stage');
        stageSelect.innerHTML = '<option value="">اختر المرحلة...</option>';
        
        stages.forEach(stage => {
            stageSelect.innerHTML += `<option value="${stage.id}">${stage.name}</option>`;
        });
    } catch (error) {
        console.error("خطأ في جلب المراحل:", error);
    }
}

// مستمع لحدث تغيير القوائم (المرحلة، الصف)
document.addEventListener('change', async function(event) {
    
    // 1️⃣ إذا كان العنصر الذي تغير هو قائمة "المرحلة"
    if (event.target && event.target.id === 'mw-stage') {
        const stageId = event.target.value;
        const gradeSelect = document.getElementById('mw-grade');
        
        // تصفير القوائم التابعة
        gradeSelect.innerHTML = '<option value="">اختر الصف...</option>';
        document.getElementById('mw-section').innerHTML = '<option value="">اختر الشعبة...</option>';
        document.getElementById('mw-subject').innerHTML = '<option value="">اختر المادة...</option>';
        document.getElementById('assessment-selection-area').style.display = 'none';
        document.getElementById('grading-grid-area').style.display = 'none';

        if (!stageId) return;

        try {
            const res = await fetch(`${window.API_BASE}/grades?stage_id=${stageId}`, { headers: authHeaders() });
            const result = await res.json();
            const grades = result.data || result;

            grades.forEach(grade => {
                gradeSelect.innerHTML += `<option value="${grade.id}">${grade.name}</option>`;
            });
        } catch (error) {
            console.error("خطأ في جلب الصفوف:", error);
        }
    }

    // 2️⃣ إذا كان العنصر الذي تغير هو قائمة "الصف"
    else if (event.target && event.target.id === 'mw-grade') {
        const gradeId = event.target.value;
        const sectionSelect = document.getElementById('mw-section');
        const subjectSelect = document.getElementById('mw-subject');

        // تصفير الشعب والمواد
        sectionSelect.innerHTML = '<option value="">اختر الشعبة...</option>';
        subjectSelect.innerHTML = '<option value="">اختر المادة...</option>';

        if (!gradeId) return;

        try {
            // جلب الشعب
            const resSec = await fetch(`${window.API_BASE}/sections?grade_id=${gradeId}`, { headers: authHeaders() });
            const resultSec = await resSec.json();
            const sections = resultSec.data || resultSec;
            
            sections.forEach(sec => {
                sectionSelect.innerHTML += `<option value="${sec.id}">${sec.name}</option>`;
            });

            // جلب المواد (بالرابط الإداري الجديد)
            const resSub = await fetch(`${window.API_BASE}/admin-assessments/subjects-by-grade?grade_id=${gradeId}`, { 
                headers: authHeaders() 
            });
            const resultSub = await resSub.json();
            const subjects = resultSub.data || [];

            subjects.forEach(sub => {
                subjectSelect.innerHTML += `<option value="${sub.id}">${sub.name}</option>`;
            });
        } catch (error) {
            console.error("خطأ في جلب الشعب والمواد:", error);
        }
    }
});

// ==========================================
// 🎯 مستمع أحداث النقر للزراير (Event Delegation)
// ==========================================

document.addEventListener('click', function(event) {
    // التقاط ضغطة زر "جلب التقييمات"
    const fetchBtn = event.target.closest('#btn-fetch-assessments');
    if (fetchBtn) {
        event.preventDefault(); 
        fetchTeacherAssessments(); 
    }
});

// ==========================================
// 🎯 دوال التعامل مع التقييمات والدرجات
// ==========================================

// 1. جلب التقييمات (عند الضغط على زر "جلب التقييمات")
async function fetchTeacherAssessments() {
    const sectionId = document.getElementById('mw-section').value;
    const subjectId = document.getElementById('mw-subject').value;

    if (!sectionId || !subjectId) {
        alert("الرجاء اختيار الشعبة والمادة أولاً.");
        return;
    }

    try {
        // تم إصلاح الرابط هنا: إزالة /api الإضافية واستخدام window.API_BASE
        const res = await fetch(`${window.API_BASE}/admin-assessments?section_id=${sectionId}&subject_id=${subjectId}`, {
            headers: authHeaders()
        });
        
        // التحقق من أن الاستجابة صحيحة لتجنب خطأ الـ HTML
        if (!res.ok) throw new Error("المسار غير موجود في الباك إند (تأكد من ربط Routes)");
        
        const result = await res.json();

        if (result.success) {
            const assessmentSelect = document.getElementById('mw-assessment');
            assessmentSelect.innerHTML = '<option value="">اختر التقييم لاستعراض الدرجات...</option>';
            
            result.data.forEach(ass => {
                const option = document.createElement('option');
                option.value = ass.assessment_id;
                option.dataset.maxScore = ass.max_score;
                option.dataset.teacherName = ass.teacher_name;
                option.dataset.status = ass.status;
                
                // تمييز حالة التقييم
                const statusText = ass.status === 'published' ? 'مفتوح' : 'مغلق';
                option.textContent = `[${statusText}] - ${ass.title}`;
                
                assessmentSelect.appendChild(option);
            });

            document.getElementById('assessment-selection-area').style.display = 'block';
            document.getElementById('grading-grid-area').style.display = 'none';
        } else {
            alert(result.message || "لم يتم العثور على تقييمات.");
        }
    } catch (error) {
        console.error("خطأ في جلب التقييمات الإدارية:", error);
        alert("حدث خطأ أثناء الاتصال بالخادم. يرجى التأكد من مسارات الباك إند.");
    }
}

// 2. جلب الدرجات (عند اختيار تقييم معين من القائمة المنسدلة للتقييمات)
// أضفنا مستمع أحداث للقائمة المنسدلة للتقييمات ليقوم بجلب الدرجات تلقائياً عند تغييرها
document.addEventListener('change', function(event) {
    if (event.target && event.target.id === 'mw-assessment') {
        loadAssessmentGrades();
    }
});

async function loadAssessmentGrades() {
    const select = document.getElementById('mw-assessment');
    currentMwAssessmentId = select.value;
    const sectionId = document.getElementById('mw-section').value;

    if (!currentMwAssessmentId) {
        document.getElementById('grading-grid-area').style.display = 'none';
        return;
    }

    // إظهار معلومات التقييم (الدرجة العظمى واسم المنشئ)
    const selectedOption = select.options[select.selectedIndex];
    selectedAssessmentMaxScore = parseFloat(selectedOption.dataset.maxScore);
    
    document.getElementById('mw-max-score').textContent = selectedAssessmentMaxScore;
    document.getElementById('mw-teacher-name').textContent = selectedOption.dataset.teacherName || 'الإدارة';
    document.getElementById('assessment-info').style.display = 'block';

    try {
        // تم إصلاح الرابط هنا أيضاً
        const res = await fetch(`${window.API_BASE}/admin-assessments/${currentMwAssessmentId}/grades?section_id=${sectionId}`, {
            headers: authHeaders()
        });
        const result = await res.json();

        if (result.success) {
            currentAdminGrades = result.data;
            renderAdminGradingTable();
        }
    } catch (error) {
        console.error("خطأ في جلب الدرجات:", error);
        alert("حدث خطأ أثناء تحميل بيانات الطلاب.");
    }
}

// 3. رسم جدول الدرجات الإداري
function renderAdminGradingTable() {
    const tbody = document.getElementById('mw-grading-body');
    tbody.innerHTML = '';

    currentAdminGrades.forEach((student, index) => {
        const scoreVal = student.score !== null ? student.score : '';
        const feedVal = student.feedback || '';
        const graderName = student.grader_name || 'لم تُرصد بعد';
        
        // تلوين اسم الراصد: أزرق إذا كانت مرصودة، أحمر إذا لم تُرصد
        const graderColor = student.score !== null ? '#3b82f6' : '#ef4444';

        const tr = `
            <tr style="border-bottom: 1px solid rgba(255,255,255,0.05);">
                <td style="text-align: center; color: #94a3b8;">${index + 1}</td>
                <td style="font-weight: bold; color: #e2e8f0;">${student.full_name}</td>
                <td style="text-align: center;">
                    <input type="number" 
                           class="ta-input mw-score-input" 
                           style="width: 80px; text-align: center; font-weight: bold; background: rgba(0,0,0,0.2);"
                           data-student-id="${student.student_id}" 
                           data-old-score="${scoreVal}"
                           value="${scoreVal}" 
                           max="${selectedAssessmentMaxScore}" min="0" step="0.25">
                </td>
                <td>
                    <input type="text" 
                           class="ta-input mw-feed-input" 
                           style="width: 100%; background: rgba(0,0,0,0.2);"
                           data-student-id="${student.student_id}" 
                           value="${feedVal}" 
                           placeholder="ملاحظات إدارة الكنترول...">
                </td>
                <td style="text-align: center; font-size: 12px; color: ${graderColor};">
                    ${graderName}
                </td>
            </tr>
        `;
        tbody.insertAdjacentHTML('beforeend', tr);
    });

    document.getElementById('grading-grid-area').style.display = 'block';
    
    // مستمع أحداث Validation: يمنع المدير من إدخال درجة تفوق الدرجة العظمى
    document.querySelectorAll('.mw-score-input').forEach(input => {
        input.addEventListener('change', function() {
            const enteredValue = parseFloat(this.value);
            if(enteredValue > selectedAssessmentMaxScore) {
                alert(`عذراً، الدرجة العظمى المسموحة لهذا التقييم هي (${selectedAssessmentMaxScore})`);
                this.value = this.dataset.oldScore; // إرجاع القيمة القديمة لمنع الخطأ
            } else if (enteredValue < 0) {
                this.value = 0;
            }
        });
    });
}

// 4. حفظ واعتماد التعديلات (إرسال للباك إند)
async function saveAdminGradesOverrides() {
    if (!currentMwAssessmentId) return;

    const modifiedGrades = [];

    // التجميع الذكي: استخراج فقط الدرجات التي تغيرت لتخفيف الحمل على الخادم
    currentAdminGrades.forEach(student => {
        const scoreInput = document.querySelector(`.mw-score-input[data-student-id="${student.student_id}"]`);
        const feedInput = document.querySelector(`.mw-feed-input[data-student-id="${student.student_id}"]`);
        
        if(scoreInput && scoreInput.value !== "") {
            // هل تم التعديل على الدرجة أو الملاحظة مقارنة بما هو في القاعدة؟
            if(scoreInput.value !== scoreInput.dataset.oldScore || feedInput.value !== (student.feedback || '')) {
                modifiedGrades.push({
                    student_id: student.student_id,
                    score: parseFloat(scoreInput.value),
                    feedback: feedInput.value
                });
            }
        }
    });

    if (modifiedGrades.length === 0) {
        alert("لم يتم إجراء أي تعديلات للحفظ.");
        return;
    }

    if(confirm(`هل أنت متأكد من اعتماد وحفظ التعديلات لعدد (${modifiedGrades.length}) طالب؟ سيتم توثيق هذا الإجراء أمنياً.`)) {
        try {
            // تم إصلاح الرابط هنا أيضاً
            const res = await fetch(`${window.API_BASE}/admin-assessments/${currentMwAssessmentId}/bulk-override`, {
                method: 'POST',
                headers: { ...authHeaders(), 'Content-Type': 'application/json' },
                body: JSON.stringify({ gradesList: modifiedGrades })
            });
            
            const result = await res.json();
            
            if(result.success) {
                alert(result.message);
                // إعادة جلب البيانات لتحديث واجهة المستخدم والحالة القديمة (old-score)
                loadAssessmentGrades(); 
            } else {
                alert("حدث خطأ: " + result.message);
            }
        } catch (error) {
            console.error("خطأ في إرسال التعديلات:", error);
            alert("حدث خطأ في الاتصال بالخادم.");
        }
    }
}