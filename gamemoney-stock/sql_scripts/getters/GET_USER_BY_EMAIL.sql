DELIMITER //
DROP PROCEDURE mydb.GET_USER_BY_EMAIL;
CREATE PROCEDURE mydb.GET_USER_BY_EMAIL(p_login varchar(255))
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
	SELECT user_id, password, salt, is_activated
    FROM mydb.t_users
    WHERE email = p_login;
END //

DELIMITER ;