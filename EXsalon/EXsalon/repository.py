from db import get_connection


# ---------- Клиенты ----------
def get_all_clients():
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM clients ORDER BY full_name"
        ).fetchall()


def add_client(full_name, phone, email=None, user_id=None):
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO clients (user_id, full_name, phone, email)
               VALUES (?, ?, ?, ?)""",
            (user_id, full_name, phone, email)
        )
        return cur.lastrowid


def find_client_by_phone(phone):
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM clients WHERE phone = ?", (phone,)
        ).fetchone()


# ---------- Мастера ----------
def get_all_masters(only_active=True):
    with get_connection() as conn:
        sql = "SELECT * FROM masters"
        if only_active:
            sql += " WHERE is_active = 1"
        return conn.execute(sql).fetchall()


def get_master_services(master_id):
    """Услуги, которые оказывает конкретный мастер."""
    with get_connection() as conn:
        return conn.execute("""
            SELECT s.*
            FROM services s
            JOIN master_services ms ON ms.service_id = s.service_id
            WHERE ms.master_id = ?
        """, (master_id,)).fetchall()


# ---------- Услуги ----------
def get_all_services():
    with get_connection() as conn:
        return conn.execute(
            "SELECT * FROM services ORDER BY category, name"
        ).fetchall()


# ---------- Расписание ----------
def get_master_schedule(master_id, date):
    with get_connection() as conn:
        return conn.execute(
            """SELECT * FROM schedules
               WHERE master_id = ? AND work_date = ?""",
            (master_id, date)
        ).fetchall()


def get_free_slots(master_id, date, service_duration):
    """Возвращает список свободных слотов для мастера на дату."""
    with get_connection() as conn:
        # Рабочие часы мастера
        sched = conn.execute(
            """SELECT start_time, end_time FROM schedules
               WHERE master_id = ? AND work_date = ?""",
            (master_id, date)
        ).fetchone()
        if not sched:
            return []

        # Занятые интервалы
        busy = conn.execute(
            """SELECT start_time, end_time FROM appointments
               WHERE master_id = ? AND date(start_time) = ?
                 AND status IN ('pending', 'confirmed')""",
            (master_id, date)
        ).fetchall()

        # Здесь можно реализовать логику нарезки свободных окон
        return [dict(s) for s in busy]


# ---------- Записи ----------
def create_appointment(client_id, master_id, service_id, start_time, end_time):
    with get_connection() as conn:
        cur = conn.execute(
            """INSERT INTO appointments
               (client_id, master_id, service_id, start_time, end_time, status)
               VALUES (?, ?, ?, ?, ?, 'pending')""",
            (client_id, master_id, service_id, start_time, end_time)
        )
        return cur.lastrowid


def confirm_appointment(appointment_id):
    with get_connection() as conn:
        conn.execute(
            "UPDATE appointments SET status = 'confirmed' WHERE appointment_id = ?",
            (appointment_id,)
        )


def cancel_appointment(appointment_id):
    with get_connection() as conn:
        conn.execute(
            "UPDATE appointments SET status = 'cancelled' WHERE appointment_id = ?",
            (appointment_id,)
        )


def get_client_appointments(client_id):
    with get_connection() as conn:
        return conn.execute("""
            SELECT a.*, s.name AS service_name, m.full_name AS master_name
            FROM appointments a
            JOIN services s ON s.service_id = a.service_id
            JOIN masters  m ON m.master_id  = a.master_id
            WHERE a.client_id = ?
            ORDER BY a.start_time DESC
        """, (client_id,)).fetchall()


def get_master_appointments_for_day(master_id, date):
    with get_connection() as conn:
        return conn.execute("""
            SELECT a.*, s.name AS service_name, c.full_name AS client_name
            FROM appointments a
            JOIN services s ON s.service_id = a.service_id
            JOIN clients  c ON c.client_id  = a.client_id
            WHERE a.master_id = ? AND date(a.start_time) = ?
            ORDER BY a.start_time
        """, (master_id, date)).fetchall()
