-- How do annual members and casual riders use Cyclistic bikes differently?
-- Exploratory Data Analysis and Data Cleaning
SELECT
	*
FROM
	rides;
	
-- Renamed member_casual COLUMN to user_type COLUMN
-- Renamed rideable_type COLUMN to bike_type COLUMN
-- Added ride_length, day_of_week, and day_number COLUMNS

-- What is the total number of rides?
SELECT
	COUNT(*)
FROM
	rides;
	
-- How many rides have either/both start station or end station missing?
-- Hypothesis: Rides with missing start or end station likely encountered system errors 
-- and are harder to validate hence my decision to exclude them from my analysis.
SELECT
	CASE
		WHEN start_station_id IS NULL AND end_station_id IS NULL THEN 'Both Missing'
		WHEN start_station_id IS NULL THEN 'Start_Station Missing'
		WHEN end_station_id IS NULL THEN 'End_Station Missing'
		ELSE 'None Missing'
	END AS station_status,
	COUNT(*) AS no_of_rides
FROM
	rides
GROUP BY
	station_status;
	
-- Are there rides with invalid start or end times?
-- If such rides exist then they need to be excluded from my analysis.
SELECT
	*,
	COUNT(*)
		OVER() AS no_of_rides
FROM
	rides
WHERE
	ended_at < started_at;

-- How are rides distributed across different duration groups?
-- Specifically, what percentage of rides lasted less than 1 minute,
-- Hypothesis: Rides that lasted less than 1 minute are likely
-- rides where system error occurred or accidental unlocks or the rider changed their mind
-- hence I have decided to exclude those rides from my analysis as well.
WITH RideDuration AS (
	SELECT
		CASE
			WHEN ride_length < INTERVAL '1 minute' THEN 'Under 1 min'
			WHEN ride_length < INTERVAL '5 minutes' THEN '1-5 mins'
			WHEN ride_length < INTERVAL '10 minutes' THEN '5-10 mins'
			WHEN ride_length < INTERVAL '15 minutes' THEN '10-15 mins'
			WHEN ride_length < INTERVAL '30 minutes' THEN '15-30 mins'
			ELSE '30+ mins'
		END AS duration,
		COUNT(*) AS no_of_rides
	FROM
		rides
	GROUP BY
		duration
),
TotalRides AS (
	SELECT
		duration,
		no_of_rides,
		SUM(no_of_rides) OVER() AS total_rides
	FROM
		RideDuration
),
Percentage AS (
	SELECT
		duration,
		no_of_rides,
		total_rides,
		ROUND(no_of_rides * 100.0 / total_rides, 2) AS percentage
	FROM
		TotalRides
)
SELECT
	duration,
	no_of_rides,
	total_rides,
	percentage
FROM
	Percentage
ORDER BY
	no_of_rides DESC;
	
-- Filter out null and invalid data
SELECT
	*,
	COUNT(*)
		OVER() AS no_of_rides
FROM
	rides
WHERE
	start_station_id IS NOT NULL
	AND end_station_id IS NOT NULL
	AND ended_at > started_at
	AND ride_length >= INTERVAL '1 minute'
ORDER BY
	started_at;

-- CREATE VIEW of cleaned data
CREATE VIEW rides_cleaned AS
	SELECT
	    *
	FROM 
		rides
	WHERE
		start_station_id IS NOT NULL
		AND end_station_id IS NOT NULL
		AND ended_at > started_at
		AND ride_length >= INTERVAL '1 minute';

-- What is the total number of valid rides?
SELECT
	COUNT(*) AS total_rides
FROM
	rides_cleaned;

-- What is the average ride length?
SELECT
	DATE_TRUNC('second', AVG(ride_length)) AS avg_ride_length
FROM
	rides_cleaned;

-- How many rides were taken by each user type?
SELECT
	user_type,
	COUNT(ride_id) AS no_of_rides
FROM
	rides_cleaned
GROUP BY
	user_type
ORDER BY
	no_of_rides DESC;

