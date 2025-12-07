// frontend/admin/js/admin.js (النسخة الموحّدة)
console.log("admin.js loaded");

// ==============================
// إعدادات عامة / ثوابت
// ==============================
const API_BASE = "https://smart-school-backend-olz8.onrender.com/api";
const THEME_KEY = "smart_school_theme";

let currentUser = null;
window.USER_PERMISSIONS = [];

// ==============================
// 🛡 حماية لوحة الأدمن + تعبئة بيانات المستخدم
// ==============================
(function authGuard() {
  const token = localStorage.getItem("token");
  const userStr = localStorage.getItem("user");

  if (!token || !userStr) {
    window.location.href = "/frontend/login/login.html";
    return;
  }

  try {
    currentUser = JSON.parse(userStr);

    const name =
      currentUser.name ||
      currentUser.full_name ||
      currentUser.username ||
      "مستخدم";

    const email = currentUser.email || "";
    const role =
      currentUser.role || currentUser.role_name || currentUser.roleName || "";

    // ⭐️ أهم تعديل: لو عندي صلاحيات داخل الـ user استخدمها مباشرة
    if (Array.isArray(currentUser.permissions)) {
      window.USER_PERMISSIONS = currentUser.permissions;
      console.log(
        "Loaded permissions from localStorage user:",
        window.USER_PERMISSIONS
      );
    }

    // عناصر النافبار
    const usernameEl = document.getElementById("navbar-username");
    const roleEl = document.getElementById("navbar-role");
    const avatarLetter = document.getElementById("navbar-avatar-letter");

    if (usernameEl) usernameEl.textContent = name;
    if (roleEl) roleEl.textContent = role || "حساب إداري";
    if (avatarLetter) avatarLetter.textContent = name.charAt(0) || "أ";

    // إيميل في فورم تغيير البريد
    const currentEmailInput = document.getElementById("currentEmail");
    if (currentEmailInput && email) currentEmailInput.value = email;

    // تعبئة مودال الملف الشخصي (لو موجود)
    const profileName = document.getElementById("profile-name");
    const profileEmail = document.getElementById("profile-email");
    const profileRole = document.getElementById("profile-role");

    if (profileName) profileName.textContent = name;
    if (profileEmail && email) profileEmail.textContent = email;
    if (profileRole) profileRole.textContent = role || "حساب إداري";
  } catch (e) {
    console.warn("Cannot parse stored user:", e);
  }
})();

// ==============================
// ⏰ الساعة الديناميكية (clock-time / clock-date)
// ==============================
function initClock() {
  const timeEl = document.getElementById("clock-time");
  const dateEl = document.getElementById("clock-date");

  if (!timeEl || !dateEl) return;

  function pad(n) {
    return n < 10 ? "0" + n : "" + n;
  }

  function tick() {
    const now = new Date();
    const h = pad(now.getHours());
    const m = pad(now.getMinutes());
    const s = pad(now.getSeconds());
    timeEl.textContent = `${h}:${m}:${s}`;

    const d = pad(now.getDate());
    const mo = pad(now.getMonth() + 1);
    const y = now.getFullYear();
    dateEl.textContent = `${d}/${mo}/${y}`;
  }

  tick();
  setInterval(tick, 1000);
}

// ==============================
// 📂 تحميل صفحات المحتوى (partials) من مجلد pages
// ==============================
function getPageContainer() {
  const screenPageContent = document.getElementById("screen-page-content");
  if (screenPageContent) return screenPageContent;

  const contentEl = document.getElementById("content");
  if (contentEl) return contentEl;

  return null;
}

const PAGE_NORMALIZE_MAP = {
  "users-manage": "rbac-users",
  "roles-manage": "rbac-roles",
  "permissions-manage": "rbac-permissions",
  "modules-manage": "rbac-modules",
};

