create database Apple_Sales_Report

use Apple_Sales_Report

create table category 
(
    catg_id varchar(10) primary key,
    catg_name varchar(100) not null unique
)

BULK INSERT category 
FROM 'C:\Data\category.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)

select * from category

create table products 
(
    prod_ID varchar(10) primary key,
    prod_Name varchar(200) not null,
    catg_ID varchar(10) not null,
    launch_date date not null,
    price decimal(10, 2) not null,
    constraint fk_products_category 
    foreign key (Catg_ID) references category(catg_id)
)

BULK INSERT products
FROM 'C:\Data\products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)

select * from products

create table stores 
(
    store_ID varchar(10) primary key,
    store_name varchar(200) not null,
    city varchar(100) not null,
    country varchar(100) not null
)

BULK INSERT stores
FROM 'C:\Data\stores.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)

select * from stores

create table sales (
    sale_id varchar(20) primary key,
    sale_date date not null,
    store_id varchar(10) not null,
    prod_id varchar(10) not null,
    quant int not null check (quant > 0),
    constraint fk_sales_store foreign key (store_id) references stores(store_ID),
    constraint fk_sales_product foreign key (prod_id) references products(prod_ID)
)

BULK INSERT sales
FROM 'C:\Data\sales.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)

select * from sales

create table warranty (
    claim_id varchar(20) primary key,
    claim_date date not null,
    sale_id varchar(20) not null,
    repair_status varchar(20) not null,
    constraint fk_warranty_sale foreign key (sale_id) references sales(sale_id),
    constraint chk_repair_status 
    check (repair_status IN ('Completed', 'Pending', 'In Progress', 'Rejected'))
)

BULK INSERT warranty
FROM 'C:\Data\warranty.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)


select * from category
select * from products
select * from stores
select * from sales
select * from warranty


--Foundational Analysirs
--1.All products with their category names.
select 
    p.prod_ID, 
    c.catg_id,
    c.catg_name 
from products p
    inner join category c on p.catg_ID = c.catg_id

--2.Product with the highest price.
select  top 1 
        prod_ID,
        prod_Name,
        catg_ID,
        price
from products 
    order by price desc
--or
select MAX(price) as Highest_Price from products
--or
select 
        prod_ID,
        prod_Name,
        catg_ID,
        price 
from products 
    where price >= (select MAX(price) from products)

--3.Number of products in each category.
select 
    catg_ID, 
    COUNT(*) as Total_Products 
from products 
    group by catg_ID
--or
select 
    category.catg_id, 
    category.catg_name,
    COUNT(products.prod_ID) as No_Of_Products 
from products 
    inner join category on
    products.catg_ID = category.catg_id 
group by category.catg_id, 
         category.catg_name
order by No_Of_Products

--4.Average price of all products.
select AVG(price) as Avg_Price from products

--5.Unique countries where stores are located.
select distinct(country) as Countries from stores 

--6.Warranty claims with 'Pending' status.
select * from warranty where repair_status = 'Pending'

--7.Country with maximum sales
select 
        Top 5 st.country, 
        (s.quant*p.price) as Total_Sale 
from stores st
    join sales s on st.store_ID = s.store_id
    join products p on p.prod_ID = s.prod_id
    order by Total_Sale Desc

--8.Countries with high quantity orders
select 
        Top 5 st.country,
        sum(quant) as Total_quant 
from stores st
    join sales s on st.store_ID = s.store_id
    group by st.country
    order by Total_quant Desc

--Intermediate Analysis 
--7.All products along with their category names and prices 
select 
    products.prod_ID, 
    products.prod_Name, 
    products.catg_ID, 
    category.catg_name
from products 
    inner join category on products.catg_ID = category.catg_id
     
--8.Total number of warranty claims per repair status.
select 
    repair_status,
    COUNT(repair_status) as No_of_Warranty
from warranty 
    group by repair_status

--9.Products that have never been sold 
select
    prod_ID
from products
    where prod_ID not in (select distinct(prod_id) from sales)
union all
select 'Products not available' where not exists 
(
select
        prod_ID
from products
    where prod_ID not in (select distinct(prod_id) from sales)
) 
select * from warranty

