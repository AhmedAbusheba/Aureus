-- ============================================================
-- PKG_GOLD: عرض قطع الذهب المتاحة للبيع (طرف البائع)
-- الطالب المسؤول: (3) - الذهب والتداول
-- ملاحظة: يعتمد على PKG_PRICE - شغّل pkg_price.sql قبل هذا الملف
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_gold AS

    -- REQ-004: بائع يعرض كمية ذهب جديدة للبيع
    PROCEDURE list_gold_item(
        p_seller_id      IN  NUMBER,
        p_karat          IN  VARCHAR2,
        p_weight_grams   IN  NUMBER,
        p_price_per_gram IN  NUMBER,
        p_item_id        OUT NUMBER
    );

    -- REQ-005: عرض كل القطع المتاحة، مع فلترة اختيارية بالعيار
    PROCEDURE get_available_items(
        p_karat  IN  VARCHAR2 DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    );

END pkg_gold;
/

CREATE OR REPLACE PACKAGE BODY pkg_gold AS

    PROCEDURE list_gold_item(
        p_seller_id      IN  NUMBER,
        p_karat          IN  VARCHAR2,
        p_weight_grams   IN  NUMBER,
        p_price_per_gram IN  NUMBER,
        p_item_id        OUT NUMBER
    ) IS
    BEGIN
        IF p_karat NOT IN ('18','21','24') THEN
            RAISE_APPLICATION_ERROR(-20010, 'عيار الذهب يجب أن يكون 18 أو 21 أو 24');
        END IF;
        IF p_weight_grams <= 0 OR p_price_per_gram <= 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'الوزن والسعر يجب أن يكونا أكبر من صفر');
        END IF;

        INSERT INTO gold_items (seller_id, karat, weight_grams, price_per_gram)
        VALUES (p_seller_id, p_karat, p_weight_grams, p_price_per_gram)
        RETURNING item_id INTO p_item_id;

        pkg_price.record_price(p_karat, p_price_per_gram);
        COMMIT;
    END list_gold_item;

    PROCEDURE get_available_items(
        p_karat  IN  VARCHAR2 DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        IF p_karat IS NULL THEN
            OPEN p_cursor FOR
                SELECT * FROM gold_items
                 WHERE status = 'available'
                 ORDER BY listed_at DESC;
        ELSE
            OPEN p_cursor FOR
                SELECT * FROM gold_items
                 WHERE status = 'available' AND karat = p_karat
                 ORDER BY listed_at DESC;
        END IF;
    END get_available_items;

END pkg_gold;
/
