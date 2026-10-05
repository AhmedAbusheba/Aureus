# مواصفات نماذج Form Builder - أوريوس (Aureus)

**ملاحظة مهمة**: Form Builder برنامج تصميم مرئي (IDE) من Oracle، ولا يمكن إنشاء ملفات `.fmb` بالكود مباشرة. هذا الملف مواصفة تفصيلية لكل نموذج (الحقول، الأزرار، والكود اللي يتحط جوّه كل Trigger) — الطالب المسؤول عن الواجهات ينشئ النماذج فعلياً داخل Form Builder ويلصق الكود المذكور هنا في الـ Trigger المناسب. **الطالب المسؤول: (4) - الواجهات والتكامل.**

كل النماذج تستدعي حزم PL/SQL الجاهزة (PKG_AUTH, PKG_GOLD, PKG_PRICE, PKG_TRADING, PKG_ADMIN) ولا تكتب أي منطق أعمال مباشرة داخل النموذج — الفصل بين الواجهة والمنطق (NFR-005).

---

## 1) FRM_LOGIN - نموذج الدخول

**Block**: BLK_LOGIN (Non-database block)
**Items**: TXT_EMAIL (Text), TXT_PASSWORD (Text, Password Case = True), BTN_LOGIN (Button), BTN_GOTO_REGISTER (Button)

**Trigger: BTN_LOGIN → WHEN-BUTTON-PRESSED**
```plsql
DECLARE
    v_user_id NUMBER;
    v_role    VARCHAR2(10);
    v_success NUMBER;
BEGIN
    pkg_auth.login_user(:BLK_LOGIN.TXT_EMAIL, :BLK_LOGIN.TXT_PASSWORD,
                         v_user_id, v_role, v_success);
    IF v_success = 1 THEN
        :GLOBAL.G_USER_ID := v_user_id;    -- متغير عام يُستخدم في كل النماذج التالية
        :GLOBAL.G_ROLE    := v_role;
        IF v_role = 'admin' THEN
            CALL_FORM('frm_admin');
        ELSIF v_role = 'seller' THEN
            CALL_FORM('frm_seller');
        ELSE
            CALL_FORM('frm_buyer');
        END IF;
    ELSE
        MESSAGE('بيانات الدخول غير صحيحة أو الحساب موقوف');
    END IF;
EXCEPTION
    WHEN OTHERS THEN MESSAGE('خطأ: ' || SQLERRM);
END;
```

**Trigger: BTN_GOTO_REGISTER → WHEN-BUTTON-PRESSED**: `CALL_FORM('frm_register');`

---

## 2) FRM_REGISTER - نموذج تسجيل حساب جديد

**Block**: BLK_REGISTER (Non-database)
**Items**: TXT_NAME, TXT_EMAIL, TXT_PHONE, TXT_PASSWORD (Password Case), RG_ROLE (Radio Group: buyer/seller), BTN_SUBMIT

**Trigger: BTN_SUBMIT → WHEN-BUTTON-PRESSED**
```plsql
DECLARE
    v_user_id NUMBER;
BEGIN
    pkg_auth.register_user(:BLK_REGISTER.TXT_NAME, :BLK_REGISTER.TXT_EMAIL,
                            :BLK_REGISTER.TXT_PHONE, :BLK_REGISTER.TXT_PASSWORD,
                            :BLK_REGISTER.RG_ROLE, v_user_id);
    MESSAGE('تم إنشاء الحساب برقم ' || v_user_id);
    CALL_FORM('frm_login');
EXCEPTION
    WHEN OTHERS THEN MESSAGE('خطأ: ' || SQLERRM);
END;
```

---

## 3) FRM_BUYER - لوحة المشتري

**Canvas 1 - تصفح القطع المتاحة**
**Block**: BLK_ITEMS (Multi-Record Block مبني على `pkg_gold.get_available_items` عبر REF CURSOR، أو استعلام مباشر `SELECT * FROM gold_items WHERE status='available'` إذا فُضّل Data Block عادي)
**Items**: عرض ITEM_ID, KARAT, WEIGHT_GRAMS, PRICE_PER_GRAM + TXT_QTY (إدخال الكمية) + BTN_BUY

