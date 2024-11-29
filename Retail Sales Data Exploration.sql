/*
Retail Sales Data Analysis

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Initial Exploration of the Data
select *
from salesdata
where Region is not null
order by 3,4;

-- Select the key fields we will start analyzing
select Store, 
		Date, 
        Total_Sales, 
        Total_Units_Sold, 
        Total_Customers, 
        Region
from salesdata
where Region is not null
order by 1,2;

-- Sales Performance by Store
-- Analyze the total sales generated per store
select Store, Date, sum(Total_Sales) as TotalSales, avg(Total_Sales) as AvgSalesPerDay
from salesdata
where Region is not null 
group by Store, Date
order by Store, Date;

-- Sales Contribution by Product Category
-- Calculate the percentage contribution of each category to total sales
select category, sum(Total_Sales) as TotalSales,
		(sum(Total_Sales) * 100.0 / sum(sum(Total_Sales)) over()) as PercentContribution
from salesdata
group by category
order by PercentContribution desc;


-- Top Scores with the Highest Sales
select Store, max(Total_Sales) as HighestSales
from salesdata
group by Store
order by HighestSales desc;

-- Average Sales per Customer
-- Show the average sales value for each customer across all stores
select store, avg(Total_Sales / nullif(Total_Customers, 0)) as AvgSalesCustomer
from salesdata
group by Store
order by AvgSalesCustomer desc;

-- Regional Analysis
-- Compare regions based on total sales and number of customers
select Region, sum(Total_Sales) as TotalSales, sum(Total_Customers) as TotalCustomers
from salesdata
group by Region
order by TotalSales desc;

-- GLOBAL ANALYSIS

-- Analyze overall sales trends and total customers globally
select sum(Total_Sales) as GlobalSales, sum(Total_Customers) as GlobalCustomers
from salesdata
where Region is not null;

-- SALES TRENDS BY DATE

-- Calculate the rolling sales figures for each store to observe trends
select Store, Date, Total_Sales,
		sum(Total_Sales) over (partition by Store order by date) as RollingSales
from salesdata
where Region is not null
order by Store, Date;

-- Using CTE for Rolling Sales Calculation

with StoreSalesTrend (Store, Date, Total_Sales, RollingSales)
as
(
	select Store, Date, Total_Sales,
			sum(Total_Sales) over (partition by Store order by Date) as RollingSales
	from salesdata
    where Region is not null
)
select *, (RollingSales / nullif(sum(Total_Sales) over (partition by Store), 0)) * 100 as PercentofStoreSales
from salesdata
order by Store, Date;

-- Using Temp Table for Sales and Customer Analysis

drop table if exists #StorePerformance
create table #StorePerformance
(
	Store nvarchar(255),
    Date datetime,
    Total_Sales numeric,
    Total_Customers numeric,
    RollingSales numeric
)

insert into #StorePerformance
select Store, Date, Total_Sales, Total_Customers,
	sum(Total_Sales) over (partition by Store order by Date) as RollingSales
from salesdata

select *, (RollingSales / nullif(sum(Total_Sales) over (partition by Store), 0)) * 100 as PercentofStoreSales
from #StorePerformance;

-- Creating View to Store Results for Visualizations

create view StoreSalesPerformance as
select Store, Date, Total_Sales, Total_Customers,
		sum(Total_Sales) over (partition by Store order by Date) as RollingSales
from salesdata
where Region is not null;
