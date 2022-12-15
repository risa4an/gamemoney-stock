DELIMITER //
DROP PROCEDURE mydb.GET_USER_ORDERS;
CREATE PROCEDURE mydb.GET_USER_ORDERS(p_coin_id smallint, p_user_id int)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
	WITH CTE AS(
		SELECT 
			CAST(created_dt AS CHAR) as created_dt,
			order_type,
			price,
			amount,
            row_number() over (partition by is_closed order by created_dt desc) as rn,
			round(amount_copleted / amount, 2) * 100 as percent_done
		FROM t_orders
		WHERE (currency_from = p_coin_id or currency_to = p_coin_id)
			and user_id = p_user_id)
	SELECT 
		created_dt,
        if(order_type=1, 'SELL', 'BUY') as order_type,
        price,
        amount,
        percent_done
    FROM CTE
    WHERE rn <= 5 or percent_done < 100;
    
END //

DELIMITER ;