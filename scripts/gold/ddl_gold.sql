 --=====================================================================================
 --DDL Script : Create gold view
 --=====================================================================================
 /*
 ---------------------------------------------------------------------------------------
 Script Purpose : 
			This script creates views for Gold layers in the data warehouse  
			This gold layer represents the final dimension and fact table .(Star schema)

			Each view performs transformations and combine data from silver layer to produce
			a clean,enriched and business-ready dataset.

Uses : 
		    This script can be directly use for analytics and reporting 

-----------------------------------------------------------------------------------------
 */

--=====================================================================================
--Create Dimension : gold.dim_customers
--=====================================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname As first_name,
	ci.cst_lastname AS last_name,
	CASE WHEN ci.cst_gndr != 'N/A' AND ci.cst_gndr !='NA'  THEN ci.cst_gndr
	ELSE COALESCE(eu.gen,'N/A') 
	END AS gender,
	el.cntry As country,
	ci.cst_material_status AS marital_status,
	eu.bdate AS birth_date,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 eu
ON		  eu.cid=ci.cst_key
LEFT JOIN silver.erp_loc_a101 el
ON		  el.cid=ci.cst_key

--=====================================================================================
--Create Dimention : gold.dim_products
--=====================================================================================

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cp.prd_start_dt,cp.prd_key) AS product_key  ,
	cp.prd_id AS product_id,
	cp.prd_key AS product_number,
	cp.prd_nm AS product_name,
	cp.cat_id AS category_id,
	ep.cat category,
	ep.subcat AS subcategory,
	ep.maintenance AS maintenance,
	cp.prd_cost AS cost,
	cp.prd_line AS line,
	cp.prd_start_dt As start_date
FROM silver.crm_prd_info cp
LEFT JOIN silver.erp_px_cat_g1v2 ep
ON		  ep.id=cp.cat_id
WHERE cp.prd_end_dt IS NULL                   -- Filter out all historical data

--=====================================================================================
--Create Fact: gold.fact_sales
--=====================================================================================

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales  AS
SELECT 
	sd.sls_ord_num AS order_number,
	p.product_key,
	c.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers c
ON c.customer_id=sd.sls_cust_id
LEFT JOIN gold.dim_products p
ON p.product_number=sd.sls_prd_key

