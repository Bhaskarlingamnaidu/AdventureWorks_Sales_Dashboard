use adventureworks;

CREATE VIEW FactSales AS
SELECT * FROM factinternetsales
UNION ALL
SELECT * FROM fact_internet_sales_new;

--- product +Category merging ------
CREATE VIEW DimProductFull AS
SELECT 
    p.ProductKey,
    p.EnglishProductName AS ProductName,
    ps.EnglishProductSubcategoryName AS SubCategory,
    pc.EnglishProductCategoryName AS Category
FROM dimproduct p
LEFT JOIN dimproductsubcategory ps
    ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
LEFT JOIN dimproductcategory pc
    ON ps.ProductCategoryKey = pc.ProductCategoryKey;
    
--- Joins ----
   CREATE VIEW SalesMaster AS
SELECT 
    f.*,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    dp.ProductName,
    dp.SubCategory,
    dp.Category,
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    d.CalendarQuarter,
    -- rename here
    STR_TO_DATE(CAST(f.OrderDateKey AS CHAR), '%Y%m%d') AS OrderDateConverted
FROM FactSales f
LEFT JOIN dimcustomer c 
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN DimProductFull dp 
    ON f.ProductKey = dp.ProductKey
LEFT JOIN dimdate d 
    ON f.OrderDateKey = d.DateKey;
    
 ------- Sales Amount --------
 SELECT 
    SalesOrderNumber,
    (UnitPrice * OrderQuantity) 
    - (UnitPrice * OrderQuantity * UnitPriceDiscountPct) 
    AS SalesAmount
FROM FactSales;

------- Production Cost --------
SELECT 
    SalesOrderNumber,
    ProductStandardCost * OrderQuantity AS ProductionCost
FROM FactSales;

--------- Profit ----------
SELECT 
    SalesOrderNumber,
    ((UnitPrice * OrderQuantity) 
        - (UnitPrice * OrderQuantity * UnitPriceDiscountPct)) 
    - (ProductStandardCost * OrderQuantity) AS Profit
FROM FactSales;

---------- Date fields ---------
SELECT 
    OrderDateKey,
    STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d') AS OrderDate
FROM FactSales;

--------- Year --------
SELECT 
    YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Year
FROM FactSales;

------- Month Number --------
SELECT 
    MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS MonthNo
FROM FactSales;

---------- Month Name --------
SELECT 
    MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS MonthName
FROM FactSales;

-------- Quarter ---------
SELECT 
    QUARTER(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Quarter
FROM FactSales;

----- Year month -------
SELECT 
    DATE_FORMAT(
        STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d'),
        '%Y-%b'
    ) AS YearMonth
FROM FactSales;

---------- Weekday Number -----------
SELECT 
    WEEKDAY(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS WeekdayNo
FROM FactSales;

---------- Weekday Name ---------
SELECT 
    DAYNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS WeekdayName
FROM FactSales;

------- Financial Month ---------
SELECT 
    CASE 
        WHEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) >= 4 
        THEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) - 3
        ELSE MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) + 9
    END AS FinancialMonth
FROM FactSales;

------- Financial Year ----------
SELECT 
    CASE 
        WHEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) >= 4 
        THEN YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d'))
        ELSE YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) - 1
    END AS FinancialYear
FROM FactSales;

--------- financial Quarter -----------
SELECT 
    CASE 
        WHEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) BETWEEN 4 AND 6 THEN 'Q1'
        WHEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) BETWEEN 7 AND 9 THEN 'Q2'
        WHEN MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS FinancialQuarter
FROM FactSales;

------ pivot(Month vs sales) ----
SELECT 
YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Year,
MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Month,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY Year, Month
ORDER BY Year;

------- Yearwise Sales ----------
SELECT 
YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Year,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY Year
ORDER BY Year;

------- MonthWise Sales ---------
SELECT 
MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Month,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY Month;

----- Quarter Sales ------
SELECT 
QUARTER(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Quarter,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY Quarter;

------- ProductWise --------
SELECT 
ProductKey,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY ProductKey
ORDER BY Sales DESC;

---- customer Wise Sales ---------
SELECT 
CustomerKey,
SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) AS Sales
FROM FactSales
GROUP BY CustomerKey
ORDER BY Sales DESC;


------ All KPIs ----------
    SELECT 
    SUM(ExtendedAmount) AS Sales,

    SUM(ProductStandardCost * OrderQuantity) AS ProductionCost,

    SUM(ExtendedAmount) 
    - SUM(ProductStandardCost * OrderQuantity) AS Profit,

    ROUND(
        (SUM(ExtendedAmount) 
        - SUM(ProductStandardCost * OrderQuantity)) 
        / SUM(ExtendedAmount) * 100, 2
    ) AS ProfitMargin,

    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders

FROM FactSales;
    


