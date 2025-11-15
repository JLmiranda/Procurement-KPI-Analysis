
CREATE DATABASE kpi;
USE kpi;

###################DATA CLEANING


##### Handling Missing or Null Values

SELECT 
	SUM(CASE WHEN Supplier IS NULL THEN 1 ELSE 0 END) AS Missing_Supplier,
    SUM(CASE WHEN Delivery_Date ='' THEN 1 ELSE 0 END) AS Missing_DeliveryDate,
    SUM(CASE WHEN Defective_Units='' THEN 1 ELSE 0 END) AS Missing_DefectiveUnits
FROM kpi.procurement;
 
 
 ############# Replace missing Defective_Units with 0
 
 UPDATE kpi.procurement
 SET Defective_Units = 0 
 WHERE Defective_Units= '';



################### Rename Table
ALTER TABLE kpi.procurement
RENAME COLUMN ï»¿PO_ID TO PO_ID;

ALTER TABLE kpi.procurement
DROP COLUMN Delivery_Date;

ALTER TABLE kpi.procurement
DROP COLUMN Order_Date;

ALTER TABLE kpi.procurement
RENAME COLUMN Delivery_Date_Clean to Delivery_Date;

ALTER TABLE kpi.procurement
RENAME COLUMN Order_Date_Clean to Order_Date;

  ####################
 
 UPDATE kpi.procurement
 SET Order_Date = str_to_date(Order_Date, '%m,%d,%Y');
 
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

 ############ REMOVE Duplicates
 
 SELECT PO_ID, count(*) AS Count
 FROM kpi.procurement
 GROUP BY PO_ID
 HAVING COUNT(*) > 1;
 
 #####Derived & Corrected Columns
 #########Add a Lead_Time column (days between order and delivery).
 
ALTER TABLE kpi.procurement ADD COLUMN Lead_Time INT;
 
UPDATE kpi.procurement SET Lead_Time = DATEDIFF( Delivery_Date,Order_Date);

 ######### Total Cost
 
 ALTER TABLE kpi.procurement
 ADD COLUMN Total_Cost INT;
 
 UPDATE kpi.procurement SET Total_Cost = (Unit_Price*Quantity);
 
 #############Savings_Amount
 
 ALTER TABLE kpi.procurement
 ADD COLUMN Savings_Amount INT;
 
 UPDATE kpi.procurement 
 SET Savings_Amount = ((Unit_Price-Negotiated_Price)*Quantity);
 
######### Defective_Rate

ALTER TABLE kpi.procurement
Drop COlUMN Defective_Rate; 

ALTER TABLE kpi.procurement
ADD COLUMN Defect_Rate DECIMAL(10,2);

UPDATE kpi.procurement 
SET Defect_Rate = (Defective_Units/Quantity) WHERE Defective_Units IS NOT NULL AND Defective_Units <> '';
  
 
 ######## UPDATE 
 
UPDATE kpi.procurement
 SET Defective_Units = "0"
 WHERE Defective_Units = '';
 
  ####### EDA
  
  ########View the first few rows
 SELECT * FROM kpi.procurement
 ORDER BY Quantity DESC
 LIMIT 10;
 
########Count number of Rows and Columns 
   
SELECT COUNT(*) AS Total_records FROM kpi.procurement;
   
############Retrieve all purchase orders from the table.

SELECT * FROM kpi.procurement;

##########List all distinct suppliers.

SELECT DISTINCT Supplier AS Unique_Suppliers FROM kpi.procurement;

#############Count how many purchase orders were made for each supplier.

SELECT Supplier, COUNT(Supplier) AS Number_of_Purchases FROM kpi.procurement
GROUP BY Supplier
ORDER BY Number_of_Purchases ASC;


#############Find the total quantity ordered per item category.
SELECT Item_Category, Supplier,SUM(Quantity) AS Total_Quantity,  AVG(Lead_time)
FROM kpi.procurement
GROUP BY 1,2
ORDER BY 3 desc;

###############Show all orders that were not delivered yet (based on Order_Status).
SELECT PO_ID, Order_Status
FROM kpi.procurement
WHERE Order_Status NOT LIKE "Delivered";

#################Get all purchase orders where compliance is marked as “No”.

SELECT PO_ID, Compliance
FROM kpi.procurement
WHERE Compliance != "YES";


############Retrieve all orders placed in 2023.

SELECT PO_ID, Supplier, Item_Category, year(Order_Date) AS Year_Ordered
FROM kpi.procurement
WHERE Order_Date LIKE "2023%%";


#########Find the average negotiated price per item category.
SELECT Item_Category, CAST(AVG(Negotiated_Price) AS DECIMAL(10,2)) AS Average_Negotiated_Price
FROM kpi.procurement
GROUP BY Item_Category;