const PAGE_FILE_MAP = {
  dashboard: "dashboard",

  "rbac-users": "users/rbac-users",
  "rbac-roles": "users/rbac-roles",
  "rbac-permissions": "users/rbac-permissions",
  "rbac-modules": "users/rbac-modules",

  studentsList: "studentsList",
  studentRegister: "studentRegister",
  studentRenew: "studentRenew",
  staffRegister: "staffRegister",
  assignTeachers: "assignTeachers",
  weeklySchedule: "weeklySchedule",
  examSchedule: "examSchedule",
  monthlyWork: "monthlyWork",
  monthlyReports: "monthlyReports",
  termWork: "termWork",
  termReports: "termReports",
  termResults: "termResults",
  yearResults: "yearResults",
  createNotify: "createNotify",
  notifyLog: "notifyLog",
  inbox: "inbox",
  barcodeAttendance: "barcodeAttendance",
  manualAttendance: "manualAttendance",
  attendanceReports: "attendanceReports",
  feesPay: "feesPay",
  feesReports: "feesReports",
  studentData: "studentData",
  staffData: "staffData",
  termGrades: "termGrades",
  finalGrades: "finalGrades",
  studentStats: "studentStats",
};

window.loadPage = async function (pageKey) {
  const container = getPageContainer();
  if (!container) {
    console.warn("لا يوجد حاوية لعرض الصفحات (screen-page-content أو content).");
    return;
  }

  const normalizedKey = PAGE_NORMALIZE_MAP[pageKey] || pageKey;
  const fileKey = PAGE_FILE_MAP[normalizedKey] || normalizedKey;

  const url = `pages/${fileKey}.html`;
  container.innerHTML = `<p style="padding:1rem;">جاري تحميل المحتوى...</p>`;

  try {
    const res = await fetch(url, { cache: "no-store" });

    if (!res.ok) {
      container.innerHTML = `
        <div style="padding:1rem; color:#c00; text-align:center;">
          <h3>تعذر تحميل الصفحة</h3>
          <p>الملف: <code>${url}</code></p>
          <p>تأكد أنك أنشأت هذا الملف داخل مجلد <code>frontend/admin/pages</code>.</p>
        </div>
      `;
      return;
    }

    const html = await res.text();
    container.innerHTML = html;

    if (window.RBAC_tabs) {
      window.RBAC_tabs.activateByPage(normalizedKey);
    }

    if (window.RBAC && typeof window.RBAC.onPageLoaded === "function") {
      window.RBAC.onPageLoaded(normalizedKey);
    }

    window.scrollTo(0, 0);
  } catch (err) {
    console.error("Error loading page:", err);
    container.innerHTML = `
      <p style="padding:1rem; color:#c00; text-align:center;">
        حدث خطأ أثناء تحميل المحتوى.
      </p>
    `;
  }
};

// تبويبات RBAC
window.RBAC_tabs = {
  open(el, pageKey) {
    if (event && event.preventDefault) {
      event.preventDefault();
    }

    loadPage(pageKey);

    document
      .querySelectorAll(".rbac-tabs .tab-link")
      .forEach((a) => a.classList.remove("active"));

    if (el) el.classList.add("active");
  },

  activateByPage(pageKey) {
    document.querySelectorAll(".rbac-tabs .tab-link").forEach((a) => {
      if (a.dataset.tab === pageKey) {
        a.classList.add("active");
      } else {
        a.classList.remove("active");
      }
    });
  },
};

// ==============================
// 🛡 نظام الصلاحيات لإخفاء العناصر
// ==============================
function hasPermission(code) {
  if (!Array.isArray(window.USER_PERMISSIONS)) return false;
  return window.USER_PERMISSIONS.includes(code);
}

function hasAnyPermission(codes) {
  if (!Array.isArray(window.USER_PERMISSIONS)) return false;
  return codes.some((c) => window.USER_PERMISSIONS.includes(c));
}

function applyMenuPermissions() {
  document.querySelectorAll("[data-permission]").forEach((el) => {
    const perm = el.getAttribute("data-permission");
    if (!perm) return;
    el.style.display = hasPermission(perm) ? "" : "none";
  });

  document.querySelectorAll("[data-any-permission]").forEach((el) => {
    const raw = el.getAttribute("data-any-permission") || "";
    const perms = raw
      .split(",")
      .map((p) => p.trim())
      .filter(Boolean);

    if (!perms.length) return;
    el.style.display = hasAnyPermission(perms) ? "" : "none";
  });
}

