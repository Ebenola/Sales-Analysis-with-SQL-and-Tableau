**<h2>SQL Analysis</h2>**
<pre>--Grouping By Productline
select PRODUCTLINE, sum(SALES) Revenue
from dbo.sales_data_sample
group by PRODUCTLINE
order by 2 desc</pre>

![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/5fa44a1f-bbd4-4c5a-af6c-acc0bd9946af)

<pre>--Calculating Total Sales by year

select YEAR_ID as Year, sum(SALES) Revenue
from dbo.sales_data_sample
group by YEAR_ID
order by 2 desc</pre>
![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/540c78c2-b8e6-46d4-b704-ae8ce0ebd098)

<pre>--Calculating best sales month in year 2004
select MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) Frequency, sum(QUANTITYORDERED) Volume 
from dbo.sales_data_sample
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc</pre>

![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/2f9ba21f-1fcf-446c-9b73-7d976e064744)

--The result showed that November is the best month

<pre>--Checking the product that sold most in November 2004
select PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Frequency, sum(QUANTITYORDERED) Volume
from dbo.sales_data_sample
where MONTH_ID = 11 and YEAR_ID = 2004
group by PRODUCTLINE
order by 2 desc</pre>

--The output showed that Classic Cars sold highest in November 2004

![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/4ca9e3a8-58cb-4f27-8250-c2a9df11a24c)

<pre>--Calculating the recency: populate frequency of purchase, recency and purchase value per customer
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
	from rfm_calc c;</pre>
 
 <pre>---Confirming the newly created table is active

select * from #rfm</pre>

<pre>-- checking for distinct rfm_cell_string data

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
from #rfm</pre>

**Distinct RFM Cell Strings:**
The first query retrieves distinct values from the rfm_cell_string column in a temporary table or dataset called #rfm. This ensures that we have unique values for further analysis.

**Customer Segmentation:**
The second query creates a new result set by combining information from the Customer, rfm_recency, rfm_frequency, and rfm_monetary columns.
It introduces a calculated column called rfm_segment using a CASE statement. This column assigns customer segments based on the values in the rfm_cell_string column.

Breaking down the segment assignments:

Lost_Customers: These are customers represented by specific rfm_cell_string values (e.g., 111, 112, etc.). They are considered lost customers.

Promising, Cannot Lose: Customers with rfm_cell_string values (e.g., 133, 134, etc.) who seldom buy but have high frequency and spend.

New Customers: Represented by certain rfm_cell_string values (e.g., 311, 312, etc.), indicating new customers.

At risk: Potential Churners: Customers with rfm_cell_string values (e.g., 221, 222, etc.) who may be at risk of churning.

Active: These are customers with high purchase frequency at a low price point (e.g., 323, 421, etc.).

Loyal: Represented by specific rfm_cell_string values (e.g., 433, 434, etc.), indicating loyal customers.

Output:
The final result set includes columns for Customer, rfm_recency, rfm_frequency, rfm_monetary, and the newly created rfm_segment.

**<h3>Complementary Product Analysis</h3>** 

<pre>select distinct OrderNumber, stuff(          
	(select ',' + PRODUCTCODE                
	FROM dbo.sales_data_sample a
	WHERE ORDERNUMBER in
		(select ORDERNUMBER
		from (select ORDERNUMBER, count(*) rn   
			  from dbo.sales_data_sample
			  where STATUS = 'Shipped'
			  group by ORDERNUMBER) b
		where rn = 2                           
		)
		and a.ORDERNUMBER = c.ORDERNUMBER
		for xml path (''))
		, 1, 1, '')  --stuff end
from dbo.sales_data_sample c
order by 2 desc</pre>

**<h3>Power BI Vizualization</h3>**
![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/0f2c9217-e7b4-4e5d-b787-15ac8e489b5f)

**<h3>Tableau Vizualization</h3>**
<a href = "https://public.tableau.com/views/Sales_Dash1_17105236771060/Sales_Dashboard1?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link">Click to View Tableau Viz</a>
![image](https://github.com/Ebenola/Sales-Analysis-with-SQL-and-Tableau/assets/104829299/6027857f-e9d5-4a27-954a-ee90bd21da76)
