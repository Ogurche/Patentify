import os
import pandas as pd
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, Http404
from django.shortcuts import render, redirect

def custom_error_view(request, exception=None):
    error_message = str(exception) if exception else "An unexpected error occurred."
    return render(request, 'error.html', {'error_message': error_message})

def check_in_database(patent_holder):
    # Здесь вы должны реализовать логику проверки в вашей базе данных
    return True  

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
        df = pd.read_csv(filepath, sep=';', encoding= 'utf-8')
    except FileNotFoundError:
        raise Http404("File not found")

    print (df.columns)

    if 'patent holders' in df.columns:
        df['checked'] = df['patent holders'].apply(check_in_database)
        result_filename = 'result_' + filename
        result_filepath = os.path.join(settings.MEDIA_ROOT, result_filename)
        df.to_csv(result_filepath, index=False)
        with open(result_filepath, 'rb') as f:
            response = HttpResponse(f, content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename={result_filename}'
            return response
    else:
        return HttpResponse("No 'patent holders' column found in the file", status=400)