--10.Total number of warranty claims per month in 2024
select 
        DATEPART(MONTH, claim_date) as Month_No,
        DATENAME(month,claim_date) as Month,
        COUNT(*) as Total_Claims
from warranty
    where claim_date between '2024-01-01' and '2024-12-31'
    group by DATEPART(MONTH, claim_date),DATENAME(month,claim_date)
    order by Month_No

--11.Top 5 most expensive products with their category names
select top 5
    p.prod_ID,
    p.prod_Name,
    p.catg_ID,
    c.catg_name,
    p.price
from products p
    inner join category c on p.catg_ID = c.catg_id
    order by p.price desc

--12.All cities that have more than 2 stores.
select 
    count(store_ID) as Total_Stores, 
    city 
from stores
    group by city
    having count(store_ID) > 2 

--13.Average product price for each category.
select 
    catg_ID,
    cast(AVG(price) as decimal(6,2)) as Avg_Price 
from products
    group by catg_ID

--14.Warranty claims made in the last 30 days from October 20, 2024.
select 
    claim_id, 
    claim_date 
from warranty 
    where claim_date between '2024-09-20' and '2024-10-20'
--or
select 
    claim_id, 
    claim_date 
from warranty
    where claim_date >= DATEADD(day, -30, '2024-10-20') and claim_date <= '2024-10-20'

--15.Sales data with product name, category name, and store name.
select 
    s.*, 
    p.prod_Name, 
    c.catg_name, 
    st.store_name
from sales s
    join products p on p.prod_ID = s.prod_id
    join category c on c.catg_id = p.catg_ID
    join stores st  on st.store_ID = s.store_id

--16.All products with prices between $500 and $1500.
select 
    s.prod_id, 
    s.quant, 
    p.price 
from sales s
    join products p on p.prod_ID = s.prod_id
    where price between 500 and 1500
    order by price

--17.Rank products by price within each category 
select 
        prod_id,
        prod_Name,
        catg_ID, price,
        DENSE_RANK() over(partition by catg_ID order by price desc) as Prod_Rank
from products 

--18.Running total of warranty claims by claim date
select 
        claim_date,
        COUNT(claim_id) over(partition by claim_date) as Claim_Count
from warranty

--19.Price difference between each product and 
--the most expensive product in its category.
select 
    prod_ID,
    prod_Name,
    catg_ID,
    price,
    MAX(price) over(partition by catg_ID) - price as Price_Diff
from products

--20.Calculate the month-over-month growth rate of warranty claims
select 
        DATEPART(month, claim_date) as Month_No,
        DATENAME(month, claim_date) as Month,
        COUNT(claim_id) over(partition by DATENAME(month, claim_date)
        order by DATENAME(month, claim_date)
        rows between unbounded preceding
        and current row) as Growth_Rate
from warranty
    group by DATEPART(month, claim_date),DATENAME(month, claim_date),
             claim_id
    order by Month_No;

--21.Top 3 most expensive products in each category
with exp_prod as 
(
select 
        prod_ID, 
        prod_Name, 
        catg_ID, 
        price,
        ROW_NUMBER() over(partition by catg_ID order by price) as Expensive_Products
from products
)
select 
        prod_ID, 
        prod_Name, 
        catg_ID, 
        Expensive_Products 
from exp_prod 
    where Expensive_Products<= 3

--22.Moving average of product prices (3-product window) within each category.
select 
        prod_ID, 
        prod_Name,
        catg_ID,
        AVG(price) as Avg_Price,
        AVG(price) over(partition by catg_ID order by price 
        rows between 2 preceding and current row) as Moving_Avg
from products
    group by prod_ID, 
             prod_Name,
             catg_ID,
             price

--23.First and last product launched in each category 
select 
        catg_ID,
        MAX(launch_date) as Last_launched_product,
        MIN(launch_date) as First_launched_product
from products
    group by catg_ID

--or 
select
        catg_ID,
        prod_ID,
        LEAD(launch_date) 
        over(partition by catg_ID order by launch_date) as Last_launched_product,
        LAG(launch_date) 
        over(partition by catg_ID order by launch_date) as First_launched_product
