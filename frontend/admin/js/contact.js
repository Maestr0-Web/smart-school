// function loadPage(page) {
//   const content = document.getElementById("content");

//   if (page === "studentsList") {
//     content.innerHTML = `
//           <div class="card">
//             <h3>📋 قائمة الطلاب</h3>
//             <p>هنا يتم عرض الطلاب المسجلين في النظام.</p>
//             <button class="btn">🔄 تحديث</button>
//           </div>`;
//   }

//   if (page === "studentRegister") {
//     content.innerHTML = `   <!-- Main Form Card -->
//         <div class="card">
//             <div class="card-header">
//                 <h2>➕ تسجيل طالب جديد</h2>
//             </div>
            
//             <form id="studentForm" onsubmit="registerStudent(event)">
                
//                 <!-- البيانات الشخصية -->
//                 <fieldset class="form-section personal-info">
//                     <legend>👨‍🎓 البيانات الشخصية</legend>
                    
//                     <div class="form-grid">
//                         <div class="form-group">
//                             <label for="studentName">اسم الطالب:</label>
//                             <input type="text" id="studentName" required placeholder="أدخل اسم الطالب كاملاً">
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentGender">الجنس:</label>
//                             <select id="studentGender">
//                                 <option value="ذكر">ذكر</option>
//                                 <option value="أنثى">أنثى</option>
//                             </select>
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentBirth">📅 تاريخ الميلاد:</label>
//                             <input type="date" id="studentBirth">
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentBirthPlace">📍 عنوان الميلاد:</label>
//                             <input type="text" id="studentBirthPlace" placeholder="مكان الولادة">
//                         </div>
                        
//                         <div class="form-group full-width">
//                             <label for="studentAddress">🏠 العنوان الحالي:</label>
//                             <input type="text" id="studentAddress" placeholder="العنوان الحالي للطالب">
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentPhone">📱 الهاتف:</label>
//                             <input type="tel" id="studentPhone" placeholder="رقم الهاتف الأساسي">
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentPhone2">📞 هاتف آخر:</label>
//                             <input type="tel" id="studentPhone2" placeholder="رقم هاتف إضافي">
//                         </div>
//                     </div>
//                 </fieldset>

//                 <!-- البيانات الأكاديمية -->
//                 <fieldset class="form-section academic-info">
//                     <legend>📚 البيانات الأكاديمية</legend>
                    
//                     <div class="form-grid">
//                         <div class="form-group">
//                             <label for="studentStage">المرحلة:</label>
//                             <select id="studentStage" onchange="loadGrades()">
//                                 <option value="">اختر المرحلة</option>
//                                 <option value="ابتدائية">ابتدائية</option>
//                                 <option value="إعدادية">إعدادية</option>
//                                 <option value="ثانوية">ثانوية</option>
//                             </select>
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentClass">الصف:</label>
//                             <select id="studentClass" disabled>
//                                 <option value="">اختر الصف</option>
//                             </select>
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="sectionType">طريقة تعيين الشعبة:</label>
//                             <select id="sectionType" onchange="toggleSectionType()" disabled>
//                                 <option value="">اختر الطريقة</option>
//                                 <option value="auto">توزيع تلقائي</option>
//                                 <option value="manual">تعيين يدوي</option>
//                             </select>
//                         </div>
                        
//                         <div id="sectionSelectBox" class="form-group hidden">
//                             <label for="studentSection">الشعبة:</label>
//                             <select id="studentSection">
//                                 <option value="A">A</option>
//                                 <option value="B">B</option>
//                                 <option value="C">C</option>
//                             </select>
//                         </div>
//                     </div>
//                 </fieldset>

//                 <!-- بيانات ولي الأمر -->
//                 <fieldset class="form-section parent-info">
//                     <legend>👨‍👩‍👦 بيانات ولي الأمر</legend>
                    
//                     <div class="form-group">
//                         <label for="parentOption">اختر ولي الأمر:</label>
//                         <select id="parentOption" onchange="toggleParentOption()">
//                             <option value="">اختر</option>
//                             <option value="existing">ولي أمر موجود مسبقًا</option>
//                             <option value="new">ولي أمر جديد</option>
//                         </select>
//                     </div>

//                     <div id="existingParent" class="form-group hidden">
//                         <label for="existingParentName">اسم ولي الأمر:</label>
//                         <input type="text" id="existingParentName" placeholder="ابحث عن ولي الأمر">
//                     </div>

//                     <div id="newParent" class="hidden">
//                         <div class="form-grid">
//                             <div class="form-group">
//                                 <label for="parentName">اسم ولي الأمر:</label>
//                                 <input type="text" id="parentName" placeholder="اسم ولي الأمر كاملاً">
//                             </div>
                            
//                             <div class="form-group">
//                                 <label for="parentGender">الجنس:</label>
//                                 <select id="parentGender">
//                                     <option value="ذكر">ذكر</option>
//                                     <option value="أنثى">أنثى</option>
//                                 </select>
//                             </div>
                            
