function lab1(isMaximization) % Основная функция, принимает параметр для задания типа задачи (максимизация или минимизация)
    clc; % Очищает консоль
    debugFlag = 1; % Флаг для включения отладочного вывода
    taskType = 0; % Инициализация переменной для переключения задачи максимизации

    % Инициализация исходной матрицы
    initMatrix = [
        3 5 2 4 8;
        10 10 4 3 6;
        5 6 9 8 3;
        6 2 5 8 4;
        5 4 8 9 3
    ];

    disp('Начальная матрица:');
    disp(initMatrix); % Вывод исходной матрицы

    % Копируем матрицу для дальнейших преобразований
    workMatrix = initMatrix;

    % Проверка на тип задачи (максимизация или минимизация)
    if isMaximization
        workMatrix = convertToMin(initMatrix); % Преобразует задачу к минимизации, если исходная задача на максимизацию
        if debugFlag == 1 
            disp('Преобразованная матрица для задачи минимизации:');
            disp(workMatrix);
        end
    end

    % Вычитание минимальных элементов по столбцам
    workMatrix = updateColumns(workMatrix);
    if debugFlag == 1
        disp('Матрица после вычитания минимального элемента по столбцам:');
        disp(workMatrix);
    end

    % Вычитание минимальных элементов по строкам
    workMatrix = updateRows(workMatrix);
    if debugFlag == 1 
        disp('Матрица после вычитания минимального элемента по строкам:');
        disp(workMatrix);
    end

    % Получение размеров матрицы
    [numRows, numCols] = size(workMatrix);

    % Инициализация структуры для начального СНН
    markingMatrix = initializeSIZ(workMatrix);
    if debugFlag == 1 
        disp('Начальное состояние СНН:');
        printSIZ(workMatrix, markingMatrix); % Вывод начального состояния СНН
    end

    zeroCount = sum(markingMatrix(:));  % Подсчет нулей в СНН
    if debugFlag == 1
        fprintf('Количество нулей в СНН: k = %d\n\n', zeroCount);
    end 

    iteration = 1; % Счетчик итераций
    while zeroCount < numCols
        if debugFlag == 1 
            fprintf('--- Итерация №%d ---\n', iteration);
        end

        markMatrix = zeros(numRows, numCols); % Матрица для отметки позиций с 0'
        colSelection = sum(markingMatrix); % Вектор, хранящий информацию о выделенных столбцах
        rowSelection = zeros(numRows, 1); % Вектор выделенных строк
        selectedMatrix = getSelectedMatrix(numRows, numCols, colSelection); % Получение выделенных строк и столбцов
        
        if debugFlag == 1 
            disp('Результат выделения столбцов с 0*:');
            printMarkedMatrix(workMatrix, markingMatrix, markMatrix, colSelection, rowSelection); % Отображение выбранных строк и столбцов
        end

        isSearching = true; % Флаг для продолжения поиска
        zeroMark = [-1 -1]; % Инициализация координат для отметки 0'
        
        while isSearching 
            if debugFlag == 1 
                disp('Поиск нулевого элемента среди невыделенных');
            end

            zeroMark = findZero(workMatrix, selectedMatrix); % Находим первую невыделенную 0
            if zeroMark(1) == -1
                workMatrix = updateMatrixNoZero(workMatrix, numRows, numCols, selectedMatrix, rowSelection, colSelection); % Если нет 0, обновляем матрицу

                if debugFlag == 1 
                    disp('Обновленная матрица после добавления нового 0:');
                    printMarkedMatrix(workMatrix, markingMatrix, markMatrix, colSelection, rowSelection);
                end

                zeroMark = findZero(workMatrix, selectedMatrix); % Повторно ищем 0
            end
        
            markMatrix(zeroMark(1), zeroMark(2)) = 1; % Помечаем найденный 0'
            if debugFlag == 1 
                disp('Матрица с пометкой найденного 0-штрих');
                printMarkedMatrix(workMatrix, markingMatrix, markMatrix, colSelection, rowSelection);
            end

            zeroStarInRow = getZeroInRow(zeroMark, numCols, markingMatrix); % Ищем 0* в строке с 0'
            if zeroStarInRow(1) == -1
                isSearching = false; % Завершаем поиск
            else
                selectedMatrix(:, zeroStarInRow(2)) = selectedMatrix(:, zeroStarInRow(2)) - 1; % Снимаем выделение столбца
                colSelection(zeroStarInRow(2)) = 0;

                selectedMatrix(zeroStarInRow(1), :) = selectedMatrix(zeroStarInRow(1), :) + 1; % Выделяем строку
                rowSelection(zeroStarInRow(1)) = 1;
                if debugFlag == 1 
                    disp('Переопределение выделения строки/столбца для обработки 0*');
                    printMarkedMatrix(workMatrix, markingMatrix, markMatrix, colSelection, rowSelection);
                end
            end
        end

        if debugFlag == 1 
           disp('Построение L-цепочки: ');
        end

        % Построение L-цепочки, заменяющей 0* на 0'
        [markMatrix, markingMatrix] = createChain(numRows, numCols, zeroMark, markMatrix, markingMatrix);

        zeroCount = sum(markingMatrix(:));  % Обновление количества нулей
        if debugFlag == 1
            disp('Обновленное СНН:');
            printSIZ(workMatrix, markingMatrix); 
            fprintf('Обновленное k = %d\n', zeroCount);
        end
        
        iteration = iteration + 1;
        disp('--------------------------------');
    end

    disp('Конечное состояние СНН:');
    printSIZ(workMatrix, markingMatrix);

    disp('Матрица X:');
    disp(markingMatrix);

    optimalValue = calculateOptimal(initMatrix, markingMatrix); % Расчет оптимального значения
    fprintf("Оптимальное значение = %d\n", optimalValue);
