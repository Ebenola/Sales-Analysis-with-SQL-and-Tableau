--Recency Frequency Monetary (RFM) Analysis
---An indexing technique that uses past purchase behavior to segment customers

---This is based on three metrics: recency (how recent did they make purchase), frequency of purchase, and purchase value

---Inspecting the dataset
select * from dbo.sales_data_sample

---checking unique values of the dataset

select distinct status from dbo.sales_data_sample
select distinct year_id from dbo.sales_data_sample
select distinct PRODUCTLINE from dbo.sales_data_sample
select distinct COUNTRY from dbo.sales_data_sample
select distinct DEALSIZE from dbo.sales_data_sample
select distinct TERRITORY from dbo.sales_data_sample

--Analysis

--Group By Productline
select PRODUCTLINE, sum(SALES) Revenue
from dbo.sales_data_sample
group by PRODUCTLINE
order by 2 desc 

--Calculate sales by year

select YEAR_ID as Year, sum(SALES) Revenue
from dbo.sales_data_sample
group by YEAR_ID
order by 2 desc
--The company raked in the highest revenue in 2004, followed by 2003 and then 2005


--Check revenue generation by size of deal

select DEALSIZE, sum(SALES) Revenue
from dbo.sales_data_sample
group by DEALSIZE
order by 2 desc
--Medium sized deals generated the highest revenue, followed by small deal and then large deals

--Calculating best sales month in year 2004
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency, sum(QUANTITYORDERED) Volume 
from dbo.sales_data_sample
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc
--The result showed that November is the best month

--Check the product that sold most in November 2004
select PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Frequency, sum(QUANTITYORDERED) Volume
from dbo.sales_data_sample
where MONTH_ID = 11 and YEAR_ID = 2004
group by PRODUCTLINE
order by 2 desc
--The output showed that Classic Cars sold highest in November 2004


--Calculating the recency: populate frequency of purchase, recency and purchase value per customer

--# is for local while ## is for global
--create the rfm into a table

DROP TABLE IF EXISTS #rfm
; with rfm as
(

	Select CUSTOMERNAME Customer,
		   sum(SALES) MonetaryValue, 
		   AVG(SALES) AvgMonetaryValue, 
		   COUNT(ORDERNUMBER) Frequency, 
		   MAX(ORDERDATE) LastOrderDate,
		   (select MAX(ORDERDATE) from [dbo].[sales_data_sample] ) MaxOrderDate,
		   DATEDIFF(DD, MAX(ORDERDATE), (select MAX(ORDERDATE) from [dbo].[sales_data_sample] )) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		   NTILE(4) OVER (order by Recency desc) rfm_recency,
		   NTILE(4) OVER (order by Frequency) rfm_frequency,
		   NTILE(4) OVER (order by AvgMonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
	from rfm_calc c;

---Confirm the newly created table is active

select * from #rfm

--Further analysis

---Note below RFM values description.

--Score Value	Description
-- 1			Lost
-- 2			Customer at Risk
-- 3			Cannot be lost
-- 4			Promising Customer
-- 5			Potential Customer

-- checking for distinct rfm_cell_string data

select distinct rfm_cell_string from #rfm

select Customer, rfm_recency, rfm_frequency, rfm_monetary,
	case
		when rfm_cell_string in (111, 112, 113, 123, 131, 132, 114, 121, 122, 212, 214) then 'Lost_Customers' --these are lost customers
		when rfm_cell_string in (133, 134, 142, 133, 143, 344) then 'Promising, Cannot Lose' --customers who seldom buy, however with high frequency & spend
		when rfm_cell_string in (311, 312, 314, 321, 331, 332, 333, 341, 342, 343) then 'New Customers'
		when rfm_cell_string in (221, 222, 223, 224, 231, 233, 234, 241, 242, 244, 322) then 'At risk: Potential Churners'
		when rfm_cell_string in (323, 421, 422, 414, 424, 432) then 'Active' --customers with high purchase frequency at low price point
		when rfm_cell_string in (433, 434, 441, 442, 443, 444) then 'Loyal'
		end rfm_segment
from #rfm

--Complementary Product Analysis: 2 products that are often sold together
select distinct OrderNumber, stuff(          --stuff is to remove the comma delimiter from starting the dataset
	(select ',' + PRODUCTCODE                -- ',' introduced a comma delimiter
	FROM dbo.sales_data_sample a
	WHERE ORDERNUMBER in
		(select ORDERNUMBER
		from (select ORDERNUMBER, count(*) rn   --rn is the row number
			  from dbo.sales_data_sample
			  where STATUS = 'Shipped'
			  group by ORDERNUMBER) b
		where rn = 2                           -- this selected 2 complimentary products. This can be tweaked to any number
		)
		and a.ORDERNUMBER = c.ORDERNUMBER
		for xml path (''))
		, 1, 1, '')  --stuff end
from dbo.sales_data_sample c
order by 2 desc
