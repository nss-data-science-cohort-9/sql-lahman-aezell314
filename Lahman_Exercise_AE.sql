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

-- Michael response:
WITH vandy_players AS (
SELECT DISTINCT playerid
FROM collegeplaying
WHERE schoolid = 'vandy'
)
SELECT
p.namefirst || ' ' || p.namelast AS full_name,
SUM(salary)::NUMERIC::MONEY AS total_earnings
FROM salaries s
INNER JOIN vandy_players v
ON s.playerid = v.playerid
INNER JOIN people p
ON s.playerid = p.playerid
GROUP BY full_name
ORDER BY total_earnings DESC;

/* 2. Using the fielding table, group players into three groups based on their position: 
 label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
 Determine the number of putouts made by each of these three groups in 2016. */

select case
		when pos = 'OF' then 'Outfield'
		when pos in ('SS','1B','2B','3B') then 'Infield'
		when pos in ('P', 'C') then 'Battery'
	end as positiontype, 
	sum(po) as totalputouts 
from fielding
where yearid = 2016
group by positiontype;

/* 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
 Do the same for home runs per game. Do you see any trends? 
 (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
 If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) */

with decades as (select * 
from generate_series(1920, 2020, 10) as decade)
select decades.decade || 's' as decade, SUM(t.SO)*1.0/(SUM(t.g)/2) as avgstrikeoutspergame, SUM(t.HR)*1.0/(SUM(t.g)/2) as avghomerunspergame
from teams t
inner join decades
on LEFT(CAST(yearid AS VARCHAR(10)), 3) = LEFT(CAST(decades.decade AS VARCHAR(10)), 3)
group by decades.decade
order by decade;
-- Average strikeouts are on the rise, starting at 5.6 in the 20's and increasing to over 15 in the 2010's. Average home runs per game started at 0.8 in the 20's,
-- then increased to 1-2 for many decades, before peaking at 2.1 in the 2000's and decreasing to 1.97 in the 2010's.

/* 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
 (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. 
 Report the players' names, number of stolen bases, number of attempts, and stolen base percentage. */

select playerid, p.namefirst || ' ' || p.namelast as playername, 
		SUM(SB) as stolenbases, SUM(SB + CS) as stealattempts, 
		ROUND((SUM(SB)*100.0)/SUM(SB + CS), 3) as stealsuccess
from batting 
inner join people p
using(playerid)
where yearid = 2016
group by playerid, playername
having SUM(SB + CS) >= 20
order by stealsuccess desc;


/* 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
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
select distinct on (playerid) playerid, yearid, sum(hr) as homeruns
from batting b
group by playerid, yearid
order by playerid, sum(hr) desc
)
select p.namefirst || ' ' || p.namelast as playername, yearid, homeruns
from careerhighhr 
inner join eligibleplayers
using(playerid)
inner join people p
using(playerid)
where yearid = 2016;


-- Open-ended questions:

/* 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. 
  As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis. */

select distinct s.yearid, corr(t.w, sum(s.salary)) OVER(partition by yearid)
from salaries s
inner join teams t
using(teamid, yearid)
where yearid >= 2000
group by s.teamid, s.yearid, t.w
order by s.yearid;

-- Correlation between number of wins and team salary varies between a low of 0.19 in 2012 to a high of 0.64 in 2016.


/* 12. In this question, you will explore the connection between number of wins and attendance.

  12a. Does there appear to be any correlation between attendance at home games and number of wins? */
  
  select corr(w, attendance)
  from teams;
  --There is a weak positive correlation between attendance at home games and number of wins, with a correlation coefficient of 0.39.
  
  /* 12b. Do teams that win the world series see a boost in attendance the following year?  */

with attendancequery as (select teamid, 
		yearid, 
		attendance, 
		wswin as WorldSeriesWinner, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) - attendance as diff
from teams
order by teamid, yearid)
select WorldSeriesWinner, avg(case 
											when diff > 0 then 1
											else 0
										end
										) as propattendanceboost
from attendancequery
where WorldSeriesWinner is not null
group by WorldSeriesWinner;
-- About 48.7% of teams that win the World Series see an attendance boost in the following year
-- However, 47% of teams that did not win the World Series also saw an attendance boost in the following year, so the effect of a World Series win seems to be small


with attendancequery as (select teamid, yearid, attendance, wswin as WorldSeriesWinner, LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance
from teams
order by teamid, yearid)
select corr(attendance, nextyearattendance) as r, REGR_SLOPE(attendance, nextyearattendance) as slope
from attendancequery
where WorldSeriesWinner = 'N';
--correlation           slope
--0.9449705534777244	0.9476427334326356

with attendancequery as (select teamid, yearid, attendance, wswin as WorldSeriesWinner, LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance
from teams
order by teamid, yearid)
select corr(attendance, nextyearattendance) as r, REGR_SLOPE(attendance, nextyearattendance) as slope
from attendancequery
where WorldSeriesWinner = 'Y';
--correlation           slope
--0.9532559371058998	0.9008125705915175