//                             <div class="form-group">
//                                 <label for="parentPhone">📱 هاتف ولي الأمر:</label>
//                                 <input type="tel" id="parentPhone" placeholder="رقم هاتف ولي الأمر">
//                             </div>
                            
//                             <div class="form-group">
//                                 <label for="parentRelation">العلاقة بالطالب:</label>
//                                 <input type="text" id="parentRelation" placeholder="مثل: والد، والدة، وصي">
//                             </div>
                            
//                             <div class="form-group">
//                                 <label for="parentEmail">📧 بريد ولي الأمر:</label>
//                                 <input type="email" id="parentEmail" placeholder="parent@example.com">
//                             </div>
                            
//                             <div class="form-group">
//                                 <label for="parentPassword">🔒 كلمة مرور ولي الأمر:</label>
//                                 <input type="password" id="parentPassword" placeholder="كلمة مرور قوية">
//                             </div>
//                         </div>
//                     </div>
//                 </fieldset>

//                 <!-- بيانات الحساب -->
//                 <fieldset class="form-section account-info">
//                     <legend>🔑 بيانات الحساب</legend>
                    
//                     <div class="form-grid">
//                         <div class="form-group">
//                             <label for="studentEmail">📧 بريد الطالب الإلكتروني:</label>
//                             <input type="email" id="studentEmail" required placeholder="student@school.edu">
//                         </div>
                        
//                         <div class="form-group">
//                             <label for="studentPassword">🔒 كلمة مرور الطالب:</label>
//                             <input type="password" id="studentPassword" required placeholder="كلمة مرور قوية">
//                         </div>
//                     </div>
//                 </fieldset>

//                 <!-- Submit Button -->
//                 <div class="submit-section">
//                     <button type="submit" class="btn-submit">
//                         <span class="btn-icon">✅</span>
//                         تسجيل الطالب
//                     </button>
//                 </div>
//             </form>
//         </div>`;
//   }

//   if (page === "studentRenew") {
//     content.innerHTML = `<div class="card"><h3>🔄 تسجيل الطلاب المستمرين</h3><p>هنا تتم عملية تجديد تسجيل الطلاب.</p></div>`;
//   }

//   if (page === "staffRegister") {
//     content.innerHTML = `<div class="card"><h3>➕ تسجيل موظف جديد</h3><p>واجهة تسجيل الموظفين.</p></div>`;
//   }

//   if (page === "assignTeachers") {
//     content.innerHTML = `<div class="card"><h3>📚 تعيين المدرسين</h3><p>إدارة ربط المدرسين بالمواد والصفوف.</p></div>`;
//   }

//   if (page === "weeklySchedule") {
//     content.innerHTML = `<div class="card"><h3>📘 جدول الحصص الأسبوعي</h3></div>`;
//   }

//   if (page === "examSchedule") {
//     content.innerHTML = `<div class="card"><h3>📝 جدول الامتحانات</h3></div>`;
//   }

//   if (page === "monthlyWork") {
//     content.innerHTML = `<div class="card"><h3>🖊️ تسجيل الأعمال الشهرية</h3></div>`;
//   }

//   if (page === "monthlyReports") {
//     content.innerHTML = `<div class="card"><h3>📑 شهائد الطلاب الشهرية</h3></div>`;
//   }

//   if (page === "termWork") {
//     content.innerHTML = `<div class="card"><h3>🖊️ تسجيل الأعمال الفصلية</h3></div>
//     <h3>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Corrupti voluptas maiores omnis totam consectetur! Debitis repudiandae incidunt, illum obcaecati autem eos nobis, dolor sequi consectetur quas dignissimos doloribus commodi delectus. Sapiente praesentium eius fugit. Fuga neque nam velit earum ratione consectetur quo tempore id facilis qui, itaque sapiente laboriosam quibusdam commodi voluptatum voluptate accusantium dolores ipsa laudantium libero voluptatibus dicta maxime. Quis nisi et, saepe commodi consequatur esse quam delectus labore maxime fugit deleniti rem ratione, nostrum recusandae inventore quibusdam consequuntur in iure illo quia tempore fugiat ipsa sequi ipsum! Similique fugit at accusantium voluptas consequatur! Maiores non minima, repudiandae quo commodi officia. Harum laboriosam sed vitae, officiis officia voluptatibus ab vel commodi nam excepturi in deserunt assumenda, nostrum quos iste itaque quo quis! Laudantium deserunt maxime aperiam! Quidem veniam nesciunt tempora, facere laboriosam doloribus cupiditate optio deleniti eaque pariatur ratione fuga quibusdam odio minima consequatur reiciendis reprehenderit officiis dolore nam illo voluptatum perspiciatis est neque exercitationem. Illum dolorem sit nesciunt maxime excepturi sequi incidunt a ratione. Alias iste repellat culpa ab et vitae dolores expedita nesciunt. Cupiditate, illum alias temporibus officia repudiandae optio earum mollitia in corporis eos impedit nulla minima blanditiis odio delectus porro! Fugiat similique consectetur ullam.</h3>

//     `;
//   }

