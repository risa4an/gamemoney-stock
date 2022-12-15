use mydb;
CREATE TABLE sequence (
  id INT UNSIGNED PRIMARY KEY NOT NULL,
  -- с помощью name мы можем хранить множество sequence в одной таблице.
  name VARCHAR(255) NOT NULL
);

INSERT INTO sequence SET id = 0, name = 't_orders';


