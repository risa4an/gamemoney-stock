DELIMITER //
drop PROCEDURE if exists mydb.PUT_USER_ORDER;
CREATE PROCEDURE mydb.PUT_USER_ORDER(p_coin_id smallint, p_price double, p_amount bigint, p_order_type smallint, p_user_id int)
BEGIN
	DECLARE amount_in_wallet_coin double;
    DECLARE amount_in_wallet_main double;
    DECLARE amount_completed_now double default 0;
    DECLARE round_num SMALLINT;
    DECLARE order_id BIGINT;
    DECLARE EXIT HANDLER FOR SQLSTATE '42901'
		BEGIN
			SELECT -1, 'insufficient funds';
	END;
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT -1, @full_error;
	 END;
	
    DROP TABLE IF EXISTS tmp_progress_order;
    create temporary table tmp_progress_order (
		order_id bigint primary key,
        user_id int,
        sum_orders int,
        amount_needed int
	);
    
    SET @round_num := 3;
    SELECT amount INTO @amount_in_wallet_coin FROM t_wallet where user_id = p_user_id and currency_id = p_coin_id LIMIT 1;
    SELECT amount INTO @amount_in_wallet_main FROM t_wallet WHERE user_id = p_user_id and currency_id = 0 LIMIT 1;
    SELECT nextval('t_orders') INTO @order_id;
    
    IF (p_order_type = 1 and @amount_in_wallet_coin < p_amount) 
		OR (p_order_type = 2 and @amount_in_wallet_main < p_amount * p_price) then 
			SIGNAL SQLSTATE '42901';
	END IF;
    
    IF p_order_type = 1 then 
		INSERT INTO t_orders 
        select 
			@order_id,
            p_user_id,
            1 as order_type,
            p_coin_id,
            0 as currency_to,
            p_amount,
            0 as amount_completed,
            p_price as price,
            0 as is_closed,
            current_timestamp;
		
        UPDATE t_wallet 
        SET amount = amount - p_amount
        WHERE user_id = p_user_id
			and currency_id = p_coin_id;
            
		INSERT INTO t_transactions
        SELECT
			nextval('t_transactions'),
			p_user_id,
            3,
            p_coin_id,
            0,
            p_amount,
            p_price,
            @order_id,
            -1,
            current_timestamp;
            
        insert into tmp_progress_order
        WITH CTE_OPEN_ORDERS AS (
			SELECT 
				o.order_id,
                o.user_id,
                o.price,
                o.amount - o.amount_copleted AS amount_needed,
                row_number() over (order by created_dt) as rn
			FROM t_orders o
            WHERE o.order_type = 2
				AND o.currency_to = p_coin_id
				AND ROUND(o.price, @round_num) = ROUND(p_price, @round_num)
                and o.is_closed = 0)
			, cte_order as (
            SELECT
				a.order_id,
                a.user_id,
                a.rn,
                a.amount_needed,
                sum(b.amount_needed) as sum_order
			from CTE_OPEN_ORDERS a
            left join CTE_OPEN_ORDERS b
				on a.rn > b.rn
			group by a.order_id,
                a.rn,
                a.user_id,
                a.amount_needed
			)
            SELECT 
				o.order_id,
                o.user_id,
                ifnull(o.sum_order, 0),
                if (o.amount_needed + ifnull(o.sum_order, 0) >= p_amount, p_amount - ifnull(o.sum_order, 0), o.amount_needed) as amount_needed
			FROM cte_order o 
            WHERE ifnull(o.sum_order, 0) < p_amount or o.rn = 1;
            
            UPDATE t_orders, tmp_progress_order
            SET t_orders.amount_copleted = t_orders.amount_copleted + tmp_progress_order.amount_needed
            WHERE t_orders.order_id = tmp_progress_order.order_id;
            
            SELECT SUM(amount_needed) into @amount_completed_now from tmp_progress_order;
            
            UPDATE t_orders 
			SET amount_copleted = @amount_completed_now
            WHERE order_id = @order_id;
            
            INSERT INTO t_transactions
            SELECT 
				nextval('t_transactions'),
                t.user_id,
                2,
                0, 
                p_coin_id,
                t.amount_needed,
                p_price,
                t.order_id,
                p_user_id,
                current_timestamp
			from tmp_progress_order t;
            
            commit;
            
            drop table if exists tmp_completed_orders;
            CREATE TEMPORARY TABLE tmp_completed_orders
            SELECT 
				order_id,
                user_id,
                amount
			FROM t_orders
            where amount_copleted = amount and is_closed = 0;
            
            UPDATE t_orders, tmp_completed_orders
            SET t_orders.is_closed = 1
            WHERE t_orders.order_id = tmp_completed_orders.order_id;
            
            commit;
            
            UPDATE t_wallet, tmp_completed_orders
            SET t_wallet.amount = t_wallet.amount + tmp_completed_orders.amount
            WHERE tmp_completed_orders.user_id = t_wallet.user_id
				AND t_wallet.currency_id = p_coin_id;
			
            commit;
                
			INSERT INTO t_transactions
            SELECT
				nextval('t_transactions'),
                t.user_id,
                4,
                p_coin_id, 
                0,
                t.amount,
                p_price,
                t.order_id,
                -1,
                current_timestamp
			from tmp_completed_orders t;
                
	end if;
    
    IF p_order_type = 2 then 
		
        UPDATE t_wallet 
        SET amount = amount - p_amount * p_price
        WHERE user_id = p_user_id
			and currency_id = 0;
            
		commit;
            
		INSERT INTO t_transactions
        SELECT
			nextval('t_transactions'),
			p_user_id,
            3,
            p_coin_id,
            0,
            p_amount,
            p_price,
            @order_id,
            -1,
            current_timestamp;
		
        insert into tmp_progress_order
        WITH CTE_OPEN_ORDERS AS (
			SELECT 
				o.order_id,
                o.user_id,
                o.price,
                o.amount - o.amount_copleted AS amount_needed,
                row_number() over (order by created_dt) as rn
			FROM t_orders o
            WHERE o.order_type = 1
				AND o.currency_from = p_coin_id
				AND ROUND(o.price, @round_num) = ROUND(p_price, @round_num)
                and o.is_closed = 0)
			, cte_order as (
            SELECT
				a.order_id,
                a.user_id,
                a.rn,
                a.amount_needed,
                sum(b.amount_needed) as sum_order
			from CTE_OPEN_ORDERS a
            left join CTE_OPEN_ORDERS b
				on a.rn > b.rn
			group by a.order_id,
                a.rn,
                a.user_id,
                a.amount_needed
			)
            SELECT 
				o.order_id as order_id,
                o.user_id as user_id,
                ifnull(o.sum_order, 0) as sum_order,
                if (o.amount_needed + ifnull(o.sum_order, 0) >= p_amount, p_amount - ifnull(o.sum_order, 0), o.amount_needed) as amount_needed
			FROM cte_order o 
            WHERE ifnull(o.sum_order, 0) < p_amount or o.rn = 1;
            
            UPDATE t_orders, tmp_progress_order
            SET t_orders.amount_copleted = t_orders.amount_copleted + tmp_progress_order.amount_needed
            WHERE t_orders.order_id = tmp_progress_order.order_id;
            
            SELECT SUM(amount_needed) into @amount_completed_now from tmp_progress_order;
            
		INSERT INTO t_orders
        select
			@order_id,
            p_user_id,
            2 as order_type,
            0 as currency_from,
            p_coin_id,
            p_amount,
            @amount_completed_now as amount_completed,
            p_price as price,
            0 as is_closed,
            current_timestamp;
            
            commit;
            
            INSERT INTO t_transactions
            SELECT 
				nextval('t_transactions'),
                t.user_id,
                1,
                p_coin_id,
                0, 
                t.amount_needed,
                p_price,
                t.order_id,
                p_user_id,
                current_timestamp
			from tmp_progress_order t;
            
            drop table if exists tmp_completed_orders;
            CREATE TEMPORARY TABLE tmp_completed_orders
            SELECT 
				order_id,
                user_id,
                amount
			FROM t_orders
            where amount_copleted = amount and is_closed = 0;
            
            UPDATE t_orders, tmp_completed_orders
            SET t_orders.is_closed = 1
            WHERE t_orders.order_id = tmp_completed_orders.order_id;
            
            commit;
            
            UPDATE t_wallet, tmp_completed_orders
            SET t_wallet.amount = t_wallet.amount + tmp_completed_orders.amount
            WHERE tmp_completed_orders.user_id = t_wallet.user_id
				AND t_wallet.currency_id = p_coin_id;
                
			commit;
                
			INSERT INTO t_transactions
            SELECT
				nextval('t_transactions'),
                t.user_id,
                4,
                p_coin_id, 
                0,
                t.amount,
                p_price,
                t.order_id,
                -1,
                current_timestamp
			from tmp_completed_orders t;
	END IF;
    
    SELECT 1, 'success';
    commit;
    
    
END //

DELIMITER ;