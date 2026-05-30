# Cyclistic Bike-Share Analysis
**Google Data Analytics Capstone Project**

## Project Overview

This project is the capstone case study for the Google Data Analytics Certificate. As a junior data analyst at the fictional bike-share company **Cyclistic**, I was tasked with analyzing 12 months of historical ride data to understand how **annual members** and **casual riders** use the service differently and to identify insights that could inform a marketing strategy to convert casual riders into members.

## Business Problem

*"How do annual members and casual riders use Cyclistic bikes differently?"*

Cyclistic's finance team has determined that annual members are significantly more profitable than casual riders. Rather than targeting brand-new customers, the marketing director believes the better opportunity is converting existing casual riders, people who are already familiar with the product into members. This analysis is the foundation for that strategy.

## Key Findings

- **Members ride more frequently; casual riders ride longer.** Members account for the majority of total rides, but casual riders average nearly twice the ride duration per trip.
- **Usage patterns diverge sharply by day.** Member rides peak on weekdays, consistent with commuting behavior. Casual rides peak on weekends, suggesting leisure use.
- **Summer is peak season for both groups**, but casual ridership is far more seasonal, dropping steeply in fall and winter compared to members.
- **Casual riders favor round trips.** A meaningfully higher share of casual rides start and end at the same station, pointing to recreational or exploratory use.
- **Ride volume is concentrated in afternoon hours (4-6 PM)** for both groups, with a secondary morning peak for members that is absent among casual riders.

## Analysis Approach

The analysis was conducted entirely in **PostgreSQL** and follows the full data analysis lifecycle:

1. **Data Cleaning:** Excluded rides with missing start or end station IDs (likely system errors), rides where the end time preceded the start time (invalid records), and rides under 1 minute (probable accidental unlocks or system glitches). This reduced the dataset to a validated working subset.

2. **Feature Engineering:** Added computed columns for ride length, day of week, and day number.

3. **Exploratory Analysis:** Examined ride volume, ride duration, bike type preference, station popularity, trip type (round vs. one-way), and time-based patterns (hourly, daily, weekly, monthly, and seasonal), all segmented by user type.

4. **Trend Analysis:** Used CTEs and window functions (`LAG`, `SUM OVER`, `ROW_NUMBER`) to calculate week-over-week and month-over-month growth, rolling cumulative volumes, and peak period identification.

## Tools & Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL + pgAdmin | Data cleaning, feature engineering, and analysis |
| SQL (CTEs, Window Functions) | Query structure and analytical logic |
| Tableau | Data visualization and dashboard |

## Dataset

- **Source:** [Divvy Bikes Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html) (made available by Motivate International Inc.)
- **License:** [Data License Agreement](https://divvybikes.com/data-license-agreement)
- **Scope:** 12 months of historical ride records
- **Note:** This is public data. Personally identifiable information is not included; riders cannot be linked across trips.

## Dashboard & Presentation

- 📊 **Tableau Dashboard:** https://public.tableau.com/views/GoogleCapstoneProject_17789827533870/RidesperHourbyUserType?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link

- 📑 **Presentation Slides:** https://docs.google.com/presentation/d/1EcTdmkl9dQJs-GQEAjyk1szMCMnQ-OhU83S_0QemopQ/edit?usp=sharing

## About

This project was completed as part of the **Google Data Analytics Professional Certificate** capstone. It demonstrates end-to-end data analysis skills: problem framing, data cleaning with documented reasoning, SQL-based exploratory analysis, and translating findings into business recommendations.
