-- ============================================================
-- PKG_AUTH: تسجيل المستخدمين وتسجيل الدخول
-- الطالب المسؤول: (2) - المستخدمون والإدارة
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_auth AS

    FUNCTION hash_password(p_password IN VARCHAR2) RETURN VARCHAR2;

    -- REQ-001/REQ-002: تسجيل مستخدم جديد، رفض البريد المكرر والدور غير الصالح
    PROCEDURE register_user(
        p_full_name IN  VARCHAR2,
        p_email     IN  VARCHAR2,
        p_phone     IN  VARCHAR2,
        p_password  IN  VARCHAR2,
        p_role      IN  VARCHAR2 DEFAULT 'buyer',
        p_user_id   OUT NUMBER
    );

    -- REQ-003: التحقق من بيانات الدخول والتأكد من أن الحساب مفعّل
    PROCEDURE login_user(
        p_email    IN  VARCHAR2,
        p_password IN  VARCHAR2,
        p_user_id  OUT NUMBER,
        p_role     OUT VARCHAR2,
        p_success  OUT NUMBER   -- 1 = نجاح، 0 = فشل
    );

END pkg_auth;
/

CREATE OR REPLACE PACKAGE BODY pkg_auth AS

    FUNCTION hash_password(p_password IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        -- تشفير SHA-256 عبر حزمة DBMS_CRYPTO المدمجة في Oracle
        RETURN RAWTOHEX(
            DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW(p_password), DBMS_CRYPTO.HASH_SH256)
        );
    END hash_password;

    PROCEDURE register_user(
        p_full_name IN  VARCHAR2,
        p_email     IN  VARCHAR2,
        p_phone     IN  VARCHAR2,
        p_password  IN  VARCHAR2,
        p_role      IN  VARCHAR2 DEFAULT 'buyer',
        p_user_id   OUT NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        IF p_role NOT IN ('buyer','seller') THEN
            RAISE_APPLICATION_ERROR(-20001, 'الدور يجب أن يكون buyer أو seller');
        END IF;
        IF INSTR(p_email, '@') = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'بريد إلكتروني غير صالح');
        END IF;

        SELECT COUNT(*) INTO v_count FROM users WHERE email = p_email;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'البريد الإلكتروني مستخدم مسبقاً');
        END IF;

        INSERT INTO users (full_name, email, phone, password_hash, role)
        VALUES (p_full_name, p_email, p_phone, hash_password(p_password), p_role)
        RETURNING user_id INTO p_user_id;

        COMMIT;
    END register_user;

    PROCEDURE login_user(
        p_email    IN  VARCHAR2,
        p_password IN  VARCHAR2,
        p_user_id  OUT NUMBER,
        p_role     OUT VARCHAR2,
        p_success  OUT NUMBER
    ) IS
        v_stored_hash VARCHAR2(255);
        v_is_active   NUMBER;
    BEGIN
        p_success := 0;

        SELECT user_id, password_hash, role, is_active
          INTO p_user_id, v_stored_hash, p_role, v_is_active
          FROM users
         WHERE email = p_email;

        IF v_stored_hash = hash_password(p_password) AND v_is_active = 1 THEN
            p_success := 1;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_user_id := NULL;
    END login_user;

END pkg_auth;
/