from products

--24.Running total of quantities sold by date.
select 
        sale_date,
        quant,
        SUM(quant) over(order by sale_date) as Total_quant_by_date
from sales;

--25.Categories where the average product price is above the overall average price.
with Avg_Price as 
(
select AVG(price) as Avg_Prod_Price from products
),
Catg_Avg_Price as 
(
select catg_ID, AVG(price) as Avg_Catg_Price from products group by catg_ID
)
select 
        c.catg_id,
        c.catg_name,
        Avg_Catg_Price 
from Catg_Avg_Price ca 
    join category c on c.catg_id = ca.catg_ID 
    join Avg_Price ap on ca.Avg_Catg_Price > ap.Avg_Prod_Price;

--25.Total claims per repair status,and statuses above average claim count.
with total_claims as 
(
select 
        repair_status,
        COUNT(*) as Claim_Count 
from warranty 
    group by repair_status
),
avg_claim as 
(
select AVG(Claim_Count) as Avg_Count from total_claims
)
select 
        tc.repair_status,
        Claim_Count,
        Avg_Count 
from total_claims tc 
    join warranty w on w.repair_status = tc.repair_status
    join avg_claim ac on tc.Claim_Count > Avg_Count 
    group by tc.repair_status,Claim_Count, Avg_Count;

--26.Most expensive product in each category and compare it to overall average.
with Most_exp as 
(
select 
        catg_ID,
        MAX(price) as Expensive_Product 
from products 
    group by catg_ID
),
Overall_Avg as 
(
select AVG(price) as Average_Price from products
)
select 
        p.catg_ID,
        me.Expensive_Product,
        oa.Average_Price 
from Most_exp me
    join products p on p.catg_ID = me.catg_ID and p.price = me.Expensive_Product
    cross join Overall_Avg oa;

--27.Percentage contribution of each category to total product inventory.
select 
        c.catg_id,
        c.catg_name, 
        COUNT(prod_id) as Product_count,
        count(p.prod_id) * 100.0 / SUM(count(p.prod_id)) 
        over() as Product_contribution
from category c
    left join products p on c.catg_id = p.catg_ID
    group by c.catg_id,c.catg_name;

--28.Find the month with the highest number of warranty claims and 
--show the percentage increase from previous month.
with MonthlyClaims as 
(
select
        Month(claim_date) as Month,
        DATENAME(MONTH,claim_date) Month_Name,
        COUNT(*) AS ClaimCount
from Warranty
    group by Month(claim_date), DATENAME(MONTH,claim_date)
),
ClaimsWithPrevious as 
(
select
        Month,
        Month_Name,
        ClaimCount,
        LAG(ClaimCount) over (order by Month) as PreviousMonthCount
from MonthlyClaims
),
ClaimsWithIncrease AS 
(
select
        Month,
        Month_Name,
        ClaimCount,
        PreviousMonthCount,
    case 
        when PreviousMonthCount IS NULL OR PreviousMonthCount = 0 then NULL
        else (
        (ClaimCount - PreviousMonthCount) * 100.0) / PreviousMonthCount
    end as PercentIncrease
from ClaimsWithPrevious
)
select TOP 1 * from ClaimsWithIncrease order by ClaimCount DESC;

--or without any CTEs

select top 1 
        MONTH(claim_date) as Month,
        DATENAME(month,claim_date) as Month_Name,
        COUNT(*) as Total_Claim,
        LAG(COUNT(*)) over(order by month(claim_date)) as PreviousMonthClaim,
        CONCAT(
        (
        COUNT(*) - LAG(COUNT(*)) over(order by month(claim_date))) * 100.0 /
        LAG(COUNT(*)) over(order by month(claim_date)
        ) , ' %' ) as PercentIncrease
from warranty 
    group by MONTH(claim_date),DATENAME(month,claim_date)
    order by Total_Claim desc;

