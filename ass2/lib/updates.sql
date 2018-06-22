-- COMP3311 18s1 Assignment 2
--
-- updates.sql
--
-- Written by <<Ziyi Cui>> (<<z5097491>>), May 2018

--  This script takes a "vanilla" MyMyUNSW database and
--  make all of the changes necessary to make the databas
--  work correctly with your PHP scripts.
--  
--  Such changes might involve adding new tables, views,
--  PLpgSQL functions, triggers, etc. Other changes might
--  involve dropping existing tables or redefining existing
--  views and functions
--  
--  Make sure that this script does EVERYTHING necessary to
--  upgrade a vanilla database; if we need to chase you up
--  because you forgot to include some of the changes, and
--  your system will not work correctly because of this, you
--  will receive a 3 mark penalty.
--
/*
create or replace type AcObjRecord as (
	objtype text,  -- academic object's type e.g. subject, stream, program
	object  text  -- academic object's code e.g. COMP3311, SENGA1, 3978
);*/

create or replace function member(integer)
	returns setof text
as $$
declare
	aor text;
	pattern varchar;
	type AcadObjectGroupType;
	dtype AcadObjectGroupDefType;
	cmd text;
	arr text[];
	fid text;
	pat text;
	types text;
	child integer;
	r text;
	x integer;
begin
	select $1 into x
    from   Acad_object_groups a 
    where  a.id = $1;
    if (not found) then
        raise EXCEPTION 'Invalid internal ID of an academic object group %',$1;
    end if;

    for child in 
	    select a.id 
	    from   Acad_object_groups a 
	    where  a.parent = $1
	loop
	    for aor in
	    	select member(child)
	    loop 
	    	return next aor;
	    end loop;
	end loop;

	select a.definition, a.gtype, a.gdefby into pattern, type, dtype
    from   Acad_object_groups a 
    where  a.id = $1;
    types := type || 's';
    if(dtype = 'enumerated') then
    	if(type = 'subject') then
    		for aor in
    			select Subjects_group(x)
    		loop
    			return next aor;
    		end loop;
    	elsif(type = 'program') then
    		for aor in 
    			select Program_group(x)
    		loop
    			return next aor;
    		end loop;
    	else
    		for aor in 
    			select Stream_group(x)
    		loop
    			return next aor;
    		end loop;
    	end if;
    end if;

    if(dtype != 'pattern') then
    	return;
    end if;

    pattern := REGEXP_REPLACE(pattern,'[\{\}]','','g');
    pattern := REGEXP_REPLACE(pattern,';',',','g');

    select regexp_split_to_array(pattern, ',') 
    into arr;
    
    Foreach r IN 
        Array arr 
    loop
        if(r ~ '^[GEN|FREE|ALL|all|####]') then
        	aor := cast(r as text);
    		return next aor;
    	elsif(regexp_matches(r,'(.*)\/F=(.*)')) then

    		r := REGEXP_REPLACE(r,'(.*)\/F=(.*)','\1\;\2');

    		select pat, fid
    		from regexp_split_to_array(r,';');

    		cmd := 'create or replace view patt as 
    		select cast(code as text)
    		from '||types||'  
    		join OrgUnits o on (s.offeredby = o.id)
    		where s.code ~ '''||pattern||'''
    		and o.unswid = '''||fid||'''';
    		execute(cmd);
    		for aor in
	 			select cast(p.code as text)
	 			from patt p
	    		order by p.code
			loop
				if(type = 'program') then
					aor := REGEXP_REPLACE(aor,'[A-Z]','','gi');
				end if;
				return next aor;
			end loop;
    	end if;
    end loop;

    pattern := REGEXP_REPLACE(pattern,'(,?)####[A-Z0-9|\[|\]]+...,?','\1','g');
    pattern := REGEXP_REPLACE(pattern,'([A-Z]?GEN[A-Z]?|FREE)#+,?','','g');
    pattern := REGEXP_REPLACE(pattern,',$','');

    if(pattern !~ '#|[A-Z]|[0-9]') then
        return;
    end if;
    
    pattern := replace(pattern,'x','#');
    pattern := replace(pattern,'#','[0-9|A-Za-z]');
    pattern := replace(pattern,',','|');
    pattern := replace(pattern,'!','~');


    cmd := 'create or replace view patt as 
    select cast(code as text) 
    from '||types||' s 
    where s.code ~ '''||pattern||'''';

    execute(cmd);
    for aor in
	 	select cast(p.code as text)
	 	from patt p
	    order by p.code
	loop
		if(type = 'program') then
			aor := REGEXP_REPLACE(aor,'[A-Z]','','gi');
		end if;
		return next aor;
	end loop;
   
end;
$$ language plpgsql
;

create or replace function Subjects_group(integer) returns setof char(8)
as
$$
	select distinct s.code
	from Subject_group_members sg
	join Subjects s on (sg.subject = s.id)
	where sg.ao_group = $1
	order by s.code
$$ language sql
;

create or replace function Stream_group(integer) returns setof char(6)
as
$$
	select distinct s.code
	from Stream_group_members sg
	join Streams s on (sg.stream = s.id)
	where sg.ao_group = $1
	order by s.code
$$ language sql
;

create or replace function Program_group(integer) returns setof char(4)
as
$$
	select distinct p.code
	from Program_group_members sg
	join Programs p on (sg.program = p.id)
	where sg.ao_group = $1
	order by p.code
$$ language sql
;

create or replace function id2code(integer,text) returns text
as
$$
declare
	code text;
	cmd text;
begin
	cmd := 'create or replace view codes as 
    select cast(s.code as text) 
    from '||$2||' s
    where s.id = '||$1||'';
    execute(cmd);
    for code in
    	select * from codes
    loop
    	return code;
    end loop;
end;
$$ language plpgsql
;

create or replace view rules_for_stream(code,id,type,min,max,ao_group)
as
SELECT p.code,
    r.id,
    r.type,
    r.min,
    r.max,
    r.ao_group
   FROM streams p
     JOIN stream_rules pr ON p.id = pr.stream
     JOIN rules r ON pr.rule = r.id;
;
