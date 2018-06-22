-- COMP3311 12s1 Exam Q4
-- The Q4 view must have attributes called (team1,team2,matches)


drop view if exists playList;
create view playList
as
select t1.country as team1, t2.country as team2, count(*) as num
from Involves i1, Involves i2
join Teams t1 on (i1.team = t1.id)
join Teams t2 on (i2.team = t2.id)
where i1.team < i2.team and i1.match = i2.match
group by i1.team, i2.team
;

drop view if exists Q4;
create view Q4
as
select p.team1, p.team2, num as matches
from playlist p
where p.num = (select max(num) from playList)
;