--29.Hierarchy showing product count, average price, 
--and price range for each category.
with catgstatus as
(
select 
        c.catg_id, 
        c.catg_name,
        count(*) as Prod_Count, 
        avg(price) as Avg_Price,
        max(price) as High_Price,
        min(price) as Low_Price,
        (MAX(price) - MIN(price)) as Range
from category c join products p on 
c.catg_id = p.catg_ID
    group by c.catg_id, c.catg_name
)
select 
        catg_id, 
        catg_id,
        Prod_Count,
        Avg_Price,
        High_Price,
        Low_Price,
        Range
from catgstatus
    order by Prod_Count Desc

--or
select 
        c.catg_id, 
        c.catg_name,
        count(*) as Prod_Count, 
        avg(price) as Avg_Price,
        max(price) as High_Price,
        min(price) as Low_Price,
        (MAX(price) - MIN(price)) as Range
from category c join products p on 
c.catg_id = p.catg_ID
    group by c.catg_id, c.catg_name
    order by Prod_Count Desc
-- or
select 
        catg_ID,
        count(*) as Prod_Count,
        max(price) as max_price,
        MIN(price) as min_price,
        (max(price) - min(price)) as range
from products 
    group by catg_ID 
    order by Prod_Count desc;

--30.Top 5 selling products and their average price.
with top_prod as
(
select top 5 
        prod_id, 
        COUNT(*) as Total_Orders 
from sales
    group by prod_id
    order by Total_Orders desc
)
select 
        p.prod_ID,
        p.prod_Name,
        Avg(price) as Avg_Price,
        t.Total_Orders 
from products p
    join top_prod t on p.prod_ID = t.prod_id
    group by p.prod_ID, p.prod_Name, t.Total_Orders

--31.Total inventory value (quantity assumed as 1) for each category.
select 
        p.catg_ID,
        sum(quant) as Total_inventory
from products p 
    join sales s on s.prod_id = p.prod_ID
    group by catg_ID
    order by Total_inventory desc

--Total products in all categories
select p.catg_ID,
       COUNT(*) as Total_inventory
from products p
    group by p.catg_ID
    order by Total_inventory desc;

--Financial and Business Analysis
--32.Year-Over-Year growth rate of product launches.
with YearlyGrowth as 
(
select 
        year(launch_date) as Year, 
        COUNT(*) as Total_Launches 
from products
    group by year(launch_date)
),
Growth as 
(
select 
        Year,
        Total_Launches, 
        LAG(Total_Launches) over(order by Year) as Prev_Year_growth
from YearlyGrowth
    group by Year, Total_Launches
)
select 
        Year,
        Total_Launches,
        case
            when Prev_Year_growth is null then null
            else ((Total_Launches - Prev_Year_growth)* 100.0 / Prev_Year_growth) 
        end as Growth_Perc
from Growth

--33.Price variance and standard deviation for each category.
select
        catg_ID,
        VAR(price) as Variance_Price,
        STDEV(price) as Std_dev_price
from products
    group by catg_ID;

--34.price tier classification (Budget: <$500, Mid-range: $500-$1200, Premium: >$1200) 
--and count products in each tier.
with products_count as 
(
select 
        price,
        COUNT(*) as Total_Products 
from products 
    group by price
),
tier_range as 
(
select 
        Total_Products,
        case
            when price <500 then 'Budget'
            when price between 500 and 1200 then 'Mid_range'
            when price > 1200 then 'Premium'
            else null
        end as Price_Tier
from products_count
)
select 
        Sum(Total_Products) as Total,Price_Tier 
from tier_range 
    group by Price_Tier;

--35.weighted average price of products, 
--weighted by the number of warranty claims (proxy for sales volume).
with avgprice as 
(
select 
        1 as dummy, 
        Avg(price) as Avg_price 
from products
),
warrantyclaims as 
(
select 
        1 as dummy,
        COUNT(*) as Total_Warranty 
from warranty
)
select 
        a.Avg_price,
        w.Total_Warranty,
        (SUM(a.Avg_price * w.Total_warranty) / Total_Warranty) as Weighted_avg_price
from warrantyclaims w
    join avgprice a on a.dummy = w.dummy
    group by a.Avg_price,w.Total_Warranty