-- What percentage of total rides comes from casual vs members?
WITH RideCount AS (
	SELECT
		user_type,
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type
),
TotalRides AS (
	SELECT
		user_type,
		no_of_rides,
		SUM(no_of_rides) 
			OVER() AS total_rides
	FROM
		RideCount
)
SELECT
	user_type,
	no_of_rides,
	total_rides,
	ROUND(no_of_rides * 100.0 / total_rides, 2) AS percentage
FROM
	TotalRides;

-- What is the average ride length by user type?
SELECT
	user_type,
	DATE_TRUNC('second', AVG(ride_length)) AS avg_ride_length
FROM
	rides_cleaned
GROUP BY
	user_type
ORDER BY
	avg_ride_length DESC;

-- What percentage of rides are shorter, average, or longer than the average ride length for each user type?
WITH AverageRideLength AS (
	SELECT
		user_type,
		ride_length,
		DATE_TRUNC('second', AVG(ride_length) 
			OVER(PARTITION BY user_type)) AS avg_ride_length
	FROM
		rides_cleaned
),
Category AS (
	SELECT
		user_type,
		ride_length,
		avg_ride_length,
		CASE
			WHEN ride_length > avg_ride_length THEN 'Long'
			WHEN ride_length < avg_ride_length THEN 'Short'
			ELSE 'Average'
		END AS ride_duration
	FROM
		AverageRideLength
),
TotalRides AS (
	SELECT
		user_type,
		avg_ride_length,
		ride_duration,
		COUNT(*) AS no_of_rides,
		SUM(COUNT(*))
			OVER(PARTITION BY user_type) AS total_rides
	FROM
		Category
	GROUP BY
		user_type,
		avg_ride_length,
		ride_duration
),
Percentage AS (
	SELECT
		user_type,
		avg_ride_length,
		ride_duration,
		no_of_rides,
		total_rides,
		ROUND(no_of_rides * 100.0 / total_rides, 2) AS percentage
	FROM
		TotalRides
)
SELECT
	*
FROM
	Percentage
ORDER BY
	user_type,
	no_of_rides DESC;	

-- What is the preferred bike type among each user type?
WITH BikeRide AS (
	SELECT
		user_type,
		bike_type,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		bike_type
)
SELECT
	user_type,
	bike_type,
	no_of_rides
FROM
	BikeRide
WHERE
	rank = 1
ORDER BY
	no_of_rides DESC;

-- What are the top 5 busiest start stations among each user type?
WITH StartStation AS (
	SELECT
		user_type,
		start_station_name,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		start_station_name
)
SELECT
	user_type,
	start_station_name,
	no_of_rides
FROM
	StartStation
WHERE
	rank <= 5
ORDER BY
	user_type,
	no_of_rides DESC;

-- Which start stations drive the highest volume of rides for each user type?
WITH StartStation AS (
	SELECT
		user_type,
		start_station_name,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		start_station_name
)
SELECT
	user_type,
	start_station_name,
	no_of_rides,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type 
			ORDER BY no_of_rides DESC) AS rolling_count,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type) AS total_rides,
	ROUND(SUM(no_of_rides) 
			OVER(PARTITION BY user_type 
				ORDER BY no_of_rides DESC) * 100.0 / 
					SUM(no_of_rides) OVER(PARTITION BY user_type), 2) AS percentage
FROM
	StartStation
ORDER BY 
	user_type, 
	no_of_rides DESC;

-- What are the top 5 busiest end stations among each user type?
WITH EndStation AS (
	SELECT
		user_type,
		end_station_name,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		end_station_name
)
SELECT
	user_type,
	end_station_name,
	no_of_rides
FROM
	EndStation
WHERE
	rank <= 5
ORDER BY
	user_type,
	no_of_rides DESC;

