import PermissionRoleModel from "../modules/permissionRoleModel.js";

export const PermissionRoleController = {
  // ربط صلاحية بدور
  async assign(req, res) {
    try {
      const { role_id, permission_id } = req.body;

      if (!role_id || !permission_id) {
        return res.status(400).json({ error: "role_id و permission_id مطلوبين" });
      }

      const data = await PermissionRoleModel.assign(role_id, permission_id);

      res.status(201).json({
        message: "تم ربط الصلاحية بالدور بنجاح",
        data,
      });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "خطأ في السيرفر" });
    }
  },

  // جلب كل العلاقات
  async getAll(req, res) {
    const data = await PermissionRoleModel.getAll();
    res.json(data);
  },

  // جلب حسب الدور
  async getByRole(req, res) {
    const { role_id } = req.params;
    const data = await PermissionRoleModel.getByRole(role_id);
    res.json(data);
  },

  // حذف علاقة
  async delete(req, res) {
    const { id } = req.params;
    const deleted = await PermissionRoleModel.delete(id);

    if (!deleted) {
      return res.status(404).json({ error: "العنصر غير موجود" });
    }

    res.json({ message: "تم الحذف بنجاح", deleted });
  },
};
