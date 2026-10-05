-- ============================================================
-- سكربت اختبار شامل - يُشغَّل داخل SQL*Plus بعد تركيب كل الحزم
-- الطالب المسؤول: (4) - الاختبار والتكامل
-- تشغيل: SQL> @test_scripts/test_all.sql
-- ============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_seller_id NUMBER;
    v_buyer_id  NUMBER;
    v_role      VARCHAR2(10);
    v_success   NUMBER;
    v_item_id   NUMBER;
    v_item2_id  NUMBER;
    v_tx_id     NUMBER;
    v_total     NUMBER;
    v_trend     VARCHAR2(50);
    v_avg       NUMBER;
    v_latest    NUMBER;
    v_tx_count  NUMBER;
    v_tx_value  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== TC-01: تسجيل بائع جديد =====');
    pkg_auth.register_user('Test Seller', 'seller_test@aureus.com', '0911111111', 'pass123', 'seller', v_seller_id);
    DBMS_OUTPUT.PUT_LINE('نجح - seller_id=' || v_seller_id);

    DBMS_OUTPUT.PUT_LINE('===== TC-02: تسجيل مشترٍ جديد =====');
    pkg_auth.register_user('Test Buyer', 'buyer_test@aureus.com', '0922222222', 'pass123', 'buyer', v_buyer_id);
    -- نمنح المشتري رصيداً تجريبياً كافياً للاختبار
    UPDATE users SET wallet_balance = 1000000 WHERE user_id = v_buyer_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('نجح - buyer_id=' || v_buyer_id);

    DBMS_OUTPUT.PUT_LINE('===== TC-03: رفض تسجيل بريد مكرر =====');
    BEGIN
        pkg_auth.register_user('Dup', 'seller_test@aureus.com', '0900', 'pass', 'seller', v_item_id);
        DBMS_OUTPUT.PUT_LINE('فشل الاختبار - كان يجب رفض البريد المكرر');
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('نجح - رُفض البريد المكرر (' || SQLERRM || ')');
    END;

    DBMS_OUTPUT.PUT_LINE('===== TC-04: تسجيل دخول ببيانات صحيحة =====');
    pkg_auth.login_user('seller_test@aureus.com', 'pass123', v_item_id, v_role, v_success);
    DBMS_OUTPUT.PUT_LINE('success=' || v_success || ' role=' || v_role);

    DBMS_OUTPUT.PUT_LINE('===== TC-05: رفض دخول بكلمة مرور خاطئة =====');
    pkg_auth.login_user('seller_test@aureus.com', 'wrongpass', v_item_id, v_role, v_success);
    DBMS_OUTPUT.PUT_LINE('success=' || v_success || ' (المتوقع 0)');

    DBMS_OUTPUT.PUT_LINE('===== TC-06: عرض قطعة ذهب للبيع =====');
    pkg_gold.list_gold_item(v_seller_id, '21', 10, 85000, v_item_id);
    DBMS_OUTPUT.PUT_LINE('نجح - item_id=' || v_item_id);

    DBMS_OUTPUT.PUT_LINE('===== TC-07: اتجاه سعر الذهب (الميزة الذكية) =====');
    pkg_price.get_price_trend('21', 5, v_trend, v_avg, v_latest);
    DBMS_OUTPUT.PUT_LINE('trend=' || v_trend || ' avg=' || v_avg || ' latest=' || v_latest);

    DBMS_OUTPUT.PUT_LINE('===== TC-08: شراء ناجح =====');
    pkg_trading.buy_gold(v_buyer_id, v_item_id, 3, v_tx_id, v_total);
    DBMS_OUTPUT.PUT_LINE('نجح - transaction_id=' || v_tx_id || ' total_price=' || v_total);

    DBMS_OUTPUT.PUT_LINE('===== TC-09: رفض شراء كمية أكبر من المتوفر =====');
    BEGIN
        pkg_trading.buy_gold(v_buyer_id, v_item_id, 999, v_tx_id, v_total);
        DBMS_OUTPUT.PUT_LINE('فشل الاختبار - كان يجب رفض الكمية');
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('نجح - رُفضت الكمية (' || SQLERRM || ')');
    END;

    DBMS_OUTPUT.PUT_LINE('===== TC-10: رفض شراء برصيد غير كافٍ =====');
    pkg_gold.list_gold_item(v_seller_id, '24', 5, 999999, v_item2_id);
    BEGIN
        pkg_trading.buy_gold(v_buyer_id, v_item2_id, 5, v_tx_id, v_total);
        DBMS_OUTPUT.PUT_LINE('فشل الاختبار - كان يجب رفض عدم كفاية الرصيد');
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('نجح - رُفض لعدم كفاية الرصيد (' || SQLERRM || ')');
    END;

    DBMS_OUTPUT.PUT_LINE('===== TC-11: تقرير المبيعات (طرف الإدارة) =====');
    pkg_admin.sales_report(v_tx_count, v_tx_value);
    DBMS_OUTPUT.PUT_LINE('عدد المعاملات المكتملة=' || v_tx_count || ' القيمة الإجمالية=' || v_tx_value);

    DBMS_OUTPUT.PUT_LINE('===== انتهى تنفيذ كل حالات الاختبار =====');
END;
/