#########Get the total number of defective units per supplier.

SELECT Supplier, SUM(Defective_Units) AS Total_Defectives
FROM kpi.procurement
GROUP BY Supplier
ORDER BY 2;


#########Find suppliers with more than 1,000 total defective units.
SELECT Supplier, SUM(Defective_Units) AS Total_Defectives
FROM kpi.procurement
GROUP BY Supplier
HAVING SUM(Defective_Units) > 10000
ORDER BY 2;

#########Determine the percentage difference between Unit_Price and Negotiated_Price for each order.

SELECT PO_ID,Item_Category, Unit_Price, Negotiated_Price, CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) AS Price_Difference
FROM kpi.procurement;


#########Show all orders where the negotiated price saved at least 5% compared to the original unit price.
SELECT PO_ID,Item_Category, Unit_Price, Negotiated_Price, CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) AS Price_Difference
FROM kpi.procurement
WHERE CAST(((Unit_Price-Negotiated_Price) * 0.1) AS DECIMAL(10,2)) > 0.5;

#########Count the number of compliant vs non-compliant orders.
SELECT 
	Compliance,
	COUNT(Compliance) AS ComplaintvsNonCompliant
FROM kpi.procurement
GROUP BY Compliance;


#########Find the top 5 suppliers by total order quantity.
SELECT Supplier, SUM(Quantity) as Total_Purchase
FROM kpi.procurement
GROUP BY Supplier
ORDER BY SUM(Quantity) DESC;

#########Date and Time Analysis
#########Find the average lead time per supplier.
SELECT Supplier, AVG(Lead_Time) AS Avg_Lead_Time FROM kpi.procurement
GROUP BY Supplier
ORDER BY AVG(Lead_Time);

#########Identify orders that took longer than 15 days to deliver.
SELECT PO_ID,Item_Category, Lead_Time
FROM kpi.procurement
WHERE 
Lead_Time > 15
ORDER BY Lead_Time;

#########Get the month and year with the highest number of purchase orders.
SELECT 
    YEAR(Order_Date) AS Highest_Order_YEAR,
    MONTH(Order_Date) AS Highest_Order_MONTH,
    SUM(Quantity) AS Total_Purchase
FROM
    kpi.procurement
GROUP BY 1 , 2
ORDER BY SUM(Quantity) DESC
LIMIT 5;

#########List suppliers with the fastest average delivery time.
SELECT Supplier, CAST(AVG(Lead_Time) AS DECIMAL(10,2)) AS AVG_LEAD_TIME
FROm kpi.procurement
GROUP BY Supplier
ORDER BY AVG(Lead_Time) ASC;

#########Compute procurement cost savings per supplier
SELECT Supplier, CAST(SUM((Unit_Price - Negotiated_Price) * Quantity) AS DECIMAL(10,2)) AS Cost_Savings
FROM kpi.procurement
GROUP BY Supplier;

#########Determine the supplier compliance rate
SELECT Supplier,
CAST((SUM(CASE WHEN Compliance = "Yes" THEN 1 ELSE 0 END)/COUNT(*))* 100 AS Decimal(10,2)) AS Compliance_Rate
FROM kpi.procurement
GROUP BY Supplier;    
    
#########Rank suppliers by total procurement spend (using RANK() window function).

SELECT PO_ID,Supplier, Quantity, RANK() OVER (PARTITION BY Supplier ORDER BY Quantity) AS RANK_PER_TOTAL_PROCUREMENT
FROM kpi.procurement;

#########Create a KPI table showing: Supplier, Total Spend, Total Savings, Total Defects, Compliance Rate.
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

#########Identify the most ordered item category and its contribution to total spend.
SELECT 
    Item_Category,
    COUNT(Item_Category) AS Total_Count,
    ROUND((SUM(Total_Cost) * 100 / (SELECT SUM(Total_Cost) FROM kpi.procurement)),2) AS Contribution_to_total
FROM
    kpi.procurement
GROUP BY 1
ORDER BY COUNT(Item_Category) DESC
LIMIT 1;


#########Find correlation-type insights, like whether higher negotiated savings are linked to higher defect rates.


 
#########Use a CASE statement to classify delivery lead times as:“Fast” (<7 days)“Moderate” (7–14 days) “Slow” (>14 days)
SELECT 
	PO_ID, Item_Category, Lead_Time,
	CASE
		WHEN Lead_Time < 7 THEN "Fast"
        WHEN Lead_Time BETWEEN 7 and 14 THEN "Moderate" 
        ELSE "Slow"
        END AS Lead_Time_Classification
	FROM kpi.procurement;
    