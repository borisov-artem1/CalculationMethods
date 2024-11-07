function hungarian_method_lab()
clc;
debugFlg = 1;
findMax = 0;

matr = [
    3 5 2 4 8;
    10 10 4 3 6;
    5 6 9 8 3;
    6 2 5 8 4;
    5 4 8 9 3];

disp('Матрица:');
disp(matr);

C = matr;

if findMax == 1
    C = convertToMin(matr);

    if debugFlg == 1 
        disp('Матрица после приведения к задаче минимизации:');
        disp(C);
    end
end

C = updateColumns(C);
if debugFlg == 1
    disp('Вычитаем наименьший элемент по столбцам:');
    disp(C);
end

C = updateRows(C);
if debugFlg == 1 
    disp('Вычитаем наименьший элемент по строкам:');
    disp(C);
end

[numRows,numCols] = size(C);

matrSIZ = getSIZInit(C);
if debugFlg == 1 
    disp('Начальная система независимых нулей:');
    printSIZ(C, matrSIZ);
end

k = sum(matrSIZ(:));
if debugFlg == 1
    fprintf('Число нулей в построенной СНН: k = %d\n\n', k);
end 

iteration = 1;
while k < numCols
    if debugFlg == 1 
        fprintf('----------------------------------- ИТЕРАЦИЯ №%d -----------------------------------\n', iteration);
    end

    matrStreak = zeros(numRows);   % матрица, в которой отмечаются позиции 0'
    selectedColumns = sum(matrSIZ); % массив где 1 это выделенный столбец, 0 не выделенный
    selectedRows = zeros(numRows); % матрица выделенных строк, пока пустой
    selection = getSelection(numRows, numCols, selectedColumns); % В каждом столбце матрицы selection прибавляется единица,
                                                                 % если эта единица есть в соответствующем столбце (элементе) selectedColumns
    if debugFlg == 1
        disp('Результат выделения столбцов, в которых стоит 0*:');
        printMarkedMatr(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
    end

    flag = true;
    streakPnt = [-1 -1]; % координата первого 0'
    while flag 
        if debugFlg == 1 
            disp('Поиск 0 среди невыделенных элементов');
        end

        streakPnt = findStreak(C, selection);
        if streakPnt(1) == -1 % Случай если мы не нашли 0'
            C = updateMatrNoZero(C, numRows, numCols, selection, selectedRows, selectedColumns);
            % Отнимаем среди невыделенных элементов минимальный элемент

            if debugFlg == 1 
                disp('Так как среди невыделенных элементов нет нулей, отнимаем минимальный элемент:');
                printMarkedMatr(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
            end
            streakPnt = findStreak(C, selection);
        end
    
        matrStreak(streakPnt(1), streakPnt(2)) = 1;
        if debugFlg == 1 
            disp('Матрица с найденным 0-штрих');
            printMarkedMatr(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
        end

        zeroStarInRow = getZeroStarInRow(streakPnt, numCols, matrSIZ);
        if zeroStarInRow(1) == -1
            flag = false;
        else
            % снять выделение со столбца с 0*
            selection(:, zeroStarInRow(2)) = selection(:, zeroStarInRow(2)) - 1;
            selectedColumns(zeroStarInRow(2)) = 0;

            % перенести выделение на строку с 0'
            selection(zeroStarInRow(1), :) = selection(zeroStarInRow(1), :) + 1; 
            selectedRows(zeroStarInRow(1)) = 1;
            if debugFlg == 1 
                disp('Так как в одной строке с 0-штрих есть 0*, происходит перевыделение:');
                printMarkedMatr(C, matrSIZ, matrStreak, selectedColumns, selectedRows);
            end
        end
    end


    if debugFlg == 1 
       disp('L-цепочка: ');
    end

    [matrStreak, matrSIZ] = createL(numRows, numCols, streakPnt, matrStreak, matrSIZ);

    k = sum(matrSIZ(:));
    if debugFlg == 1
        disp('Текущая СНН:');
        printSIZ(C, matrSIZ);
        fprintf('Итого, k = %d\n', k);
    end
    
    iteration = iteration + 1;
    disp('-----------------------------------------------------------------------------');
end

disp('Конечная СНН:');
printSIZ(C, matrSIZ);

disp('X =');
disp(matrSIZ);

fOpt = getFOpt(matr, matrSIZ);
fprintf("Результат = %d\n", fOpt);

end 

% Найти первый нулевой элемент среди невыделенных, в одной строке с которым не
% стоит 0*
function [streakPnt] = findStreak(matr, selection) 
    streakPnt = [-1 -1];
    [numRows,numCols] = size(matr);
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

% Вывод начальной СНН
function [] = printSIZ(matr, matrSIZ)
    [numRows,numCols] = size(matr);

    fprintf("\n");
    for i = 1 : numRows
        for j = 1 : numCols
            if matrSIZ(i, j) == 1 % Если в СНН встретился 1, ставим в начальной матрице * возле 0
                fprintf("\t%d*\t", matr(i, j));
            else
                fprintf("\t%d\t", matr(i, j));
            end
        end
        fprintf("\n");
    end
    fprintf("\n");
end

% Рассатвляем плюсики в начале строк и в конце столбцов
function [] = printMarkedMatr(matr, matrSIZ, matrStreak, selectedCols, selectedRows)
    [numRows,numCols] = size(matr);

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

% Для случая задачи максимизации - привести её к задаче минимизации
function matr = convertToMin(matr)
    maxElem = max(max(matr)); % Находим максимальные по столбцам, потом среди максимальных
    matr = matr * (-1) + maxElem; % Вычитаем максимальный из матрицы стоимостей
end

% В каждом столбце С нах. наим. эл-т и вычесть его из соотв. столбца
function matr = updateColumns(matr)
    minElemArr = min(matr); % Находим минимумумы среди всех столбцов столбцов
    for i = 1 : length(minElemArr) % Проходимся по каждому эелементу сформированного массива
        matr(:, i) = matr(:, i) - minElemArr(i); % Вычитаем элемент массива из каждого столбца
    end
end

% В каждой строке С нах. наим. эл-т и вычесть его из соотв. строки
function matr = updateRows(matr)
    minElemArr = min(matr, [], 2); % Поиск минимальных элементов по строкам
    for i = 1 : length(minElemArr)
        matr(i, :) = matr(i, :) - minElemArr(i); % Вычитание минимального в каждой строке
    end
end

% Начальное состояние СНН
function matrSIZ = getSIZInit(matr)
    [numRows,numCols] = size(matr);
    matrSIZ = zeros(numRows, numCols);

    for i = 1: numCols
        for j = 1 : numRows
            if matr(j, i) == 0
                count = 0;
                for k = 1 : numCols % Нахождение нулей сначала по столбцам
                   count = count + matrSIZ(j, k);
                end
                for k = 1 : numRows % Нахождение нулей по строкам
                   count = count + matrSIZ(k, i);
                end
                if count == 0 % Если нули не найдены значит отмчаем 0* и присваеваем соответствующему элементу единицу в другой матрице
                    matrSIZ(j, i) = 1;
                end 
            end
        end 
    end
end

% Выделить столбцы, в которых стоит 0*
function [selection] = getSelection(numRows, numCols, selectedColumns)
    selection = zeros(numRows, numCols);
    for i = 1 : numCols
        if selectedColumns(i) == 1 
            selection(:, i) = selection(:, i) + 1;
        end 
    end
end

% Изменить матрицу в случае, если среди невыделенных элементов нет нуля
function [matr] = updateMatrNoZero(matr, numRows, numCols, selection, selectedRows, selectedColumns)
    h = 1e5; % Наименьший элемент среди невыделенных
    for i = 1 : numCols
        for j = 1 : numRows
            if selection(j, i) == 0 && matr(j, i) < h
                h = matr(j, i);
            end
        end 
    end

    for i = 1 : numCols
        if selectedColumns(i) == 0
            matr(:, i) = matr(:, i) - h;
        end 
    end
    for i = 1 : numRows
        if selectedRows(i) == 1
            matr(i, :) = matr(i, :) + h;
        end 
    end
end

% Найти 0* в той же строке, что и 0'
function [zeroStarInRow] = getZeroStarInRow(streakPnt, numCols, matrSIZ)
    j = streakPnt(1);
    zeroStarInRow = [-1 -1];
    for i = 1 : numCols
       if matrSIZ(j, i) == 1
           zeroStarInRow(1) = j;
           zeroStarInRow(2) = i;
           break
       end 
    end
end

% Построить L-цепочку
function [matrStreak, matrSIZ] = createL(numRows, numCols, streakPnt, matrStreak, matrSIZ)
    i = streakPnt(1);
    j = streakPnt(2);
    while i > 0 && j > 0 && i <= numRows && j <= numCols
        % Снять *
        matrStreak(i, j) = 0;

        % Заменить ' на *
        matrSIZ(i, j) = 1;

        fprintf("[%d, %d] ", i, j);

        % Дойти до 0* по столбцу от 0'
        kRow = 1;
        while kRow <= numRows  && (matrSIZ(kRow, j) ~= 1 || kRow == i)
            kRow = kRow + 1;
        end

        if (kRow <= numRows)  
            % Дойти до 0' по строке от 0*
            lCol = 1;
            while lCol <= numCols && (matrStreak(kRow, lCol) ~= 1 || lCol == j)
                lCol = lCol + 1;
            end

            if lCol <= numCols
                matrSIZ(kRow,j) = 0;
                fprintf("-> [%d, %d] -> ", kRow, j);
            end
            j = lCol;
        end
        i = kRow;
     end

     fprintf("\n");
end

function [fOpt] = getFOpt(matr, matrSIZ)
    fOpt = 0;
    [numRows,numCols] = size(matr);

    for i = 1 : numCols
        for j = 1 : numRows
            if matrSIZ(j, i) == 1 
                fOpt = fOpt + matr(j, i);
            end
        end
    end
end


    