-- Which end stations drive the highest volume of rides for each user type?
WITH EndStation AS (
	SELECT
		user_type,
		end_station_name,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		end_station_name
)
SELECT
	user_type,
	end_station_name,
	no_of_rides,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type 
			ORDER BY no_of_rides DESC) AS rolling_count,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type) AS total_rides,
	ROUND(SUM(no_of_rides) 
			OVER(PARTITION BY user_type 
				ORDER BY no_of_rides DESC) * 100.0 / 
					SUM(no_of_rides) OVER(PARTITION BY user_type), 2) AS percentage
FROM
	EndStation
ORDER BY 
	user_type, 
	no_of_rides DESC;

-- What percentage of rides are round vs one-way trips for each user type?
WITH RideCategory AS (
	SELECT
		user_type,
		CASE
			WHEN start_station_name = end_station_name THEN 'Round Trip'
			ELSE 'One-Way Trip'
		END AS ride_category,
		COUNT(ride_id) AS no_of_rides,
		SUM(COUNT(ride_id))
			OVER(PARTITION BY user_type) AS total_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		ride_category
),
Percentage AS (
	SELECT
		user_type,
		ride_category,
		no_of_rides,
		total_rides,
		ROUND(no_of_rides * 100.0 / total_rides, 2) AS percentage
	FROM
		RideCategory
)
SELECT
	*
FROM
	Percentage
ORDER BY
	user_type,
	no_of_rides DESC;

-- What is the average number of rides taken each day among each user type?
WITH DailyRides AS (
    SELECT
        user_type,
        DATE(started_at) AS ride_date,
        COUNT(ride_id) AS no_of_rides
    FROM 
		rides_cleaned
    GROUP BY
        user_type,
        ride_date
	ORDER BY
		user_type,
		ride_date
)
SELECT
    user_type,
    ROUND(AVG(no_of_rides)) AS avg_daily_rides
FROM 
	DailyRides
GROUP BY 
	user_type
ORDER BY
	avg_daily_rides DESC;

-- How many rides are taken each hour by user type?
SELECT
	user_type,
	EXTRACT(HOUR FROM started_at) AS hour,
	COUNT(ride_id) AS no_of_rides
FROM
	rides_cleaned
GROUP BY
	user_type,
	hour
ORDER BY
	user_type, 
	hour;

-- Which hours contribute most to total ride volume for each user type, 
-- and how concentrated are rides in peak hours?
WITH HourlyRides AS (
	SELECT
		user_type,
		EXTRACT(HOUR FROM started_at) AS hour,
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		hour	
)
SELECT
	user_type,
	hour,
	no_of_rides,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type 
			ORDER BY no_of_rides DESC) AS rolling_count,
	SUM(no_of_rides) 
		OVER(PARTITION BY user_type) AS total_rides,
	ROUND(SUM(no_of_rides) 
			OVER(PARTITION BY user_type 
				ORDER BY no_of_rides DESC) * 100.0 / 
					SUM(no_of_rides) OVER(PARTITION BY user_type), 2) AS percentage
FROM
	HourlyRides
ORDER BY 
	user_type, 
	no_of_rides DESC;

-- What is the peak hour each month by user type?
WITH PeakHours AS (
    SELECT
        user_type,
		TO_CHAR(ended_at, 'FMMonth') AS month_name,
	    EXTRACT(MONTH FROM ended_at) AS month_num,
        EXTRACT(HOUR FROM started_at) AS hour,
        COUNT(ride_id) AS no_of_rides,
        ROW_NUMBER() 
			OVER(PARTITION BY EXTRACT(MONTH FROM ended_at), user_type 
				ORDER BY COUNT(ride_id) DESC) AS rank
    FROM 
		rides_cleaned
    GROUP BY 
		month_name, 
		month_num, 
		hour, 
		user_type
)
SELECT
	user_type,
	month_name,
    hour,
    no_of_rides
FROM 
	PeakHours
WHERE 
	rank = 1
ORDER BY
	user_type,
	month_num;

-- How many rides are taken each day of week among each user type?
SELECT
    user_type,
    day_of_week,
    COUNT(ride_id) AS no_of_rides
FROM 
	rides_cleaned
GROUP BY
    user_type,
    day_of_week,
	day_number
ORDER BY
    user_type,
	day_number;

