// ===============================
// RBAC Filters (Search in Tables)
// ===============================
window.RBAC_filters = {
  filter(input, tbodyId) {
    const q = (input.value || "").toLowerCase();
    const tbody = document.getElementById(tbodyId);
    if (!tbody) return;

    tbody.querySelectorAll("tr").forEach((tr) => {
      tr.style.display = tr.innerText.toLowerCase().includes(q) ? "" : "none";
    });
  },
};

// ===============================
// UserUI - واجهة إدارة المستخدمين
// ===============================
window.UserUI = {
  modalEl: null,
  formEl: null,
  titleEl: null,
  countBadge: null,

  // تهيئة العناصر من الـ DOM
  init() {
    this.modalEl = document.getElementById("user-modal");
    this.formEl = document.getElementById("rbac-user-form");
    this.titleEl = document.getElementById("user-modal-title");
    this.countBadge = document.getElementById("users-count-badge");

    // إغلاق بالمفتاح Esc
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.close();
      }
    });

    // لو RBAC كان جاهز ومحمّل مستخدمين، حدّث العداد الآن
    if (window.RBAC && Array.isArray(window.RBAC.users)) {
      this.updateCount(window.RBAC.users.length);
    }
  },

  // تأكيد أن العناصر مقروءة من الـ DOM
  ensureInit() {
    if (!this.modalEl || !this.formEl || !this.titleEl) {
      this.init();
    }
  },

  // فتح لإنشاء مستخدم جديد (زر: مستخدم جديد)
  openCreate() {
    this.ensureInit();
    if (!this.modalEl || !this.formEl) return;

    this.formEl.reset();
    const idInput = document.getElementById("user-id");
    if (idInput) idInput.value = "";

    if (this.titleEl) this.titleEl.textContent = "مستخدم جديد";
    this.modalEl.classList.add("is-open");
  },

  // فتح لتعديل مستخدم (يُستدعى بعد ما JS يملأ الحقول)
  openEdit() {
    this.ensureInit();
    if (!this.modalEl) return;

    if (this.titleEl) this.titleEl.textContent = "تعديل مستخدم";
    this.modalEl.classList.add("is-open");
  },

  // إغلاق المودال
  close() {
    this.ensureInit();
    if (!this.modalEl) return;
    this.modalEl.classList.remove("is-open");
  },

  // بحث داخل جدول المستخدمين
  search(query) {
    const tbody = document.getElementById("rbac-users-tbody");
    if (!tbody) return;

    const q = (query || "").toLowerCase();
    tbody.querySelectorAll("tr").forEach((tr) => {
      const text = tr.innerText.toLowerCase();
      tr.style.display = text.includes(q) ? "" : "none";
    });
  },

  // 🔢 تحديث عدّاد المستخدمين (يُستدعى من RBAC.loadUsers)
  updateCount(count) {
    // حاول تأخذ العنصر لو مش محفوظ
    if (!this.countBadge) {
      this.countBadge = document.getElementById("users-count-badge");
    }
    if (!this.countBadge) {
      return;
    }

    const n = Number(count || 0);
    let text;

    if (n === 0) {
      text = "لا يوجد مستخدمون";
    } else if (n === 1) {
      text = "مستخدم واحد";
    } else if (n === 2) {
      text = "مستخدمان";
    } else if (n <= 10) {
      text = `${n} مستخدمين`;
    } else {
      text = `${n} مستخدم`;
    }

    this.countBadge.textContent = text;
  },
};

// تشغيل init بعد تحميل الصفحة بالكامل
document.addEventListener("DOMContentLoaded", () => {
  if (window.UserUI && typeof window.UserUI.init === "function") {
    window.UserUI.init();
  }
});

// ===============================
// Idle Auto Logout System
// ===============================
const IDLE_LIMIT = 15 * 60 * 1000; // 15 دقيقة
let idleTimer;

function logoutDueToIdle() {
  alert("تم تسجيل خروجك بسبب عدم النشاط");
  localStorage.removeItem("token");
  localStorage.removeItem("user");
  window.location.href = "/frontend/login/login.html";
}

function resetIdleTimer() {
  clearTimeout(idleTimer);
  idleTimer = setTimeout(logoutDueToIdle, IDLE_LIMIT);
}

["mousemove", "keydown", "click", "scroll"].forEach((evt) => {
  document.addEventListener(evt, resetIdleTimer);
});

resetIdleTimer();
