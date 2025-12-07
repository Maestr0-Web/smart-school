// frontend/login/js/auth-guard.js
console.log("auth-guard.js loaded");

// دالة مساعدة ترجع رابط لوحة التحكم حسب الدور
function resolveDashboardUrl(roleRaw) {
  const role = String(roleRaw || "").toLowerCase();

  if (role.includes("admin")) {
    return "/frontend/admin/index.html";
  } else if (role.includes("teacher")) {
    return "/frontend/teacher/index.html";
  } else if (role.includes("student")) {
    return "/frontend/student/index.html";
  } else if (role.includes("parent")) {
    return "/frontend/parent/index.html";
  }

  return "/frontend/login/login.html";
}

function runAuthGuard() {
  console.log("runAuthGuard called");

  // 1) تأكد أن عندنا جلسة (token + user)
  const token = localStorage.getItem("token");
  const userStr = localStorage.getItem("user");

  console.log("token:", token ? "exists" : "missing");
  console.log("userStr:", userStr);

  if (!token || !userStr) {
    console.log("no session -> redirect to login");
    window.location.href = "/frontend/login/login.html";
    return;
  }

  let user;
  try {
    user = JSON.parse(userStr);
  } catch (e) {
    console.warn("stored user JSON invalid:", e);
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    window.location.href = "/frontend/login/login.html";
    return;
  }

  const roleRaw = user.role || user.role_name || user.roleName || "";
  const role = String(roleRaw || "").toLowerCase();
  console.log("user role:", roleRaw, "->", role);

  // 2) الدور المطلوب لهذه الصفحة (من body[data-role])
  const requiredRole = String(
    (document.body && document.body.dataset.role) || ""
  ).toLowerCase();

  console.log("requiredRole (data-role):", requiredRole);

  // لو الصفحة ما حدّدت دور، نتركها
  if (!requiredRole) {
    console.log("no requiredRole on this page -> guard skipped");
    return;
  }

  // 3) التحقق: هل يطابق دور المستخدم الدور المطلوب؟
  if (!role.includes(requiredRole)) {
    console.warn(
      "role mismatch: user role =",
      role,
      ", requiredRole =",
      requiredRole
    );

    alert("لا تملك صلاحية لفتح هذه الصفحة");

    const url = resolveDashboardUrl(role);
    console.log("redirecting to:", url);
    window.location.href = url;
  } else {
    console.log("role matches, access granted");
  }
}

// نتأكد أن الـ DOM جاهز ثم نشغّل الحارس
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", runAuthGuard);
} else {
  runAuthGuard();
}
