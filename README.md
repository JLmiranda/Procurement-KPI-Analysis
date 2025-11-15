# Procurement-KPI-Analysis
This project analyzes procurement performance data using SQL to identify trends in supplier efficiency, cost control, and operational effectiveness. It includes data cleaning, exploratory data analysis (EDA), and key performance indicator (KPI) queries for business insights.

### Objectives
1. **Set up a procurement database:** Create and populate a procurement database with the provided dataset.
2. **Data Cleaning:** Identify and correct inconsistent data types, date formats, and missing values
3. **Exploratory Data Analysis (EDA):** Perform descriptive analysis to understand procurement trends and supplier performance.
4. **Business Analysis:** Use SQL to answer specific business questions, derive actionable insights, and evaluate KPIs such as lead time, cost efficiency, and defect rates.

### Project Structure

**1. Database Setup**
      - Database Creation:
        The project begins with creating a database named `kpi`.
```sql
      CREATE DATABASE kpi;
      USE kpi;
```
**2. Table Creation:**
A table named `procurement` is created to store procurement data.
The structure includes columns for:

`PO_ID`

`Supplier`

`Category`

`Quantity`

`Item_Category`

`Unit_Price`

`Order_Date`

`Delivery_Date`

`Defective_Units`

`Negotiated_Price`

`Compliance`


**3. Data Cleaning**
- Data cleaning ensures all columns have correct data types, consistent formats, and valid values.
The following SQL steps were performed in MySQL to prepare the dataset for analysis.

```sql
---Handling Missing or Null Values

SELECT 
	SUM(CASE WHEN Supplier IS NULL THEN 1 ELSE 0 END) AS Missing_Supplier,
    SUM(CASE WHEN Delivery_Date ='' THEN 1 ELSE 0 END) AS Missing_DeliveryDate,
    SUM(CASE WHEN Defective_Units='' THEN 1 ELSE 0 END) AS Missing_DefectiveUnits
FROM kpi.procurement;

---Replace missing Defective_Units with 0
 
 UPDATE kpi.procurement
 SET Defective_Units = 0 
 WHERE Defective_Units= '';

---Create new column and convert Order_Date and Delivery_Date to proper date format

ALTER TABLE kpi.procurement
ADD COLUMN Order_Date_Clean DATE;

ALTER TABLE kpi.procurement
ADD COLUMN Delivery_Date_Clean DATE;

UPDATE kpi.procurement
SET Order_Date_Clean = STR_TO_DATE(TRIM(Order_Date), '%m/%d/%Y')
WHERE Order_Date IS NOT NULL AND Order_Date <> '';
 
  UPDATE kpi.procurement
SET Delivery_Date_Clean = STR_TO_DATE(TRIM(Delivery_Date), '%m/%d/%Y')
WHERE Delivery_Date IS NOT NULL AND Delivery_Date <> '';

---Rename Column Names

ALTER TABLE kpi.procurement
RENAME COLUMN Delivery_Date_Clean to Delivery_Date;

ALTER TABLE kpi.procurement
RENAME COLUMN Order_Date_Clean to Order_Date;

--- REMOVE Duplicates
 
 SELECT PO_ID, count(*) AS Count
 FROM kpi.procurement
 GROUP BY PO_ID
 HAVING COUNT(*) > 1;

--- Create Derived Columns: Add calculated fields for better KPI tracking.

--- Add a Lead_Time column (days between order and delivery)

ALTER TABLE kpi.procurement ADD COLUMN Lead_Time INT;

UPDATE kpi.procurement SET Lead_Time = DATEDIFF( Delivery_Date,Order_Date);

---Total Cost

 ALTER TABLE kpi.procurement
 ADD COLUMN Total_Cost INT;
 
 UPDATE kpi.procurement SET Total_Cost = (Unit_Price*Quantity);

---Savings_Amount
 
 ALTER TABLE kpi.procurement
 ADD COLUMN Savings_Amount INT;
 
 UPDATE kpi.procurement 
 SET Savings_Amount = ((Unit_Price-Negotiated_Price)*Quantity);


--- Defective_Rate

ALTER TABLE kpi.procurement
Drop COlUMN Defective_Rate; 

ALTER TABLE kpi.procurement
ADD COLUMN Defect_Rate DECIMAL(10,2);

UPDATE kpi.procurement 
SET Defect_Rate = (Defective_Units/Quantity) WHERE Defective_Units IS NOT NULL AND Defective_Units <> '';

```
**4. Exploratory Data Analysis (EDA)** - After cleaning the data, the next step is to perform Exploratory Data Analysis (EDA) to understand supplier performance, procurement trends, and category spending patterns.
The following SQL queries provide descriptive insights into the procurement dataset.

