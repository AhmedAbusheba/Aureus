-- ============================================================
-- PKG_PRICE: تسجيل أسعار الذهب وتحليل الاتجاه (الميزة الذكية)
-- الطالب المسؤول: (1) - قاعدة البيانات والأسعار
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_price AS

    PROCEDURE record_price(
        p_karat          IN VARCHAR2,
        p_price_per_gram IN NUMBER
    );

    -- REQ-011: الميزة الذكية - يحسب اتجاه السعر بمقارنة آخر سعر
    -- بمتوسط آخر N سعر مسجّل (صاعد / هابط / مستقر)
    PROCEDURE get_price_trend(
        p_karat   IN  VARCHAR2,
        p_last_n  IN  NUMBER DEFAULT 5,
        p_trend   OUT VARCHAR2,
        p_average OUT NUMBER,
        p_latest  OUT NUMBER
    );

END pkg_price;
/

CREATE OR REPLACE PACKAGE BODY pkg_price AS

    PROCEDURE record_price(
        p_karat          IN VARCHAR2,
        p_price_per_gram IN NUMBER
    ) IS
    BEGIN
        INSERT INTO gold_price_history (karat, price_per_gram)
        VALUES (p_karat, p_price_per_gram);
        COMMIT;
    END record_price;

    PROCEDURE get_price_trend(
        p_karat   IN  VARCHAR2,
        p_last_n  IN  NUMBER DEFAULT 5,
        p_trend   OUT VARCHAR2,
        p_average OUT NUMBER,
        p_latest  OUT NUMBER
    ) IS
        CURSOR c_prices IS
            SELECT price_per_gram
              FROM (SELECT price_per_gram
                      FROM gold_price_history
                     WHERE karat = p_karat
                     ORDER BY recorded_at DESC)
             WHERE ROWNUM <= p_last_n;

        v_sum   NUMBER := 0;
        v_count NUMBER := 0;
        v_first BOOLEAN := TRUE;
    BEGIN
        FOR rec IN c_prices LOOP
            IF v_first THEN
                p_latest := rec.price_per_gram;
                v_first := FALSE;
            END IF;
            v_sum   := v_sum + rec.price_per_gram;
            v_count := v_count + 1;
        END LOOP;

        IF v_count = 0 THEN
            p_trend   := 'لا توجد بيانات كافية';
            p_average := NULL;
            p_latest  := NULL;
            RETURN;
        END IF;

        p_average := ROUND(v_sum / v_count, 2);

        IF p_latest > p_average * 1.01 THEN
            p_trend := 'صاعد';
        ELSIF p_latest < p_average * 0.99 THEN
            p_trend := 'هابط';
        ELSE
            p_trend := 'مستقر';
        END IF;
    END get_price_trend;

END pkg_price;
/
