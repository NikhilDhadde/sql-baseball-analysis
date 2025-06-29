-- ========================================
-- ⚾ BASEBALL PLAYER & SALARY SQL ANALYSIS
-- ========================================

-- PART I: SCHOOL ANALYSIS
-- ------------------------

-- 1. View the schools and school_details tables
SELECT * FROM schools;
SELECT * FROM school_details;

-- Join both tables to view full school information
SELECT * 
FROM schools s 
LEFT JOIN school_details sd ON s.schoolID = sd.schoolID;

-- 2. Number of schools that produced players, grouped by decade
SELECT 
    ROUND(yearid, -1) AS decade,
    COUNT(DISTINCT schoolid) AS total_schools
FROM schools
GROUP BY decade;

-- 3. Top 5 schools that produced the most players
SELECT  
    sd.name_full, 
    COUNT(DISTINCT s.playerID) AS player_count
FROM schools s 
LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
GROUP BY s.schoolID, sd.name_full
ORDER BY player_count DESC
LIMIT 5;

-- 4. Top 3 schools per decade based on players produced
WITH school_counts AS (
    SELECT  
        FLOOR(yearid / 10) * 10 AS decade,
        sd.name_full, 
        COUNT(DISTINCT s.playerID) AS player_count
    FROM schools s 
    LEFT JOIN school_details sd ON s.schoolID = sd.schoolID
    GROUP BY decade, sd.name_full
),
ranked_schools AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY decade ORDER BY player_count DESC) AS rn
    FROM school_counts
)
SELECT 
    decade, 
    name_full, 
    player_count
FROM ranked_schools
WHERE rn <= 3
ORDER BY decade DESC, player_count DESC;


-- PART II: SALARY ANALYSIS
-- -------------------------

-- 1. View salaries for a specific team (ANA)
SELECT * 
FROM salaries 
WHERE teamID = 'ANA';

-- 2. Top 20% teams by average annual salary
WITH team_yearly_salary AS (
    SELECT 
        teamID, 
        yearID, 
        SUM(salary) AS total_salary
    FROM salaries
    GROUP BY teamID, yearID
),
average_spending AS (
    SELECT 
        teamID,
        AVG(total_salary) AS avg_annual_salary,
        NTILE(5) OVER (ORDER BY AVG(total_salary) DESC) AS percentile
    FROM team_yearly_salary
    GROUP BY teamID
)
SELECT 
    teamID, 
    ROUND(avg_annual_salary / 1e6, 1) AS avg_salary_millions
FROM average_spending
WHERE percentile = 1;

-- 3. Cumulative team spending over the years
WITH yearly_spend AS (
    SELECT 
        yearID, 
        teamID, 
        SUM(salary) AS total_salary
    FROM salaries
    GROUP BY yearID, teamID
)
SELECT 
    teamID, 
    yearID, 
    total_salary,
    SUM(total_salary) OVER (PARTITION BY teamID ORDER BY yearID) AS cumulative_spending
FROM yearly_spend;

-- 4. First year each team’s cumulative spending crossed $1 billion
WITH yearly_spend AS (
    SELECT 
        yearID, 
        teamID, 
        SUM(salary) AS total_salary
    FROM salaries
    GROUP BY yearID, teamID
),
cumulative AS (
    SELECT 
        teamID, 
        yearID, 
        SUM(total_salary) OVER (PARTITION BY teamID ORDER BY yearID) AS cumulative_spending
    FROM yearly_spend
),
milestone AS (
    SELECT 
        teamID, 
        yearID, 
        cumulative_spending,
        ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY yearID) AS rn
    FROM cumulative
    WHERE cumulative_spending > 1e9
)
SELECT * 
FROM milestone
WHERE rn = 1;


-- PART III: PLAYER CAREER ANALYSIS
-- --------------------------------

-- 1. View all players
SELECT * FROM players;

-- 2. Player age at debut, final game, and career length (in years)
SELECT 
    nameGiven,
    TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), debut) AS start_age,
    TIMESTAMPDIFF(YEAR, CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE), finalGame) AS end_age,
    TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM players
ORDER BY career_length DESC;

-- 3. Team each player debuted and ended with
SELECT  
    p.nameGiven, 
    p.debut, 
    p.finalGame,
    s.teamID AS debut_team,
    e.yearID AS end_year,
    e.teamID AS end_team
FROM players p
INNER JOIN salaries s 
    ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID
INNER JOIN salaries e 
    ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID;

-- 4. Players who started and ended on the same team, and played 10+ years
SELECT  
    p.nameGiven, 
    p.debut, 
    p.finalGame,
    s.teamID AS debut_team,
    e.teamID AS end_team,
    e.yearID - s.yearID AS years_played
FROM players p
INNER JOIN salaries s 
    ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID
INNER JOIN salaries e 
    ON p.playerID = e.playerID AND YEAR(p.finalGame) = e.yearID
WHERE s.teamID = e.teamID 
  AND e.yearID - s.yearID >= 10;


-- PART IV: PLAYER COMPARISON ANALYSIS
-- -----------------------------------

-- 1. Players table overview
SELECT * FROM players;

-- 2. Players with the same birthday (1980–1990)
WITH birthdates AS (
    SELECT 
        CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS dob, 
        nameGiven
    FROM players
)
SELECT 
    dob, 
    COUNT(*) AS players_count,
    GROUP_CONCAT(nameGiven SEPARATOR ', ') AS players
FROM birthdates
WHERE YEAR(dob) BETWEEN 1980 AND 1990
GROUP BY dob
ORDER BY dob;

-- 3. % of players by batting hand (Right, Left, Both) per team
SELECT 
    s.teamID,
    ROUND(SUM(CASE WHEN p.bats = 'R' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS right_pct,
    ROUND(SUM(CASE WHEN p.bats = 'L' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS left_pct,
    ROUND(SUM(CASE WHEN p.bats = 'B' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS both_pct
FROM salaries s
LEFT JOIN players p ON s.playerID = p.playerID
GROUP BY s.teamID;

-- 4. Avg height and weight at debut by decade, with decade-over-decade difference
WITH decade_data AS (
    SELECT 
        FLOOR(YEAR(debut) / 10) * 10 AS decade,
        AVG(weight) AS avg_weight,
        AVG(height) AS avg_height
    FROM players
    GROUP BY decade
)
SELECT 
    decade,
    avg_weight - LAG(avg_weight) OVER (ORDER BY decade) AS weight_diff,
    avg_height - LAG(avg_height) OVER (ORDER BY decade) AS height_diff
FROM decade_data
WHERE decade IS NOT NULL;
