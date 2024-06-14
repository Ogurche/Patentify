import os
import pandas as pd
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, Http404
from django.shortcuts import render, redirect
from django.db import connection
import re
import time

def custom_error_view(request, exception=None):
    error_message = str(exception) if exception else "An unexpected error occurred."
    return render(request, 'error.html', {'error_message': error_message})

def check_in_database(patent_holder, application_num, reg_num, patent_str_dt, allow, unix):

    with connection.cursor() as cursor:
        
        if patent_str_dt == 0:
            patent_str_dt = None

        allow = 1 if str(allow).lower() == 'true' else 0

        cursor.execute("""SELECT o_inn, o_full_name 
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
                o_inn, o_full_name = result
                return [o_inn, o_full_name]
        else:
            return [None, None]  

def apply_check(row, unix):  
    o_inn, o_full_name = check_in_database(
        row['patent holders'],
        row['application number'],
        row['registration number'],
        row['patent starting date'],
        row['actual'],
        unix
    )
    return pd.Series([o_inn, o_full_name])

def clean_patent_holder(patent_holder):
    return re.sub(r'\(\b[A-Za-zА-Яа-я]{2,3}\b\)', '', patent_holder).strip()

def upload_file(request):
    if request.method == 'POST' and request.FILES['file']:
        file = request.FILES['file']
        fs = FileSystemStorage(location=settings.MEDIA_ROOT)
        filename = fs.save(file.name, file)
        return redirect('process_file', filename=filename)
    return render(request, 'upload.html')

def process_file(request, filename):
    filepath = os.path.join(settings.MEDIA_ROOT, filename)
    try:
        df = pd.read_csv(filepath, sep=',', encoding= 'utf-8-sig')
    except FileNotFoundError:
        raise Http404("File not found")

    unix = int(time.time())

    if 'patent holders' in df.columns:

#govnocode = True
        df['patent holders'] = df['patent holders'].apply(clean_patent_holder)
        df['application number'] = df['application number'].apply(pd.to_numeric, errors='coerce').fillna(0).astype(int)
        df['registration number'] = df['registration number'].apply(pd.to_numeric, errors='coerce').fillna(0).astype(int)

        if 'patent starting date' in df.columns:
            df['patent starting date'] = df['patent starting date'].apply(pd.to_numeric, errors='coerce').fillna(0).astype(int)

        df[['inn', 'full_name']] = df.apply(apply_check, axis=1, args=(unix,))

        result_filename = 'result_' + filename
        result_filepath = os.path.join(settings.MEDIA_ROOT, result_filename)
        df.to_csv(result_filepath, index=False)
        with open(result_filepath, 'rb') as f:
            response = HttpResponse(f, content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename={result_filename}'
            return response
        return redirect('analytics', unixtime=unix)
    else:
        return HttpResponse("No 'patent holders' column found in the file", status=400)

def analytics_view (request, unix):
    with connection.cursor() as cursor:
        cursor.execute ("""SELECT * FROM patent_case.analytics_by_unix(%s::int)""", [unix])
        data = cursor.fetchall()

    return render(request, 'analytics.html', {'data': data})