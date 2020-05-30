
/*
Пример 1
Таблица – вложенный запрос по статической таблице из базы, оборачивается в круглые скобки
Группировка по городам
Ищем медиану по сумме
Делаем сортировку по сумме
Указываем необходимый период (Месяц С, Месяц По, Название поля, Тип данных (Дата текстового формата, указываем date))
*/

declare
  @tbl varchar(max)
, @grp varchar(max)
, @val varchar(max)
, @ord varchar(max)
, @period varchar(max)

-- Задаем параметры
select @tbl = '(select city, month, sum(summa) summa from Baza.table where typestat = ''Выручка'' and budget = ''Факт'' and year = 2020 group by city, month)'
, @grp = 'city'
, @val = 'summa'
, @ord = 'summa'
, @period = '2020-01, 2020-04, month, date'

exec sp_getMediana @tbl, @grp, @val, @ord, @period


/*
Пример 2
Таблица из БД
Группировка по городам
Ищем медиану по массиву числовых полей
Делаем сортировку по первому столбцу
В периоде задаем числовые значения даты
*/

declare
  @tbl varchar(max)
, @grp varchar(max)
, @val varchar(max)
, @ord varchar(max)
, @period varchar(max)

select @tbl = 'Таблица'
  , @grp = 'Города'
  , @val = 'Поле_1, Поле_2, Поле_3, Поле_4, Поле_5, Поле_6, Поле_7, Поле_8'
  , @ord = 'Поле_1'
  , @period = '202001, 202005, Месяц, int'

exec sp_getMediana @tbl, @grp, @val, @ord, @period

 
/*
Пример 3
Вложенный запрос по таблице в базе
Группировка по Городу, ИНН и наименованию
Медиану ищем по сумме
Сортировка по ней же (напоминаю, программно в сортировке сначала идут столбцы из группировки)
Период не задаем
*/

declare
  @tbl varchar(max)
, @grp varchar(max)
, @val varchar(max)
, @ord varchar(max)

select @tbl = '(select City, INN, ClienName, month, sum(SumRub) as SumRub from Таблица group by City, INN, ClientName, month)'
  , @grp = 'City, INN, ClientName'
  , @val = 'SumRub'
  , @ord = 'SumRub'

exec sp_getMediana @tbl, @grp, @val, @ord

 
/*
Пример 4
Таблица из БД
Одно поле для группировки
Медиана по одному полю
Сортировка по ней же
Период в формате даты (200401 еквивалентен 2020-04-01)
*/

declare
  @tbl varchar(max)
, @grp varchar(max)
, @val varchar(max)
, @ord varchar(max)
, @period varchar(max)

select @tbl = 'Table'
  , @grp = 'BalDeb'
  , @val = 'SumRub'
  , @ord = 'SumRub'
  , @period = '200401, 200430, date, date'

exec sp_getMediana @tbl, @grp, @val, @ord, @period
