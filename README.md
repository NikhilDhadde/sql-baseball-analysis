# ⚾ Baseball Career & Salary SQL Analysis

This project analyzes player careers, school contributions, and team salary patterns in professional baseball using SQL.

---

## 🔍 Objective

To derive insights from historical baseball data and answer analytical business questions across schools, teams, and players.

---

## 🧠 Skills Demonstrated

- Complex SQL joins (LEFT, INNER)
- Window functions (ROW_NUMBER, SUM OVER, LAG)
- Grouping, aggregation, and ranking logic
- Common Table Expressions (CTEs)
- Date calculations (career age, debut analysis)
- Business insights using data

---

## 🧾 Analysis Breakdown

### 🏫 School Analysis
- Schools producing the most players
- Top 3 schools by decade
- Total schools by player-producing decade

### 💰 Salary Analysis
- Top 20% of teams by average salary
- Cumulative and billion-dollar salary milestones
- Team spending trends by year

### 🧓 Player Career Analysis
- Player age at debut and retirement
- Career length calculation
- Players who began and ended on the same team

### 🧬 Player Comparison
- Players sharing birthdays
- Batting hand percentages per team
- Height/weight trends across decades

---

## 📌 Sample Query

```sql
SELECT decade, 
       avgwt - LAG(avgwt) OVER(ORDER BY decade) AS wt_diff,
       avght - LAG(avght) OVER(ORDER BY decade) AS ht_diff
FROM (
    SELECT FLOOR(YEAR(debut) / 10) * 10 AS decade,
           AVG(weight) AS avgwt,
           AVG(height) AS avght
    FROM players
    GROUP BY decade
) AS data;
