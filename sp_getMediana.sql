Create procedure [dbo].[sp_getMediana]



/*
Created by: Могилевцев Дмитрий
Created date: 2020-05-29
Description: 
Медиана - число, стоящее посередине упорядоченного по возрастанию ряда чисел (в случае, если количество чисел нечётное). Если же количество чисел в ряду чётно, то медианой ряда является полусумма двух стоящих посередине чисел упорядоченного по возрастанию ряда

Параметры:
	1)	@tbl – Название таблицы /вложенный запрос типа
	2)	@grp – поле или массив полей по которым будет происходить группировка (массив передается в кавычках через запятую)
	3)	@val – числовые поля по которым будет происходить группировка, сортировка и поиск медианы (поиск медианы идет по первому столбцу из массива подробнее далее)
	4)	@ord – поля для сортировки. Стоит учитывать, что итоговый результат будет зависеть от того как задана сортировка. В сортировку программно передаются поля группировки, затем поля которые будут указаны в сортировке (ниже по примерам будет яснее)
	5)	@period – опциональный параметр (можно не задавать), но если задаете, то в него обязательно необходимо передать 4 параметра:
		a.	Начальная дата
		b.	Конечная дата
		c.	Название поля для которого задается дата
		d.	Тип данных в этом поле (date или int) – т.к. в разных таблицах мы строим поля даты то в формате то даты, то в формате строки, то в формате числа (ниже по примерам я разбираю все три случая). Для типа строки и даты необходимо указывать тип date,			и только для числа int
*/

-- Параметры
  @tbl varchar(max)
, @grp varchar(max)
, @val varchar(max)
, @ord varchar(max)
, @period varchar(max) = ''		-- опционально

as

SET NOCOUNT ON

declare @exec varchar(max), @error varchar(max)


-- Удаляем пробелы
select @tbl = @tbl + ' as tbl ', @grp = dbo.fc_RemoveAllSpaces(@grp), @val = dbo.fc_RemoveAllSpaces(@val), @ord = dbo.fc_RemoveAllSpaces(@ord), @period = dbo.fc_RemoveAllSpaces(@period)

-- Создаем таблицы
declare @groupBy table(id int, col varchar(max))
declare @valueBy table(id int, col varchar(max))
declare @orderBy table(id int, col varchar(max))
declare @periodBy table(id int, col varchar(max))


-- Наполняем таблицы
insert into @groupBy select * from f_SplitToTable(',', @grp)
insert into @valueBy select * from f_SplitToTable(',', @val)
insert into @orderBy select * from f_SplitToTable(',', @ord)
insert into @periodBy select * from f_SplitToTable(',', @period)

-- Задаем сразу поля сортировки
select @ord = @grp + ',' + @ord


-- проверка переданных параметров
if (((len(@period) != 0) and (select count(*) from @periodBy) != 4))
	begin
		select @error = 'Не верно задан параметр ''@period''. Необходимо либо оставить данное поле пустым, либо передать 4 параметра: 1- Начальная дата, 2- Конечная дата, 3- Название поля даты, 4- тип данных (date,int)'
		raiserror (@error, 11, 1)
		return
	end
else 
	if ((select col from @periodBy where id = 4) not in ('date','int'))
		begin
			select @error = 'Не верно задан 4 параметр в поле ''Период''. Необходимо указать date или int'
			raiserror (@error, 11, 1)
			return
		end


-- проверка переданных полей в @valueBy на соответствие числовому значению
IF OBJECT_ID('TempDB..#isnumeric', 'U') IS NOT NULL
	DROP TABLE #isnumeric
create table #isnumeric (a int)
declare @i int = 1
while @i < (select max(id) from @valueBy) + 1
begin
	select @exec = 'select top 1 ISNUMERIC(' + (select col from @valueBy where id = @i) + ') from ' + @tbl
	insert into #isnumeric
	exec (@exec)
	if ((select a from #isnumeric) = 0)
		begin
			select @error = 'Поле ''' + (select col from @valueBy where id = @i) + ''' не является числовым в переданной таблице и не может быть использовано для подсчета медианы'
			raiserror (@error, 11, 1)
			return
		end
	set @i = @i + 1
	truncate table #isnumeric
end


-- Проверка переданной даты, если таковая имеется
if ((select len(@period)) != 0 and (select col from @periodBy where id = 2) < (select col from @periodBy where id = 1))
begin
	select @error = 'Конечная дата не может быть меньше начальной даты'
	raiserror (@error, 11, 1)
	return
end


-- Проверка был ли задан период
if (len(@period) = 0)
	select @period = ''
else
	select @period = 'where ' + (select col from @periodBy where id = 3) + ' between ' +
		case 
			when (select col from @periodBy where id = 4) = 'int'
				then cast((select col from @periodBy where id = 1) as varchar) + ' and ' + cast((select col from @periodBy where id = 2) as varchar)
			else '''' + (select col from @periodBy where id = 1) + ''' and ''' + (select col from @periodBy where id = 2) + ''''
		end

-- Таблица с набором результирующих данных
declare @resTbl varchar(max) = '
select ROW_NUMBER() over (partition by ' + @grp + ' order by ' + @grp + ',' + @ord + ') as id
	,' + @grp + ',' + @val + '
from ' + @tbl + ' ' + @period

-- Проверка на количество строк чтобы выбрать какой логикой искать медиану
select @exec = 'select max(id) from (' + @resTbl + ') a'
declare @resMaxId table(id int)
insert into @resMaxId(id)
exec(@exec)



if ((select id from @resMaxId) % 2 = 0)
	begin
		-- Если четное кол-во - берем полусумму двух стоящих посередине чисел упорядоченного по возрастанию ряда
		select @i = 1, @val = ''
		while @i < (select max(id) from @valueBy) + 1
		begin
			select @val += 'sum(' + (select col from @valueBy where id = @i) + ')/2.0 as ' + (select col from @valueBy where id = @i) + ','
			set @i += 1
		end
		select @val	= left(@val, len(@val)-1)
		select @exec = 'select ' + @grp + ',' + @val + ' from (' + @resTbl + ') a where id in (' + cast((select id from @resMaxId)/2 as varchar) + ',' + cast((select id from @resMaxId)/2+1 as varchar) + ') group by ' + @grp
		--print @exec
	end
else
	begin
		-- если нечетное кол-во - число, стоящее посередине упорядоченного по возрастанию ряда чисел
		select @exec = 
		'select ' + @grp + ',' + @val + ' 
		from (' + @resTbl + '
		) a
		where id = CEILING(cast((select max(id) from (' + @resTbl + ') a)as float)/2)'
	end
	
	
-- Вывод результирующего набора
exec(@exec)
