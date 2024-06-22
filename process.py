import psycopg2
from concurrent.futures import ThreadPoolExecutor, as_completed
import os 

user = os.environ.get('DB_USER')
password = os.environ.get('DB_PASSWORD')
host = os.environ.get('DB_HOST')
port = os.environ.get('DB_PORT')
database = os.environ.get('DB_DATABASE')

# Настройки подключения к базе данных PostgreSQL
DB_CONFIG = {
    'dbname': database,
    'user': user,
    'password': password,
    'host': host,
    'port': port,
}

# pool = ThreadPoolExecutor(150)

# Функция для выполнения поисковой функции для одного ФИО и регистрационного номера
def call_search_function(fio, rg):
    # conn = None 
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("SELECT o_inn, o_full_name , o_id FROM patent_case.find_similarity_2(i_patent_holder := %s, i_reg_num := %s)", (fio, rg))
        result = cur.fetchone()
        # conn.commit()
        cur.close()
        conn.close()
        # print('done')
        return result
    except Exception as e:
        print(f"Error processing {fio}: {e}")
        return None
    # finally:
    #     if conn:
    #         pool.putconn(conn)

# Функция для получения всех ФИО и регистрационных номеров из таблицы патентов
def get_all_fio():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute('''SELECT s.patent_holders as fio, s.﻿registration_number 
                    FROM patent_case.invention_raw s 
                    LEFT JOIN patent_case.patent_request p 
                    ON s.﻿registration_number = p.reg_number::varchar
                    WHERE p.reg_number IS NULL
                    and s.patent_holders != 'NULL'
                    order by s.patent_holders asc ''')
        rows = cur.fetchall()
        fio_list = [row[0] for row in rows]
        rg_list = [row[1] for row in rows]
        cur.close()
        conn.close()
        print("get_all_fio done")
        return fio_list, rg_list
    except Exception as e:
        print(f"Error fetching FIO list: {e}")
        return [], []

def main():
    fio_list, rg_list = get_all_fio()
    if not fio_list:
        print("No FIOs found or error occurred.")
        return

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(call_search_function, fio, rg): (fio, rg) for fio, rg in zip(fio_list, rg_list)}
        for future in as_completed(futures):
            fio, rg = futures[future]
            try:
                result = future.result()
                print(f"Result for {fio} (Reg. No: {rg}): {result}")
            except Exception as e:
                print(f"Error processing {fio} (Reg. No: {rg}): {e}")

if __name__ == "__main__":
    main()
