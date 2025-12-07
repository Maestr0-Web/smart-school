document.addEventListener("DOMContentLoaded", function () {
  var btn = document.getElementById("theme-toggle");
  var icon = document.getElementById("theme-icon");
  var label = document.getElementById("theme-label");

  function setTheme(isDark) {
    document.body.classList.toggle("theme-dark", isDark);
    if (icon) icon.className = isDark ? "ri-moon-line" : "ri-sun-line";
    if (label) label.textContent = isDark ? "الوضع الفاتح" : "الوضع الداكن";
  }

  // الوضع الافتراضي نهاري: لا نضيف أي كلاس
  setTheme(false);

  if (btn) {
    btn.addEventListener("click", function (e) {
      e.preventDefault();
      var isDark = !document.body.classList.contains("theme-dark");
      setTheme(isDark);
    });
  }
});
