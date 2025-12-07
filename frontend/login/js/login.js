console.log('login.js loaded');

// ✅ لو المستخدم مسجل دخول من قبل، نوجّهه مباشرة للوحة التحكم
(function autoRedirectIfLoggedIn() {
  try {
    const token = localStorage.getItem("token");
    const userStr = localStorage.getItem("user");
    if (!token || !userStr) return;

    const user = JSON.parse(userStr);
    const roleRaw = user && (user.role || user.role_name || user.roleName || '');
    const role = String(roleRaw).toLowerCase();

    if (!role) return;

    if (role.includes('admin')) {
      window.location.href = "/frontend/admin/index.html";
    } else if (role.includes('teacher')) {
      window.location.href = "/frontend/teacher/index.html";
    } else if (role.includes('student')) {
      window.location.href = "/frontend/student/index.html";
    } else if (role.includes('parent')) {
      window.location.href = "/frontend/parent/index.html";
    }
  } catch (e) {
    console.warn("Error reading stored user:", e);
  }
})();

const loginBtn = document.getElementById("login-btn");
const usernameError = document.getElementById("username-error");
const passwordError = document.getElementById("password-error");
// الحقول نفسها (الإيميل + كلمة المرور)
const usernameInput = document.getElementById("username");
const passwordInput = document.getElementById("password");

// دالة مريحة لتشغيل تسجيل الدخول
function triggerLogin() {
  if (loginBtn) {
    loginBtn.click(); // هذا يستدعي نفس الكود اللي كتبته للزر
  }
}

// لو العناصر موجودة نضيف لها الأحداث
if (usernameInput && passwordInput) {
  // 1) في حقل الإيميل
  usernameInput.addEventListener("keydown", (e) => {
    // Enter = تسجيل الدخول
    if (e.key === "Enter") {
      e.preventDefault();
      triggerLogin();
    }

    // سهم ↓ = انتقال لحقل كلمة المرور
    if (e.key === "ArrowDown") {
      e.preventDefault();
      passwordInput.focus();
    }
  });

  // 2) في حقل كلمة المرور
  passwordInput.addEventListener("keydown", (e) => {
    // Enter = تسجيل الدخول
    if (e.key === "Enter") {
      e.preventDefault();
      triggerLogin();
    }

    // (اختياري) سهم ↑ يرجع لحقل الإيميل
    if (e.key === "ArrowUp") {
      e.preventDefault();
      usernameInput.focus();
    }
  });
}

// ✅ هذا ثابت: الباك إند على المنفذ 5000
const API_BASE = "http://localhost:5000";

if (!loginBtn) {
  console.error('login button not found (id=login-btn)');
} else {
  loginBtn.addEventListener("click", async (e) => {
    e.preventDefault();

    // تنظيف الأخطاء
    if (usernameError) { 
      usernameError.textContent = ""; 
      usernameError.style.display = 'none'; 
    }
    if (passwordError) { 
      passwordError.textContent = ""; 
      passwordError.style.display = 'none'; 
    }

    const email = document.getElementById("username").value.trim();
    const password = document.getElementById("password").value.trim();

    let hasError = false;

    if (!email) {
      usernameError.textContent = "يرجى إدخال البريد الإلكتروني";
      usernameError.style.display = 'block';
      hasError = true;
    }
    if (!password) {
      passwordError.textContent = "يرجى إدخال كلمة المرور";
      passwordError.style.display = 'block';
      hasError = true;
    }
    if (hasError) return;

    // حالة تحميل للزر
    const originalBtnContent = loginBtn.innerHTML;
    loginBtn.innerHTML = '<span class="btn-text">جاري الدخول...</span>';
    loginBtn.style.opacity = "0.7";
    loginBtn.disabled = true;

    try {
      const url = `${API_BASE}/api/auth/login`;
      console.log('POST', url, { email });

      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ email, password })
      });

      console.log('response status', res.status);
      const data = await res.json();
      console.log('response body', data);

      if (!res.ok) {
        const errorMsg = data.message || data.error || "فشل تسجيل الدخول";

        if (errorMsg.includes("كلمة المرور")) {
          if (passwordError) { 
            passwordError.textContent = errorMsg; 
            passwordError.style.display = 'block'; 
          }
        } else {
          if (usernameError) { 
            usernameError.textContent = errorMsg; 
            usernameError.style.display = 'block'; 
          }
        }
        return;
      }

      // ✅ نجاح الدخول
      localStorage.setItem("token", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));

      // نقرأ الدور من الرد
      const roleRaw = data.user && (data.user.role || data.user.role_name || data.user.roleName || '');
      const role = String(roleRaw).toLowerCase();
      console.log('Resolved role:', roleRaw, '->', role);

      // ✅ التوجيه إلى واجهات الفرونت إند (على Live Server)
      // لاحظ المسارات: كلها داخل مجلد frontend
      if (role.includes('admin')) {
        window.location.href = "/frontend/admin/index.html";
      } else if (role.includes('teacher')) {
        window.location.href = "/frontend/teacher/index.html";
      } else if (role.includes('student')) {
        window.location.href = "/frontend/student/index.html";
      } else if (role.includes('parent')) {
        window.location.href = "/frontend/parent/index.html";
      } else {
        // في حالة دور غير معروف نرسل المدير
        window.location.href = "/frontend/admin/index.html";
      }

    } catch (err) {
      console.error(err);
      if (passwordError) {
        passwordError.textContent = "خطأ في الاتصال بالسيرفر، تأكد من تشغيله (port 5000).";
        passwordError.style.display = 'block';
      }
    } finally {
      loginBtn.innerHTML = originalBtnContent;
      loginBtn.style.opacity = "1";
      loginBtn.disabled = false;
    }
  });
}
