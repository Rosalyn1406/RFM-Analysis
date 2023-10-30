-- Inspecting Data
select * from [dbo].[sales_data_sample]

-- Checking unique values
select distinct status from [dbo].[sales_data_sample] -- plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] -- plot
select distinct COUNTRY from [dbo].[sales_data_sample] --plot
select distinct DEALSIZE from [dbo].[sales_data_sample] --plot
select distinct TERRITORY from [dbo].[sales_data_sample] --plot

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2003

-- Analysis

-- Grouping sales by productline
select PRODUCTLINE, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select DEALSIZE, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

-- What was the best month for sales in a specific year? How much was earned that much?
select MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc

-- Best month: Novemeber
select MONTH_ID, PRODUCTLINE, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID= 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc

/*select 
	CUSTOMERNAME,
	sum(SALES) as MonetaryValue,
	avg(SALES) as AvgMonetaryValue,
	count(ORDERNUMBER) as Frequency,
	max(ORDERDATE) as last_order_date,
	(select max(ORDERDATE) from [dbo].[sales_data_sample]) as max_order_date, -- maximum order date in the dataset
	datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) as Recency -- difference in days
from [dbo].[sales_data_sample]
group by CUSTOMERNAME
*/

/*
 recency: last order date
 frequency: count of total orders
 monetary value: total spend
*/

-- Who is our best customer (RFM analysis)
drop table if exists #rfm
;with rfm as 
(
select 
	CUSTOMERNAME,
	sum(SALES) as MonetaryValue,
	avg(SALES) as AvgMonetaryValue,
	count(ORDERNUMBER) as Frequency,
	max(ORDERDATE) as last_order_date,
	(select max(ORDERDATE) from [dbo].[sales_data_sample]) as max_order_date, -- maximum order date in the dataset
	datediff(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) as Recency -- difference in days
from [dbo].[sales_data_sample]
group by CUSTOMERNAME
),
rfm_calc as 
(

	select r.*,
		ntile(4) over (order by Recency desc) as rfm_recency,
		ntile(4) over (order by Frequency) as rfm_frequency,
		ntile(4) over (order by MonetaryValue) as rfm_monetary
	from rfm as r
)
select
	c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
	cast (rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc as c

select CUSTOMERNAME,rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

-- What products are most often sold together?
-- select * from sales_data_sample where ORDERNUMBER = 10411

select distinct ORDERNUMBER, stuff(
	(select ',' + PRODUCTCODE
	from sales_data_sample as p 
	where ORDERNUMBER in 
		(
		select ORDERNUMBER
		from (
			select ORDERNUMBER, count(*) as rn
			from sales_data_sample
			where STATUS = 'Shipped'
			group by ORDERNUMBER
		)m 
		where rn = 3 
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path(''))
		, 1,1,'') as ProductCodes
from sales_data_sample as s
order by 2 desc

