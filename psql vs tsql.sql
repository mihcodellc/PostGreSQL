-- https://www.red-gate.com/simple-talk/blogs/how-can-sql-server-developers-get-started-with-postgre-sql/#:~:text=HOW%20CAN%20SQL%20SERVER%20DEVELOPERS%20GET%20STARTED%20WITH,JOIN%20m%20...%20%2014%20more%20rows%20
-- https://www.postgresql.org/docs/9.3/sql-syntax-lexical.html
--tsql
set showplan_xml on
go
set noexec on
go 
select * from TABLE

--pgsql
EXPLAIN select * from TABLE

--data type 
datetime/datetime2 (tsq) => timestamp(psql) with time zone => datetimeoffset (tsql) 
varchar(n) n ie n bytes length (tsql) <> n ie n characters length
no confusion with timestamp  = rowversion in TSQL

-- add a new column with default to a table works differently in pg 9.3 versus tsql 2017.
pg will update the previous value by default. If not wanted, please find other solution

alter table mytable add col1 int not null constraint df_col1 default 0 --update the previous column
----select top 1 col1,* from mytable 
--alter table payments drop constraint df_col1
--alter table payments drop column col1	

--closest tsql
select datediff(mm,'20150101', '20210401')
select datediff(dd,'20150101', '20210401')	
select datediff(hh,'20150101', '20210401')
select datediff(MINUTE,'20150101', '20210401')

select datepart(yy,getdate())
select datepart(SECOND,getdate())

--pgsql
SET intervalstyle = 'postgres';
SELECT
	INTERVAL '6 years 5 months 4 days 3 hours 2 minutes 1 second';

SELECT EXTRACT (MINUTE FROM INTERVAL '5 hours 21 minutes');
select age(now(),'2022-04-27 12:11:50.029451-05')
SELECT current_date, AGE (timestamp '2001-10-10');-- age and current date
SELECT AGE (timestamp '2001-01-01', timestamp '2020-01-01'); -- 19 years

-- like 
a.adsrc like '%merchantbatch_id_seq%'; --sql
a.adsrc ~ 'merchantbatch_id_seq'; -- psql


--***begin tran and roll it back
--psql
begin; --block limit in tsql
	<statement in psql>
rollback;--commit

do $$ 
declare v_count int :=0;
begin
   --statement
end  
$$; --; can be just after end

--tsql
begin tran
	<statement in tsql>
rollback tran--commit tran

--declare @count int = 0;	HIS PLACE doesn't matter
begin 
   declare @count int = 0;
   --statement
end


--***insert, UPDATE, delete: obtain data from modified rows while they are being manipulated
--psql	
--INSERT, UPDATE, and DELETE commands all have an optional RETURNING clause 
--In an INSERT, the data available to RETURNING is the row as it was inserted.	
--IN an UPDATE, the data available to RETURNING is the new content of the modified row
--In a DELETE, the data available to RETURNING is the content of the deleted row
with cte as (
UPDATE products SET price = price * 1.10
  WHERE price <= 99.99
  RETURNING name, price AS new_price;
) select * from cte
--tsql
UPDATE products SET price = price * 1.10
	OUTPUT deleted.price as OldPrice, inserted.price as NewPrice INTO #temp
  WHERE price <= 99.99

---***concatenate string and assign 
select 'text 1' || ' text 2' into v_t1t2--psql
select @t1t2 = 'text 1' + ' text 2' --tsql
