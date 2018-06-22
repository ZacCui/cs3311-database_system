-- COMP3311 18s1 Assignment 1
-- Written by Ziyi Cui (z5097491), April 2018

-- Q1: ...

create or replace view Q1(unswid, name)
as
select p.unswid as "studnet id", p.name as "name"
from People p, Course_enrolments c
where p.id = c.student and c.grade is not null
group by p.id
having count(c.course) > 65
;

-- Q2: ...

create or replace view Q2(nstudents, nstaff, nboth)
as
select st.nstudents, sta.nstaff, nb.nboth
from (select count(*) as nstudents
	  from People p join Students s on (p.id = s.id)) st,
	 (select count(*) as nstaff
	  from People p join Staff s on (p.id = s.id)) sta,
	 (select count(*) as nboth
	  from People p join Students s on (p.id = s.id)
	  join Staff st on (st.id = p.id)) nb 

;

-- Q3: ...

create or replace view LicFreq(staff, num) 
as
select cs.staff as staff,count(cs.course) as num
from Course_staff cs
where cs.role = (select id from staff_roles
where name = 'Course Convenor')
group by cs.Staff
;

create or replace view Q3(name, ncourses)
as
select p.name, l.num as ncourses 
from People p join
(select l.Staff, l.num
from LicFreq l
where l.num = (select max(num)
				from LicFreq)
) l
on (l.Staff = p.id)
;

-- Q4: ...
create or replace view IdOfSe(id)
as 
select s.id 
from Semesters s
where s.year = 2005 and s.term = 'S2'
;

create or replace view Q4a(id)
as
select distinct p.unswid
from People p
join 
(select pe.student as id
from Program_enrolments pe
where exists
(select p.id from programs p where p.code = '3978'
and p.id = pe.program)
and exists 
(select i.id from IdOfSe i 
where pe.Semester = i.id)) i
on (p.id = i.id)

;

create or replace view Q4b(id)
as
select distinct p.unswid
from People p
join 
(select pe.student as id
from Program_enrolments pe join
(select se.partof
from (select id from Streams where name = 'Software Engineering') i
join Stream_enrolments se on(i.id = se.stream)) i
on (pe.id = i.partof)
where exists
(select i.id from IdOfSe i
where pe.semester = i.id)) i
on (p.id = i.id)
;

create or replace view CSE_Programs(id,name,school)
as
select p.id, p.name, o.name as school
from programs p
join orgunits o
on (p.offeredby = o.id)
where o.name ilike 'Computer Science and Engineering%'
;

create or replace view Q4c(id)
as
select distinct p.unswid
from People p
join 
(select pe.student as id 
from Program_enrolments pe join
CSE_Programs cp
on (cp.id = pe.program)
where exists
(select i.id from IdOfSe i
where pe.semester = i.id)) i
on (p.id = i.id)
;

-- Q5: ...
create or replace view numofcom(fid,num)
as
select l.fid, count(l.name) as num
from 
(select facultyof(id) as fid ,name 
from orgunits 
where name ilike '%committee%') l
where l.fid is not null
group by l.fid
;

create or replace view Q5(name)
as
select o.name
from
(select n.fid 
from numofcom n
where n.num = 
(select max(num)
from numofcom
))n 
join orgunits o
on (n.fid = o.id)
;

-- Q6: ...

create or replace function Q6(integer) returns text
as
$$
	select p.name 
	from People p
	where p.unswid = $1
	or p.id = $1;
$$ language sql
;

-- Q7: ...
create or replace view Liclist(id,course)
as
	select cs.staff as staff, cs.course
	from Course_staff cs
	where cs.role = (select id from staff_roles
	where name = 'Course Convenor')
;

create or replace function Q7(text)
	returns table (course text, year integer, term text, convenor text)
as $$
	select $1, se.year, cast(se.term as text), p.name
	from Courses c
	join Subjects s 
	on (c.subject = s.id)
	join Semesters se
	on (se.id = c.semester)
	join Liclist l 
	on (l.course = c.id)
	join People p
	on (p.id = l.id)
	where s.code = $1;
$$ language sql
;

-- Q8: ...

create or replace function Q8(_sid integer)
	returns setof NewTranscriptRecord
