import psycopg2
import os
import pandas as pds
import sqlalchemy as sa

user = os.environ.get('DB_USER')
password = os.environ.get('DB_PASSWORD')
host = os.environ.get('DB_HOST')
port = os.environ.get('DB_PORT')
database = os.environ.get('DB_DATABASE')

file_path = os.environ.get('PATH')

def insert_file_into_db():
    conn = None
    try:
        # conn = psycopg2.connect(user=user, password=password, host=host, port=port, database=database
                                # ,options="-c search_path=patent_case,public")
        
        conn = sa.create_engine(f'postgresql://{user}:{password}@{host}:{port}/{database}')

        
        columns = ["ID компании",
                    "Наименование полное",
                    "Наименование краткое",
                    "инн",
                    "Юр адрес",
                    "Факт адрес",
                    "огрн",
                    "Головная компания (1) или филиал (0)",
                    "кпп",
                    "ОКОПФ (код)",
                    "ОКОПФ (расшифровка)",
                    "оквэд2",
                    "ОКВЭД2 расшифровка",
                    "Дата создания",
                    "статус по ЕГРЮЛ ",
                    "ОКФС код",
                    "ОКФС (форма собственности)",
                    "Компания действующая (1) или нет (0)",
                    "id Компании-наследника (реорганиза",
                    "телефоны СПАРК",
                    "почта СПАРК",
                    "сайты",
                    "ФИО директора",
                    "Название должности",
                    "доп. ОКВЭД2"]
        
        # cur = conn.connect()
        for file in os.listdir(file_path):

            file = file_path +'\\'+ file
            dfr = pds.read_csv(file,encoding='utf-8',sep=';', on_bad_lines='skip', header=None, names=columns)

            dfr.to_sql(name='inn_raw', con=conn
                    , schema='inn_matching', if_exists='append'
                    , index= False
                    , chunksize= 2000)                     
            
            print (file)

    except (Exception, psycopg2.Error) as error:
        print("Error: %s" % error) 
    finally:
        if conn is not None:
            conn.dispose()

if __name__=='__main__':
        print('start')
        insert_file_into_db()  
