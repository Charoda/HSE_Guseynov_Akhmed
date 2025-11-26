#!/bin/bash

# Скрипт для создания бэкапа файлов по расширению
# Использование: ./run.sh --input_folder <путь> --extension <расширение> --backup_folder <папка> --backup_archive_name <имя архива>

# Функция для вывода справки
show_help() {
    echo "Использование: $0 --input_folder <абсолютный путь к директории> --extension <расширение> --backup_folder <название папки для бэкапа> --backup_archive_name <имя архива с бэкапом>"
    echo ""
    echo "Пример:"
    echo "  $0 --input_folder ~/repo --extension cpp --backup_folder backup --backup_archive_name backup.tar.gz"
    echo ""
    echo "Все параметры обязательны и могут передаваться в любом порядке:"
    echo "  --input_folder        Абсолютный путь к исходной директории"
    echo "  --extension           Расширение файлов для бэкапа"
    echo "  --backup_folder       Название папки для временного хранения файлов"
    echo "  --backup_archive_name Имя финального архива с бэкапом"
    exit 1
}

# Функция для разбора аргументов командной строки (обработка в случайном порядке)
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --input_folder)
                if [ -n "$2" ] && [[ $2 != --* ]]; then
                    INPUT_FOLDER="$2"
                    shift 2
                else
                    echo "Ошибка: Для --input_folder не указано значение"
                    show_help
                fi
                ;;
            --extension)
                if [ -n "$2" ] && [[ $2 != --* ]]; then
                    EXTENSION="$2"
                    shift 2
                else
                    echo "Ошибка: Для --extension не указано значение"
                    show_help
                fi
                ;;
            --backup_folder)
                if [ -n "$2" ] && [[ $2 != --* ]]; then
                    BACKUP_FOLDER="$2"
                    shift 2
                else
                    echo "Ошибка: Для --backup_folder не указано значение"
                    show_help
                fi
                ;;
            --backup_archive_name)
                if [ -n "$2" ] && [[ $2 != --* ]]; then
                    BACKUP_ARCHIVE_NAME="$2"
                    shift 2
                else
                    echo "Ошибка: Для --backup_archive_name не указано значение"
                    show_help
                fi
                ;;
            -h|--help)
                show_help
                ;;
            --*)
                echo "Неизвестный параметр: $1"
                show_help
                ;;
            *)
                # Игнорируем позиционные аргументы или лишние параметры
                shift
                ;;
        esac
    done
}

