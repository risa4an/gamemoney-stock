DELIMITER //
DROP PROCEDURE mydb.PUT_NEW_USER;
CREATE PROCEDURE mydb.PUT_NEW_USER(p_login varchar(255), p_password_hash varchar(255), p_salt varchar(10), p_telephone varchar(15))
BEGIN
	DECLARE user_id int;
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
     
    SET user_id = nextval('t_users');
    
	INSERT INTO mydb.t_users values (
		user_id, 
		p_login, 
		null, 
		p_telephone, 
		p_password_hash,
		p_salt,
		0
	);
    
    INSERT INTO mydb.t_wallet
    SELECT 
		user_id,
        0,
        100000
	
    union all
    
    SELECT 
		user_id,
		currency_from,
        0
	FROM vw_exchange_rate_act;
	commit;
END //

DELIMITER ;