```sql

---Retrieve all purchase orders from the table

SELECT * FROM kpi.procurement;

-- View the first few rows (Top 10 by Quantity)

 SELECT * FROM kpi.procurement
 ORDER BY Quantity DESC
 LIMIT 10;
-- Count number of Rows

SELECT COUNT(*) AS Total_records FROM kpi.procurement;
   
-- List all distinct suppliers

SELECT DISTINCT Supplier AS Unique_Suppliers FROM kpi.procurement;

-- Count number of purchase orders per supplier

SELECT Supplier, COUNT(Supplier) AS Number_of_Purchases FROM kpi.procurement
GROUP BY Supplier
ORDER BY Number_of_Purchases ASC;

-- Total quantity ordered per item category

SELECT Item_Category,SUM(Quantity) AS Total_Quantity
FROM kpi.procurement
GROUP BY 1
ORDER BY 2;

---Orders that were not delivered yet (based on Order_Status)

SELECT PO_ID, Order_Status
FROM kpi.procurement
WHERE Order_Status NOT LIKE "Delivered";

---- Non-compliant purchase orders	

SELECT PO_ID, Compliance
FROM kpi.procurement
WHERE Compliance != "YES";

-- Orders placed in 2023

SELECT PO_ID, Supplier, Item_Category, year(Order_Date) AS Year_Ordered
FROM kpi.procurement
WHERE Order_Date LIKE "2023%%";


-- Average negotiated price per category

SELECT Item_Category, CAST(AVG(Negotiated_Price) AS DECIMAL(10,2)) AS Average_Negotiated_Price
FROM kpi.procurement
GROUP BY Item_Category;

-- Total defective units per supplier

SELECT Supplier, SUM(Defective_Units) AS Total_Defectives
FROM kpi.procurement
GROUP BY Supplier
ORDER BY 2;

-- Suppliers with more than 10,000 defective units

SELECT Supplier, SUM(Defective_Units) AS Total_Defectives
FROM kpi.procurement
GROUP BY Supplier
HAVING SUM(Defective_Units) > 10000
ORDER BY 2;

-- Price difference between Unit Price and Negotiated Price

SELECT PO_ID,Item_Category, Unit_Price, Negotiated_Price, CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) AS Price_Difference
FROM kpi.procurement;

-- Negotiated price savings >= 5%

SELECT PO_ID,Item_Category, Unit_Price, Negotiated_Price, CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) AS Price_Difference
FROM kpi.procurement
WHERE CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) > 0.5;

-- Compliant vs Non-Compliant

SELECT 
	Compliance,
	COUNT(Compliance) AS ComplaintvsNonCompliant
FROM kpi.procurement
GROUP BY Compliance;


-- Top 5 suppliers by total order quantity

SELECT Supplier, SUM(Quantity) as Total_Purchase
FROM kpi.procurement
GROUP BY Supplier
ORDER BY SUM(Quantity) DESC;

-Date and Time Analysis

-- Average lead time per supplier

SELECT Supplier, AVG(Lead_Time) AS Avg_Lead_Time FROM kpi.procurement
GROUP BY Supplier
ORDER BY AVG(Lead_Time);

-- Orders with lead time greater than 15 days

SELECT PO_ID,Item_Category, Lead_Time
FROM kpi.procurement
WHERE 
Lead_Time > 15
ORDER BY Lead_Time;

-- Month-year with highest purchase volume

SELECT 
    YEAR(Order_Date) AS Highest_Order_YEAR,
    MONTH(Order_Date) AS Highest_Order_MONTH,
    SUM(Quantity) AS Total_Purchase
FROM
    kpi.procurement
GROUP BY 1 , 2
ORDER BY SUM(Quantity) DESC
LIMIT 5;

-- Fastest average delivery time (best suppliers)

SELECT Supplier, CAST(AVG(Lead_Time) AS DECIMAL(10,2)) AS AVG_LEAD_TIME
FROm kpi.procurement
GROUP BY Supplier
ORDER BY AVG(Lead_Time) ASC;

-- Procurement cost savings per supplier

SELECT Supplier, CAST(SUM((Unit_Price - Negotiated_Price) * Quantity) AS DECIMAL(10,2)) AS Cost_Savings
FROM kpi.procurement
GROUP BY Supplier;

-- Supplier compliance rate (%)

SELECT Supplier,
CAST((SUM(CASE WHEN Compliance = "Yes" THEN 1 ELSE 0 END)/COUNT(*))* 100 AS Decimal(10,2)) AS Compliance_Rate
FROM kpi.procurement
GROUP BY Supplier;    
    
-- Supplier Ranking by Quantity (Window Function)

SELECT PO_ID,Supplier, Quantity, RANK() OVER (PARTITION BY Supplier ORDER BY Quantity) AS RANK_PER_TOTAL_PROCUREMENT
FROM kpi.procurement;

-- KPI Table (Spend, Savings, Defects, Compliance)

With KPI_Table AS
(
	Select 
		Supplier, 
        SUM(Total_Cost) AS Total_Cost, 
        SUM(Savings_Amount) AS Total_Savings,
        SUM(Defective_Units) AS Total_defectives, 
        CAST((SUM(CASE WHEN Compliance = "Yes" THEN 1 ELSE 0 END)/COUNT(*)) *100 AS DECIMAL(10,2)) AS Compliance_Rate
    FROM kpi.procurement
    GROUP BY Supplier
)
Select
Supplier,
Total_Cost,
Total_Savings,
Total_Defectives,
Compliance_Rate
FROM
KPI_Table;


-- Most ordered category + % contribution to total spend

SELECT 
    Item_Category,
    COUNT(Item_Category) AS Total_Count,
    ROUND((SUM(Total_Cost) * 100 / (SELECT SUM(Total_Cost) FROM kpi.procurement)),2) AS Contribution_to_total
FROM
    kpi.procurement
GROUP BY 1
ORDER BY COUNT(Item_Category) DESC
LIMIT 1;

-- Classify orders by delivery speed
SELECT 
	PO_ID, Item_Category, Lead_Time,
	CASE
		WHEN Lead_Time < 7 THEN "Fast"
        WHEN Lead_Time BETWEEN 7 and 14 THEN "Moderate" 
        ELSE "Slow"
        END AS Lead_Time_Classification
	FROM kpi.procurement;
```