--36.Products with prices in the top 10 percentile using NTILE() function.
select 
        prod_ID,
        prod_Name,
        price,
        Percentile 
from 
(
select 
    prod_ID,
    prod_Name,
    price,
    NTILE(10) over(order by price desc)Percentile 
from products
)
ranked_products where Percentile = 1;

--37.Cumulative revenue potential for products launched each quarter
with quarter_revenue as
(
select 
        s.prod_id as Products,
        DATEPART(year,launch_date) as launch_year,
        DATENAME(quarter,launch_date) as launch_quarter,
        SUM(p.price * s.quant) as Revenue
from products p join sales s on
    p.prod_ID = s.prod_id
    group by s.prod_id,DATEPART(year,launch_date),DATENAME(quarter,launch_date)
)
select
        products,
        launch_year,
        launch_quarter,
        sum(Revenue) 
        over(order by launch_year,launch_quarter 
        rows between unbounded preceding and current row) as Cummukaltive_Revenue,
        CUME_DIST() over(order by Revenue desc) as Cume_rank
from quarter_revenue
    order by launch_year

--38.Price elasticity indicator: products with high claim counts 
--relative to their price point.
select 
        s.store_id,
        s.prod_id,
        p.price,
        COUNT(w.claim_id) as Claim_count,
        COUNT(w.claim_id) * 1.0 / p.price as Elasticity_Indicator,
        COUNT(w.claim_id) * 1.0 / SUM(p.price * s.quant) as Claims_per_revenue
from warranty w 
    join sales s on w.sale_id = s.sale_id
    join products p on p.prod_ID = s.prod_id
    group by s.store_id,s.prod_id,p.price
    order by Elasticity_Indicator desc;

--39.financial summary report showing min, max, avg, median price by category

with catg_count as 
(
select 
        catg_ID,
        price,
        ROW_NUMBER() over(partition by catg_ID order by price) as rn,
        COUNT(*) over(partition by catg_ID) as Total
from products
),
median as 
(
select 
        catg_ID,
        AVG(price*1.0) as Median
from catg_count
    where rn in (CEILING((1+Total)/2.0),floor((1+Total)/2.0))
    group by catg_ID
)
select 
        m.catg_ID,
        Min(price) as Min_price,
        Max(price) as Max_price,
        round(AVG(price),2) as Avg_price,
        round(AVG(Median),2) as Median_price,
        ROUND(stdev(price),2) as price_dev 
from median m
    join catg_count cc on cc.catg_ID = m.catg_ID
    group by m.catg_ID;

--40.claim resolution rate: percentage of completed vs total claims by month
with completed as 
(
select 
        year(claim_date) as Year,
        month(claim_date) as Month,
        COUNT(repair_status) as completed
from warranty 
    where repair_status = 'Completed'
    group by year(claim_date),month(claim_date)
),
total_claims as 
(
select 
        month(claim_date) as month,
        COUNT(*) as Total_claims
from warranty
    group by month(claim_date)
)
select 
        c.Year,
        c.Month,
        c.completed,
        tc.Total_claims,
        (c.completed * 100.0 / tc.Total_claims) as resolution_rate
from completed c 
    join total_claims tc on c.Month = tc.month
    order by Year,Month;

--41.high-risk products: products with highest ratio of pending/rejected 
--claims to total claims.
with prods as 
(
select 
    p.prod_Name,
    count(w.repair_status) as Total_claims,
    SUM(case when w.repair_status in ('Rejected','Pending') 
    then 1 else 0 end) as rej_pen_claims,
    1.0 * SUM(case when w.repair_status in ('Rejected','Pending') 
    then 1 else 0 end) / count(w.repair_status) as ratio
from warranty w 
    join sales s on s.sale_id = w.sale_id
    join products p on p.prod_ID = s.prod_id
    group by p.prod_Name
    having COUNT(*) >0
)
select 
        prod_Name,
        Total_claims,
        rej_pen_claims,
        ROUND(ratio*100,2) as rej_pen_total,
        RANK() over(order by ratio desc) as rej_pen_ratio 