--Normal year-to-year variation actually appears to increase attendance more than a World Series win does. For teams that did not win a World Series,
--the linear regression model expects an increase of 0.95 attendees per person in the subsequent year. For teams that did win a World Series, 
--the linear model only expects an increase of 0.9 attendees per person in the subsequent year.

-- Ideally we would set up a linear regression model with x = current year's home attendance and y = next year's home attendance, 
-- with World Series Win as an extra explanatory variable. Then we could isolate the effect of a World Series win, beyond the normal
-- year-to-year variation in attendance


/* What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner. */

with attendancequery as (select teamid, 
		yearid, 
		attendance, 
		case
			when DivWin = 'Y' then 'Y'
			when WCWin = 'Y' then 'Y'
			else 'N'
		end as madeplayoffs
		, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) - attendance as diff
from teams
order by teamid, yearid)
select madeplayoffs, avg(case 
							when diff > 0 then 1
							else 0
						end
						) as propattendanceboost
from attendancequery
group by madeplayoffs;
-- About 56% of teams that made the playoffs see an attendance boost in the following year, compared with 44% of teams that did not make the playoffs.
-- The effect of making the playoffs seems to be larger than the effect of a World Series win on the subsequent year's home attendance.

with attendancequery as (select teamid, 
		yearid, 
		attendance, 
		case
			when DivWin = 'Y' then 'Y'
			when WCWin = 'Y' then 'Y'
			else 'N'
		end as madeplayoffs
		, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) - attendance as diff
from teams
order by teamid, yearid)
select corr(attendance, nextyearattendance) as r, REGR_SLOPE(attendance, nextyearattendance) as slope
from attendancequery
where madeplayoffs = 'N';
--correlation           slope
--0.9384717687386521	0.9449257043396853

with attendancequery as (select teamid, 
		yearid, 
		attendance, 
		case
			when DivWin = 'Y' then 'Y'
			when WCWin = 'Y' then 'Y'
			else 'N'
		end as madeplayoffs
		, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) as nextyearattendance, 
		LEAD (attendance) OVER (PARTITION BY teamid ORDER BY yearid) - attendance as diff
from teams
order by teamid, yearid)
select corr(attendance, nextyearattendance) as r, REGR_SLOPE(attendance, nextyearattendance) as slope
from attendancequery
where madeplayoffs = 'Y';
--correlation           slope
--0.8954860602925234	0.8832100450497469

--Normal year-to-year variation actually appears to increase attendance more than making the playoffs does. For teams that did not make the playoffs,
--the linear regression model expects an increase of 0.94 attendees per person in the subsequent year. For teams that did make the playoffs, 
--the linear model only expects an increase of 0.88 attendees per person in the subsequent year.

-- Ideally we would set up a linear regression model with x = current year's home attendance and y = next year's home attendance, 
-- with making the playoffs as an extra explanatory variable. Then we could isolate the effect of making the playoffs, beyond the normal
-- year-to-year variation in attendance


/* 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
  Investigate this claim and present evidence to either support or dispute this claim. 
  
  First, determine just how rare left-handed pitchers are compared with right-handed pitchers. */
  
  select throws, count(playerid), count(playerid)*100.0/sum(count(playerid)) OVER() as pct
  from people
  where throws in ('R','L')
  group by throws;
  -- There are 14,480 right-handed players in our dataset (about 80% of players) and 3,654 left-handed players (about 20% of players).
  
  /* Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame? */
with cyyoungwinners as 
(select playerid, 'Y' as won 
from awardsplayers 
where awardID = 'Cy Young Award'
)
select throws, avg(case
					  when cyyoungwinners.won = 'Y' then 1
					  else 0
					end
					) as propwinner
from people 
left join cyyoungwinners
using(playerid)
where throws in ('R','L')
group by throws;
-- Left handed pitchers are more likely to win the Cy Young award. About 1% of left handed pitchers won the award, compared to 0.5% of right handed pitchers.


with halloffamers as 
(select playerid, inducted
from HallOfFame 
)
select throws, avg(case
					  when halloffamers.inducted = 'Y' then 1
					  else 0
					end
					) as propwinner
from people 
left join halloffamers
using(playerid)
where throws in ('R','L')
group by throws;
-- Left handed pitchers are slightly less likely to be inducted into the hall of fame. 
-- About 1.2% of left handed pitchers are inducted, compared to 1.4% of right-handed pitchers

-- Do left handed pitchers get more strikeouts per game?
select throws, sum(so)*1.0/sum(g) as strikeouts
from people p 
inner join pitching p2
using(playerid)
where throws in ('R','L')
group by throws;
-- Lefties have about the same proportion of strikeouts as righties.

-- There does not seem to be compelling evidence that left handed pitchers are much more successful than right handed pitchers. However, they are
-- twice as likely to win the Cy Young Award.


