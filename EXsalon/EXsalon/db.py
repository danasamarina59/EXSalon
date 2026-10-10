
import sqlite3
from contextlib import contextmanager
from pathlib import Path

DB_PATH = Path(__file__).parent / "beauty_salon.db"
SCHEMA_PATH = Path(__file__).parent / "schema.sql"


def init_db():
    """Инициализация БД: создание таблиц и заполнение тестовыми данными."""
    with sqlite3.connect(DB_PATH) as conn:
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            conn.executescript(f.read())
        conn.commit()
    print(f"✅ База данных создана: {DB_PATH}")


@contextmanager
def get_connection():
    """Контекстный менеджер для подключения к БД."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # доступ по имени колонки
    conn.execute("PRAGMA foreign_keys = ON")  # включаем FK
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
