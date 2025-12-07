// تعريف دالة لمساعدة إنشاء خصائص للكائنات
function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true,
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

// مدة التحريك للأنيميشن (بالمللي ثانية)
const ANIMATION_DURATION = 300;

// عنصر الـ sidebar الرئيسي
const SIDEBAR_EL = document.getElementById("sidebar");
// عنصر الـ layout الجذر (يُستخدم لضبط هوامش المحتوى عند التصغير)
const ROOT_LAYOUT = document.querySelector(
  ".layout.has-sidebar.fixed-sidebar.fixed-header"
);

// جميع عناصر القوائم الفرعية في القائمة الجانبية
const SUB_MENU_ELS = document.querySelectorAll(
  ".menu > ul > .menu-item.sub-menu"
);

// أزرار القوائم الفرعية (المستوى الأول)
const FIRST_SUB_MENUS_BTN = document.querySelectorAll(
  ".menu > ul > .menu-item.sub-menu > a"
);

// أزرار القوائم الفرعية الداخلية (المستوى الثاني)
const INNER_SUB_MENUS_BTN = document.querySelectorAll(
  ".menu > ul > .menu-item.sub-menu .menu-item.sub-menu > a"
);

// كلاس لإدارة popper (القائمة المنبثقة)
class PopperObject {
  constructor(reference, popperTarget) {
    _defineProperty(this, "instance", null);
    _defineProperty(this, "reference", null);
    _defineProperty(this, "popperTarget", null);
    this.init(reference, popperTarget);
  }

  // تهيئة الـ popper وربطه بالعنصر المرجعي
  init(reference, popperTarget) {
    this.reference = reference;
    this.popperTarget = popperTarget;
    this.instance = Popper.createPopper(this.reference, this.popperTarget, {
      placement: "right",
      strategy: "fixed",
      resize: true,
      modifiers: [
        {
          name: "computeStyles",
          options: {
            adaptive: false,
          },
        },
        {
          name: "flip",
          options: {
            fallbackPlacements: ["left", "right"],
          },
        },
      ],
    });

    // إغلاق القائمة المنبثقة عند الضغط خارجها
    document.addEventListener(
      "click",
      (e) => this.clicker(e, this.popperTarget, this.reference),
      false
    );

    // تحديث موضع القائمة عند تغيير الحجم
    const ro = new ResizeObserver(() => {
      this.instance.update();
    });

    ro.observe(this.popperTarget);
    ro.observe(this.reference);
  }

  // دالة لفحص الضغط خارج القائمة المنبثقة
  clicker(event, popperTarget, reference) {
    if (
      SIDEBAR_EL.classList.contains("collapsed") &&
      !popperTarget.contains(event.target) &&
      !reference.contains(event.target)
    ) {
      this.hide();
    }
  }

  // إخفاء القائمة المنبثقة
  hide() {
    this.instance.state.elements.popper.style.visibility = "hidden";
  }
}

// كلاس لإدارة جميع القوائم المنبثقة الفرعية
class Poppers {
  constructor() {
    _defineProperty(this, "subMenuPoppers", []);
    this.init();
  }

  // تهيئة جميع القوائم المنبثقة
  init() {
    SUB_MENU_ELS.forEach((element) => {
      this.subMenuPoppers.push(
        new PopperObject(element, element.lastElementChild)
      );
      this.closePoppers();
    });
  }

  // تبديل ظهور القائمة المنبثقة
  togglePopper(target) {
    if (window.getComputedStyle(target).visibility === "hidden")
      target.style.visibility = "visible";
    else target.style.visibility = "hidden";
  }

  // تحديث جميع القوائم المنبثقة
  updatePoppers() {
    this.subMenuPoppers.forEach((element) => {
      element.instance.state.elements.popper.style.display = "none";
      element.instance.update();
    });
  }

  // إغلاق جميع القوائم المنبثقة
  closePoppers() {
    this.subMenuPoppers.forEach((element) => {
      element.hide();
    });
  }
}

