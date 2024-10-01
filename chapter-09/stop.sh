#!/bin/bash

# Остановка всех контейнеров
docker-compose down

# Пауза на 10 секунд для гарантии завершения всех процессов
sleep 10

# Запуск PostgreSQL без запроса пароля
sudo systemctl start postgresql

# Ожидание нажатия клавиши для выхода
read -p "Press any key to exit..."

