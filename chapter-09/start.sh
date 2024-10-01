#!/bin/bash

sudo systemctl stop postgresql

sleep 5

# Запустите все контейнеры в фоновом режиме
docker-compose up --detach

# Отобразите логи в терминале
docker-compose logs -f &

# Ожидаем завершения фоновых процессов
wait

read -p "Press any key to exit..."