-- What day of week is the busiest among each user type?
WITH BusiestDay AS (
	SELECT
		user_type,
		day_of_week,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER() 
			OVER(PARTITION BY user_type 
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type, 
		day_of_week, 
		day_number
)
SELECT
	user_type,
	day_of_week,
	no_of_rides
FROM
	BusiestDay
WHERE
	rank = 1
ORDER BY
	no_of_rides DESC;

-- Weekly trend of rides taken by user type
WITH WeeklyRides AS (
	SELECT
		user_type,
		DATE_TRUNC('week', started_at + INTERVAL '1 day') - INTERVAL '1 day' AS week, -- Week starts from Sunday
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		week
	ORDER BY
		week
)
SELECT
    user_type,
    week :: DATE,
    no_of_rides
FROM 
	WeeklyRides
ORDER BY
    user_type,
	week;

-- What is the percentage week over week growth/decline in number of rides taken by each user type?
WITH WeeklyRides AS (
	SELECT
		user_type,
		DATE_TRUNC('week', started_at + INTERVAL '1 day') - INTERVAL '1 day' AS week, -- Week starts from Sunday
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		week
	ORDER BY
		user_type,
		week
),
Difference AS (
	SELECT
		user_type,
		week,
		no_of_rides,
		no_of_rides - LAG(no_of_rides)
			OVER(PARTITION BY user_type 
				ORDER BY week) AS difference
	FROM
		WeeklyRides
),
Percentage AS (
	SELECT
		user_type,
		week,
		no_of_rides,
		difference,
		difference * 100.0 / LAG(no_of_rides)
			OVER(PARTITION BY user_type
				ORDER BY week) AS percentage
	FROM
		Difference
)
SELECT
    user_type,
    week :: DATE,
    no_of_rides,
	difference,
	ROUND(percentage, 2) AS percentage_growth
FROM 
	Percentage
ORDER BY
    user_type,
	week;

-- What week had the most rides taken by each user type?
WITH WeeklyRides AS (
	SELECT
		user_type,
		DATE_TRUNC('week', started_at + INTERVAL '1 day') - INTERVAL '1 day' AS week,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER()
			OVER(PARTITION BY user_type
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		week
)
SELECT
    user_type,
    week :: DATE,
    no_of_rides
FROM 
	WeeklyRides
WHERE
	rank = 1
ORDER BY
	no_of_rides DESC;

-- What is the monthly trend of rides taken by each user type?
-- And the percentage month over month growth/decline in number of rides taken by each user type?
-- Using ended_at to define month period
With MonthlyRides AS (
	SELECT
		user_type,
		TO_CHAR(ended_at, 'FMMonth') AS month_name,
		EXTRACT(MONTH FROM ended_at) AS month_num,
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type,
		month_name,
		month_num
),
Difference AS (
	SELECT
		user_type,
		month_name,
		month_num,
		no_of_rides,
		no_of_rides - LAG(no_of_rides)
			OVER(PARTITION BY user_type 
				ORDER BY month_num) AS difference
	FROM
		MonthlyRides
),
Percentage AS (
	SELECT
		user_type,
		month_name,
		month_num,
		no_of_rides,
		difference,
		difference * 100.0 / LAG(no_of_rides)
			OVER(PARTITION BY user_type
				ORDER BY month_num) AS percentage
	FROM
		Difference
)
SELECT
	user_type,
	month_name,
	no_of_rides,
	ROUND(percentage, 2) AS percentage_growth
FROM
	Percentage
ORDER BY
	user_type,
	month_num;

-- What month had the most rides taken by user type? 
WITH PeakMonth AS (
	SELECT
		TO_CHAR(ended_at, 'FMMonth') AS month_name,
		user_type,
		COUNT(ride_id) AS no_of_rides,
		ROW_NUMBER() 
			OVER(PARTITION BY user_type 
				ORDER BY COUNT(ride_id) DESC) AS rank
	FROM
		rides_cleaned
	GROUP BY
		month_name, 
		user_type
)
SELECT
	user_type,
	month_name,
	no_of_rides
FROM
	PeakMonth
WHERE
	rank = 1
ORDER BY
	no_of_rides DESC;

-- Categorize months into seasons and track rides taken by user type
-- What is the peak season?
SELECT
	user_type,
	CASE
		WHEN EXTRACT(MONTH FROM ended_at) IN (3, 4, 5) THEN 'Spring'
		WHEN EXTRACT(MONTH FROM ended_at) IN (6, 7, 8) THEN 'Summer'
		WHEN EXTRACT(MONTH FROM ended_at) IN (9, 10, 11) THEN 'Fall'
		ELSE 'Winter'
	END AS season,
	COUNT(ride_id) AS no_of_rides
FROM
	rides_cleaned
GROUP BY
	user_type, 
	season
ORDER BY
	user_type,
	no_of_rides DESC;

-- What is the percentage of seasonal rides to total yearly rides by each user type?
WITH SeasonalRides AS (
	SELECT
		user_type,
		CASE
			WHEN EXTRACT(MONTH FROM ended_at) IN (3, 4, 5) THEN 'Spring'
			WHEN EXTRACT(MONTH FROM ended_at) IN (6, 7, 8) THEN 'Summer'
			WHEN EXTRACT(MONTH FROM ended_at) IN (9, 10, 11) THEN 'Fall'
			ELSE 'Winter'
		END AS season,
		CASE
			WHEN EXTRACT(MONTH FROM ended_at) IN (3, 4, 5) THEN 1
			WHEN EXTRACT(MONTH FROM ended_at) IN (6, 7, 8) THEN 2
			WHEN EXTRACT(MONTH FROM ended_at) IN (9, 10, 11) THEN 3
			ELSE 4
		END AS season_order,
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type, 
		season,
		season_order
)
SELECT
	user_type,
	season,
	no_of_rides,
	SUM(no_of_rides)
			OVER(PARTITION BY user_type) AS total_rides,
	ROUND(no_of_rides * 100.0 / SUM(no_of_rides) OVER(PARTITION BY user_type), 2) AS percentage_of_total_rides
FROM
	SeasonalRides
ORDER BY
	user_type,
	season_order;

-- What is the percentage growth/decline in rides between consecutive seasons for each user type?
WITH SeasonalRides AS (
	SELECT
		user_type,
		CASE
			WHEN EXTRACT(MONTH FROM ended_at) IN (3, 4, 5) THEN 'Spring'
			WHEN EXTRACT(MONTH FROM ended_at) IN (6, 7, 8) THEN 'Summer'
			WHEN EXTRACT(MONTH FROM ended_at) IN (9, 10, 11) THEN 'Fall'
			ELSE 'Winter'
		END AS season,
		CASE
			WHEN EXTRACT(MONTH FROM ended_at) IN (3, 4, 5) THEN 1
			WHEN EXTRACT(MONTH FROM ended_at) IN (6, 7, 8) THEN 2
			WHEN EXTRACT(MONTH FROM ended_at) IN (9, 10, 11) THEN 3
			ELSE 4
		END AS season_order,
		COUNT(ride_id) AS no_of_rides
	FROM
		rides_cleaned
	GROUP BY
		user_type, 
		season,
		season_order
),
Difference AS (
	SELECT
		user_type,
		season,
		season_order,
		no_of_rides,
		no_of_rides - LAG(no_of_rides)
			OVER(PARTITION BY user_type 
				ORDER BY season_order) AS difference
	FROM
		SeasonalRides
),
Percentage AS (
	SELECT
		user_type,
		season,
		season_order,
		no_of_rides,
		difference,
		difference * 100.0 / LAG(no_of_rides)
			OVER(PARTITION BY user_type
				ORDER BY season_order) AS percentage
	FROM
		Difference
)
SELECT
	user_type,
	season,
	no_of_rides,
	ROUND(percentage, 2) AS percentage_growth
FROM
	Percentage
ORDER BY
	user_type,
	season_order;










