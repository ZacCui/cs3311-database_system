create table R(
	a		integer,
	b		varchar(10),
	c   numeric(4,2),
	primary key (a)
);

create table S(
	b		varchar(10),
	d		integer,
	--FOREIGN KEY (b) REFERENCES r(b),
	primary key (d)
);