**Trigger: BTN_BUY → WHEN-BUTTON-PRESSED**
```plsql
DECLARE
    v_tx_id NUMBER;
    v_total NUMBER;
BEGIN
    pkg_trading.buy_gold(:GLOBAL.G_USER_ID, :BLK_ITEMS.ITEM_ID,
                          :BLK_ITEMS.TXT_QTY, v_tx_id, v_total);
    MESSAGE('تمت عملية الشراء - رقم المعاملة ' || v_tx_id || ' بقيمة ' || v_total);
    GO_BLOCK('BLK_ITEMS'); EXECUTE_QUERY;  -- تحديث القائمة
EXCEPTION
    WHEN OTHERS THEN MESSAGE('خطأ: ' || SQLERRM);
END;
```

**Canvas 2 - سجل معاملاتي** (Block: BLK_MY_TX، مصدره `pkg_trading.get_user_transactions`)

**Canvas 3 - اتجاه السعر**: LOV بالعيار + BTN_CHECK_TREND
```plsql
DECLARE
    v_trend VARCHAR2(50); v_avg NUMBER; v_latest NUMBER;
BEGIN
    pkg_price.get_price_trend(:BLK_TREND.LOV_KARAT, 5, v_trend, v_avg, v_latest);
    :BLK_TREND.TXT_RESULT := 'الاتجاه: ' || v_trend || ' | المتوسط: ' || v_avg;
END;
```

---

## 4) FRM_SELLER - لوحة البائع

**Block**: BLK_NEW_ITEM (Non-database) — LOV_KARAT, TXT_WEIGHT, TXT_PRICE, BTN_LIST

**Trigger: BTN_LIST → WHEN-BUTTON-PRESSED**
```plsql
DECLARE
    v_item_id NUMBER;
BEGIN
    pkg_gold.list_gold_item(:GLOBAL.G_USER_ID, :BLK_NEW_ITEM.LOV_KARAT,
                             :BLK_NEW_ITEM.TXT_WEIGHT, :BLK_NEW_ITEM.TXT_PRICE, v_item_id);
    MESSAGE('تم عرض القطعة برقم ' || v_item_id);
    CLEAR_FORM;
EXCEPTION
    WHEN OTHERS THEN MESSAGE('خطأ: ' || SQLERRM);
END;
```

**Canvas 2 - سجل معاملاتي**: نفس بنية FRM_BUYER (Block مصدره `pkg_trading.get_user_transactions`)

---

## 5) FRM_ADMIN - لوحة الإدارة

**Canvas 1 - المستخدمون** (Block: BLK_USERS، مصدره `pkg_admin.list_users`)
**Items إضافية**: LOV_FILTER_ROLE، BTN_TOGGLE_ACTIVE

**Trigger: BTN_TOGGLE_ACTIVE → WHEN-BUTTON-PRESSED**
```plsql
BEGIN
    pkg_admin.set_user_active(:GLOBAL.G_USER_ID, :BLK_USERS.USER_ID,
                               1 - :BLK_USERS.IS_ACTIVE);  -- يعكس الحالة الحالية
    GO_BLOCK('BLK_USERS'); EXECUTE_QUERY;
EXCEPTION
    WHEN OTHERS THEN MESSAGE('خطأ: ' || SQLERRM);
END;
```

**Canvas 2 - تقرير المبيعات**: BTN_LOAD_REPORT
```plsql
DECLARE
    v_count NUMBER; v_value NUMBER;
BEGIN
    pkg_admin.sales_report(v_count, v_value);
    :BLK_REPORT.TXT_COUNT := v_count;
    :BLK_REPORT.TXT_VALUE := v_value;
END;
```

---

## ملاحظات تصميم عامة

- عرّف متغيرات عامة (Global Variables) في FRM_LOGIN: `G_USER_ID`, `G_ROLE` — تُستخدم لتمرير هوية المستخدم بين النماذج بدل تسجيل الدخول من جديد في كل نموذج.
- كل الحقول اللي بتاخد بيانات من Cursor (REF CURSOR راجع من الحزم) تحتاج Block من نوع "Non-database" مع برمجة الاستعلام يدوياً في WHEN-NEW-BLOCK-INSTANCE، أو ببساطة استخدم Data Block عادي مبني مباشرة على الجداول (gold_items, transactions, users) للعرض فقط، وخلّي كل التعديل (Insert/Update) يمر حصرياً عبر استدعاء الحزم كما في الأمثلة أعلاه — هذا يحافظ على قواعد التحقق (Validation) الموجودة في PL/SQL ولا يكرر المنطق في الفورم.
- زر "رجوع" أو "تسجيل خروج" في كل نموذج: `CALL_FORM('frm_login');`
