-- COMP3311 12s1 Exam Q3
-- The Q3 view must have attributes called (team,players)

drop view if exists scoredPlayer;
create view scoredPlayer
as
select p.id as player
from Players p
join Goals g on (g.scoredby = p.id)
group by p.id
;

drop view if exists Team_num;
create view Team_num
as
select t.country as name, count(*) as num
from Teams t
join Players p on (p.memberof = t.id)
where p.id not in 
(select player from scoredPlayer)
group by t.id
;

drop view if exists Q3;
create view Q3
as
select name as team , num as players
from Team_num
where num = (select max(num) from Team_num)
;
