from django.urls import path
from django.conf.urls import include
from django.contrib import admin


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/laundry-room/', include('laundry_room.urls')),
    path('api/v1/study_room/', include('study_room.urls')),
    path('api/v1/printer/', include('printer.urls')),
]
