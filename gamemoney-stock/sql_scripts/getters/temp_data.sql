SELECT * FROM mydb.t_exchange_rate;
truncate table mydb.t_exchange_rate;
insert into mydb.t_exchange_rate
select currency_id, 0, current_timestamp, rand() * 10
from mydb.t_currencies
where currency_id <> 0;


 
-- SELL
insert into mydb.t_orders
with t1(i) as (select 0 union all select 0),
t2(i) as (select 0 from t1 a, t1 b),
t3(i) as (select 0 from t2 a, t2 b),
t4(i) as (select row_number() over (partition by a.i) from t3 a, t3 b)
select 
	nextval('t_orders'),
    -1,
    1,
    e.currency_from as currency_from,
    0 as currency_to,
    round(rand() * 100 + 1) as amount,
    0, 
    case when rand() > 0.5 then
		round(rand() / 4 + e.exchange_rate, 3)
	else round(e.exchange_rate - rand() / 6, 3) end as price,
    0 as is_closed,
    current_timestamp
from vw_exchange_rate_act e
cross join t4 t;

-- BUY
insert into mydb.t_orders
with t1(i) as (select 0 union all select 0),
t2(i) as (select 0 from t1 a, t1 b),
t3(i) as (select 0 from t2 a, t2 b),
t4(i) as (select row_number() over (partition by a.i) from t3 a, t3 b)
select 
	nextval('t_orders'),
    -1,
    2,
    0 as currency_from,
    e.currency_from as currency_to,
    round(rand() * 100 + 1) as amount,
    0, 
    round(e.exchange_rate - rand() / 4, 2) as price,
    0 as is_closed,
    current_timestamp
from vw_exchange_rate_act e
cross join t4 t;

update sequence set id = 1 where name = 't_orders';

truncate table t_orders;

truncate table t_transactions;

truncate table t_coefficient;

insert into sequence values ( 0, 't_users');

insert into sequence values (0, 't_transactions');

insert into sequence values (0, 't_proposals');