//   if (page === "termReports") {
//     content.innerHTML = `<div class="card"><h3>📑 شهائد درجات الفصلية</h3></div>`;
//   }

//   if (page === "termResults") {
//     content.innerHTML = `<div class="card"><h3>📊 نتائج نهاية الفصل</h3></div>`;
//   }

//   if (page === "yearResults") {
//     content.innerHTML = `<div class="card"><h3>📊 نتائج نهاية العام</h3></div>`;
//   }

//   if (page === "createNotify") {
//     content.innerHTML = `<div class="card"><h3>➕ إنشاء إشعار</h3></div>`;
//   }

//   if (page === "notifyLog") {
//     content.innerHTML = `<div class="card"><h3>📜 سجل الإشعارات</h3></div>`;
//   }

//   if (page === "barcodeAttendance") {
//     content.innerHTML = `<div class="card"><h3>📱 تسجيل حضور باركود</h3></div>`;
//   }

//   if (page === "manualAttendance") {
//     content.innerHTML = `<div class="card"><h3>✍️ تسجيل الحضور اليدوي</h3></div>`;
//   }

//   if (page === "attendanceReports") {
//     content.innerHTML = `<div class="card"><h3>📊 تقارير الحضور</h3></div>`;
//   }

//   if (page === "feesPay") {
//     content.innerHTML = `<div class="card"><h3>💵 سداد الرسوم</h3></div>`;
//   }

//   if (page === "feesReports") {
//     content.innerHTML = `<div class="card"><h3>📊 تقارير الرسوم</h3></div>`;
//   }

//   if (page === "studentData") {
//     content.innerHTML = `<div class="card"><h3>👨‍🎓 بيانات الطلاب</h3></div>`;
//   }

//   if (page === "staffData") {
//     content.innerHTML = `<div class="card"><h3>👥 بيانات الموظفين</h3></div>`;
//   }

//   if (page === "termGrades") {
//     content.innerHTML = `<div class="card"><h3>📊 تقارير الدرجات الفصلية</h3></div>`;
//   }

//   if (page === "finalGrades") {
//     content.innerHTML = `<div class="card"><h3>📊 تقارير الدرجات النهائية</h3></div>`;
//   }

//   if (page === "studentStats") {
//     content.innerHTML = `<div class="card"><h3>📈 إحصائيات الطلاب</h3></div>`;
//   }

//   if (page === "notifyBox") {
//     content.innerHTML = `<div class="card"><h3>🔔 الإشعارات</h3></div>`;
//   }

//   if (page === "classSchedule") {
//     content.innerHTML = `<div class="card"><h3>📘 جدول الحصص</h3></div>`;
//   }

//   if (page === "inbox") {
//     content.innerHTML = `<div class="card"><h3>📥 صندوق الوارد</h3></div>`;
//   }
//   if (page === "profilr-person") {
//     content.innerHTML = `<div class="card"><h3>📥  إعدادات الملف الشخصي</h3></div>`;
//   }
//   if (page === "change-password") {
//     content.innerHTML = `<div class="card"><h3> تغير كلمة المرور     </h3></div>`;
//   }
//   if (page === "langeuge") {
//     content.innerHTML = `<div class="card"><h3> تغير  اللغة     </h3></div>`;
//   }
// }
// function loadGrades() {
//   const stage = document.getElementById("studentStage").value;
//   const classSelect = document.getElementById("studentClass");
//   classSelect.innerHTML = "<option value=''>اختر الصف</option>";
//   classSelect.disabled = !stage;
//   let grades = [];
//   if (stage === "ابتدائية")
//     grades = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس"];
//   if (stage === "إعدادية")
//     grades = ["الأول الإعدادي", "الثاني الإعدادي", "الثالث الإعدادي"];
//   if (stage === "ثانوية")
//     grades = ["الأول الثانوي", "الثاني الثانوي", "الثالث الثانوي"];
//   grades.forEach((g) => {
//     const opt = document.createElement("option");
//     opt.value = g;
//     opt.textContent = g;
//     classSelect.appendChild(opt);
//   });
//   document.getElementById("sectionType").disabled = false;
// }
// function toggleParentOption() {
//   const option = document.getElementById("parentOption").value;
//   const existingParent = document.getElementById("existingParent");
//   const newParent = document.getElementById("newParent");

//   if (option === "existing") {
//     existingParent.classList.remove("hidden");
//     newParent.classList.add("hidden");
//   } else if (option === "new") {
//     newParent.classList.remove("hidden");
//     existingParent.classList.add("hidden");
//   } else {
//     existingParent.classList.add("hidden");
//     newParent.classList.add("hidden");
//   }
// }

// function toggleSectionType() {
//   const sectionType = document.getElementById("sectionType").value;
//   const sectionSelectBox = document.getElementById("sectionSelectBox");
//   if (sectionType === "manual") {
//     sectionSelectBox.classList.remove("hidden");
//   } else {
//     sectionSelectBox.classList.add("hidden");
//   }
// }
if (pageName === 'users-permissions') {
  initUsersPermissionsPage();
}
