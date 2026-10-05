# Aureus | أوريوس - النموذج الأولي (Oracle SQL/PL-SQL + Form Builder)

نسخة النموذج الأولي (Prototype) من نظام أوريوس، مبنية على قاعدة بيانات Oracle، بمنطق أعمال بالكامل داخل حزم PL/SQL، وواجهة Oracle Forms Builder.

## ⚠️ ملاحظة مهمة وصريحة
تم كتابة كل كود PL/SQL بعناية باتّباع الصياغة القياسية لـ Oracle، لكن **لم يُشغَّل أو يُختبر فعلياً على خادم Oracle حقيقي** (بيئة العمل هنا لا تحتوي قاعدة بيانات Oracle). لازم الفريق يشغّل ملفات الحزم وسكربت الاختبار على SQL*Plus فعلي (أو SQL Developer) قبل الاعتماد عليها، ويصلّح أي خطأ صياغي بسيط قد يظهر حسب إصدار Oracle المستخدم (11g/12c/19c...).

## ترتيب التشغيل في SQL*Plus (مهم - الترتيب يفرق بسبب الاعتماديات)

```sql
-- 1) قاعدة البيانات
@database/schema.sql

-- 2) الحزم المستقلة أولاً
@packages/pkg_price.sql
@packages/pkg_auth.sql

-- 3) الحزم المعتمِدة على اللي فوق
@packages/pkg_gold.sql
@packages/pkg_trading.sql
@packages/pkg_admin.sql

-- 4) اختبار شامل لكل الحزم
@test_scripts/test_all.sql
```

## هيكل المشروع

```
aureus_oracle/
├── database/schema.sql          # التسلسلات + الجداول + القيود + Triggers الترقيم التلقائي
├── packages/
│   ├── pkg_price.sql            # تاريخ الأسعار + الميزة الذكية (اتجاه السعر)
│   ├── pkg_auth.sql             # تسجيل / دخول
│   ├── pkg_gold.sql             # عرض قطع الذهب (يعتمد على pkg_price)
│   ├── pkg_trading.sql          # الشراء والمعاملات (قفل صفوف FOR UPDATE للذرية)
│   └── pkg_admin.sql            # إدارة المستخدمين + سجل التدقيق + التقارير
├── test_scripts/test_all.sql    # 11 حالة اختبار عبر DBMS_OUTPUT
└── forms_spec/forms_specification.md   # مواصفة كل نموذج Form Builder + كود الـ Triggers
```

## توزيع الأدوار بين أعضاء الفريق (٤ طلاب) - محدّث للنسخة Oracle

| الطالب | الوحدة المسؤول عنها | الملفات |
|---|---|---|
| الطالب 1 | قاعدة البيانات (الجداول، التسلسلات، القيود، Triggers) | `database/schema.sql` |
| الطالب 2 | المستخدمون والإدارة | `packages/pkg_auth.sql`, `packages/pkg_admin.sql` |
| الطالب 3 | الذهب والتداول والأسعار | `packages/pkg_gold.sql`, `packages/pkg_trading.sql`, `packages/pkg_price.sql` |
| الطالب 4 | واجهات Form Builder + الاختبار + التكامل النهائي | `forms_spec/`, `test_scripts/test_all.sql` |

يبني كل طالب وحدته بالاعتماد على تواقيع الإجراءات (Procedure signatures) الموثّقة في مواصفة كل حزمة، ثم يجتمع الفريق لتشغيل سكربت الاختبار الشامل والتحقق من التكامل قبل بناء النماذج، وأخيراً بناء نماذج Form Builder على الحزم الجاهزة.
