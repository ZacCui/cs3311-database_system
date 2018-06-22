-- COMP3311 12s1 Exam Q2
-- The Q2 view must have one attribute called (player,goals)

drop view if exists Q2;
create view Q2
as
select p.name as player, count(*) as goals
from Players p
join Goals g on (g.scoredby = p.id)
where g.rating = 'amazing'
group by p.id
having count(*) > 1
;
