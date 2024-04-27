from django.urls import path

from . import views


urlpatterns = [
    path('', views.PrintersByUsers.as_view()),
]
