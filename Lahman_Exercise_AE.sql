/* 1. Find all players in the database who played at Vanderbilt University. 
Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors? */

select s.playername, sum(salary) as totalsalary
from
(select distinct namefirst || ' ' || namelast as playername, playerid
from people
inner join collegeplaying
using(playerid)
inner join schools
using(schoolid)
where schoolname = 'Vanderbilt University') s
inner join salaries
using(playerid)
group by s.playername
order by totalsalary desc;
-- David Price was the Vanderbilt player who went on to make the most money in the major leagues. 

/* Using the fielding table, group players into three groups based on their position: 
 label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
 Determine the number of putouts made by each of these three groups in 2016. */

select s.positiontype, sum(s.po) as totalputouts 
from
(select po, pos, case
	when pos = 'OF' then 'Outfield'
	when pos in ('SS','1B','2B','3B') then 'Infield'
	when pos in ('P', 'C') then 'Battery'
end as positiontype
from fielding
where yearid = 2016) s
group by s.positiontype;

/* Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
 Do the same for home runs per game. Do you see any trends? 
 (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
 If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) */

select d.decade, sum(strikeouts) as totalstrikeouts, sum(homeruns) as totalhomeruns
from
(
(select b.yearid, SUM(b.SO) as strikeouts, SUM(b.HR) as homeruns
from batting b
group by b.yearid) b
inner join (select * 
from generate_series(1920, 2020, 10) as decade) d
on LEFT(CAST(b.yearid AS VARCHAR(10)), 3) = LEFT(CAST(d.decade AS VARCHAR(10)), 3)
) 
group by d.decade;
-- Strikeouts and home runs are mostly on the rise from the 1920s to the 2010s. Both peaked in the 2000s and declined in the 2010s.

/* 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
 (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. 
 Report the players' names, number of stolen bases, number of attempts, and stolen base percentage. */

select p.namefirst || ' ' || p.namelast as playername, SUM(SB) as stolenbases, SUM(SB + CS) as stealattempts, ROUND((SUM(SB)*100.0)/SUM(SB + CS), 2) as stealsuccess
from batting 
inner join people p
using(playerid)
where yearid = 2016
group by playerid, playername
having SUM(SB + CS) >= 20;


/* From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
 What is the smallest number of wins for a team that did win the world series? 
 Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
 Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? 
 What percentage of the time? */

--largest number of wins for a team that did not win the world series
select teamid, name, W as wins, yearid
from teams
where yearid between 1970 and 2016
and WSWin = 'N'
order by wins desc;

--SEA	Seattle Mariners	116	2001

--smallest number of wins for a team that did win the world series
select teamid, name, W as wins, yearid
from teams
where yearid between 1970 and 2016
and WSWin = 'Y'
order by wins;

--LAN	Los Angeles Dodgers	63	1981

select teamid, yearid, g
from teams 
where WSWin = 'Y'
and yearid between 1970 and 2016
order by g;

--The LA Dodgers in 1981 played the lowest total number of games for any World Series winner between 1970 and 2016, which could explain the unusually small number of wins.

--smallest number of wins for a team that did win the world series (excluding 1981)
select teamid, name, W as wins, yearid
from teams
where yearid between 1970 and 2016
and not yearid = 1981
and WSWin = 'Y'
order by wins;

--How often from 1970 to 2016 was it the case that a team with the most wins also won the world series?
select yearid, teamid
from
((select distinct on (yearid) yearid, teamid
from teams
where yearid between 1970 and 2016
order by yearid, w desc)
union all
(select yearid, teamid
from teams
where yearid between 1970 and 2016
and WSWin = 'Y'))
group by yearid, teamid
having count(*) = 2;
-- There were 10 years between 1970 and 2016 where the team with the most wins also won the world series.


/* 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
 Give their full name and the teams that they were managing when they won the award. */

select p.namefirst || ' ' || p.namelast as managername, a.awardid, a.yearid, a.lgid, t.name
from AwardsManagers a
inner join managers m
using(playerid, yearid)
inner join teams t
using(yearid, teamid)
inner join people p 
using(playerid)
where a.awardid = 'TSN Manager of the Year' 
and a.lgid in ('NL', 'AL')
and a.playerid in 
	(select distinct playerid
	from AwardsManagers
	where awardid = 'TSN Manager of the Year' and lgid in ('NL', 'AL')
	group by playerid
	having count(distinct lgid) = 2)
order by managername, yearid;

/* 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). 
 Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player. */
select pe.namefirst || ' ' || pe.namelast as playername, round(sum(cast(s.salary as numeric))/sum(cast(p.so as numeric)), 2) as efficiency
from pitching p
inner join salaries s
using(playerid)
inner join people pe
using(playerid)
where p.yearid = 2016
group by playerid, playername
having min(gs) >= 10
order by efficiency
limit 1;
-- Robbie Ray was the least efficient pitcher in 2016 in terms of salary / strikeouts.

/* 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame 
(If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' 
in the inducted column of the halloffame table. */
with halloffamers as 
	(select playerid, yearid
	from HallOfFame
	where inducted = 'Y')
select p.namefirst || ' ' || p.namelast as playername, sum(b.H) as careerhits, halloffamers.yearid as yearinducted
from batting b
inner join people p
using(playerid)
left join halloffamers
using(playerid)
group by playerid, playername, halloffamers.yearid
having sum(b.H) >= 3000
order by careerhits;


/* 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names. */

with highhitters as (select playerid, teamid, sum(h) as totalhits 
from batting
group by playerid, teamid
having sum(h) >= 1000)
select distinct p.namefirst || ' ' || p.namelast as playername
from highhitters
inner join people p
using(playerid)
group by playerid, playername
having count(teamid) = 2;

/* 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016. */
with eligibleplayers as (
(select playerid 
from batting b
group by playerid
having max(yearid) - min(yearid) + 1 >= 10)
intersect
(select playerid
from batting b
where yearid = 2016
and hr > 0)
),
careerhighhr as (
select distinct on (playerid) playerid, yearid, hr as homeruns
from batting b
order by playerid, hr desc
)
select p.namefirst || ' ' || p.namelast as playername, yearid, homeruns
from careerhighhr 
inner join eligibleplayers
using(playerid)
inner join people p
using(playerid)
where yearid = 2016;







