drop view if exists q1;
create view q1 as
select b.name as beer
from Beers b
join Brewers br on (b.brewer = br.id)
where br.name = 'Toohey''s'
;

drop view if exists q3;
create view q3 as
select br.name
from Likes l
join drinkers d on (l.drinker = d.id)
join beers b on (b.id = l.beer)
join brewers br on (br.id = b.brewer)
where d.name = 'John';

drop view if exists q4;
create view q4 as
select count(distinct id)
from beers;

drop view if exists q5;
create view q5 as
select count(distinct id)
from brewers;

drop view if exists q6;
create view q6 as
select b.name, c.name
from beers b
join beers c on (c.brewer = b.brewer)
where b.name < c.name;

drop view if exists q7;
create view q7 as
select br.name, count(*) as num
from brewers br
join beers b on (br.id = b.brewer)
group by br.name
order by count(*) asc;

drop view if exists q8;
create view q8 as
select br.name
from q7 br
where br.num = (select max(num) from q7);

drop view if exists q9;
create view q9 as
select name
from beers
group by brewer
having count(*) = 1;

drop view if exists q10;
create view q10 as
select distinct(b.name) as beer
from   Frequents f
         join Drinkers d on (d.id=f.drinker)
         join Sells s on (s.bar=f.bar)
         join Beers b on (b.id=s.beer)
where  d.name = 'John'
;

drop view if exists q11;
create view q11 as
select distinct ba.name 
from bars ba
join frequents f on (ba.id = f.bar)
join drinkers d on (d.id = f.drinker)
where d.name = 'John' or d.name = 'Gernot';

drop view if exists bar_and_drinker;
create view bar_and_drinker as
select b.name as bar, d.name as drinker
from   Bars b
         join Frequents f on (b.id=f.bar)
         join Drinkers d on (d.id=f.drinker)
;

drop view if exists Q11;
create view Q11 as
select bar from Bar_and_drinker where drinker = 'John'
intersect
select bar from Bar_and_drinker where drinker = 'Gernot'
;


drop view if exists beer_price;
create view beer_price as
select b.name, s.price
from sells s
join beers b on(b.id = s.beer);

drop view if exists Q14;
create view Q14 as
select b.name 
from beer_price b
where b.price = (select max(price) from beer_price);


drop view if exists q21;
create view q21 as 
select b.name, count(s.bar) as num
from beers b 
join sells s on (b.id = s.beer)
group by b.name;

drop view if exists q211;
create view q211 as 
select name 
from q21
where num = (select count(*) from bars);



