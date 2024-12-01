/*
E-Commerce Data Analysis

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Segmentation

*/

-- Initial Exploration of the Data
select *
from orders
where TotalAmount is not null
order by OrderDate;

-- Select key fields for initial analysis
select OrderID, CustomerID, OrderDate, TotalAmount, PaymentMethod
from Orders
where TotalAmount is not null	
order by CustomerID, OrderDate;

-- CUSTOMER LIFETIME VALUE
-- Analyze total spending per customer and their contribution to revenue
select C.CustomerID, C.Name,
        sum(O.TotalAmount) as TotalSpending
from Customers C 
join Orders O on C.CustomerID = O.CustomerID
group by C.CustomerID, C.Name
order by TotalSpending desc;

-- PRODUCT SALES ANALYSIS
-- Identify top-performing products by total revenue
select P.ProductID, P.ProductName,
		sum(OD.Quantity) as TotalUnitsSold,
        sum(OD.Subtotal) as TotalRevenue
from Products P
join OrderDetails OD on P.ProductID = OD.ProductID
group by P.ProductID, P.ProductName
order by TotalRevenue desc;

-- MONTHLY SALES TRENDS
-- Categorize customers based on behavior and spending
select C.CustomerID, C.Name,
	case
		when sum(O.TotalAmount) > 1000 then 'High Value'
        else 'Mid Value'
	end as CustomerValue,
	case
        when COUNT(O.OrderID) > 5 AND sum(O.TotalAmount) <= 1000 then 'Frequent Buyer'
        when COUNT(O.OrderID) <= 5 then 'Occasional Buyer'
        else 'No Orders'
	end as CustomerSegment
from Customers C
join Orders O on C.CustomerID = O.CustomerID
group by C.CustomerID, C.Name
order by C.CustomerID asc;

-- INACTIVE CUSTOMERS
-- Identify customers with no purchases in the last 6 months
select C.CustomerID, C.Name,
		max(O.OrderDate) as LastOrderDate
from Customers C
left join Orders O on C.CustomerID = O.CustomerID
group by C.CustomerID, C.Name
having max(O.OrderDate) < curdate() - interval 6 month or max(O.OrderDate) IS NULL;

-- Using CTE for Product Revenue Contribution
with ProductRevenue as (
	select P.ProductID, P.ProductName,
			sum(OD.Subtotal) as TotalRevenue
	from Products P
    join OrderDetails OD on P.ProductID = OD.ProductID
    group by P.ProductID, P.ProductName
)
select ProductName, TotalRevenue, 
		(TotalRevenue * 100.0 / sum(TotalRevenue) over()) as RevenuePercentage
from ProductRevenue
order by RevenuePercentage desc;

-- Creating a View for Top Customers
create view TopCustomers as
select C.CustomerID, C.Name,
	sum(O.TotalAmount) as TotalSpending
from Customers C 
join Orders O on C.CustomerID = O.CustomerID
group by C.CustomerID, C.Name
order by TotalSpending desc;

-- Creating Temporary Table for Sales Trends
drop temporary table if exists SalesTrends;
create temporary table SalesTrends (
	month TEXT,
    TotalSales real
);

insert into SalesTrends (month, TotalSales)
select date_format(OrderDate, '%Y-%m') as Month,
		sum(TotalAmount) as TotalSales
from Orders
group by Month;

select *
from SalesTrends
order by Month;
