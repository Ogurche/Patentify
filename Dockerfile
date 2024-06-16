# Используем официальный образ Python
FROM python:3.10-slim

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    && apt-get clean

# Устанавливаем Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Добавляем Poetry в PATH
ENV PATH="/root/.local/bin:$PATH"

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файлы pyproject.toml и poetry.lock и устанавливаем зависимости
COPY pyproject.toml poetry.lock /app/
RUN poetry install --no-root

# Копируем содержимое текущей директории в рабочую директорию контейнера
COPY . /app/

# Переключаем рабочую директорию в hackaton
WORKDIR /app/hackaton_project

# Настраиваем переменные окружения
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE hackaton_project.settings

# Открываем порт
EXPOSE 8000

# Запускаем сервер
CMD ["poetry", "run", "gunicorn", "--bind", "0.0.0.0:8000", "hackaton.wsgi:application"]
