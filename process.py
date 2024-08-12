import psycopg2
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import re 

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
def split_names(text):
    text = re.sub(r'\(\b[A-Za-zА-Яа-я]{2,3}\b\)', '', text).strip()
    return re.sub(r'([А-Я][а-я]+)([А-Я])', r'\1, \2', text)

# Функция для добавления запятых после каждого ФИО и приведения к нижнему регистру
def process_names(text):
    names = split_names(text).strip().split('\n')
    processed_names = [name.strip().lower() for name in names]
    return ','.join(processed_names)

# Функция для выполнения поисковой функции для одного ФИО и регистрационного номера
def call_search_function(fio, rg, type_p, adrs,auth, pat_nm):
    # conn = None 
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cur = conn.cursor()
        fio = process_names(fio)
        cur.execute('''SELECT o_inn, o_full_name , o_id FROM inn_matching.find_similarity_v2(
                        i_patent_holder := %s
                        , i_reg_num := %s
                        , i_patent_type := %s
                        , i_address := %s
                        , i_author := %s
                        , i_invent_name := %s
                        , upload_id := 20232)'''
                    , (fio, rg, type_p, adrs,auth, pat_nm))
        result = cur.fetchone()
        cur.close()
        conn.close()
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
        cur.execute('''SELECT 
                            s.patent_holder  as fio
                            , s.reg_num
                            ,case p_type
                                when 'полезные модели'
                                then 2 
                                when 'промышленные образцы'
                                then 3      
                                when 'изобретения'
                                then 1
                                else 4
                            END as type_p
                            , s.address as address
                            , s.authors
                            , s.patent_name
                        FROM inn_matching.patent_matching_tbl s 
                        LEFT JOIN inn_matching.patent_request p 
                            ON s.reg_num = p.reg_number::varchar
                        WHERE 
                            p.reg_number IS NULL    
                            and s.patent_holder  != 'NULL'
                            and s.patent_holder IS NOT NULL
                            and s.id >= 660000
                        order by s.patent_holder asc
                        ''')
        
        rows = cur.fetchall()
        fio_list = [row[0] for row in rows]
        rg_list = [row[1] for row in rows]
        type_p = [row[2] for row in rows]
        adr = [row[3] for row in rows]
        authors = [row[4] for row in rows]
        patent_name = [row[5] for row in rows]
        # invent = [row[2] for row in rows]
        # auth = [row[3] for row in rows]
        cur.close()
        conn.close()
        print("get_all_fio done")
        return fio_list, rg_list, type_p, adr, authors, patent_name
    except Exception as e:
        print(f"Error fetching FIO list: {e}")
        return [], [], [], [], [], []

def main():
    fio_list, rg_list, type_p, adrs,auth, pat_nm  = get_all_fio()
    if not fio_list:
        print("No FIOs found or error occurred.")
        return

    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(call_search_function, fio, rg, types, adr,authr, patm)
                   : (fio, rg,types, adr,authr, patm) for fio, rg, types, adr,authr, patm in zip(fio_list, rg_list,type_p, adrs,auth, pat_nm)}
        for future in as_completed(futures):
            fio, rg, id = futures[future]
            try:
                result = future.result()
                print(f"Result for {fio} (Reg. No: {rg}): {result}")
            except Exception as e:
                print(f"Error processing {fio} (Reg. No: {rg}): {e}")

if __name__ == "__main__":
    main()
