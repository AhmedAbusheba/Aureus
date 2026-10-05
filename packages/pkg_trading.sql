-- ============================================================
-- PKG_TRADING: تنفيذ عمليات الشراء وسجل المعاملات
-- الطالب المسؤول: (3) - الذهب والتداول
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_trading AS

    -- REQ-006/007/008: تنفيذ عملية شراء متكاملة وذرية (Atomic):
    -- التحقق من التوفر، التحقق من الرصيد، تحديث المحافظ وحالة القطعة، تسجيل المعاملة
    PROCEDURE buy_gold(
        p_buyer_id       IN  NUMBER,
        p_item_id        IN  NUMBER,
        p_quantity_grams IN  NUMBER,
        p_transaction_id OUT NUMBER,
        p_total_price    OUT NUMBER
    );

    -- REQ-009: سجل معاملات المستخدم (كمشترٍ أو بائع)
    PROCEDURE get_user_transactions(
        p_user_id IN  NUMBER,
        p_cursor  OUT SYS_REFCURSOR
    );

END pkg_trading;
/

CREATE OR REPLACE PACKAGE BODY pkg_trading AS

    PROCEDURE buy_gold(
        p_buyer_id       IN  NUMBER,
        p_item_id        IN  NUMBER,
        p_quantity_grams IN  NUMBER,
        p_transaction_id OUT NUMBER,
        p_total_price    OUT NUMBER
    ) IS
        v_status      gold_items.status%TYPE;
        v_weight      gold_items.weight_grams%TYPE;
        v_price_per_g gold_items.price_per_gram%TYPE;
        v_seller_id   gold_items.seller_id%TYPE;
        v_wallet      users.wallet_balance%TYPE;
        v_remaining   NUMBER;
    BEGIN
        -- FOR UPDATE: يقفل صف القطعة لمنع عمليتي شراء متزامنتين على نفس الكمية (NFR-003)
        SELECT status, weight_grams, price_per_gram, seller_id
          INTO v_status, v_weight, v_price_per_g, v_seller_id
          FROM gold_items
         WHERE item_id = p_item_id
           FOR UPDATE;

        IF v_status != 'available' THEN
            RAISE_APPLICATION_ERROR(-20020, 'القطعة غير متاحة للشراء');
        END IF;
        IF p_quantity_grams <= 0 OR p_quantity_grams > v_weight THEN
            RAISE_APPLICATION_ERROR(-20021, 'الكمية المطلوبة غير صالحة');
        END IF;

        p_total_price := ROUND(p_quantity_grams * v_price_per_g, 2);

        SELECT wallet_balance INTO v_wallet
          FROM users WHERE user_id = p_buyer_id FOR UPDATE;

        IF v_wallet < p_total_price THEN
            RAISE_APPLICATION_ERROR(-20022, 'الرصيد غير كافٍ لإتمام عملية الشراء');
        END IF;

        UPDATE users SET wallet_balance = wallet_balance - p_total_price
         WHERE user_id = p_buyer_id;

        UPDATE users SET wallet_balance = wallet_balance + p_total_price
         WHERE user_id = v_seller_id;

        v_remaining := v_weight - p_quantity_grams;
        IF v_remaining <= 0 THEN
            UPDATE gold_items SET status = 'sold' WHERE item_id = p_item_id;
        ELSE
            UPDATE gold_items SET weight_grams = v_remaining WHERE item_id = p_item_id;
        END IF;

        INSERT INTO transactions (item_id, buyer_id, seller_id, quantity_grams, total_price, status)
        VALUES (p_item_id, p_buyer_id, v_seller_id, p_quantity_grams, p_total_price, 'completed')
        RETURNING transaction_id INTO p_transaction_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END buy_gold;

    PROCEDURE get_user_transactions(
        p_user_id IN  NUMBER,
        p_cursor  OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT * FROM transactions
             WHERE buyer_id = p_user_id OR seller_id = p_user_id
             ORDER BY created_at DESC;
    END get_user_transactions;

END pkg_trading;
/
