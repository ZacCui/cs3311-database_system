create table Car(
	rego varchar(10),
	model varchar(10),
	year Date,
	primary key rego
)

create table Person(
	name varchar(10),
	licence varchar(10),
	address varchar(50),
	primary key licence
)

create table Accident(
	report varchar(10),
	'date' Date,
	location varchar(50),
	primary key report
)

create table owns(
	car varchar references Car(rego),
	person varchar references Person(licence)
	primary key (car,person)
	
)

create Table involved(
	person varchar references Person(liceece),
	accident varchar reference Accident(),
	
)
