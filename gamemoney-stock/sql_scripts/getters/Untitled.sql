DELIMITER //
DROP PROCEDURE mydb.GET_COINS_LIST;
CREATE PROCEDURE mydb.GET_COINS_LIST(p_user_id int)
BEGIN
	SELECT 
		c.currency_id,
        c.display_name,
        c.short_name,
        round(e.exchange_rate, 3),
        round(w.amount) as amount
    FROM mydb.t_currencies c
    left JOIN mydb.vw_exchange_rate_act e
		ON e.currency_from = c.currency_id
	left join t_wallet w
		on w.user_id = p_user_id
        and w.currency_id = c.currency_id;
    
    commit;
END //

DELIMITER ;