// ⭐️ نستخدم الـ API فقط إذا ما وجدنا صلاحيات في الـ user
async function fetchMenuPermissions() {
  const token = localStorage.getItem("token");
  if (!token) {
    window.USER_PERMISSIONS = [];
    applyMenuPermissions();
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/users/me/menu-permissions`, {
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    if (!res.ok) {
      console.warn("menu-permissions error:", res.status);
      return; // لا نلمس الصلاحيات الحالية، فقط نطبع الخطأ
    }

    const data = await res.json();
    window.USER_PERMISSIONS = Array.isArray(data.permissions)
      ? data.permissions
      : [];

    applyMenuPermissions();
  } catch (err) {
    console.warn("Failed to load menu permissions:", err);
  }
}

// ==============================
// 🎛 واجهة الداشبورد الجديدة (شاشات + ثيم + مودالات)
// ==============================
(function () {
  function $(selector) {
    return document.querySelector(selector);
  }

  function $all(selector) {
    return document.querySelectorAll(selector);
  }

  // 🔧 دالة مساعدة لطلبات تغيير الباسورد/الإيميل
  async function profileApiRequest(subPath, payload) {
    const token = localStorage.getItem("token");
    const headers = { "Content-Type": "application/json" };
    if (token) headers.Authorization = `Bearer ${token}`;

    try {
      const res = await fetch(`${API_BASE}/profile${subPath}`, {
        method: "PUT",
        headers,
        body: JSON.stringify(payload),
      });

      if (res.status === 401) {
        let msg = "تم انتهاء الجلسة، الرجاء تسجيل الدخول من جديد";
        try {
          const txt = await res.text();
          try {
            const json = JSON.parse(txt);
            msg = json.message || msg;
          } catch (_) {
            if (txt && txt.trim()) msg = txt;
          }
        } catch (_) {}

        alert(msg);
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = "/frontend/login/login.html";
        return null;
      }

      const txt = await res.text();

      if (!res.ok) {
        let msg = "حدث خطأ في الخادم";
        try {
          const json = JSON.parse(txt);
          msg = json.message || msg;
        } catch (_) {}
        throw new Error(msg);
      }

      if (!txt) return null;
      try {
        return JSON.parse(txt);
      } catch (_) {
        return null;
      }
    } catch (err) {
      console.error("Profile API error:", err);
      alert(`خطأ: ${err.message}`);
      throw err;
    }
  }

  /* =========================
     تبديل الشاشات
  ========================== */
  function switchScreen(targetId) {
    const screens = $all(".screen");
    const navButtons = $all(".bottom-item[data-target]");

    screens.forEach((screen) => {
      screen.classList.toggle("is-active", screen.id === targetId);
    });

    navButtons.forEach((btn) => {
      const target = btn.getAttribute("data-target");
      btn.classList.toggle("bottom-item--active", target === targetId);
    });

    if (window.Dashboard) {
      window.Dashboard.currentScreenId = targetId;
    }
  }

  window.Dashboard = {
    currentScreenId: "screen-dashboard",
    previousScreenId: null,

    switchScreen,

    openPage(pageKey, title) {
      const pageScreen = document.getElementById("screen-page");
      const pageTitleEl = document.getElementById("screen-page-title");

      if (pageScreen && pageTitleEl && getPageContainer()) {
        this.previousScreenId = this.currentScreenId || "screen-dashboard";
        pageTitleEl.textContent = title || this.mapPageTitle(pageKey);
        switchScreen("screen-page");
        loadPage(pageKey);
        return;
      }

      if (getPageContainer()) {
        loadPage(pageKey);
        return;
      }

      console.log("فتح صفحة:", pageKey);
      alert("سيتم لاحقًا ربط هذا الخيار بصفحة: " + pageKey);
    },

    backFromPage() {
      const prev = this.previousScreenId || "screen-dashboard";
      switchScreen(prev);
    },

    mapPageTitle(pageKey) {
      const map = {
        studentsList: "عرض الطلاب",
        studentRegister: "تسجيل طالب جديد",
        studentRenew: "تسجيل المستمرين",
        staffRegister: "تسجيل الموظفين",
        assignTeachers: "تعيين المدرسين",
        weeklySchedule: "جداول الحصص الأسبوعية",
        examSchedule: "جداول الامتحانات",
        barcodeAttendance: "تسجيل الحضور باركود",
        manualAttendance: "تسجيل الحضور يدويًا",
        attendanceReports: "تقارير الحضور",
        feesPay: "سداد الرسوم",
        feesReports: "تقارير الرسوم",
        studentData: "بيانات الطلاب",
        staffData: "بيانات الموظفين",
        termGrades: "تقارير الدرجات الفصلية",
        finalGrades: "تقارير الدرجات النهائية",
        studentStats: "إحصائيات الطلاب",
        "rbac-users": "المستخدمون",
        "rbac-roles": "الأدوار",
        "rbac-permissions": "الصلاحيات",
        "rbac-modules": "الوحدات (Modules)",
      };
      return map[pageKey] || "تفاصيل";
    },
  };

  /* =========================
     الشريط السفلي
  ========================== */
  function initBottomNav() {
    $all(".bottom-item[data-target]").forEach((btn) => {
      if (btn.classList.contains("bottom-item--menu")) return;

      btn.addEventListener("click", () => {
        const targetId = btn.getAttribute("data-target");
        switchScreen(targetId);
      });
    });

    const backBtn = document.getElementById("screen-page-back");
    if (backBtn) {
      backBtn.addEventListener("click", () => {
        window.Dashboard.backFromPage();
      });
    }
  }

  /* =========================
     شيت القائمة الرئيسية
  ========================== */
  function initMainMenuSheet() {
    const sheet = $("#main-menu-sheet");
    const openBtn = $("#main-menu-button");
    const closeBtn = $("#main-menu-close");

    if (!sheet || !openBtn || !closeBtn) return;

    function openSheet() {
      sheet.classList.add("is-open");
    }

    function closeSheet() {
      sheet.classList.remove("is-open");
    }

    openBtn.addEventListener("click", openSheet);
    closeBtn.addEventListener("click", closeSheet);

    sheet.addEventListener("click", (e) => {
      if (e.target === sheet) closeSheet();
    });

    sheet.querySelectorAll(".sheet-item[data-target]").forEach((item) => {
      item.addEventListener("click", () => {
        const targetId = item.getAttribute("data-target");
        switchScreen(targetId);
        closeSheet();
      });
    });
  }

  /* =========================
     منيو الحساب + المودالات
  ========================== */
  function initAccountMenu() {
    const toggle = $("#account-menu-toggle");
    const dropdown = $("#account-dropdown");

    if (!toggle || !dropdown) return;

    toggle.addEventListener("click", (e) => {
      e.stopPropagation();
      dropdown.classList.toggle("is-open");
    });

    document.addEventListener("click", (e) => {
      if (!dropdown.contains(e.target) && !toggle.contains(e.target)) {
        dropdown.classList.remove("is-open");
      }
    });
  }

  function initModals() {
    const overlay = $("#modal-overlay");
    const profileModal = $("#profile-modal");
    const changePasswordModal = $("#change-password-modal");
    const changeEmailModal = $("#change-email-modal");

    if (!overlay) return;

    function openModal(modal) {
      if (!modal) return;
      overlay.classList.add("is-visible");
      modal.classList.add("is-visible");
    }

    function closeAllModals() {
      overlay.classList.remove("is-visible");
      [profileModal, changePasswordModal, changeEmailModal].forEach((m) => {
        if (m) m.classList.remove("is-visible");
      });
    }

    const openProfile = $("#open-profile-modal");
    const openPassword = $("#open-change-password-modal");
    const openEmail = $("#open-change-email-modal");

    if (openProfile && profileModal) {
      openProfile.addEventListener("click", () => {
        if (currentUser) {
          const name =
            currentUser.name ||
            currentUser.full_name ||
            currentUser.username ||
            "مستخدم";
          const email = currentUser.email || "-";
          const role =
            currentUser.role ||
            currentUser.role_name ||
            currentUser.roleName ||
            "-";
          const pn = document.getElementById("profile-name");
          const pe = document.getElementById("profile-email");
          const pr = document.getElementById("profile-role");
          if (pn) pn.textContent = name;
          if (pe) pe.textContent = email;
          if (pr) pr.textContent = role;
        }
        openModal(profileModal);
      });
    }
    if (openPassword && changePasswordModal) {
      openPassword.addEventListener("click", () =>
        openModal(changePasswordModal)
      );
    }
    if (openEmail && changeEmailModal) {
      openEmail.addEventListener("click", () => openModal(changeEmailModal));
    }

    const openProfileCard = $("#open-profile-modal-card");
    const openPasswordCard = $("#open-change-password-modal-card");
    const openEmailCard = $("#open-change-email-modal-card");

    if (openProfileCard && profileModal) {
      openProfileCard.addEventListener("click", () => openModal(profileModal));
    }
    if (openPasswordCard && changePasswordModal) {
      openPasswordCard.addEventListener("click", () =>
        openModal(changePasswordModal)
      );
    }
    if (openEmailCard && changeEmailModal) {
      openEmailCard.addEventListener("click", () =>
        openModal(changeEmailModal)
      );
    }

    document.querySelectorAll("[data-close-modal]").forEach((btn) => {
      btn.addEventListener("click", closeAllModals);
    });

    overlay.addEventListener("click", closeAllModals);

    // 🔑 تغيير كلمة المرور (اتصال حقيقي بالـ API)
    const changePasswordForm = $("#changePasswordForm");
    if (changePasswordForm) {
      changePasswordForm.addEventListener("submit", async (e) => {
        e.preventDefault();

        const current = $("#currentPassword")?.value.trim();
        const np = $("#newPassword")?.value.trim();
        const cp = $("#confirmNewPassword")?.value.trim();

        if (!current || !np || !cp) {
          alert("الرجاء تعبئة جميع الحقول.");
          return;
        }
        if (np !== cp) {
          alert("كلمة المرور الجديدة وتأكيدها غير متطابقتين.");
          return;
        }
        if (np.length < 6) {
          alert("يفضل أن تكون كلمة المرور 6 أحرف/أرقام على الأقل.");
          return;
        }

        try {
          await profileApiRequest("/change-password", {
            currentPassword: current,
            newPassword: np,
          });

          alert("✅ تم تغيير كلمة المرور بنجاح، سيتم تسجيل خروجك الآن.");
          changePasswordForm.reset();
          closeAllModals();

          // تسجيل خروج محلي
          localStorage.removeItem("token");
          localStorage.removeItem("user");
          window.location.href = "/frontend/login/login.html";
        } catch (err) {
          // الخطأ تم عرضه داخل profileApiRequest
        }
      });
    }

    // 📧 تغيير البريد الإلكتروني (اتصال حقيقي بالـ API)
    const changeEmailForm = $("#changeEmailForm");
    if (changeEmailForm) {
      changeEmailForm.addEventListener("submit", async (e) => {
        e.preventDefault();

        let newEmail = $("#newEmail")?.value.trim();

        if (!newEmail) {
          alert("الرجاء إدخال بريد جديد.");
          return;
        }

        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(newEmail)) {
          alert("صيغة البريد الإلكتروني غير صحيحة.");
          return;
        }

        try {
          const data = await profileApiRequest("/change-email", { newEmail });

          if (data && data.email) {
            newEmail = data.email;
          }

          alert("✅ تم تحديث البريد الإلكتروني بنجاح.");

          // تحديث localStorage.user
          try {
            const userStr = localStorage.getItem("user");
            const oldUser = userStr ? JSON.parse(userStr) : {};
            const updatedUser = { ...oldUser, email: newEmail };
            localStorage.setItem("user", JSON.stringify(updatedUser));
            currentUser = updatedUser;
          } catch (_) {}

          // تحديث الحقل الحالي في المودال
          const currentEmailInput = document.getElementById("currentEmail");
          if (currentEmailInput) currentEmailInput.value = newEmail;

          changeEmailForm.reset();
          closeAllModals();
        } catch (err) {
          // الخطأ تم عرضه داخل profileApiRequest
        }
      });
    }

    const logoutBtn = document.getElementById("logout-btn");
    if (logoutBtn) {
      logoutBtn.addEventListener("click", () => {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = "/frontend/login/login.html";
      });
    }
  }

  /* =========================
     تبديل الثيم (نهاري / ليلي)
  ========================== */
  function applyTheme(theme) {
    const body = document.body;
    const themeBtn = $("#theme-toggle");
    const cardBtn = $("#theme-toggle-card");

    if (theme === "dark") {
      body.classList.add("theme-dark");
    } else {
      body.classList.remove("theme-dark");
    }

    if (themeBtn) {
      themeBtn.textContent = theme === "dark" ? "☀️" : "🌙";
    }
    if (cardBtn) {
      cardBtn.textContent = theme === "dark" ? "الوضع النهاري" : "الوضع الليلي";
    }
  }

  function initThemeToggle() {
    let initial = "light";

    try {
      const saved = localStorage.getItem(THEME_KEY);
      if (saved === "light" || saved === "dark") {
        initial = saved;
      }
    } catch (e) {}

    applyTheme(initial);

    function toggleTheme() {
      const isDark = document.body.classList.contains("theme-dark");
      const next = isDark ? "light" : "dark";
      applyTheme(next);
      try {
        localStorage.setItem(THEME_KEY, next);
      } catch (e) {}
    }

    const topBtn = $("#theme-toggle");
    const cardBtn = $("#theme-toggle-card");

    if (topBtn) topBtn.addEventListener("click", toggleTheme);
    if (cardBtn) cardBtn.addEventListener("click", toggleTheme);
  }

  /* =========================
     مركز الأوامر (بحث عام)
  ========================== */
  function initCommandCenter() {
    const input = document.getElementById("command-input");
    if (!input) return;

    // أوامر جاهزة (اختصارات)
    const COMMANDS = [
      {
        keywords: ["الطلاب", "عرض الطلاب", "قائمة الطلاب"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.openPage("studentsList", "عرض الطلاب");
          }
        },
      },
      {
        keywords: ["تسجيل طالب", "طالب جديد", "تسجيل الطلاب"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.openPage("studentRegister", "تسجيل طالب جديد");
          }
        },
      },
      {
        keywords: ["الرسوم", "سداد الرسوم", "المالية"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-fees");
          }
        },
      },
      {
        keywords: ["الحضور", "الغياب", "جداول الحصص", "الجدول"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-timetable");
          }
        },
      },
      {
        keywords: ["التقارير", "تقرير", "إحصاء", "إحصائيات"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-reports");
          }
        },
      },
      {
        keywords: ["مستخدم", "مستخدمين", "صلاحيات", "rbac", "الأدوار"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-rbac");
          }
        },
      },
      {
        keywords: ["الحساب", "البريد", "كلمة المرور", "الملف الشخصي"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-account");
          }
        },
      },
      {
        keywords: ["الرئيسية", "الصفحة الرئيسية", "dashboard", "home"],
        run() {
          if (window.Dashboard) {
            window.Dashboard.switchScreen("screen-dashboard");
          }
        },
      },
    ];

    function executeCommand(query) {
      const q = (query || "").trim().toLowerCase();
      if (!q) return;

      // 1) محاولة مطابقة الأوامر
      for (const cmd of COMMANDS) {
        const match = cmd.keywords.some((k) => {
          const kk = k.toLowerCase();
          return q.includes(kk) || kk.includes(q);
        });

        if (match) {
          cmd.run();
          return;
        }
      }

      // 2) بحث عام في النصوص داخل الشاشة الحالية
      const activeScreen =
        document.querySelector(".screen.is-active") || document;
      const elements = activeScreen.querySelectorAll("*");
      let foundEl = null;

      for (const el of elements) {
        if (el.children.length === 0) {
          const text = (el.textContent || "").trim().toLowerCase();
          if (text && text.includes(q)) {
            foundEl = el;
            break;
          }
        }
      }

      if (foundEl) {
        foundEl.scrollIntoView({ behavior: "smooth", block: "center" });
        foundEl.classList.add("search-hit");
        setTimeout(() => foundEl.classList.remove("search-hit"), 1500);
      } else {
        alert("لم يتم العثور على شيء يطابق: " + query);
      }
    }

    // تنفيذ الأمر عند الضغط على Enter
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        executeCommand(input.value);
        input.select();
      }
    });

    // اختصار Ctrl+K أو ⌘K للتركيز على حقل البحث
    document.addEventListener("keydown", (e) => {
      const isMac = navigator.platform.toUpperCase().includes("MAC");
      const hotkeyPressed =
        (!isMac && e.ctrlKey && e.key.toLowerCase() === "k") ||
        (isMac && e.metaKey && e.key.toLowerCase() === "k");

      if (hotkeyPressed) {
        e.preventDefault();
        input.focus();
        input.select();
      }
    });
  }

  /* =========================
     تهيئة عامة
  ========================== */
  document.addEventListener("DOMContentLoaded", () => {
    initBottomNav();
    initMainMenuSheet();
    initAccountMenu();
    initModals();
    initThemeToggle();
    initCommandCenter();
    initClock();

    // ⭐️ هنا نرجّع سلوك المشروع القديم:
    // لو عندي صلاحيات من الـ user → استخدمها مباشرة
    if (Array.isArray(window.USER_PERMISSIONS) && window.USER_PERMISSIONS.length) {
      applyMenuPermissions();
    } else {
      // لو ما في صلاحيات، نحاول نجيبها من الـ API
      fetchMenuPermissions();
    }

    switchScreen("screen-dashboard");
  });
})();
