insert into t_coefficient
with t1(i) as (select 0 union all select 0),
t2(i) as (select 0 from t1 a, t1 b),
t3(i) as (select row_number() over (partition by a.i) from t2 a, t2 b)
select 
	(i - 1) * 0.01 as range_start,
    i * 0.01 as range_end,
    1 / pow(2, i - 1) as coefficient
from t3;

create or replace view vw_exchange_rate_act as
select * 
from t_exchange_rate e
where e.insert_dt = (select max(f.insert_dt) from t_exchange_rate f where f.currency_from = e.currency_from and f.currency_to = e.currency_to);

SET GLOBAL event_scheduler = ON;

CREATE EVENT test_calculation_exchange_rate
ON SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP
ENDS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
ON COMPLETION NOT PRESERVE
DO
    CALL CALCULATE_EXCHANGE_RATE();
    
SHOW PROCESSLIST;
SELECT * FROM vw_exchange_rate_act;

select * from t_exchange_rate;