// دوال تحريك القوائم الفرعية (إظهار وإخفاء مع أنيميشن)
const slideUp = (target, duration = ANIMATION_DURATION) => {
  const { parentElement } = target;
  parentElement.classList.remove("open");
  target.style.transitionProperty = "height, margin, padding";
  target.style.transitionDuration = `${duration}ms`;
  target.style.boxSizing = "border-box";
  target.style.height = `${target.offsetHeight}px`;
  target.offsetHeight;
  target.style.overflow = "hidden";
  target.style.height = 0;
  target.style.paddingTop = 0;
  target.style.paddingBottom = 0;
  target.style.marginTop = 0;
  target.style.marginBottom = 0;
  window.setTimeout(() => {
    target.style.display = "none";
    target.style.removeProperty("height");
    target.style.removeProperty("padding-top");
    target.style.removeProperty("padding-bottom");
    target.style.removeProperty("margin-top");
    target.style.removeProperty("margin-bottom");
    target.style.removeProperty("overflow");
    target.style.removeProperty("transition-duration");
    target.style.removeProperty("transition-property");
  }, duration);
};
const slideDown = (target, duration = ANIMATION_DURATION) => {
  const { parentElement } = target;
  parentElement.classList.add("open");
  target.style.removeProperty("display");
  let { display } = window.getComputedStyle(target);
  if (display === "none") display = "block";
  target.style.display = display;
  const height = target.offsetHeight;
  target.style.overflow = "hidden";
  target.style.height = 0;
  target.style.paddingTop = 0;
  target.style.paddingBottom = 0;
  target.style.marginTop = 0;
  target.style.marginBottom = 0;
  target.offsetHeight;
  target.style.boxSizing = "border-box";
  target.style.transitionProperty = "height, margin, padding";
  target.style.transitionDuration = `${duration}ms`;
  target.style.height = `${height}px`;
  target.style.removeProperty("padding-top");
  target.style.removeProperty("padding-bottom");
  target.style.removeProperty("margin-top");
  target.style.removeProperty("margin-bottom");
  window.setTimeout(() => {
    target.style.removeProperty("height");
    target.style.removeProperty("overflow");
    target.style.removeProperty("transition-duration");
    target.style.removeProperty("transition-property");
  }, duration);
};

// تبديل إظهار/إخفاء القائمة الفرعية
const slideToggle = (target, duration = ANIMATION_DURATION) => {
  if (window.getComputedStyle(target).display === "none")
    return slideDown(target, duration);
  return slideUp(target, duration);
};

// إنشاء كائن لإدارة جميع القوائم المنبثقة
const PoppersInstance = new Poppers();

/**
 * wait for the current animation to finish and update poppers position
 */
const updatePoppersTimeout = () => {
  setTimeout(() => {
    PoppersInstance.updatePoppers();
  }, ANIMATION_DURATION);
};

/**
 * sidebar collapse handler
 */
const btnCollapse = document.getElementById("btn-collapse");
if (btnCollapse && SIDEBAR_EL) {
  btnCollapse.addEventListener("click", () => {
    SIDEBAR_EL.classList.toggle("collapsed");
    SIDEBAR_EL.style.transition = "all 0.4s";

    // ✅ مزامنة حالة التصغير مع الـ layout (لتغيير هوامش المحتوى من الـ CSS)
    if (ROOT_LAYOUT) {
      if (SIDEBAR_EL.classList.contains("collapsed")) {
        ROOT_LAYOUT.classList.add("sidebar-collapsed");
      } else {
        ROOT_LAYOUT.classList.remove("sidebar-collapsed");
      }
    }

    PoppersInstance.closePoppers();
    if (SIDEBAR_EL.classList.contains("collapsed"))
      FIRST_SUB_MENUS_BTN.forEach((element) => {
        element.parentElement.classList.remove("open");
      });
    updatePoppersTimeout();
  });
}

