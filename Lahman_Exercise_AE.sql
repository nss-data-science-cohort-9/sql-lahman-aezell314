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
-- There were 10 years between 1970 and 2016 where the team with the most wins also won the world serie.