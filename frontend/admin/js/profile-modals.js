// // frontend/admin/js/profile-modals.js
// console.log("profile-modals.js loaded");

// // عدّل حسب سيرفرك
// const API_BASE = "http://127.0.0.1:5000";

// function profileGetAuthHeaders() {
//   const token = localStorage.getItem("token");
//   const headers = { "Content-Type": "application/json" };
//   if (token) headers.Authorization = `Bearer ${token}`;
//   return headers;
// }

// async function profileApiRequest(path, options = {}) {
//   const finalOptions = {
//     headers: {
//       ...profileGetAuthHeaders(),
//       ...(options.headers || {}),
//     },
//     ...options,
//   };

//   try {
//     const res = await fetch(`${API_BASE}${path}`, finalOptions);

//     if (res.status === 401) {
//       let msg = "تم انتهاء الجلسة، الرجاء تسجيل الدخول من جديد";
//       try {
//         const txt = await res.text();
//         try {
//           const json = JSON.parse(txt);
//           msg = json.message || msg;
//         } catch (_) {
//           if (txt && txt.trim()) msg = txt;
//         }
//       } catch (_) {}

//       alert(msg);
//       localStorage.removeItem("token");
//       localStorage.removeItem("user");
//       window.location.href = "/frontend/login/login.html";
//       return;
//     }

//     if (!res.ok) {
//       const txt = await res.text();
//       let msg = "حدث خطأ في الخادم";
//       try {
//         const json = JSON.parse(txt);
//         msg = json.message || msg;
//       } catch (_) {}
//       throw new Error(msg);
//     }

//     if (res.status === 204) return null;
//     return await res.json();
//   } catch (err) {
//     console.error("Profile API error:", err);
//     alert(`خطأ: ${err.message}`);
//     throw err;
//   }
// }

// function closeModalById(id) {
//   const modal = document.getElementById(id);
//   if (!modal) return;
//   const closeBtn = modal.querySelector("[data-close-modal]");
//   if (closeBtn) {
//     closeBtn.click();
//   } else {
//     modal.classList.remove("is-open");
//   }
// }

// document.addEventListener("DOMContentLoaded", () => {
//   // تعبئة البريد الحالي من localStorage
//   try {
//     const userStr = localStorage.getItem("user");
//     if (userStr) {
//       const user = JSON.parse(userStr);
//       const currentEmailInput = document.getElementById("currentEmail");
//       if (currentEmailInput && user.email) {
//         currentEmailInput.value = user.email;
//       }
//     }
//   } catch (_) {}

//   // 🔑 تغيير كلمة المرور
//   const changePasswordForm = document.getElementById("changePasswordForm");
//   if (changePasswordForm) {
//     changePasswordForm.addEventListener("submit", async (e) => {
//       e.preventDefault();

//       const currentPassword =
//         document.getElementById("currentPassword")?.value.trim();
//       const newPassword =
//         document.getElementById("newPassword")?.value.trim();
//       const confirmNewPassword =
//         document.getElementById("confirmNewPassword")?.value.trim();

//       if (!currentPassword || !newPassword || !confirmNewPassword) {
//         alert("يرجى تعبئة جميع الحقول");
//         return;
//       }

//       if (newPassword !== confirmNewPassword) {
//         alert("كلمة المرور الجديدة وتأكيدها غير متطابقين");
//         return;
//       }

//       if (newPassword.length < 6) {
//         alert("يفضل أن تكون كلمة المرور 6 أحرف/أرقام على الأقل");
//         return;
//       }

//       try {
//         await profileApiRequest("/api/profile/change-password", {
//           method: "PUT",
//           body: JSON.stringify({ currentPassword, newPassword }),
//         });

//         alert("✅ تم تغيير كلمة المرور بنجاح، سيتم تسجيل خروجك");
//         changePasswordForm.reset();
//         closeModalById("change-password-modal");

//         // تسجيل خروج محلي
//         localStorage.removeItem("token");
//         localStorage.removeItem("user");
//         window.location.href = "/frontend/login/login.html";
//       } catch (err) {
//         // تم إظهار الرسالة
//       }
//     });
//   }

//   // 📧 تغيير البريد
//   const changeEmailForm = document.getElementById("changeEmailForm");
//   if (changeEmailForm) {
//     changeEmailForm.addEventListener("submit", async (e) => {
//       e.preventDefault();

//       const newEmail = document.getElementById("newEmail")?.value.trim();
//       if (!newEmail) {
//         alert("يرجى إدخال البريد الإلكتروني الجديد");
//         return;
//       }

//       if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(newEmail)) {
//         alert("صيغة البريد الإلكتروني غير صحيحة");
//         return;
//       }

//       try {
//         const data = await profileApiRequest("/api/profile/change-email", {
//           method: "PUT",
//           body: JSON.stringify({ newEmail }),
//         });

//         alert("✅ تم تحديث البريد الإلكتروني بنجاح");

//         // تحديث localStorage.user
//         try {
//           const userStr = localStorage.getItem("user");
//           const oldUser = userStr ? JSON.parse(userStr) : {};
//           const updatedUser = {
//             ...oldUser,
//             email: newEmail,
//           };
//           localStorage.setItem("user", JSON.stringify(updatedUser));
//         } catch (_) {}

//         // تحديث الحقل في المودال
//         const currentEmailInput = document.getElementById("currentEmail");
//         if (currentEmailInput) currentEmailInput.value = newEmail;

//         changeEmailForm.reset();
//         closeModalById("change-email-modal");
//       } catch (err) {
//         // تم إظهار الرسالة
//       }
//     });
//   }
// });
