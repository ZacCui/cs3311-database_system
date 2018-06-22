-- COMP3311 12s1 Exam Q5
-- The Q5 view must have attributes called (team,reds,yellows)

drop view if exists card_list;
create view card_list
as
select c.givenTO , c.cardtype, count(c.cardtype) as num
from Cards c
where c.cardType in ('red','yellow')
group by c.givenTo, c.cardtype 
;


drop view if exists redlist;
create view redlist
as
select t.country , count(*) as num
from card_list c
join players p on (c.givenTo = p.id)
join Teams t on (t.id = p.memberof)
where c.cardtype = 'red'
group by t.id
;

drop view if exists Q5;
create view Q5
as
select t.country as team , coalesce(r.num,0) as reds, count(*) as yellows
from card_list c
join players p on (c.givenTo = p.id)
join Teams t on (t.id = p.memberof)
left outer join redlist r on (t.country = r.country)
where c.cardtype = 'yellow'
group by t.id
;