/**
 * sidebar toggle handler (on break point )
 */
const btnToggle = document.getElementById("btn-toggle");
if (btnToggle && SIDEBAR_EL) {
  btnToggle.addEventListener("click", () => {
    SIDEBAR_EL.classList.toggle("toggled");
    SIDEBAR_EL.style.transition = "all 0.4s";
    updatePoppersTimeout();
  });
}

/**
 * إظهار القوائم الفرعية المفتوحة افتراضياً
 */
const defaultOpenMenus = document.querySelectorAll(".menu-item.sub-menu.open");
defaultOpenMenus.forEach((element) => {
  element.lastElementChild.style.display = "block";
});

/**
 * handle top level submenu click
 */
FIRST_SUB_MENUS_BTN.forEach((element) => {
  element.addEventListener("click", () => {
    if (SIDEBAR_EL.classList.contains("collapsed"))
      PoppersInstance.togglePopper(element.nextElementSibling);
    else {
      const parentMenu = element.closest(".menu.open-current-submenu");
      if (parentMenu)
        parentMenu
          .querySelectorAll(":scope > ul > .menu-item.sub-menu > a")
          .forEach(
            (el) =>
              window.getComputedStyle(el.nextElementSibling).display !==
                "none" && slideUp(el.nextElementSibling)
          );

      slideToggle(element.nextElementSibling);
    }
  });
});

/**
 * handle inner submenu click
 */
INNER_SUB_MENUS_BTN.forEach((element) => {
  element.addEventListener("click", () => {
    slideToggle(element.nextElementSibling);
  });
});

/**
 * إغلاق الـ sidebar عند الضغط خارجها
 * في الشاشات الصغيرة: إزالة toggled (إغلاق الـ overlay)
 * في الشاشات الكبيرة: تصغيره فقط (collapsed) وتحديث الـ layout
 */
document.addEventListener("click", function (event) {
  const sidebar = SIDEBAR_EL;
  const toggleBtn = document.getElementById("btn-toggle");
  if (!sidebar) return;

  const clickedOutsideSidebar =
    !sidebar.contains(event.target) &&
    (!toggleBtn || !toggleBtn.contains(event.target));

  if (clickedOutsideSidebar) {
    if (window.innerWidth <= 960) {
      // في الموبايل: نغلق الـ overlay فقط
      sidebar.classList.remove("toggled");
    } else {
      // في الديسكتوب: نكتفي بتصغيره (collapsed) مع تحديث الـ layout
      sidebar.classList.add("collapsed");
      if (ROOT_LAYOUT) {
        ROOT_LAYOUT.classList.add("sidebar-collapsed");
      }
    }
    sidebar.style.transition = "all 0.4s";
  }
});

/**
 * إغلاق الـ sidebar عند الضغط على عنصر فرعي (في وضع الموبايل فقط)
 */
const subMenuItems = document.querySelectorAll(
  ".sub-menu-list ul li.menu-item"
);
subMenuItems.forEach((item) => {
  item.addEventListener("click", () => {
    if (SIDEBAR_EL.classList.contains("toggled")) {
      SIDEBAR_EL.classList.remove("toggled");
    }
    // لا نلمس collapsed أبداً هنا
  });
});

// مراقبة تغيير حجم الشاشة لإعادة ضبط sidebar تلقائياً
window.addEventListener("resize", function () {
  const sidebar = SIDEBAR_EL;
  if (!sidebar) return;

  if (window.innerWidth > 960) {
    // العودة إلى وضع الديسكتوب: نزيل الـ overlay فقط
    sidebar.classList.remove("toggled");
    sidebar.style.transition = "all 0.4s";
  }

  // إذا تمت إزالة collapsed بطريقة أخرى، نزيل كلاس الـ layout أيضاً
  if (!sidebar.classList.contains("collapsed") && ROOT_LAYOUT) {
    ROOT_LAYOUT.classList.remove("sidebar-collapsed");
  }
});
