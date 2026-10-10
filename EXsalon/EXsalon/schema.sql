-- ============================================
-- База данных салона красоты
-- ============================================

-- Удаление таблиц в обратном порядке (от зависимых к независимым)
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS schedules;
DROP TABLE IF EXISTS master_services;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS masters;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS users;

-- ============================================
-- 1. ПОЛЬЗОВАТЕЛИ
-- ============================================
CREATE TABLE users (
    user_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    login         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('client', 'master', 'admin')),
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================
-- 2. КЛИЕНТЫ
-- ============================================
CREATE TABLE clients (
    client_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER UNIQUE,
    full_name   TEXT NOT NULL,
    phone       TEXT NOT NULL UNIQUE,
    email       TEXT,
    birth_date  TEXT,
    notes       TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ============================================
-- 3. МАСТЕРА
-- ============================================
CREATE TABLE masters (
    master_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id        INTEGER UNIQUE,
    full_name      TEXT NOT NULL,
    specialization TEXT NOT NULL,
    phone          TEXT,
    hire_date      TEXT,
    is_active      INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ============================================
-- 4. УСЛУГИ
-- ============================================
CREATE TABLE services (
    service_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL,
    category     TEXT NOT NULL,
    price        REAL NOT NULL CHECK (price >= 0),
    duration_min INTEGER NOT NULL CHECK (duration_min > 0),
    description  TEXT
);

-- ============================================
-- 5. СВЯЗЬ МАСТЕР ↔ УСЛУГА (M:N)
-- ============================================
CREATE TABLE master_services (
    master_id  INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    PRIMARY KEY (master_id, service_id),
    FOREIGN KEY (master_id)  REFERENCES masters(master_id)  ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE
);

-- ============================================
-- 6. РАСПИСАНИЕ МАСТЕРОВ
-- ============================================
CREATE TABLE schedules (
    schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
    master_id   INTEGER NOT NULL,
    work_date   TEXT NOT NULL,
    start_time  TEXT NOT NULL,
    end_time    TEXT NOT NULL,
    FOREIGN KEY (master_id) REFERENCES masters(master_id) ON DELETE CASCADE,
    UNIQUE (master_id, work_date, start_time)
);

-- ============================================
-- 7. ЗАПИСИ
-- ============================================
CREATE TABLE appointments (
    appointment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id      INTEGER NOT NULL,
    master_id      INTEGER NOT NULL,
    service_id     INTEGER NOT NULL,
    start_time     TEXT NOT NULL,
    end_time       TEXT NOT NULL,
    status         TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at     TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (client_id)  REFERENCES clients(client_id)  ON DELETE CASCADE,
    FOREIGN KEY (master_id)  REFERENCES masters(master_id)  ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
);

-- ============================================
-- ИНДЕКСЫ
-- ============================================
CREATE INDEX idx_appointments_master  ON appointments(master_id, start_time);
CREATE INDEX idx_appointments_client  ON appointments(client_id);
CREATE INDEX idx_schedules_master     ON schedules(master_id, work_date);

-- ============================================
-- НАЧАЛЬНЫЕ ДАННЫЕ
-- ============================================

-- ---------- Пользователи ----------
-- role: admin | master | client
INSERT INTO users (login, password_hash, role) VALUES
('admin',      'hash_admin_123',    'admin'),
('ivanova',    'hash_master_123',   'master'),
('petrova',    'hash_master_456',   'master'),
('smirnov',    'hash_master_789',   'master'),
('client1',    'hash_client_123',   'client'),
('client2',    'hash_client_456',   'client'),
-- ⬇⬇⬇ НОВЫЕ пользователи-клиенты ⬇⬇⬇
('fistin',     'hash_client_789',   'client'),   -- Фистин Семён
('vashchenko', 'hash_client_101',   'client'),   -- Ващенко Ева
('samarina',   'hash_client_112',   'client');   -- Самарина Милана

-- ---------- Клиенты ----------
-- user_id: 5=client1, 6=client2, 7=fistin, 8=vashchenko, 9=samarina
INSERT INTO clients (user_id, full_name, phone, email, birth_date, notes) VALUES
(5, 'Серова Вера Петровна',      '+79001112233', 'serova@mail.ru',    '1995-04-12', 'Постоянный клиент'),
(6, 'Кузнецов Игорь Олегович',   '+79004445566', 'kuznetsov@mail.ru', '1988-11-30', NULL),
-- ⬇⬇⬇ НОВЫЕ клиенты ⬇⬇⬇
(7, 'Фистин Семён Андреевич',    '+79007778899', 'fistin@mail.ru',    '1992-07-18', 'Записывается на стрижку'),
(8, 'Ващенко Ева Дмитриевна',    '+79002223344', 'vashchenko@mail.ru', '2000-02-25', 'Предпочитает маникюр'),
(9, 'Самарина Милана Александровна', '+79005556677', 'samarina@mail.ru', '1997-09-05', 'Постоянный клиент, косметология');

-- ---------- Мастера ----------
-- user_id: 2=ivanova, 3=petrova, 4=smirnov
INSERT INTO masters (user_id, full_name, specialization, phone, hire_date) VALUES
(2, 'Иванова Анна Сергеевна',    'Парикмахер',   '+79002223344', '2022-03-01'),
(3, 'Петрова Мария Ивановна',   'Маникюр',      '+79005556677', '2023-06-15'),
(4, 'Смирнов Алексей Петрович', 'Косметолог',   '+79008889900', '2021-09-10');

-- ---------- Услуги ----------
INSERT INTO services (name, category, price, duration_min, description) VALUES
('Стрижка женская',      'Парикмахерские', 1500, 60, 'Модельная стрижка с укладкой'),
('Стрижка мужская',      'Парикмахерские', 1000, 45, 'Классическая мужская стрижка'),
('Маникюр классический', 'Ногтевой сервис', 1200, 60, 'Обработка и покрытие'),
('Педикюр',              'Ногтевой сервис', 1800, 90, 'Полная обработка стоп'),
('Чистка лица',          'Косметология',    2500, 75, 'Ультразвуковая чистка'),
('Массаж лица',          'Косметология',    2000, 60, 'Расслабляющий массаж');

-- ---------- Какие услуги оказывает какой мастер ----------
INSERT INTO master_services (master_id, service_id) VALUES
(1, 1), (1, 2),           -- Иванова: стрижки
(2, 3), (2, 4),           -- Петрова: маникюр/педикюр
(3, 5), (3, 6);           -- Смирнов: косметология

-- ---------- Расписание мастеров ----------
INSERT INTO schedules (master_id, work_date, start_time, end_time) VALUES
(1, '2025-10-13', '09:00', '18:00'),
(1, '2025-10-14', '09:00', '18:00'),
(2, '2025-10-13', '10:00', '19:00'),
(2, '2025-10-14', '10:00', '19:00'),
(3, '2025-10-15', '11:00', '20:00');

-- ---------- Записи ----------
-- client_id: 1=Серова, 2=Кузнецов, 3=Фистин, 4=Ващенко, 5=Самарина
INSERT INTO appointments (client_id, master_id, service_id, start_time, end_time, status) VALUES
-- Серова Вера
(1, 1, 1, '2025-10-13 10:00', '2025-10-13 11:00', 'confirmed'),
(1, 2, 3, '2025-10-14 12:00', '2025-10-14 13:00', 'pending'),
-- Кузнецов Игорь
(2, 3, 5, '2025-10-15 11:00', '2025-10-15 12:15', 'confirmed'),
-- ⬇⬇⬇ НОВЫЕ записи ⬇⬇⬇
-- Фистин Семён — на мужскую стрижку к Ивановой
(3, 1, 2, '2025-10-13 15:00', '2025-10-13 15:45', 'confirmed'),
(3, 1, 2, '2025-10-20 15:00', '2025-10-20 15:45', 'pending'),
-- Ващенко Ева — на маникюр к Петровой
(4, 2, 3, '2025-10-13 12:00', '2025-10-13 13:00', 'confirmed'),
-- Самарина Милана — на чистку лица к Смирнову
(5, 3, 5, '2025-10-15 13:00', '2025-10-15 14:15', 'pending'),
(5, 3, 6, '2025-10-22 13:00', '2025-10-22 14:00', 'pending');
