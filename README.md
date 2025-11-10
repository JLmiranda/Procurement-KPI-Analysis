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
A table named procurement is created to store procurement data.
The structure includes columns for:

`PO_ID`

`Supplier_Name`

`Category`

`Quantity`

`Unit_Price`

`Order_Date`

`Delivery_Date`

`Defective_Units`

`Total_Cost`