from prods 
    order by rej_pen_ratio

--42.Average time-to-claim: days between product launch date and first warranty claim

select 
        p.prod_ID,
        p.prod_Name,
        Abs(Avg(DATEDIFF(day,p.launch_date,w.claim_date))) as Days_diff 
from products p
    join sales s on p.prod_ID = s.prod_id
    join warranty w on w.sale_id = s.sale_id
    group by p.prod_ID, p.prod_Name
    order by Days_diff

--43.cohort analysis: analysing the warranty claim patterns
select 
        YEAR(p.launch_date) as Launch_year,
        YEAR(w.claim_date) - YEAR(p.launch_date) as Years_from_launch,
        COUNT(w.claim_id) as Total_claims
from products p
    join sales s on p.prod_ID = s.prod_id
    join warranty w on w.sale_id = s.sale_id
    group by YEAR(p.launch_date),
             YEAR(w.claim_date) - YEAR(p.launch_date)
    order by Launch_year;

--44.product portfolio analysis: product category by price and claim frequency
with prod_claims as 
(
select
        p.prod_ID,
        p.prod_Name,
        p.price,
        COUNT(w.claim_id) as claim_count
from products p
    join sales s
    on p.prod_ID = s.prod_id
    join warranty w 
    on w.sale_id = s.sale_id
    group by
    p.prod_ID,
    p.prod_Name,
    p.price
),
bucketed_prod as 
(
select
        *,
        NTILE(3) over (order by price) as price_tile,
        NTILE(3) over (order by claim_count) as claim_tile
from prod_claims
)
select
        prod_ID,
        prod_Name,
        price,
        claim_count,
        case price_tile
            when 1 then 'Low Price'
            when 2 then 'Medium Price'
            when 3 then 'High Price'
        end as price_category,
        case claim_tile
            when 1 then 'Low Claims'
            when 2 then 'Medium Claims'
            when 3 then 'High Claims'
        end as claim_category
from bucketed_prod
    order by price desc, claim_category asc;

--45. Using Pivot to transform repair stats into columns showing claim counts
select
    p.prod_Name,
    ISNULL([In Progress], 0) as In_Progress_Claims,
    ISNULL([Pending], 0)  as Pending_Claims,
    ISNULL([Rejected], 0) as Rejected_Claims,
    ISNULL([Completed],0) as Completed_Claims
from 
(
select
        s.prod_id,
        w.repair_status,
        w.claim_id
from warranty w
    join sales s on w.sale_id = s.sale_id
) src
pivot 
(
    COUNT(claim_id)
    for repair_status in ([In Progress], [Pending], [Rejected],[Completed])
) pv
join products p on pv.prod_id = p.prod_ID;

--46.using string_agg to list all poducts in each category as comma-seperated values
with prod_claims as 
(
select
        p.prod_ID,
        p.prod_Name,
        p.price,
        COUNT(w.claim_id) as claim_count
from products p
    join sales s
    on p.prod_ID = s.prod_id
    join warranty w
    on w.sale_id = s.sale_id
    group by p.prod_ID, p.prod_Name, p.price
),
bucketed_prod as 
(
select
        *,
        NTILE(3) over (order by price) as price_tile,
        NTILE(3) over (order by claim_count) as claim_tile
from prod_claims
)
select
        case price_tile
            when 1 then 'Low Price'
            when 2 then 'Medium Price'
            when 3 then 'High Price'
        end as price_category,
        case claim_tile
            when 1 then 'Low Claims'
            when 2 then 'Medium Claims'
            when 3 then 'High Claims'
        end as claim_category,
        STRING_AGG(prod_Name, ', ') as products
from bucketed_prod
group by
    price_tile,
    claim_tile
order by
    price_tile,
    claim_tile;