end



% Функция для нахождения невыделенного 0
function [zeroPosition] = findZero(matrix, selection) 
    zeroPosition = [-1 -1];
    [rows, cols] = size(matrix);
    for colIdx = 1 : cols
        for rowIdx = 1 : rows
           if selection(rowIdx, colIdx) == 0 && matrix(rowIdx, colIdx) == 0 
                zeroPosition(1) = rowIdx;
                zeroPosition(2) = colIdx;
                return;
           end
        end 
    end
end

% Вывод текущего состояния СНН
function [] = printSIZ(matrix, markingMatrix)
    [rows, cols] = size(matrix);

    fprintf("\n");
    for rowIdx = 1 : rows
        for colIdx = 1 : cols
            if markingMatrix(rowIdx, colIdx) == 1
                fprintf("\t%d*\t", matrix(rowIdx, colIdx));
            else
                fprintf("\t%d\t", matrix(rowIdx, colIdx));
            end
        end
        fprintf("\n");
    end
    fprintf("\n");
end


% Вывод матрицы с отметками
function [] = printMarkedMatrix(matrix, markingMatrix, tempMarkingMatrix, selectedCols, selectedRows)
    [rowCount, colCount] = size(matrix); % Получение количества строк и столбцов матрицы

    % Проход по строкам матрицы
    for rowIdx = 1 : rowCount
        if selectedRows(rowIdx) == 1 % Проверка, выделена ли текущая строка
            fprintf("+"); % Печать символа '+' для выделенной строки
        end

        % Проход по столбцам матрицы
        for colIdx = 1 : colCount
            fprintf("\t%d", matrix(rowIdx, colIdx)); % Печать значения элемента матрицы с табуляцией
            if markingMatrix(rowIdx, colIdx) == 1 % Проверка, является ли элемент 0*
                fprintf("*\t"); % Печать '*' рядом с элементом 0*
            elseif tempMarkingMatrix(rowIdx, colIdx) == 1 % Проверка, является ли элемент 0'
                fprintf("'\t"); % Печать "'" рядом с элементом 0'
            else
                fprintf("\t"); % Печать дополнительной табуляции, если элемент не помечен
            end
        end
    
        fprintf('\n'); % Переход на новую строку после печати строки матрицы
    end

    % Печать выделенных столбцов
    for colIdx = 1 : colCount
        if selectedCols(colIdx) == 1 % Проверка, выделен ли столбец
            fprintf("\t+\t"); % Печать '+' под выделенным столбцом
        else 
            fprintf(" \t\t"); % Печать пустой табуляции для невыделенного столбца
        end 
    end
    fprintf('\n\n'); % Переход на новую строку после завершения печати всех столбцов
