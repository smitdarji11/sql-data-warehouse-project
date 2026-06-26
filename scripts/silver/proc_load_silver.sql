-------------------------------------------------------
--Store Proceduer : Load Silver Layer (Source > Silver)
-------------------------------------------------------
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @start_time DATETIME,@end_time DATETIME, @batch_start_time DATETIME , @batch_end_time DATETIME;
	BEGIN TRY
		PRINT '======================================================';
		PRINT 'Loading SIlver Layer';
		PRINT '======================================================';
	
		PRINT'---------------------------------------------------------';
		PRINT'Loading CRM Tables';
		PRINT'---------------------------------------------------------';


		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT'>>Inserting data into : silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id ,
			cst_key ,
			cst_firstname,
			cst_lastname,
			cst_material_status ,
			cst_gndr ,
			cst_create_date)
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,  -- Remove blank spaces in first name
			TRIM(cst_lastname) AS cst_lastname,    -- Remove black spaces in last name
			CASE UPPER(TRIM(cst_material_status))
			WHEN 'S' THEN 'Single'
			WHEN 'M' THEN 'Married'
			ELSE 'N/A'
			END AS cst_material_status,             -- Normalize material stutus and handle unknow values 
			CASE UPPER(TRIM(cst_gndr))
			WHEN 'F' THEN 'Female'
			WHEN 'M' THEN 'Male'
			ELSE 'N/A'								
			END AS cst_gndr,						-- Normalize gender and handle unknow values  
			cst_create_date
		FROM
		(SELECT *,
			RANK() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS last_flag   -- Remove duplicate and null cst_id
		FROM bronze.crm_cust_info
		WHERE cst_id IS Not NULL) t
		WHERE last_flag=1;
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info
		PRINT'>>Inserting data into : silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id ,
			cat_id,
			prd_key,
			prd_nm,  
			prd_cost,
			prd_line,
			prd_start_dt ,
			prd_end_dt )
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, -- Extract cat_id
			SUBSTRING(prd_key,5,LEN(prd_key)) AS prd_key, --Extract prd_key
			prd_nm,
			COALESCE(prd_cost,0) AS prd_cost, -- Fix Null values
			CASE UPPER(TRIM(prd_line))  
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'  
			WHEN 'T' THEN 'Touring'
			ELSE 'NA'
			END AS prd_line, -- Map product line codes to descriptive values 
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt -- calcutale last date as one day before start day 
		FROM bronze.crm_prd_info
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details
		PRINT'>>Inserting data into : silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price 
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,

			CASE WHEN sls_order_dt=0 OR LEN(sls_order_dt)!=8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS date ) 
			END AS sls_order_dt,												--Handle invalid date using Null 

			CASE WHEN sls_ship_dt=0 OR LEN(sls_ship_dt)!=8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS date ) 
			END AS sls_ship_dt,													--Handle invalid date using Null 

			CASE WHEN sls_due_dt=0 OR LEN(sls_due_dt)!=8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS date ) 
			END AS sls_due_dt,													--Handle invalid date using Null 


			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity*ABS(sls_price) 
				THEN sls_quantity * ABS(sls_price) 
				ELSE sls_sales
			END AS sls_sales,													--Check sales is not null,not negitive and match sales=quatity*price 


			sls_quantity,

			CASE WHEN sls_price IS NULL OR sls_price <=0  
				THEN sls_sales/sls_quantity 
				ELSE sls_price
			END AS sls_price										--Check Price is not null,not negitive and match Price=sales/quantity

		FROM bronze.crm_sales_details
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT'>>Inserting data into : silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(cid,bdate,gen)

		SELECT 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))		
				ELSE cid
			END	AS cid,														-- Remove prefix 'NAS' if present
	
			CASE WHEN bdate > GETDATE() THEN NULL	
				ELSE bdate
			END AS bdate,						-- SET Future birthday to null

			CASE WHEN UPPER((TRIM(gen))) IN ('F','Female') THEN 'Female'
				WHEN UPPER((TRIM(gen))) IN ('M','Male') THEN 'Male'
				ELSE 'N/A'
			END AS gen					-- Norrmalize gender values and handle unknow case
		FROM bronze.erp_cust_az12
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT'>>Inserting data into : silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(cid,cntry)
		SELECT 
			REPLACE(cid,'-','') AS cid, -- Remove '-' From cid
			CASE 
				WHEN TRIM(cntry)='DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US','USA') THEN 'United States' 
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
				END AS cntry		-- Normalization and haldle balck values 
		FROM bronze.erp_loc_a101	
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';

		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT '>> Truncating Table :silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2 
		PRINT'>>Inserting data into :silver.erp_px_cat_g1v2 ';
		INSERT INTO silver.erp_px_cat_g1v2 (id,cat,subcat,maintenance)
		SELECT *
		FROM bronze.erp_px_cat_g1v2
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';
		END TRY
	BEGIN CATCH
		PRINT'==============================================='
		PRINT'ERROR OCCURE DURING LOADING BRONZE LAYER'
		PRINT'Error Message : '  + CAST(ERROR_MESSAGE() AS NVARCHAR)
		PRINT'Error State : ' + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT'==============================================='
	END CATCH
END;

EXEC silver.load_silver