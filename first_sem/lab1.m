function lab1(isMaximization) % Основная функция, принимает параметр для задания типа задачи (максимизация или минимизация)
    clc; % Очищает консоль
    debugFlag = 2; % Флаг для включения отладочного вывода
    findMax = 0; % Инициализация переменной для переключения задачи максимизации

    % Инициализация исходной матрицы
    matrix = [
        3 5 2 4 8;
        10 10 4 3 6;
        5 6 9 8 3;
        6 2 5 8 4;
        5 4 8 9 3
    ];

    disp('Начальная матрица:');
    disp(matrix); % Вывод исходной матрицы

    % Копируем матрицу для дальнейших преобразований
    C = matrix;

    % Проверка на тип задачи (максимизация или минимизация)
    if isMaximization
        C = convertToMin(matrix); % Преобразует задачу к минимизации, если исходная задача на максимизацию
        if debugFlag == 1 
            disp('Преобразованная матрица для задачи минимизации:');
            disp(C);
        end
    end

    % Вычитание минимальных элементов по столбцам
    C = updateColumns(C);
    if debugFlag == 1
        disp('Матрица после вычитания минимального элемента по столбцам:');
        disp(C);
    end

    % Вычитание минимальных элементов по строкам
    C = updateRows(C);
    if debugFlag == 1 
        disp('Матрица после вычитания минимального элемента по строкам:');
        disp(C);
    end

    % Получение размеров матрицы
    [numRows, numCols] = size(C);

    % Инициализация структуры для начального СНН
    matrSIZ = initializeSIZ(C);
    if debugFlag == 1 
        disp('Начальное состояние СНН:');
        printSIZ(C, matrSIZ); % Вывод начального состояния СНН
    end

    k = sum(matrSIZ(:));  % Подсчет нулей в СНН
    if debugFlag == 1
        fprintf('Количество нулей в СНН: k = %d\n\n', k);
    end 

    iteration = 1; % Счетчик итераций
    while k < numCols
        if debugFlag == 1 
            fprintf('--- Итерация №%d ---\n', iteration);
        end

        matrStreak = zeros(numRows, numCols); % Матрица для отметки позиций с 0'
        selectedColumns = sum(matrSIZ); % Вектор, хранящий информацию о выделенных столбцах
        selectedRows = zeros(numRows, 1); % Вектор выделенных строк
        selection = getSelectedMatrix(numRows, numCols, selectedColumns); % Получение выделенных строк и столбцов
        
        if debugFlag == 1 
            disp('Результат выделения столбцов с 0*:');
            printMarkedMatrix(C, matrSIZ, matrStreak, selectedColumns, selectedRows); % Отображение выбранных строк и столбцов
        end

        isSearching = true; % Флаг для продолжения поиска
        streakPnt = [-1 -1]; % Инициализация координат для отметки 0'
        
        while isSearching 
            if debugFlag == 1 
                disp('Поиск нулевого элемента среди невыделенных');
            end

            streakPnt = findZero(C, selection); % Находим первую невыделенную 0
            if streakPnt(1) == -1
                C = updateMatrixNoZero(C, numRows, numCols, selection, selectedRows, selectedColumns); % Если нет 0, обновляем матрицу

                if debugFlag == 1 
                    disp('Обновленная матрица после добавления нового 0:');
                    printMarkedMatrix(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
                end

                streakPnt = findZero(C, selection); % Повторно ищем 0
            end
        
            matrStreak(streakPnt(1), streakPnt(2)) = 1; % Помечаем найденный 0'
            if debugFlag == 1 
                disp('Матрица с пометкой найденного 0-штрих');
                printMarkedMatrix(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
            end

            zeroStarInRow = getZeroInRow(streakPnt, numCols, matrSIZ); % Ищем 0* в строке с 0'
            if zeroStarInRow(1) == -1
                isSearching = false; % Завершаем поиск
            else
                selection(:, zeroStarInRow(2)) = selection(:, zeroStarInRow(2)) - 1; % Снимаем выделение столбца
                selectedColumns(zeroStarInRow(2)) = 0;

                selection(zeroStarInRow(1), :) = selection(zeroStarInRow(1), :) + 1; % Выделяем строку
                selectedRows(zeroStarInRow(1)) = 1;
                if debugFlag == 1 
                    disp('Переопределение выделения строки/столбца для обработки 0*');
                    printMarkedMatrix(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
                end
            end
        end

        if debugFlag == 1 
           disp('Построение L-цепочки: ');
        end

        % Построение L-цепочки, заменяющей 0* на 0'
        [matrStreak, matrSIZ] = createChain(numRows, numCols, streakPnt, matrStreak, matrSIZ);

        k = sum(matrSIZ(:));  % Обновление количества нулей
        if debugFlag == 1
            disp('Обновленное СНН:');
            printSIZ(C, matrSIZ); 
            fprintf('Обновленное k = %d\n', k);
        end
        
        iteration = iteration + 1;
        disp('--------------------------------');
    end

    disp('Конечное состояние СНН:');
    printSIZ(C, matrSIZ);

    disp('Матрица X:');
    disp(matrSIZ);

    fOpt = calculateOptimal(matrix, matrSIZ); % Расчет оптимального значения
    fprintf("Оптимальное значение = %d\n", fOpt);
end 


% Функция для нахождения невыделенного 0
function [streakPnt] = findZero(matr, selection) 
    streakPnt = [-1 -1];
    [numRows, numCols] = size(matr);
    for i = 1 : numCols
        for j = 1 : numRows
           if selection(j, i) == 0 && matr(j, i) == 0 
                streakPnt(1) = j;
                streakPnt(2) = i;
                return;
           end
        end 
    end
end

% Вывод текущего состояния СНН
function [] = printSIZ(matr, matrSIZ)
    [numRows, numCols] = size(matr);

    fprintf("\n");
    for i = 1 : numRows
        for j = 1 : numCols
            if matrSIZ(i, j) == 1
                fprintf("\t%d*\t", matr(i, j));
            else
                fprintf("\t%d\t", matr(i, j));
            end
        end
        fprintf("\n");
    end
    fprintf("\n");
end

% Вывод матрицы с отметками
function [] = printMarkedMatrix(matr, matrSIZ, matrStreak, selectedCols, selectedRows)
    [numRows, numCols] = size(matr);

    for i = 1 : numRows
        if selectedRows(i) == 1
            fprintf("+")
        end

        for j = 1 : numCols
            fprintf("\t%d", matr(i, j))
            if matrSIZ(i, j) == 1 
                fprintf("*\t");
            elseif matrStreak(i, j) == 1
                fprintf("'\t")
            else
                fprintf("\t");
            end
        end
    
        fprintf('\n');
    end

    for i = 1 : numCols
        if selectedCols(i) == 1
            fprintf("\t+\t")
        else 
            fprintf(" \t\t")
        end 
    end
    fprintf('\n\n');
end

% Преобразование для задачи минимизации
function matr = convertToMin(matr)
    maxElem = max(max(matr));
    matr = matr * (-1) + maxElem;
end

% В каждом столбце C находит минимальный элемент и вычитает его из столбца
function matr = updateColumns(matr)
    minElemArr = min(matr);
    for i = 1 : length(minElemArr)
        matr(:, i) = matr(:, i) - minElemArr(i);
    end
end

% В каждой строке C находит минимальный элемент и вычитает его из строки
function matr = updateRows(matr)
    minElemArr = min(matr, [], 2);
    for i = 1 : length(minElemArr)
        matr(i, :) = matr(i, :) - minElemArr(i);
    end
end

% Начальная СНН
function matrSIZ = initializeSIZ(matr)
    [numRows, numCols] = size(matr);
    matrSIZ = zeros(numRows, numCols);

    for i = 1: numCols
        for j = 1 : numRows
            if matr(j, i) == 0
                count = 0;
                for k = 1 : numCols
                   count = count + matrSIZ(j, k);
                end
                for k = 1 : numRows
                   count = count + matrSIZ(k, i);
                end

                if count == 0
                    matrSIZ(j, i) = 1;
                end
            end
        end
    end
end

% Получение целочисленного решения
function fOpt = calculateOptimal(matr, matrSIZ)
    fOpt = 0;
    [numRows, numCols] = size(matr);
    for i = 1 : numRows
        for j = 1 : numCols
            if matrSIZ(i, j) == 1
                fOpt = fOpt + matr(i, j);
            end
        end
    end
end

% Получение выделенных столбцов
function selection = getSelectedMatrix(numRows, numCols, selectedColumns)
    selection = zeros(numRows, numCols);
    for i = 1 : numCols
        if selectedColumns(i) == 1
            selection(:, i) = 1;
        end
    end
end

% Получение строки, где есть 0* и возвращает её
function zeroStarInRow = getZeroInRow(streakPnt, numCols, matrSIZ)
    zeroStarInRow = [-1 -1];
    for j = 1 : numCols
        if matrSIZ(streakPnt(1), j) == 1
            zeroStarInRow(1) = streakPnt(1);
            zeroStarInRow(2) = j;
            return;
        end
    end
end

% Обновление матрицы, если отсутствует 0
function matr = updateMatrixNoZero(matr, numRows, numCols, selection, selectedRows, selectedColumns)
    delta = inf;
    for i = 1:numRows
        for j = 1:numCols
            if selection(i, j) == 0
                delta = min(delta, matr(i, j));
            end
        end
    end

    for i = 1:numRows
        for j = 1:numCols
            if selection(i, j) == 0
                matr(i, j) = matr(i, j) - delta;
            end
            if selectedRows(i) == 1
                matr(i, j) = matr(i, j) + delta;
            end
            if selectedColumns(j) == 1
                matr(i, j) = matr(i, j) + delta;
            end
        end
    end
end

% Построение L-цепочки
function [matrStreak, matrSIZ] = createChain(numRows, numCols, streakPnt, matrStreak, matrSIZ)
    i = streakPnt(1);
    j = streakPnt(2);
    while i > 0 && j > 0 && i <= numRows && j <= numCols
        matrStreak(i, j) = 0; % Убираем отметку 0*

        matrSIZ(i, j) = 1; % Ставим новую отметку 0'

        fprintf("[%d, %d] ", i, j);

        % Переход к следующему элементу
        kRow = 1;
        while kRow <= numRows && (matrSIZ(kRow, j) ~= 1 || kRow == i)
            kRow = kRow + 1;
        end

        if (kRow <= numRows)  
            lCol = 1;
            while lCol <= numCols && (matrStreak(kRow, lCol) ~= 1 || lCol == j)
                lCol = lCol + 1;
            end

            if lCol <= numCols
                matrSIZ(kRow, j) = 0;
                fprintf("-> [%d, %d] -> ", kRow, j);
            end
            j = lCol;
        end
        i = kRow;
     end

     fprintf("\n");
end


    