# Data Integration with ksqlDB and Kafka Connect
This code corresponds with Chapter 9 in the upcoming O'Reilly book: [Mastering Kafka Streams and ksqlDB][book] by Mitch Seymour. This tutorial shows how to use ksqlDB and Kafka Connect to build data pipelines, which route data from one source (e.g. Postgres) to an external sink (e.g. Elasticsearch).

[book]: https://www.kafka-streams-book.com/

# Running Locally
We're deploying the following components with Docker compose:

- Zookeeper
- Kafka
- ksqlDB server (with Kafka Connect running in embedded mode)
- ksqlDB CLI
- Schema Registry
- Postgres
- Elasticsearch


Feel free to checkout the [ksqlDB Server config][ksqldb-server-config] and [Kafka Connect config][connect-config]. Also, the connectors will be installed using `confluent-hub` from this [startup script][script], so if you'd like to install / experiment with different connectors other than the Postgres and Elasticsearch connectors (which are used for this tutorial), feel free to update the script.

Once you're ready to start everything, run the following command:

[script]: files/ksqldb-server/run.sh

```sh
$ docker-compose up
```

[ksqldb-server-config]: files/ksqldb-server/ksql-server.properties
[connect-config]: files/ksqldb-server/connect.properties

Once the services are running, open another tab and log into the ksqlDB CLI using the following command:

```sh
$ docker-compose exec ksqldb-cli  ksql http://ksqldb-server:8088
```

If you see a `Could not connect to the server` error in the CLI, wait a few seconds and try again. ksqlDB can take several seconds to start.

Now, you're ready to run the ksqlDB statements to setup the connectors. The statements we need to run can be found [here][sql]. Either copy and paste each statement into the CLI, or run:

```sql
ksql> RUN SCRIPT '/etc/sql/all.sql';
```

You should see output similar to the following:

```sql
-----------------------------------
 Created connector postgres-source
-----------------------------------
--------------------------------------
 Created connector elasticsearch-sink
--------------------------------------
```

Now, our Postgres database was [pre-populated with a table][pg] called _titles_, and three separate rows.

```sh
docker exec -ti postgres psql -c "select * from titles"

 id |      title
----+-----------------
  1 | Stranger Things
  2 | Black Mirror
  3 | The Office
```

Therefore, verifying that the connectors worked simply involves checking to see if the Postgres data made it's way to Elasticsearch. We can verify by opening a third tab, and running a simple query against the Elasticsearch container:

[pg]: https://github.com/mitch-seymour/mastering-kafka-streams-and-ksqldb-private/blob/master/chapter-09.1/files/postgres/init.sql

```sh
$ docker-compose exec elasticsearch \
  curl -XGET 'localhost:9200/titles/_search?format=json&pretty'
```

If all goes well, you should see the following output:

```json
{
  "took" : 2,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "titles",
        "_type" : "changes",
        "_id" : "1",
        "_score" : 1.0,
        "_source" : {
          "id" : 1,
          "title" : "Stranger Things"
        }
      },
      {
        "_index" : "titles",
        "_type" : "changes",
        "_id" : "3",
        "_score" : 1.0,
        "_source" : {
          "id" : 3,
          "title" : "The Office"
        }
      },
      {
        "_index" : "titles",
        "_type" : "changes",
        "_id" : "2",
        "_score" : 1.0,
        "_source" : {
          "id" : 2,
          "title" : "Black Mirror"
        }
      }
    ]
  }
}
```

[sql]: files/ksqldb-cli/all.sql

Feel free to experiment by inserting new rows into Postgres and re-running the Elasticsearch query. Once you're finished, tear everything down using the following command:

```sh
docker-compose down
```

# Установки
## docker-compose.yml
Файл с контейнерами.

- zookeeper на порту 2188.

- kafka на порту 29092.

- ksqldb-server на порту 8088. Сервер ksqldb. В идеале должен запуститься run.sh из ./files/ksqldb-server, который создаст плагины для коннекторов. Если не сработает или запуститься раньше времени, придется запускать его потом из контейнера.

- ksqldb-cli - клиент базы. Можно включить с помощью команды:
    ```docker-compose exec ksqldb-cli  ksql http://ksqldb-server:8088```
    Файл ./files/ksqldb-cli/all.sql копируется в /etc/sql контейнера и запускается, создавая два коннектора. Если не сработает, запустим позже из контейнера.
schema-registry - схемы данных будем хранить здесь. Порт 8081 и 31002

- kafka-ui - чисто для себя (в книге не было). На 18080 смотрим ui админку Кафки.

- postgres - сама БД. Внешний доступ по 5430, внутренний по 5432. ./files/postgres/init.sql создает таблицу titles и 3 строки в ней.

