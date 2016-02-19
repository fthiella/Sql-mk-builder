/*
  conn="dbi:SQLite:dbname=test.sqlite3"
  username=""
  password=""
*/
drop table if exists gardens;

create table gardens (
	id integer primary key,
	name varchar(100),
	city varchar(100)
);

insert into gardens (name, city) values
('Gardens By The Bay', 'Singapore'), ('Hyde Park', 'London'),
('Central Park', 'New York'), ('Villa Borghese', 'Rome'),
('Princes Street Gardens','Edinburgh');

select * from gardens;
