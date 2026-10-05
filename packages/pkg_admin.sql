-- ============================================================
-- PKG_ADMIN: إدارة المستخدمين وسجل التدقيق والتقارير
-- الطالب المسؤول: (2) - المستخدمون والإدارة
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_admin AS

    PROCEDURE log_action(
        p_admin_id     IN NUMBER,
        p_action       IN VARCHAR2,
        p_target_table IN VARCHAR2 DEFAULT NULL,
        p_target_id    IN NUMBER   DEFAULT NULL
    );

    -- REQ-012: عرض كل المستخدمين، مع فلترة اختيارية بالدور
    PROCEDURE list_users(
        p_role   IN  VARCHAR2 DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    );

    -- REQ-013: تفعيل/إيقاف حساب مستخدم، مع تسجيل الإجراء
    PROCEDURE set_user_active(
        p_admin_id IN NUMBER,
        p_user_id  IN NUMBER,
        p_active   IN NUMBER
    );

    -- REQ-014: تقرير ملخص للمبيعات
    PROCEDURE sales_report(
        p_total_transactions OUT NUMBER,
        p_total_value        OUT NUMBER
    );

END pkg_admin;
/

CREATE OR REPLACE PACKAGE BODY pkg_admin AS

    PROCEDURE log_action(
        p_admin_id     IN NUMBER,
        p_action       IN VARCHAR2,
        p_target_table IN VARCHAR2 DEFAULT NULL,
        p_target_id    IN NUMBER   DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO admin_logs (admin_id, action, target_table, target_id)
        VALUES (p_admin_id, p_action, p_target_table, p_target_id);
        COMMIT;
    END log_action;

    PROCEDURE list_users(
        p_role   IN  VARCHAR2 DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        IF p_role IS NULL THEN
            OPEN p_cursor FOR
                SELECT user_id, full_name, email, role, is_active FROM users;
        ELSE
            OPEN p_cursor FOR
                SELECT user_id, full_name, email, role, is_active
                  FROM users WHERE role = p_role;
        END IF;
    END list_users;

    PROCEDURE set_user_active(
        p_admin_id IN NUMBER,
        p_user_id  IN NUMBER,
        p_active   IN NUMBER
    ) IS
    BEGIN
        UPDATE users SET is_active = p_active WHERE user_id = p_user_id;
        log_action(p_admin_id, 'set_active=' || p_active, 'users', p_user_id);
        COMMIT;
    END set_user_active;

    PROCEDURE sales_report(
        p_total_transactions OUT NUMBER,
        p_total_value        OUT NUMBER
    ) IS
    BEGIN
        SELECT COUNT(*), NVL(SUM(total_price), 0)
          INTO p_total_transactions, p_total_value
          FROM transactions
         WHERE status = 'completed';
    END sales_report;

END pkg_admin;
/