--47.Multiple calculated fields for price category,claim risk level,prouct age
with product_claims as 
(
select
        p.prod_ID,
        p.prod_Name,
        p.price,
        p.launch_date,
        COUNT(w.claim_id) as claim_count
from products p
    join sales s
    on p.prod_ID = s.prod_id
    join warranty w
    on w.sale_id = s.sale_id
    group by
    p.prod_ID,
    p.prod_Name,
    p.price,
    p.launch_date
)
select
        prod_ID,
        prod_Name,
        price,
        claim_count,
        case
            when price < 1000 then 'Low Price'
            when price between 1000 and 3000 then 'Medium Price'
            else 'High Price'
        end as price_category,
        case
            when claim_count = 0 then 'No Risk'
            when claim_count between 1 and 3 then 'Low Risk'
            when claim_count between 4 and 6 then 'Medium Risk'
        else 'High Risk'
        end as claim_risk_level,
        case
            when DATEDIFF(YEAR, launch_date, GETDATE()) < 1 then 'New'
            when DATEDIFF(YEAR, launch_date, GETDATE()) between 2 and 3 then 'Mid Age'
            else 'Old'
        end as product_age
from product_claims
    order by price, claim_count desc;

--48.View combining products,categories and aggregate warranty data
drop view if exists vw_prod_warr_analysis;
GO
create view vw_prod_warr_analysis as
with warranty_agg as
(
select
        s.prod_id,
        COUNT(w.claim_id) as total_claims,
        COUNT(case when w.repair_status = 'In Progress' then 1 end) as In_progress_claims,
        COUNT(case when w.repair_status = 'Completed' then 1 end) as Completed_claims,
        COUNT(case when w.repair_status = 'Pending' then 1 end) as pending_claims,
        COUNT(case when w.repair_status = 'Rejected' then 1 end) as rejected_claims
from sales s
    join warranty w
    on w.sale_id = s.sale_id
    group by s.prod_id
)
select
        p.prod_ID,
        p.prod_Name,
        c.catg_name,
        p.price,
        p.launch_date,
        COALESCE(w.total_claims, 0) as total_claims,
        COALESCE(w.In_progress_claims, 0) as In_progress_claims,
        COALESCE(w.Completed_claims, 0) as Completed_claims,
        COALESCE(w.pending_claims, 0) as pending_claims,
        COALESCE(w.rejected_claims, 0) as rejected_claims,
        case
            when p.price < 1000 then 'Low Price'
            when p.price BETWEEN 1000 AND 3000 then 'Medium Price'
            else 'High Price'
        end as price_category,
        case
            when COALESCE(w.total_claims, 0) = 0 then 'No Risk'
            when COALESCE(w.total_claims, 0) BETWEEN 1 AND 3 then 'Low Risk'
            when COALESCE(w.total_claims, 0) BETWEEN 4 AND 6 then 'Medium Risk'
            else 'High Risk'
        end as claim_risk_level,
        case
            when DATEDIFF(YEAR, p.launch_date, GETDATE()) < 1 then 'New'
            when DATEDIFF(YEAR, p.launch_date, GETDATE()) BETWEEN 1 AND 3 then 'Mid Age'
            else 'Old'
        end as product_age
from products p
    join category c
    on p.catg_id = c.catg_id
    join warranty_agg w
    on p.prod_ID = w.prod_id;
    GO

select * from vw_prod_warr_analysis where claim_risk_level = 'High Risk';

--49.Product-level forecast
with monthly_product_claims as 
(
select
        s.prod_id,
        DATEFROMPARTS(YEAR(w.claim_date), MONTH(w.claim_date), 1) as claim_month,
        COUNT(*) as claims
from warranty w
    join sales s
    on w.sale_id = s.sale_id
    group by
    s.prod_id,DATEFROMPARTS(YEAR(w.claim_date), MONTH(w.claim_date), 1)
),
last_3_months as 
(
select
        prod_id,
        claims
from 
(
select      
        prod_id,
        claims,
        ROW_NUMBER() over (partition by prod_id order by claim_month desc) as rn
from monthly_product_claims) t
    where rn <= 3
)
select
        prod_id,
        AVG(claims) as forecasted_claims_next_month
from last_3_months
    group by prod_id;

