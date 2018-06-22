-- COMP3311 Prac 03 Exercise
-- Schema for simple company database

create table Employees (
	tfn         char(11)
							constraint ValidTFN
							check (tfn ~ '[0-9]{3}-[0-9]{3}-[0-9]{3}'),
	givenName   varchar(30) not null,
	familyName  varchar(30),
	hoursPweek  float
							check (hourspweek >= 0 and hourspweek <= 24*7),
	primary key (tfn)
);

create table Departments (
	id          char(3)
							constraint ValidDepartment check (id ~ '[0-9]{3}'),
	name        varchar(100) unique,
	manager     char(11) not null unique
							constraint ValidEmployee references Employees(tfn),
	primary key (id)
);

create table DeptMissions (
	department  char(3)
							constraint ValidDepartment references Departments(id),
	keyword     varchar(20),
	primary key (department,keyword)
);

create table WorksFor (
	employee    char(11)
							constraint ValidEmployee references Employees(tfn),
	department  char(3)
							constraint ValidDepartment references Departments(id),
	percentage  float
							constraint ValidPercengage
							check (percentage > 0.0 and percentage <= 100.0),
	primary key (employee,department)
);

create function check_worksfor_insert()
	 returns trigger as $sum_of_percentage$
    declare
	percentage1 float;
	percentage2 float;
    begin
	select into percentage1 sum(percentage) 
	from WorksFor
	where employee = NEW.employee;
	percentage2 = percentage1 + NEW.percentage;
	if percentage2 > 100 then
	    raise exception 'work percentage cannot exceed 100 percent';
	end if;
	return NEW;
    end;
    
$sum_of_percentage$ language plpgsql;
	
create trigger sum_of_percentage before insert or update on WorksFor
    for each row execute procedure check_worksfor_insert();
