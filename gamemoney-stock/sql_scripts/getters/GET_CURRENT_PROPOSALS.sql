DELIMITER //
DROP PROCEDURE if exists mydb.GET_CURRENT_PROPOSALS;
CREATE PROCEDURE mydb.GET_CURRENT_PROPOSALS(p_user_id int)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
     
	SELECT
		p.proposal_id,
        p.display_name,
        p.proposal_text,
        p.price,
        g.game_name,
        e.short_name,
        if(up.proposal_id is not null, p.promocode, null) as promocode 
	FROM t_proposals p
    JOIN t_games g
		on g.game_id = p.game_id
	JOIN t_currencies e
		on e.currency_id = p.currency_id
	LEFT JOIN t_bought_proposals up
		on up.proposal_id = p.proposal_id
        and up.user_id = p_user_id
	WHERE current_timestamp between p.valid_from and p.valid_to;

END //

DELIMITER ;