from rest_framework import viewsets

from common.models import Floor
from . import serializers


class FloorViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = serializers.FloorSerializer
    queryset = Floor.objects.filter(study_rooms__isnull=False)