as $$
declare
        rec NewTranscriptRecord;
        UOCtotal integer := 0;
        UOCpassed integer := 0;
        wsum integer := 0;
        wam integer := 0;
        x integer;
begin
        select s.id into x
        from   Students s join People p on (s.id = p.id)
        where  p.unswid = _sid;
        if (not found) then
                raise EXCEPTION 'Invalid student %',_sid;
        end if;
        for rec in
        		select N.code, N.terms,N.pcode,N.name,N.mark,N.grade,N.uoc
        		from 
                (select  distinct su.code as code, t.starting,
                         substr(t.year::text,3,2)||lower(t.term) as terms,
                         pro.code as pcode,
                         substr(su.name,1,20) as name,
                         e.mark, e.grade, su.uoc
                from   People p
                         join Students s on (p.id = s.id)
                         join Course_enrolments e on (e.student = s.id)
                         join Courses c on (c.id = e.course)
                         join Subjects su on (c.subject = su.id)
                         join Semesters t on (c.semester = t.id)
                         join Program_enrolments pe on (pe.student = p.id)
                         join programs pro on (pe.program = pro.id)
                where  p.unswid = _sid and pe.Semester = c.Semester
                order by t.starting ,su.code
                ) N
        loop
                if (rec.grade = 'SY') then
                        UOCpassed := UOCpassed + rec.uoc;
                elsif (rec.mark is not null) then
                        if (rec.grade in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                                -- only counts towards creditted UOC
                                -- if they passed the course
                                UOCpassed := UOCpassed + rec.uoc;
                        end if;
                        -- we count fails towards the WAM calculation
                        UOCtotal := UOCtotal + rec.uoc;
                        -- weighted sum based on mark and uoc for course
                        wsum := wsum + (rec.mark * rec.uoc);
                        -- don't give UOC if they failed
                        if (rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
                                rec.uoc := 0;
                        end if;

                end if;
                return next rec;
        end loop;
        if (UOCtotal = 0) then
                rec := (null,null,null,'No WAM available',null,null,null);
        else
                wam := wsum / UOCtotal;
                rec := (null,null,null,'Overall WAM',wam,null,UOCpassed);
        end if;
        -- append the last record containing the WAM
        return next rec;
end;
$$ language plpgsql
;


-- Q9: ...
create or replace function Q9(integer)
	returns setof AcObjRecord
as $$
declare
	aor AcObjRecord;
	pattern varchar;
	type AcadObjectGroupType;
	dtype AcadObjectGroupDefType;
	cmd text;
	arr text[];
	r text;
	x integer;
begin
	select $1 into x
    from   Acad_object_groups a 
    where  a.id = $1;
    if (not found) then
        raise EXCEPTION 'Invalid internal ID of an academic object group %',$1;
    end if;

	select a.definition, a.gtype, a.gdefby into pattern, type, dtype
    from   Acad_object_groups a 
    where  a.id = $1;
    if(dtype = 'query' or dtype = 'enumerated' or pattern ~ '{.*}' or pattern ~ '.*\/F=.*') then
    	return;
    end if;
    
    select regexp_split_to_array(pattern, ',') 
    into arr;
    
    Foreach r IN 
        Array arr 
    loop
        if(r ~ 'GEN|FREE') then
        	aor.objtype := type;
        	aor.object := r;
    		return next aor;
    	end if;
    end loop;
    
    pattern := REGEXP_REPLACE(pattern,'([A-Z]?GEN[A-Z]?|FREE)#+,?','','g');
    pattern := REGEXP_REPLACE(pattern,',$','');

    if(pattern !~ '#|[A-Z]|[0-9]') then
        return;
    end if;
    
    pattern := replace(pattern,'x','#');
    pattern := replace(pattern,'#','[0-9|A-Za-z]');
    pattern := replace(pattern,',','|');

    cmd := 'create or replace view patt as select * from subjects s where s.code ~ '''||pattern||'''';


    execute(cmd);
    for aor in
	 	select cast(type as text), p.code
	 	from patt p
	    order by p.code
	loop
		return next aor;
	end loop;
   
end;
$$ language plpgsql
;