- elasticsearch - в него будем писать данные из базы.

## Файл start.sh
Стартуем docker-compose.

## Файл stop.sh
Выключаем контейнеры docker-compose.

## Установка коннекторов
Входим в контейнер ksqldb-server:

```docker-compose exec ksqldb-server /bin/bash```
Устанавливаем плагины для контейнеров:

```confluent-hub install confluentinc/kafka-connect-jdbc:10.0.0 \
\--component-dir /home/appuser/ \
\--worker-configs /etc/ksqldb-server/connect.properties \
\--no-prompt

confluent-hub install confluentinc/kafka-connect-elasticsearch:10.0.2 \
\--component-dir /home/appuser/ \
\--worker-configs /etc/ksqldb-server/connect.properties \
\--no-prompt
```
Перезапускаем контейнер
```
docker-compose restart ksqldb-server
```
Заходим в базу:
```
./start_ksqldb.sh
```
или
```
docker-compose exec ksqldb-cli  ksql http://ksqldb-server:8088
```
Появляется приглашение для ввода команд “ksql>”.

Проверим, есть ли коннекторы в ksqldb:
```
SHOW CONNECTORS;
```
Если список пуст, создадим коннекторы:
```
CREATE SOURCE CONNECTOR `postgres-source` WITH(
"connector.class"='io.confluent.connect.jdbc.JdbcSourceConnector',
"connection.url"=
'jdbc:postgresql://postgres:5432/root?user=root&password=secret',
"mode"='incrementing',
" incrementing.column.name "='id',
"topic.prefix"='',
"table.whitelist"='titles',
"key"='id')

CREATE SINK CONNECTOR `elasticsearch-sink` WITH(
"connector.class"=
'io.confluent.connect.elasticsearch.ElasticsearchSinkConnector',
"connection.url"=' http://elasticsearch:9200 ',
"connection.username"='',
"connection.password"='',
"batch.size"='1',
"write.method"='insert',
"topics"='titles',
" type.name "='changes',
"key"='title_id');
```
Если все удачно, то команда SHOW CONNECTORS; выдаст примерно это:
```
Connector Name
| Type
| Class
| Status
---------------------------------------------------------------------
postgres-source
| SOURCE | ...
| RUNNING (1/1 tasks RUNNING)
elasticsearch-sink | SINK
| ...
| RUNNING (1/1 tasks RUNNING)
```
## Дополнительные команды
### ksqldb-cli
- DESCRIBE CONNECTOR postgres-source; - подробности о коннекторе
- SHOW CONNECTORS; - показать все коннекторы
- DROP CONNECTOR postgres-source ; - удалить коннектор

### ksqldb-server
``` docker-compose exec ksqldb-server /bin/bash
```
- curl -XGET localhost:8083/connectors - получение списка коннекторов
- curl -XGET localhost:8083/connectors/elasticsearch-sink - получение описаний коннекторов
- curl -XGET -s localhost:8083/connectors/elasticsearch-sink/tasks - получение списка задач
- curl -XGET -s localhost:8083/connectors/elasticsearch-sink/tasks/0/status - получение состояний задач
- curl -XPOST -s localhost:8083/connectors/elasticsearch-sink/tasks/0/restart - перезапуск задачи

### schema-registry
```docker-compose exec schema-registry /bin/bash
```
- curl -XGET localhost:8081/subjects/ - получение схемы типов
- curl -XGET localhost:8083/connectors/elasticsearch-sink - получение схемы типов
- curl -XGET localhost:8081/subjects/titles-value/versions - получение списка версий схемы
- curl -XGET localhost:8081/subjects/titles-value/versions/1 - получение схемы с указанной версией
- curl -XGET localhost:8081/subjects/titles-value/versions/latest - схемы последней версии

# Упражнения из книги
В терминале “ksql>” запустим
```
PRINT `titles` FROM BEGINNING ;
```
Получим:
```
Key format: JSON or KAFKA_STRING
Value format: AVRO or KAFKA_STRING

rowtime: 2024/10/01 16:35:06.180 Z, key: 1, value: \{"id": 1, "title": "Stranger Things"\}
rowtime: 2024/10/01 16:35:06.181 Z, key: 2, value: \{"id": 2, "title": "Black Mirror"\}
rowtime: 2024/10/01 16:35:06.181 Z, key: 3, value: \{"id": 3, "title": "The Office"\}
```
Зайдем в БД Postgresql и добавим строку в таблицу:
```
INSERT INTO titles (title) values ('Andrix');
```
В терминале ksql появится новая строка:
```
rowtime: 2024/10/01 16:38:15.946 Z, key: 4, value: \{"id": 4, "title": "Andrix"\}
```
