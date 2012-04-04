/* More readable summary of daily sleep logs */
SELECT date, DATE_FORMAT(date, '%a') AS day, DAYOFWEEK(date) IN (1,7) AS weekend, 
  local_time_started AS asleep, local_time_finished AS awake, 
  SUBSTRING(SEC_TO_TIME(ROUND((time_finished-time_started)/60)*60), 1, 5) AS hours,
  ROUND((time_finished-time_started)/60/60, 1) AS hours_f, 
  quality, location
FROM sleeps
ORDER BY time_finished ASC;

/* Sleep by day of week - all time */
SELECT day, ROUND(avg(hours),2) AS avg
FROM sleep_summary
GROUP BY day
ORDER BY weekend;

/* Sleep on weekdays vs weekends showing per month */
SELECT DATE_FORMAT(date, "%M %Y") AS month, 
  IF(weekend=0, "Mon-Fri", "Sat-Sun") AS days, 
  SUBSTRING(SEC_TO_TIME(ROUND(AVG(hours)*60)*60), 1, 5) AS avg,
  AVG(hours) AS avg_f
FROM sleep_summary
GROUP BY MONTH(date), weekend
ORDER BY YEAR(date), MONTH(date), weekend;

