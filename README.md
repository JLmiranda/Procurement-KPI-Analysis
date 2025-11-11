# Procurement-KPI-Analysis
This project analyzes procurement performance data using SQL to identify trends in supplier efficiency, cost control, and operational effectiveness. It includes data cleaning, exploratory data analysis (EDA), and key performance indicator (KPI) queries for business insights.

###Objectives
1. **Set up a procurement database:** Create and populate a procurement database with the provided dataset.
2. **Data Cleaning:** Identify and correct inconsistent data types, date formats, and missing values
3. **Exploratory Data Analysis (EDA):** Perform descriptive analysis to understand procurement trends and supplier performance.
4. **Business Analysis:** Use SQL to answer specific business questions, derive actionable insights, and evaluate KPIs such as lead time, cost efficiency, and defect rates.

###Project Structure

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



  
