DELIMITER //
DROP PROCEDURE if exists mydb.PUT_USER_BUY_PROPOSAL;
CREATE PROCEDURE mydb.PUT_USER_BUY_PROPOSAL(p_user_id int, p_proposal_id int)
BEGIN
	DECLARE amount_in_wallet_coin double;
    DECLARE coin_id INT;
    DECLARE proposal_price DOUBLE;
    
    DECLARE EXIT HANDLER FOR SQLSTATE '42901'
		BEGIN
			SELECT -1, 'insufficient funds';
	END;
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
     
	SELECT currency_id INTO @coin_id FROM t_proposals WHERE proposal_id = p_proposal_id;
    SELECT price INTO @proposal_price FROM t_proposals WHERE proposal_id = p_proposal_id;
    SELECT amount INTO @amount_in_wallet_coin FROM t_wallet WHERE user_id = p_user_id and currency_id = @coin_id;
    
    IF @proposal_price > @amount_in_wallet_coin THEN 
		SIGNAL SQLSTATE '42901';
	END IF;
    
    INSERT INTO t_bought_proposals
    SELECT
		p_user_id,
        p_proposal_id,
        current_timestamp;
        
	UPDATE t_wallet
    SET amount := amount - @proposal_price
    WHERE user_id = p_user_id and currency_id = @coin_id;
        
	SELECT 1, 'success';
    
    commit;
		

END //

DELIMITER ;