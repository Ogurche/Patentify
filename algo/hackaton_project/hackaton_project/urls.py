"""
URL configuration for hackaton_project project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from myapp import views
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # Ваши URL-обработчики
    path('admin/', admin.site.urls),
    path('', views.upload_file, name='upload_file'),
    path('search/', views.search_db, name='search'),
    path('process/<str:filename>/', views.process_file, name='process_file'),
    path('download/<str:filepath>/', views.download, name='download'),
    path('analytics/<int:unix>/', views.analytics_view, name='analytics'),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

handler404 = 'myapp.views.custom_error_view'
handler500 = 'myapp.views.custom_error_view'