end

% Преобразование для задачи минимизации
function transformedMatrix = convertToMin(matrix)
    maxElement = max(max(matrix)); % Находим максимальный элемент в матрице
    transformedMatrix = matrix * (-1) + maxElement; % Преобразуем элементы, чтобы найти эквивалент минимизации
end

% В каждом столбце матрицы находит минимальный элемент и вычитает его из столбца
function updatedMatrix = updateColumns(matrix)
    minElementsByColumn = min(matrix); % Находим минимальные элементы для каждого столбца
    updatedMatrix = matrix; % Создаём копию матрицы для обновлений
    for colIdx = 1 : length(minElementsByColumn) % Проход по каждому столбцу
        updatedMatrix(:, colIdx) = updatedMatrix(:, colIdx) - minElementsByColumn(colIdx); % Вычитаем минимальное значение из столбца
    end
end

% В каждой строке матрицы находит минимальный элемент и вычитает его из строки
function updatedMatrix = updateRows(matrix)
    minElementsByRow = min(matrix, [], 2); % Находим минимальные элементы для каждой строки
    updatedMatrix = matrix; % Создаём копию матрицы для обновлений
    for rowIdx = 1 : length(minElementsByRow) % Проход по каждой строке
        updatedMatrix(rowIdx, :) = updatedMatrix(rowIdx, :) - minElementsByRow(rowIdx); % Вычитаем минимальное значение из строки
    end
end


% Инициализация начальной СНН
function assignmentMatrix = initializeSIZ(inputMatrix)
    [rowCount, colCount] = size(inputMatrix); % Определение количества строк и столбцов исходной матрицы
    assignmentMatrix = zeros(rowCount, colCount); % Создание нулевой матрицы для СНН

    % Проход по столбцам
    for colIdx = 1 : colCount
        % Проход по строкам
        for rowIdx = 1 : rowCount
            if inputMatrix(rowIdx, colIdx) == 0 % Проверка, является ли элемент нулем
                zeroCount = 0; % Инициализация счетчика для проверки наличия отметок в строке и столбце

                % Подсчет отметок в текущей строке
                for colCheck = 1 : colCount
                   zeroCount = zeroCount + assignmentMatrix(rowIdx, colCheck);
                end

                % Подсчет отметок в текущем столбце
                for rowCheck = 1 : rowCount
                   zeroCount = zeroCount + assignmentMatrix(rowCheck, colIdx);
                end

                % Установка отметки 0*, если не найдено других отметок в строке и столбце
                if zeroCount == 0
                    assignmentMatrix(rowIdx, colIdx) = 1;
                end
            end
        end
    end
end

% Получение целочисленного оптимального решения
function optimalValue = calculateOptimal(costMatrix, assignmentMatrix)
    optimalValue = 0; % Инициализация оптимального значения
    [rowCount, colCount] = size(costMatrix); % Получение размеров матрицы

    % Проход по всем элементам матрицы
    for rowIdx = 1 : rowCount
        for colIdx = 1 : colCount
            if assignmentMatrix(rowIdx, colIdx) == 1 % Проверка, есть ли отметка 0* в позиции
                optimalValue = optimalValue + costMatrix(rowIdx, colIdx); % Добавление значения элемента к оптимальному решению
            end
        end
    end
end

% Создание матрицы выделенных столбцов
function selectionMatrix = getSelectedMatrix(rowCount, colCount, selectedColumns)
    selectionMatrix = zeros(rowCount, colCount); % Инициализация матрицы выделения

    % Проход по всем столбцам
    for colIdx = 1 : colCount
        if selectedColumns(colIdx) == 1 % Проверка, выделен ли столбец
            selectionMatrix(:, colIdx) = 1; % Пометка выделенного столбца в матрице выделения
        end
    end
