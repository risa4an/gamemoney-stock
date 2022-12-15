DELIMITER //
DROP PROCEDURE if exists mydb.GET_COINS_OPEN_ORDERS;
CREATE PROCEDURE mydb.GET_COINS_OPEN_ORDERS(p_currency_id SMALLINT)
BEGIN
	WITH CTE AS (
		SELECT 
			round(t.price, 3) as price, 
			sum(t.amount - t.amount_copleted) as amount
		FROM mydb.t_orders t
		WHERE (t.currency_from = p_currency_id)
			AND t.is_closed = 0
		GROUP BY round(t.price, 3)
	)
    , cte_current_rate as (
		select 
			round(exchange_rate, 3) as price,
            null as amount
		from vw_exchange_rate_act 
        where currency_from = p_currency_id
	)
			
    , cte_ordered as (
		select 
			c.price, 
            c.amount,
            if(c.price>r.price, 1, 2) as block_num,
            row_number() over (partition by if(c.price>r.price, 1, 2) order by if(c.price>r.price, c.price, -1 * c.price)) as rn
		from CTE c
        cross join cte_current_rate r
        
        union all 
        
        select 
			price,
            amount,
            0 as block_num,
            0 as rn
		from cte_current_rate 
	)
    select
		price,
        amount,
        block_num
	from cte_ordered
    where rn < 5
    order by if(block_num=1, -rn, rn);
    
    commit;
END //

DELIMITER ;