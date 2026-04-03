-- 1. إضافة عمود school_id لجدول الأدوار
ALTER TABLE roles ADD COLUMN school_id INT;

-- 2. ربط الأدوار القديمة (الموجودة مسبقاً) بمدرستك الحالية (لنفترض أن رقمها 4) 
-- (قم بتغيير رقم 4 إلى رقم مدرستك إذا كان مختلفاً)
UPDATE roles SET school_id = 4 WHERE school_id IS NULL;

-- 3. (اختياري ومهم جداً للحماية) جعل العمود إجبارياً وربطه بجدول المدارس
ALTER TABLE roles ALTER COLUMN school_id SET NOT NULL;
ALTER TABLE roles ADD CONSTRAINT fk_roles_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;