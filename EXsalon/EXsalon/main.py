from db import init_db
from repository import (
    get_all_clients, get_all_masters, get_all_services,
    create_appointment, get_client_appointments, confirm_appointment
)


def main():
    # 1. Инициализация БД
    init_db()

    # 2. Просмотр данных
    print("\n👥 Клиенты:")
    for c in get_all_clients():
        print(f"  [{c['client_id']}] {c['full_name']} — {c['phone']}")

    print("\n💇 Мастера:")
    for m in get_all_masters():
        print(f"  [{m['master_id']}] {m['full_name']} ({m['specialization']})")

    print("\n💅 Услуги:")
    for s in get_all_services():
        print(f"  [{s['service_id']}] {s['name']} — {s['price']}₽ ({s['duration_min']} мин)")

    # 3. Создание новой записи
    new_id = create_appointment(
        client_id=2, master_id=1, service_id=2,
        start_time='2025-10-13 14:00',
        end_time='2025-10-13 14:45'
    )
    print(f"\n✅ Создана запись #{new_id}")

    # 4. Просмотр записей клиента
    print(f"\n📅 Записи клиента #2:")
    for a in get_client_appointments(2):
        print(f"  {a['start_time']} — {a['service_name']} у {a['master_name']} [{a['status']}]")

    # 5. Подтверждение записи
    confirm_appointment(new_id)
    print(f"\n✅ Запись #{new_id} подтверждена")


if __name__ == "__main__":
    main()