# Функция проверки обязательных параметров
validate_arguments() {
    local missing_params=()
    
    if [ -z "$INPUT_FOLDER" ]; then
        missing_params+=("--input_folder")
    fi
    
    if [ -z "$EXTENSION" ]; then
        missing_params+=("--extension")
    fi
    
    if [ -z "$BACKUP_FOLDER" ]; then
        missing_params+=("--backup_folder")
    fi
    
    if [ -z "$BACKUP_ARCHIVE_NAME" ]; then
        missing_params+=("--backup_archive_name")
    fi
    
    if [ ${#missing_params[@]} -ne 0 ]; then
        echo "Ошибка: Отсутствуют обязательные параметры: ${missing_params[*]}"
        show_help
    fi
}

# Функция проверки существования исходной папки
check_input_folder() {
    if [ ! -d "$INPUT_FOLDER" ]; then
        echo "Ошибка: Исходная папка '$INPUT_FOLDER' не существует!"
        exit 1
    fi
    
    if [ ! -r "$INPUT_FOLDER" ]; then
        echo "Ошибка: Нет прав на чтение исходной папки '$INPUT_FOLDER'!"
        exit 1
    fi
}

# Функция создания бэкапа
create_backup() {
    local extension="$1"
    local backup_folder="$2"
    local archive_name="$3"
    
    echo "=== НАЧАЛО СОЗДАНИЯ БЭКАПА ==="
    echo "Исходная папка: $INPUT_FOLDER"
    echo "Расширение файлов: .$extension"
    echo "Папка для бэкапа: $backup_folder"
    echo "Имя архива: $archive_name"
    echo ""
    
    # Создаем папку для бэкапа
    echo "Создаем папку для бэкапа: $backup_folder"
    mkdir -p "$backup_folder"
    
    if [ $? -ne 0 ]; then
        echo "Ошибка: Не удалось создать папку для бэкапа '$backup_folder'!"
        exit 1
    fi
    
    # Ищем файлы с указанным расширением
    echo "Поиск файлов с расширением .$extension в $INPUT_FOLDER..."
    FILES_FOUND=$(find "$INPUT_FOLDER" -type f -name "*.$extension" 2>/dev/null | wc -l)
    
    if [ $FILES_FOUND -eq 0 ]; then
        echo "Файлов с расширением .$extension не найдено!"
        rmdir "$backup_folder" 2>/dev/null
        exit 0
    fi
    
    echo "Найдено файлов: $FILES_FOUND"
    echo ""
    
    # Копируем файлы в папку бэкапа
    echo "Копируем файлы в папку бэкапа..."
    COUNTER=0
    find "$INPUT_FOLDER" -type f -name "*.$extension" 2>/dev/null | while read -r file; do
        COUNTER=$((COUNTER + 1))
        filename=$(basename "$file")
        echo "[$COUNTER/$FILES_FOUND] Копируем: $filename"
        cp "$file" "$backup_folder/"
    done
    
    echo ""
    echo "✓ Копирование завершено!"
    echo "Скопировано файлов: $FILES_FOUND"
    
    # Создаем архив
    echo ""
    echo "Создаем архив: $archive_name"
    
    if [[ "$archive_name" == *.tar.gz ]]; then
        tar -czf "$archive_name" "$backup_folder" 2>/dev/null
    elif [[ "$archive_name" == *.tar.bz2 ]]; then
        tar -cjf "$archive_name" "$backup_folder" 2>/dev/null
    elif [[ "$archive_name" == *.tar ]]; then
        tar -cf "$archive_name" "$backup_folder" 2>/dev/null
    elif [[ "$archive_name" == *.zip ]]; then
        zip -rq "$archive_name" "$backup_folder" 2>/dev/null
    else
        # По умолчанию используем tar.gz
        archive_name="${archive_name}.tar.gz"
        tar -czf "$archive_name" "$backup_folder" 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Архив успешно создан: $archive_name"
        
        # Показываем информацию об архиве
        if command -v du &> /dev/null && [ -f "$archive_name" ]; then
            size=$(du -h "$archive_name" | cut -f1)
            echo "  Размер архива: $size"
        fi
    else
        echo "✗ Ошибка при создании архива!"
        exit 1
    fi
    
    # Удаляем временную папку бэкапа
    echo ""
    echo "Удаляем временную папку бэкапа: $backup_folder"
    rm -rf "$backup_folder"
    
    if [ $? -eq 0 ]; then
        echo "✓ Временная папка удалена"
    else
        echo "⚠ Не удалось удалить временную папку '$backup_folder'"
    fi
}

# Функция показа итоговой информации
show_summary() {
    echo ""
    echo "=== БЭКАП УСПЕШНО СОЗДАН ==="
    echo "Исходная папка: $INPUT_FOLDER"
    echo "Расширение файлов: .$EXTENSION"
    echo "Файлов обработано: $FILES_FOUND"
    echo "Финальный архив: $BACKUP_ARCHIVE_NAME"
    
    if [ -f "$BACKUP_ARCHIVE_NAME" ] && command -v du &> /dev/null; then
        size=$(du -h "$BACKUP_ARCHIVE_NAME" | cut -f1)
        echo "Размер архива: $size"
    fi
    
    echo ""
    echo "Содержимое архива:"
    if [[ "$BACKUP_ARCHIVE_NAME" == *.tar.gz ]] || [[ "$BACKUP_ARCHIVE_NAME" == *.tar ]] || [[ "$BACKUP_ARCHIVE_NAME" == *.tar.bz2 ]]; then
        tar -tzf "$BACKUP_ARCHIVE_NAME" 2>/dev/null | head -10
        total_files=$(tar -tzf "$BACKUP_ARCHIVE_NAME" 2>/dev/null | wc -l 2>/dev/null)
        if [ $total_files -gt 10 ]; then
            echo "... и ещё $((total_files - 10)) файлов"
        fi
    elif [[ "$BACKUP_ARCHIVE_NAME" == *.zip ]]; then
        unzip -l "$BACKUP_ARCHIVE_NAME" 2>/dev/null | tail -n +4 | head -10
        total_files=$(unzip -l "$BACKUP_ARCHIVE_NAME" 2>/dev/null | tail -1 | awk '{print $2}')
        if [ $total_files -gt 10 ]; then
            echo "... и ещё $((total_files - 10)) файлов"
        fi
    fi
}

# Основная функция
main() {
    # Разбор аргументов
    parse_arguments "$@"
    
    # Проверка обязательных параметров
    validate_arguments
    
    # Проверка исходной папки
    check_input_folder
    
    # Удаляем точку из расширения если есть
    EXTENSION="${EXTENSION#.}"
    
    # Создаем бэкап
    create_backup "$EXTENSION" "$BACKUP_FOLDER" "$BACKUP_ARCHIVE_NAME"
    
    # Показываем итоги
    show_summary
}

# Запуск основной функции
main "$@"