### Summary of EDA Insights
#### Analysis and Key Insights
- Supplier Analysis - Identified top-performing and highest-spend suppliers
- Category Analysis - Determined top categories contributing to total spend
- Lead Time - Evaluated supplier delivery performance
- Defect Rate - Detected suppliers with high defect ratios
- Monthly Trends - Showed seasonality and cost fluctuation patterns

## Findings
### 1. Data Overview & Structure

- The table contains all purchase orders, showing a complete procurement record for analysis.
- The dataset includes multiple fields such as Supplier, Category, Quantity, Costs, Dates, Defects, and Compliance—allowing KPI tracking across procurement performance.

### 2. Supplier Analysis

- There are multiple distinct suppliers, indicating a diversified vendor base.
- Some suppliers have more frequent purchase orders compared to others, showing dependency on top vendors.
- Several suppliers show high defective unit counts, with some exceeding the 10,000 defects threshold, signaling quality issues.
- Compliance levels vary—while many orders are marked "Yes", notable non-compliance still exists.
- Suppliers with the fastest delivery times are easily identifiable; some consistently provide quick fulfillment, while others have long delays.

### 3. Delivery Performance

- Multiple orders show delayed delivery beyond 15 days.
- Average lead time varies significantly by supplier—some vendors show consistent delays.
- Month–year grouping reveals which periods experience peak procurement activity, useful for demand forecasting.
- Lead time classification shows a mix of Fast, Moderate, and Slow deliveries, suggesting inconsistent fulfillment rates.

### 4. Compliance & Quality

- A notable number of purchase orders are non-compliant, which may indicate issues in documentation, process adherence, or supplier behavior.
- Defective units vary widely across suppliers; some suppliers show a pattern of high defectiveness, affecting product quality and returns.


### 5. Cost & Price Optimization

- Negotiated prices sometimes differ significantly from unit prices, generating cost savings.
- Some orders show 5%+ savings, demonstrating successful procurement negotiation.
- Cost savings by supplier reveal which vendors offer the highest financial benefit through price negotiations.
- Ranking suppliers by spend shows which vendors receive the largest share of the budget.

### 7. Procurement KPIs

- The KPI table highlights:
	- Top suppliers by total spend
	- Suppliers that produce the most savings
	- Vendors with high defect rates
	- Compliance performance across the supplier base
- These KPIs help evaluate supplier reliability, quality, and financial impact.







