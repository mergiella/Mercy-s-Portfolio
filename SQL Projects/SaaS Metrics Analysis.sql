/*
SaaS Metrics Analysis: User Engagement, Retention, and Revenue Optimization

Skills used: Advanced Joins, CTEs, Temp Tables, Window Functions, Cohort Analysis, Churn Prediction, Revenue Segmentation, Lifetime Value, Time Series Forecasting

*/

-- Initial Exploration of the Data
select *
from UserActivity
where ActivityStatus is not null
order by ActivityDate;

-- USER ENGAGEMENT METRICS
-- Calculate the average session duration, total sessions, and the number of active users per day
select UserID,
		count(SessionID) as TotalSessions,
        avg(SessionDuration) as AvgSessionDuration,
        sum(case when ActivityStatus = 'Active' then 1 else 0 end) as ActiveSessions, ActivityDate
from UserActivity
where ActivityStatus = 'Active'
group by UserID, ActivityDate
order by ActivityDate;

-- USER RETENTION ANALYSIS
-- Calculate user retention rates by cohort (e.g., users who signed up in the first quarter of 2023)
with UserCohorts as (
	select UserID,
		min(SignupDate) as SignupDate,
        date_format(min(SignupDate), '%Y-%m') as CohortMonth
	from Users
    group by UserID
)
select CohortMonth,
	count(UserCohorts.UserID) as NewUsers,
    count(case when date_format(LastLoginDate, '%Y-%m') = CohortMonth then 1 end) as RetainedUsers,
    (count(case when date_format(LastLoginDate, '%Y-%m') = CohortMonth then 1 end) * 100.0) / nullif(count(UserCohorts.UserID), 0) as RetentionRate
from UserCohorts
join Users U on UserCohorts.UserID = U.UserID
group by CohortMonth
order by CohortMonth;


-- MONTHLY ACTIVE USERS (MAU) AND DAILY ACTIVE USERS 
-- Calculate MAU and DAU over time to observe useer engagement
with ActiveUserMetrics as (
	select date_format(ActivityDate, '%Y-%m') as Month,
		count(distinct UserID) as MAU,
        count(distinct case when date(ActivityDate) = current_date then UserID end) as DAU
from UserActivity
where ActivityStatus = 'Active'
group by Month
)
select Month, MAU, DAU,
		(DAU * 100.0 / NULLIF(MAU, 0)) as DAU_to_MAU_Ratio
from ActiveUserMetrics
order by Month;

-- Churn Prediction
-- Predict churn by analyzing the length of user activity and last activity date
with ChurnedUsers as (
	select UserID,
		max(ActivityDate) as LastActivityDate,
        datediff(current_date, max(ActivityDate)) as DaysSinceLastActivity
	from UserActivity
    where ActivityStatus = 'Active'
    group by UserID
)
select UserID, DaysSinceLastActivity,
	case when DaysSinceLastActivity > 30 then 'Churned' else 'Active' end as ChurnStatus
from ChurnedUsers
where DaysSinceLastActivity > 30
order by DaysSinceLastActivity desc;

-- CUSTOMER LIFETIME VALUE (CLV) ESTIMATION FOR SAAS USERS
-- Estimate the lifetime value based on monthly subscription fees and average user lifetime
with UserSubscription as (
	select UserID,
			avg(MonthlyFee) as AvgMonthlyFee,
            datediff(max(SubscriptionEndDate), min(SubscriptionStartDate)) as UserLifetime
	from UserSubscriptions
    group by UserID
)
select UserID, AvgMonthlyFee, UserLifetime,
		(AvgMonthlyFee * UserLifetime) as CLV
from UserSubscription
order by CLV desc;

-- REVENUE SEGMENTATION BY SUBSCRIPTION PLAN
-- Break down revenue by subscription plan (e.g., Basic,Pro,Enterprise)
select U.SubscriptionPlan,
		sum(US.MonthlyFee) as TotalRevenue,
        count(US.UserID) as TotalUses,
        (sum(US.MonthlyFee) * 100.0 / (select sum(MonthlyFee) from UserSubscriptions)) as PlanRevenueShare
from Users as U
join UserSubscriptions as US on U.UserID = US.UserID
group by U.SubscriptionPlan
order by TotalRevenue desc;

-- USER ACQUISITION COST (UAC) and PAYCHECK PERIOD
-- Calculate the cost of acquiring a new user and the time it takes to recover that cost
with MarketingSpend as (
select CampaignID,
		sum(SpendAmount) as TotalSpend
from MarketingCampaigns
group by CampaignID
),
NewUsers as (
	select CampaignID,
			count(UserID) as NewUsersAcquired
	from Users
    where SignupDate between '2023-01-01' and '2023-03-31'
    group by CampaignID
)
select M.CampaignID, M.TotalSpend, M.NewUsersAcquired, 
		(M.TotalSpend / nullif(N.NewUsersAcquired, 0)) as UAC,
        (M.TotalSpend / nullif(N.NewUsersAcquired, 0)) / (avg(MonthlyFee) * 12) as PaybackPeriod
from MarketingSpend M
join NewUsers N on M.CampaignID = N.CampaignID
join UserSubscriptions U on N.UserID = U.UserID
group by M.CampaignID
order by PaybackPeriod;
	
-- MONTHLY REVENUE FORCASTING USING TIME-SERIES ANALYSIS
-- Forecast the next 3 months of revenue using a simple moving average
with MonthlyRevenue as (
	select date_format(SubscriptionStartDate, '%Y-%m') as month,
			sum(MonthlyFee) as Revenue
	from UserSubscriptions
    group by Month
)
select Month,Revenue,
		avg(Revenue) over (order by Month rows between 2 preceding and current row) as MovingAvgRevenue
from MonthlyRevenue
order by Month;

-- Creating view for user engagement insights
create view UserEngagementInsights as
select 
	date_format(ActivityDate, '%Y-%m') as Month,
    count(distinct UserID) as MonthlyActiveUsers,
    count(distinct case when date(ActivityDate) = current_date then UserID end) as DailyActiveUsers
from UserActivty
where ActivityStatus = 'Active'
group by Month;

-- Query the UserEngagementInsights view for visualization
select *
from UserEngagementInsights
order by Month;

-- Temporary Table for User Retention Insights
drop temporary table if exists UserRetention;
-- Create temporary table
create temporary table UserRetention (
	CohortMonth varchar(7),
    NewUsers int,
    RetainedUsers int,
    RetentionRate decimal(5,2)
);

-- Insert data into the temporary table
insert into UserRetention (CohortMonth, NewUsers, RetainedUsers, RetentionRate)
select
	date_format(CohortMonth, '%Y-%m') as CohortMonth, 
    count(U.UserID) as NewUsers,
    count(CASE WHEN date_format(LastLoginDate, '%Y-%m') = date_format(CohortMonth, '%Y-%m') then 1 end) as RetainedUsers,
    (count(CASE WHEN date_format(LastLoginDate, '%Y-%m') = date_format(CohortMonth, '%Y-%m') then 1 end) * 100.0) / nullif(count(U.UserID), 0) as RetentionRate
from UserCohorts
join Users U on UserCohorts.UserID = U.UserID
join Users U on UserCohorts.UserID = U.UserID
group by date_format(CohortMonth, '%Y-%m');

-- Query the temporary table
select *
from UserRetention
order by CohortMonth;








        


        
        
