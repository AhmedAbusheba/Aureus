-- ============================================================
-- Aureus | أوريوس - نظام إدارة مستخدمي بيع وشراء الذهب
-- قاعدة البيانات: Oracle Database (SQL*Plus)
-- ============================================================
-- شغّل هذا الملف أولاً قبل أي حزمة (Package):
--   SQL> @database/schema.sql
-- ============================================================

-- ------------------------------------------------------------
-- التسلسلات (Sequences) - تولّد المفاتيح الأساسية تلقائياً
-- ------------------------------------------------------------
CREATE SEQUENCE seq_users          START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_gold_items     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_price_history  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_transactions   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_admin_logs     START WITH 1 INCREMENT BY 1;

-- ------------------------------------------------------------
-- 1. users: المشترون والبائعون والمدراء
-- ------------------------------------------------------------
CREATE TABLE users (
    user_id        NUMBER          PRIMARY KEY,
    full_name      VARCHAR2(100)   NOT NULL,
    email          VARCHAR2(100)   NOT NULL UNIQUE,
    phone          VARCHAR2(20),
    password_hash  VARCHAR2(255)   NOT NULL,
    role           VARCHAR2(10)    DEFAULT 'buyer' NOT NULL,
    wallet_balance NUMBER(15,2)    DEFAULT 0 NOT NULL,
    is_active      NUMBER(1)       DEFAULT 1 NOT NULL,
    created_at     DATE            DEFAULT SYSDATE,
    CONSTRAINT chk_role CHECK (role IN ('buyer','seller','admin')),
    CONSTRAINT chk_wallet_nonneg CHECK (wallet_balance >= 0),
    CONSTRAINT chk_is_active CHECK (is_active IN (0,1))
);

CREATE OR REPLACE TRIGGER trg_users_bi
BEFORE INSERT ON users FOR EACH ROW
WHEN (NEW.user_id IS NULL)
BEGIN
    :NEW.user_id := seq_users.NEXTVAL;
END;
/

-- ------------------------------------------------------------
-- 2. gold_items: قطع الذهب المعروضة للبيع
-- ------------------------------------------------------------
CREATE TABLE gold_items (
    item_id         NUMBER          PRIMARY KEY,
    seller_id       NUMBER          NOT NULL,
    karat           VARCHAR2(2)     NOT NULL,
    weight_grams    NUMBER(10,3)    NOT NULL,
    price_per_gram  NUMBER(12,2)    NOT NULL,
    status          VARCHAR2(10)    DEFAULT 'available' NOT NULL,
    listed_at       DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_item_seller FOREIGN KEY (seller_id) REFERENCES users(user_id),
    CONSTRAINT chk_karat CHECK (karat IN ('18','21','24')),
    CONSTRAINT chk_item_status CHECK (status IN ('available','reserved','sold')),
    CONSTRAINT chk_weight_pos CHECK (weight_grams > 0),
    CONSTRAINT chk_price_pos CHECK (price_per_gram > 0)
);

CREATE OR REPLACE TRIGGER trg_gold_items_bi
BEFORE INSERT ON gold_items FOR EACH ROW
WHEN (NEW.item_id IS NULL)
BEGIN
    :NEW.item_id := seq_gold_items.NEXTVAL;
END;
/

-- ------------------------------------------------------------
-- 3. gold_price_history: يغذّي ميزة اتجاه السعر الذكي
-- ------------------------------------------------------------
CREATE TABLE gold_price_history (
    price_id        NUMBER          PRIMARY KEY,
    karat           VARCHAR2(2)     NOT NULL,
    price_per_gram  NUMBER(12,2)    NOT NULL,
    recorded_at     DATE            DEFAULT SYSDATE,
    CONSTRAINT chk_ph_karat CHECK (karat IN ('18','21','24'))
);

CREATE OR REPLACE TRIGGER trg_price_history_bi
BEFORE INSERT ON gold_price_history FOR EACH ROW
WHEN (NEW.price_id IS NULL)
BEGIN
    :NEW.price_id := seq_price_history.NEXTVAL;
END;
/

-- ------------------------------------------------------------
-- 4. transactions: عمليات الشراء والبيع
-- ------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id   NUMBER          PRIMARY KEY,
    item_id          NUMBER          NOT NULL,
    buyer_id         NUMBER          NOT NULL,
    seller_id        NUMBER          NOT NULL,
    quantity_grams   NUMBER(10,3)    NOT NULL,
    total_price      NUMBER(15,2)    NOT NULL,
    status           VARCHAR2(10)    DEFAULT 'pending' NOT NULL,
    created_at       DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_tx_item   FOREIGN KEY (item_id)   REFERENCES gold_items(item_id),
    CONSTRAINT fk_tx_buyer  FOREIGN KEY (buyer_id)  REFERENCES users(user_id),
    CONSTRAINT fk_tx_seller FOREIGN KEY (seller_id) REFERENCES users(user_id),
    CONSTRAINT chk_tx_status CHECK (status IN ('pending','completed','cancelled'))
);

CREATE OR REPLACE TRIGGER trg_transactions_bi
BEFORE INSERT ON transactions FOR EACH ROW
WHEN (NEW.transaction_id IS NULL)
BEGIN
    :NEW.transaction_id := seq_transactions.NEXTVAL;
END;
/

-- ------------------------------------------------------------
-- 5. admin_logs: سجل تدقيق إجراءات الإدارة
-- ------------------------------------------------------------
CREATE TABLE admin_logs (
    log_id        NUMBER          PRIMARY KEY,
    admin_id      NUMBER          NOT NULL,
    action        VARCHAR2(255)   NOT NULL,
    target_table  VARCHAR2(50),
    target_id     NUMBER,
    created_at    DATE            DEFAULT SYSDATE,
    CONSTRAINT fk_log_admin FOREIGN KEY (admin_id) REFERENCES users(user_id)
);

CREATE OR REPLACE TRIGGER trg_admin_logs_bi
BEFORE INSERT ON admin_logs FOR EACH ROW
WHEN (NEW.log_id IS NULL)
BEGIN
    :NEW.log_id := seq_admin_logs.NEXTVAL;
END;
/

-- ------------------------------------------------------------
-- فهارس مساعدة
-- ------------------------------------------------------------
CREATE INDEX idx_items_status ON gold_items(status);
CREATE INDEX idx_tx_buyer     ON transactions(buyer_id);
CREATE INDEX idx_tx_seller    ON transactions(seller_id);
CREATE INDEX idx_price_karat  ON gold_price_history(karat, recorded_at);

COMMIT;
