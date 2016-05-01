# Sql Markdown builder 1.0

I like text editors, I have fallen in love with Sublime Text, and everything I write is in Markdown syntax!

This simple Perl sript executes SQL queries and produces a Markdown output. It can be easily integrated with Sublime Text editor, but it can also be used at the command line.

# Usage

Create a .sql file, specify in a comment the connection string (in perl DBI format) and the username and password,
and a list of SQL queries separated by semicolon (and newline), create a build system and assiciate your file with it, press Ctrl+B to execute the query.

![Run SQL Query](https://raw.githubusercontent.com/fthiella/Sql-mk-builder/master/builder.gif)

# Sample Query

````
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
	('Gardens By The Bay',    'Singapore'),
	('Hyde Park',             'London'),
	('Central Park',          'New York'),
	('Villa Borghese',        'Rome'),
	('Princes Street Gardens','Edinburgh')
;

select * from gardens;

````

# Sample Build System

Add a build system in Sublime Text:

````
{
	"cmd": ["perl", "sqlbuild.pl", "-", "$file" ],
	"working_dir": "c:\\GitHub\\Sql-mk-builder\\",
	"selector": "*.sql"
}
````

Press ctrl+B and the SQL query will be executed inside your favourite editor!