end

% Поиск строки с 0*, возвращает её
function zeroStarRow = getZeroInRow(searchPoint, colCount, assignmentMatrix)
    zeroStarRow = [-1 -1]; % Инициализация возвращаемого значения
    rowIdx = searchPoint(1); % Индекс строки для поиска

    % Проход по всем столбцам в указанной строке
    for colIdx = 1 : colCount
        if assignmentMatrix(rowIdx, colIdx) == 1 % Проверка наличия отметки 0*
            zeroStarRow = [rowIdx, colIdx]; % Возврат координат позиции 0*
            return;
        end
    end
end

% Обновление матрицы при отсутствии нуля
function updatedMatrix = updateMatrixNoZero(matrix, rowCount, colCount, selectionMatrix, selectedRows, selectedColumns)
    minDelta = inf; % Инициализация минимального значения для обновления

    % Поиск минимального элемента в невыделенных ячейках
    for rowIdx = 1 : rowCount
        for colIdx = 1 : colCount
            if selectionMatrix(rowIdx, colIdx) == 0 % Проверка, не выделена ли ячейка
                minDelta = min(minDelta, matrix(rowIdx, colIdx)); % Обновление минимального значения
            end
        end
    end

    % Обновление значений в матрице на основе выделенных строк и столбцов
    for rowIdx = 1 : rowCount
        for colIdx = 1 : colCount
            if selectionMatrix(rowIdx, colIdx) == 0 % Если ячейка не выделена, вычитаем минимальное значение
                matrix(rowIdx, colIdx) = matrix(rowIdx, colIdx) - minDelta;
            end
            if selectedRows(rowIdx) == 1 % Если строка выделена, прибавляем минимальное значение
                matrix(rowIdx, colIdx) = matrix(rowIdx, colIdx) + minDelta;
            end
            if selectedColumns(colIdx) == 1 % Если столбец выделен, прибавляем минимальное значение
                matrix(rowIdx, colIdx) = matrix(rowIdx, colIdx) + minDelta;
            end
        end
    end
    updatedMatrix = matrix; % Возврат обновленной матрицы
end

% Построение L-цепочки и обновление отметок
function [tempMarkingMatrix, assignmentMatrix] = createChain(rowCount, colCount, startPoint, tempMarkingMatrix, assignmentMatrix)
    rowIdx = startPoint(1); % Начальная строка цепочки
    colIdx = startPoint(2); % Начальный столбец цепочки

    % Проход по цепочке до выхода за границы
    while rowIdx > 0 && colIdx > 0 && rowIdx <= rowCount && colIdx <= colCount
        tempMarkingMatrix(rowIdx, colIdx) = 0; % Снятие отметки 0'

        assignmentMatrix(rowIdx, colIdx) = 1; % Установка новой отметки 0*

        fprintf("[%d, %d] ", rowIdx, colIdx); % Печать текущей позиции цепочки

        % Переход к следующей позиции в строке
        rowInChain = 1;
        while rowInChain <= rowCount && (assignmentMatrix(rowInChain, colIdx) ~= 1 || rowInChain == rowIdx)
            rowInChain = rowInChain + 1;
        end

        % Если найдена отметка 0* в строке, продолжаем цепочку по столбцу
        if (rowInChain <= rowCount)
            colInChain = 1;
            while colInChain <= colCount && (tempMarkingMatrix(rowInChain, colInChain) ~= 1 || colInChain == colIdx)
                colInChain = colInChain + 1;
            end

            % Если найдена отметка 0' в столбце, обновляем цепочку
            if colInChain <= colCount
                assignmentMatrix(rowInChain, colIdx) = 0; % Снятие отметки 0* на предыдущей позиции
                fprintf("-> [%d, %d] -> ", rowInChain, colIdx); % Печать следующей позиции цепочки
            end
            colIdx = colInChain; % Обновление индекса столбца
        end
        rowIdx = rowInChain; % Обновление индекса строки
    end

    fprintf("\n"); % Печать новой строки для завершения цепочки
end


    
