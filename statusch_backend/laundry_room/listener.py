import logging
import time

import influxdb_client
from threading import Thread
from collections import namedtuple
from django.conf import settings

_HISTORY_LEN_SEC = 5
_POWER_THRESHOLD = 30
_N_FLOORS = 19

logger = logging.getLogger(__name__)


class Listener(object):
    def __init__(self):
        self._stop_flag = False
        self._thread = Thread(target=self._thread_listener_loop)
        self._thread.daemon = True

    def _init_db(self):
        import itertools
        for floor, type_id in itertools.product(range(0, _N_FLOORS), ['WM', 'DR']):
            self._update_db(floor, type_id, 0)

    def _update_db(self, floor_id, machine, status):
        from laundry_room import models
        from common.models import Floor
        from django.utils import timezone

        floor_obj, created = Floor.objects.get_or_create(id=floor_id)
        if created:
            floor_obj.save()

        floor_obj.last_query_time = timezone.now()
        floor_obj.save()

        if status is not None:
            machine_obj, created = models.Machine.objects.get_or_create(kind_of=machine, floor=floor_obj)
            if machine_obj.status is not status:
                machine_obj.status = status
                machine_obj.save()

    def _thread_listener_loop(self):
        while not self._stop_flag:
            influxdb_config = settings.INFLUXDB
            inf = influxdb_client.InfluxDBClient(
                url=influxdb_config['url'],
                token=influxdb_config['token'],
                org=influxdb_config['org'])
            query_api = inf.query_api()
            flux_tables = query_api.query(f'''
                from(bucket: "{influxdb_config['bucket']}")
                  |> range(start: -10m)
                  |> filter(fn: (r) => r["_measurement"] == "meres")
                  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
                  |> yield(name: "mean")
            ''')

            for table in flux_tables:
                values = table.records[-1].values
                floor_num = int(values['level'])
                value = values['_value']
                kind_of = 'WM' if values['_field'] == 'wm_power' else 'DR' if values['_field'] == 'drier_power' else None
                self._update_db(floor_num, kind_of, value > _POWER_THRESHOLD)
                logger.debug('update_db: %s %s %s', floor_num, kind_of, value > _POWER_THRESHOLD)
            
            time.sleep(10)

    def start(self):
        logger.info('Start listener thread')
        self._thread.start()

    def stop(self):
        logger.info('THREAD STOP!')
        self._stop_flag = True
        self._thread.join()
        logger.info('STOPPED!')
