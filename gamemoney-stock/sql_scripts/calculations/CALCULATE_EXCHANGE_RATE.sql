DELIMITER //
DROP PROCEDURE IF EXISTS CALCULATE_EXCHANGE_RATE;
CREATE PROCEDURE mydb.CALCULATE_EXCHANGE_RATE()
BEGIN
	DECLARE q_t INTEGER;
    SET @q_t := 100;
    
	insert into t_exchange_rate
	with cte_sell as (
		SELECT 
			e.currency_from,
			e.currency_to,
			c.coefficient,
			IFNULL(SUM(amount), 1) AS amount,
			ROUND(exchange_rate, 2) + c.range_start as price
		FROM vw_exchange_rate_act e
		CROSS JOIN t_coefficient c
		LEFT JOIN t_orders o
			ON o.currency_to = e.currency_to
			AND o.currency_from = e.currency_from
			AND o.price BETWEEN ROUND(exchange_rate, 2) + c.range_start AND ROUND(exchange_rate, 2) + c.range_end
            and o.order_type = 1
			AND o.is_closed = 0
		group by e.currency_from,
			e.currency_to,
			c.coefficient,
			ROUND(exchange_rate, 2) + c.range_start)
	, cte_bid as (
		SELECT 
			e.currency_from,
			e.currency_to,
			c.coefficient,
			IFNULL(SUM(amount), 1) AS amount,
			ROUND(exchange_rate, 2) - c.range_start as price
		FROM vw_exchange_rate_act e
		CROSS JOIN t_coefficient c
		LEFT JOIN t_orders o
			ON o.currency_from = e.currency_to
			AND o.currency_to = e.currency_from
			AND o.price BETWEEN ROUND(exchange_rate, 2) - c.range_end AND ROUND(exchange_rate, 2) - c.range_start
            AND o.order_type = 2
			and o.is_closed = 0
		group by e.currency_from,
			e.currency_to,
			c.coefficient,
			ROUND(exchange_rate, 2) - c.range_start)
	, cte_pre_result as(
		select 
			currency_from,
			currency_to,
			sum(amount * price * coefficient) / sum(amount * coefficient) as price
		from cte_sell 
		group by currency_from,
			currency_to
			
		union all 
		
		select 
			currency_from,
			currency_to,
			sum(amount * price * coefficient) / sum(amount * coefficient) as price
		from cte_bid
		group by currency_from,
			currency_to
	)
    , cte_transactions as(
		select 
			currency_from as currency_from,
            currency_to as currency_to,
            price,
            amount
		from t_transactions
        where transaction_type = 1
			and insert_dt > current_timestamp - INTERVAL 1 minute
		
        union all 
		select 
			currency_to as currency_from,
			currency_from as currency_to,
			price,
			amount
		from t_transactions
        where transaction_type = 2
			and insert_dt > current_timestamp - INTERVAL 1 minute
	)
    , cte_transactions_groupped as(
		select 
			currency_from,
            currency_to,
            sum(amount) / (sum(amount) + @q_t) as q,
            sum(price * amount) / sum(amount) as price
		from cte_transactions
        group by 
			currency_from,
            currency_to
	)
    , cte_mid as (
		select 
			currency_from,
			currency_to,
			sum(price) / 2 as price
		from cte_pre_result 
		group by currency_from,
			currency_to
	)
    select 
		m.currency_from,
        m.currency_to,
        current_timestamp,
        (1 - IFNULL(g.q, 0)) * m.price + IFNULL(g.q, 0) * ifnull(g.price, m.price) as price
	from cte_mid m 
    left join cte_transactions_groupped g
		on g.currency_from = m.currency_from
        and g.currency_to = m.currency_to
		;
END //

DELIMITER ;

	