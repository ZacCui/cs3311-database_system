-- COMP3311 12s1 Exam Q6
-- The Q6 view must have attributes called
-- (location,date,team1,goals1,team2,goals2)


drop view if exists goalslist;
create view goalslist
as
select m.id as id , t.id as team, count(*) as num
from matches m 
join goals g on (m.id = g.scoredIn)
join players p on (p.id = g.scoredby)
join teams t on (t.id = p.memberof)
group by m.id, t.id
;

drop view if exists playList;
create view playList
as
select m.city, m.playedon as 'date',t1.country as team1, coalesce(gs1.num,0) ,t2.country as team2, coalesce(gs2.num,0)
from Involves i1, Involves i2
join Teams t1 on (i1.team = t1.id)
join Teams t2 on (i2.team = t2.id)
join Matches m on (m.id = i1.match)
left outer join goalslist gs1 on (m.id = gs1.id and gs1.team = t1.id)
left outer join goalslist gs2 on (m.id = gs2.id and gs2.team = t2.id)
where i1.team < i2.team and i1.match = i2.match
group by i1.team, i2.team, m.id
;



drop view if exists Q6;
create view Q6
as
select * from playlist
;
