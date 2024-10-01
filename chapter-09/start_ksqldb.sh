#!/bin/bash

docker-compose exec ksqldb-cli  ksql http://ksqldb-server:8088

# Ожидаем завершения фоновых процессов
wait

read -p "Press any key to exit..."


