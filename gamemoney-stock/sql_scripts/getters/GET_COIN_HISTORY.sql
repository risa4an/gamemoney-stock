DELIMITER //
DROP PROCEDURE if exists mydb.GET_COIN_HISTORY;
CREATE PROCEDURE mydb.GET_COIN_HISTORY(p_coin_id smallint)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
     
	SELECT 
		cast(round(UNIX_TIMESTAMP(insert_dt) / 60) * 60 as unsigned) as display_time,
        round(exchange_rate, 4) as exchange_rate
	FROM t_exchange_rate
    WHERE currency_from = p_coin_id
    ORDER BY insert_dt
    limit 100;
END //

DELIMITER ;