--50.ustomer segmentation based on warranty claim patterns
with customer_claims as 
(
select
        s.sale_id as customer_id,
        COUNT(w.claim_id) as total_claims
from sales s
    join warranty w
    on s.sale_id = w.sale_id
    group by s.sale_id
)
select
        customer_id,
        total_claims,
        case NTILE(4) over (order by total_claims)
            when 1 then 'Very Low Risk'
            when 2 then 'Low Risk'
            when 3 then 'Medium Risk'
            else 'High Risk'
        end as customer_segment
from customer_claims
    order by total_claims desc;

--51.products that need price adjustment based on claim rates. 
with product_stats as 
(
select
        p.prod_ID,
        p.prod_Name,
        p.price,
        COUNT(distinct s.sale_id) as total_sales,
        COUNT(w.claim_id) as total_claims
from products p
    join sales s
    on p.prod_ID = s.prod_id
    join warranty w
    on w.sale_id = s.sale_id
    group by
        p.prod_ID,
        p.prod_Name,
        p.price
),
claim_rates as 
(
select
        *,
        case
        when total_sales = 0 then 0.0
        else CAST(total_claims as float) / total_sales
        end as claim_rate
from product_stats
),
ranked_products as 
(
select
        *,
        NTILE(3) over (order by claim_rate desc) as claim_risk_bucket
from claim_rates
)
select
        prod_ID,
        prod_Name,
        price,
        total_sales,
        total_claims,
        claim_rate,
        case claim_risk_bucket
            when 1 then 'Increase Price / Improve Quality'
            when 2 then 'Review Pricing'
            else 'No Action Needed'
        end as pricing_recommendation
from ranked_products
    order by claim_rate desc;

--52.inventory optimization:slow-moving products by category
with product_sales as 
(
select
        p.prod_ID,
        p.prod_Name,
        c.catg_name,
        COUNT(s.sale_id) as total_sales
from products p
    join category c
    on p.catg_ID = c.catg_id
    join sales s
    on p.prod_ID = s.prod_id
    group by
    p.prod_ID,
    p.prod_Name,
    c.catg_name
),
movement_rank as 
(
select
    *,
    NTILE(3) over (partition by catg_name order by total_sales asc) as movement_bucket
from product_sales
)
select
        prod_ID,
        prod_Name,
        catg_name,
        total_sales,
        case movement_bucket
            when 1 then 'Slow Moving'
            when 2 then 'Medium Moving'
            else 'Fast Moving'
        end as inventory_movement_status
from movement_rank
    order by catg_name, total_sales;

--53.alert system: products with abnormally high claim rejection rates. 
with claim_summary as 
(
select
        p.prod_ID,
        p.prod_Name,
        COUNT(w.claim_id) as total_claims,
        SUM(
        case 
        when w.repair_status = 'Rejected' then 1 else 0 end) as rejected_claims
from products p
    join sales s
    on p.prod_ID = s.prod_id
    join warranty w
    on w.sale_id = s.sale_id
    group by
    p.prod_ID,
    p.prod_Name
),
rejection_rates as 
(
select
        *,
        case
        when total_claims = 0 then 0.0
        else CAST(rejected_claims as float) / total_claims
        end as rejection_rate
from claim_summary
),
threshold_calc as 
(
select
        *,
        PERCENTILE_CONT(0.90)
        within group (order by rejection_rate) over () as alert_cutoff
from rejection_rates
)
select
        prod_ID,
        prod_Name,
        total_claims,
        rejected_claims,
        rejection_rate,
        case
        when rejection_rate >= alert_cutoff
        then 'ALERT: Abnormally High Rejection Rate'
        else 'Normal'
        end as alert_status
from threshold_calc
    order by rejection_rate desc;

--54.Monthly Trend by Product Category
select
        c.catg_name,
        YEAR(w.claim_date)  as claim_year,
        MONTH(w.claim_date) as claim_month,
        COUNT(w.claim_id)   as total_claims
from warranty w
    join sales s
    on w.sale_id = s.sale_id
    join products p
    on s.prod_id = p.prod_ID
    join category c
    on p.catg_ID = c.catg_id
    group by
    c.catg_name,
    YEAR(w.claim_date),
    MONTH(w.claim_date)
    order by
    c.catg_name,
    claim_year,
    claim_month;

