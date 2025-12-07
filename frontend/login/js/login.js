console.log("login.js loaded");

// 🔧 نحدد إذا كنا على Render أو على جهازك (محلي)
const IS_RENDER = location.hostname.includes("onrender.com");

// 🧭 دالة تعطيك المسار الصحيح حسب البيئة
function frontPath(type) {
  // على Render جذر الموقع هو / (الفرونت داخل frontend لكن نشرته كجذر)
  // محليًا غالبًا تفتح من جذر المشروع، فيكون عندك /frontend/...
  const base = IS_RENDER ? "" : "/frontend";

  if (type === "admin") return `${base}/admin/index.html`;
  if (type === "teacher") return `${base}/teacher/index.html`;
  if (type === "student") return `${base}/student/index.html`;
  if (type === "parent") return `${base}/parent/index.html`;
  if (type === "login") return `${base}/login/login.html`;
  return `${base}/admin/index.html`;
}

// ✅ لو المستخدم مسجل دخول من قبل، نوجّهه مباشرة للوحة التحكم
(function autoRedirectIfLoggedIn() {
  try {
    const token = localStorage.getItem("token");
    const userStr = localStorage.getItem("user");
    if (!token || !userStr) return;

    const user = JSON.parse(userStr);
    const roleRaw =
      user && (user.role || user.role_name || user.roleName || "");
    const role = String(roleRaw).toLowerCase();

    if (!role) return;

    if (role.includes("admin")) {
      window.location.href = frontPath("admin");
    } else if (role.includes("teacher")) {
      window.location.href = frontPath("teacher");
    } else if (role.includes("student")) {
      window.location.href = frontPath("student");
    } else if (role.includes("parent")) {
      window.location.href = frontPath("parent");
    }
  } catch (e) {
    console.warn("Error reading stored user:", e);
  }
})();

// عناصر الـ DOM
const loginBtn = document.getElementById("login-btn");
const usernameError = document.getElementById("username-error");
const passwordError = document.getElementById("password-error");
const usernameInput = document.getElementById("username");
const passwordInput = document.getElementById("password");

// دالة مريحة لتشغيل تسجيل الدخول
function triggerLogin() {
  if (loginBtn) loginBtn.click();
}

// أحداث الكيبورد في الحقول
if (usernameInput && passwordInput) {
  usernameInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      triggerLogin();
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      passwordInput.focus();
    }
  });

  passwordInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      triggerLogin();
    }
    if (e.key === "ArrowUp") {
      e.preventDefault();
      usernameInput.focus();
    }
  });
}

// 🔗 عنوان الـ API على Render (بدون تكرار /api)
const API_BASE = "https://smart-school-backend-olz8.onrender.com/api";

if (!loginBtn) {
  console.error("login button not found (id=login-btn)");
} else {
  loginBtn.addEventListener("click", async (e) => {
    e.preventDefault();

    // تنظيف الأخطاء
    if (usernameError) {
      usernameError.textContent = "";
      usernameError.style.display = "none";
    }
    if (passwordError) {
      passwordError.textContent = "";
      passwordError.style.display = "none";
    }

    const email = usernameInput ? usernameInput.value.trim() : "";
    const password = passwordInput ? passwordInput.value.trim() : "";

    let hasError = false;

    if (!email) {
      if (usernameError) {
        usernameError.textContent = "يرجى إدخال البريد الإلكتروني";
        usernameError.style.display = "block";
      }
      hasError = true;
    }
    if (!password) {
      if (passwordError) {
        passwordError.textContent = "يرجى إدخال كلمة المرور";
        passwordError.style.display = "block";
      }
      hasError = true;
    }
    if (hasError) return;

    // حالة تحميل للزر
    const originalBtnContent = loginBtn.innerHTML;
    loginBtn.innerHTML = '<span class="btn-text">جاري الدخول...</span>';
    loginBtn.style.opacity = "0.7";
    loginBtn.disabled = true;

    try {
      const url = `${API_BASE}/auth/login`; // ✅ هنا أصلحنا /api/api
      console.log("POST", url, { email });

      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      console.log("response status", res.status);

      const text = await res.text();
      let data = null;
      try {
        data = text ? JSON.parse(text) : null;
      } catch {
        console.warn("Response is not valid JSON, raw:", text);
      }

      if (!res.ok) {
        const errorMsg =
          (data && (data.message || data.error)) ||
          "فشل تسجيل الدخول، تأكد من البيانات.";

        if (errorMsg.includes("كلمة المرور")) {
          if (passwordError) {
            passwordError.textContent = errorMsg;
            passwordError.style.display = "block";
          }
        } else {
          if (usernameError) {
            usernameError.textContent = errorMsg;
            usernameError.style.display = "block";
          }
        }
        return;
      }

      if (!data || !data.token || !data.user) {
        if (usernameError) {
          usernameError.textContent = "استجابة غير متوقعة من الخادم.";
          usernameError.style.display = "block";
        }
        return;
      }

      // ✅ نجاح الدخول
      localStorage.setItem("token", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));

      const roleRaw =
        data.user &&
        (data.user.role || data.user.role_name || data.user.roleName || "");
      const role = String(roleRaw).toLowerCase();
      console.log("Resolved role:", roleRaw, "->", role);

      if (role.includes("admin")) {
        window.location.href = frontPath("admin");
      } else if (role.includes("teacher")) {
        window.location.href = frontPath("teacher");
      } else if (role.includes("student")) {
        window.location.href = frontPath("student");
      } else if (role.includes("parent")) {
        window.location.href = frontPath("parent");
      } else {
        window.location.href = frontPath("admin");
      }
    } catch (err) {
      console.error("Login error:", err);
      if (passwordError) {
        passwordError.textContent =
          "خطأ في الاتصال بالخادم، يرجى المحاولة لاحقًا.";
        passwordError.style.display = "block";
      }
    } finally {
      loginBtn.innerHTML = originalBtnContent;
      loginBtn.style.opacity = "1";
      loginBtn.disabled = false;
    }
  });
}
