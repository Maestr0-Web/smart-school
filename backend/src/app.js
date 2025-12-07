import express from "express";
import cors from "cors";
import moduleRoutes from "./routes/moduleRoutes.js";
import permissionRoutes from "./routes/permissionRoutes.js";
import roleRoutes from "./routes/roleRoutes.js";
import permissionRoleRoutes from "./routes/permissionRoleRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";


import dotenv from "dotenv";
dotenv.config();


const app = express();
app.use(express.json());                        // لاستقبال JSON
app.use(express.urlencoded({ extended: true })); // لاستقبال x-www-form-urlencoded

app.use(cors());

// مسار الوحدات
app.use("/api/modules", moduleRoutes);
app.use("/api/permissions", permissionRoutes);
app.use("/api/roles", roleRoutes);
app.use("/api/role-permissions", permissionRoleRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/profile", profileRoutes);

// معالجة الأخطاء بشكل مركزي
app.use((err, req, res, next) => {
	console.error(err.stack);
	res.status(500).json({ error: "خطأ في السيرفر" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));