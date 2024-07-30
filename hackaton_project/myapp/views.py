import os
import pandas as pd
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, Http404, JsonResponse
from django.shortcuts import render, redirect
from django.db import connection
import re
import time
import csv 
from concurrent.futures import ThreadPoolExecutor, as_completed 

# Функция для разделения склеенных ФИО
# И убираем (все что в скобках) пренадлежность к стране 
def split_names(text):
    text = re.sub(r'\(\b[A-Za-zА-Яа-я]{2,3}\b\)', '', text).strip()
    return re.sub(r'([А-Я][а-я]+)([А-Я])', r'\1, \2', text)

# Функция для добавления запятых после каждого ФИО и приведения к нижнему регистру
def process_names(text):
    names = split_names(text).strip().split('\n')
    processed_names = [name.strip().lower() for name in names]
    return ','.join(processed_names)

def custom_error_view(request, exception=None):
    error_message = str(exception) if exception else "An unexpected error occurred."
    return render(request, 'error.html', {'error_message': error_message})

def check_in_database(patent_holder, application_num, reg_num, patent_str_dt, allow, unix, author,address, model, classification):

    with connection.cursor() as cursor:
        
        if patent_str_dt == 0:
            patent_str_dt = None

        allow = 1 if str(allow).lower() == 'true' else 0
        cursor.execute("""SELECT o_inn, o_full_name , o_id
                       FROM patent_case.find_similarity(
                            %s::varchar
                            ,%s::int
                            ,%s::int 
                            ,%s::int
                            ,%s::int
                            ,%s::int)"""
                       , [patent_holder,application_num, reg_num, allow, unix, patent_str_dt])
        result = cursor.fetchone()
        if result:
                o_inn, o_full_name, id = result
                cursor.execute("""UPDATE patent_case.patent_request
                                SET author = %s, 
                               address = %s, 
                               model_name = %s, 
                               classific = %s
                               WHERE id = %s"""
                               , [author, address, model, classification, id])
                
                # print ([o_inn, o_full_name])
                return [o_inn, o_full_name]
        else:
            return [None, None]  

def apply_check(row, unix):

    authors = row.get('authors', '')
    correspondence_address = row.get('correspondence address', '')

    # Проверка наличия названий
    name_fields = ['utility model name', 'industrial design name', 'invention name']
    name = next((row[field] for field in name_fields if field in row and pd.notnull(row[field])), '')

    # Проверка наличия mpk и mkpo
    classification_fields = ['mpk', 'mkpo']
    classification = next((row[field] for field in classification_fields if field in row and pd.notnull(row[field])), '')  

    o_inn, o_full_name = check_in_database(
        row['patent holders'],
        row['application number'],
        row['registration number'],
        row['patent starting date'],
        row['actual'],
        unix,
        authors,
        correspondence_address,
        name,
        classification
    )
    # print (o_inn, o_full_name)
    return pd.Series([o_inn, o_full_name])

def upload_file(request):
    if request.method == 'POST' and request.FILES['file']:
        file = request.FILES['file']
        fs = FileSystemStorage(location=settings.MEDIA_ROOT)
        filename = fs.save(file.name, file)
        return redirect('process_file', filename=filename)
    return render(request, 'upload.html')

def search_db(request):
    try:
        inn = request.GET.get('inn')
        if not inn:
            return JsonResponse(status=400, data={'status': 'error', 'message': 'Параметр ИНН отсутствует'})
        if not inn.isnumeric():
            return JsonResponse(status=400, data={'status': 'error', 'message': 'Введенный ИНН не является числом'})
        
        with connection.cursor() as cursor:
            cursor.execute("""SELECT * from patent_case.patent_request WHERE %s::varchar = ANY(string_to_array(inn , ','))""", [inn])
            fields = [field_md[0] for field_md in cursor.description]
            data = [dict(zip(fields,row)) for row in cursor.fetchall()]

        return JsonResponse(data={'status': 'ok', 'data': data})
    except Exception as exc:
        return JsonResponse(status=500, data={'status': 'server_failure', 'message': str(exc)})

def process_file(request, filename):
    try:
        return do_process_file(request, filename)
    except Exception as exc:
        return JsonResponse(status=500, data={'status': 'server_failure', 'message': str(exc)})

def do_process_file(request, filename):
    filepath = os.path.join(settings.MEDIA_ROOT, filename)
    try:
        sniffer = csv.Sniffer()
        with open(filepath, encoding= 'utf-8') as fp:
            delimiter = sniffer.sniff(fp.read(100)).delimiter
        df = pd.read_csv(filepath,sep=delimiter, encoding= 'utf-8-sig')
        unix = int(time.time())
    
    except FileNotFoundError:
        return JsonResponse(status=404, data={'status': 'error', 'message': "File not found"})

    if 'patent holders' in df.columns:
#govnocode = True
        df['patent holders'] = df['patent holders'].apply(process_names)
        df['application number'] = df['application number'].apply(pd.to_numeric, errors='coerce').fillna(0).astype(int)
        df['registration number'] = df['registration number'].apply(pd.to_numeric, errors='coerce').astype(int)

        if 'patent starting date' in df.columns:
            df['patent starting date'] = df['patent starting date'].apply(pd.to_numeric, errors='coerce').fillna(0).astype(int)

#Параллельная обработка
        with ThreadPoolExecutor(max_workers=50) as executor:
            futures = {executor.submit(apply_check, row, unix): index for index, row in df.iterrows()}
            
            for future in as_completed(futures):
                index = futures[future]
                
                try:
                    result = future.result()
                    df.at[index, 'inn'] = result[0]
                    df.at[index, 'full_name'] = result[1]
                except Exception as e:
                    print(f"Error processing row {index}: {e}")

        result_filename = 'result_' + filename
        result_filepath = os.path.join(settings.MEDIA_ROOT, result_filename)

        df.to_csv(result_filepath, index=False)
        return JsonResponse(data={'status': 'ok', 'id': unix, 'filepath': result_filename})
        #хз как сделать редирект нормально
        # return redirect('analytics', unixtime=unix)
    else:
        return JsonResponse(status=400, data={'status': 'error', 'data': "No 'patent holders' column found in the file"})

def analytics_view (request, unix):
    with connection.cursor() as cursor:
        cursor.execute ("""SELECT * FROM patent_case.analytics_by_unix(%s::int)""", [unix])
        fields = [field_md[0] for field_md in cursor.description]
        data = [dict(zip(fields,row)) for row in cursor.fetchall()]

        display = dict()
        # i'm sorry
        for entry in data:
            patent_count = display.setdefault(entry['patent_types'].replace(' ', '_'), [0, 0])
            patent_count[0] += entry['num_of_actual']
            patent_count[1] += entry['num_of_not_actual']

    return render(request, 'analytics.html', {'data': data, 'table': display})

def download(request, filepath):
    with open(os.path.join(settings.MEDIA_ROOT, filepath), 'rb') as f:
        response = HttpResponse(f, content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename={filepath}'
        return response
