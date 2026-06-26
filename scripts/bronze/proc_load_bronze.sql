EXEC bronze.load_bronze


-------------------------------------------------------
--Store Proceduer : Load Bronze Layer (SOurce > Bronze)
-------------------------------------------------------

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

	DECLARE @start_time DATETIME,@end_time DATETIME, @batch_start_time DATETIME , @batch_end_time DATETIME;
	BEGIN TRY
		PRINT '======================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '======================================================';
	
		PRINT'---------------------------------------------------------';
		PRINT'Loading CRM Tables';
		PRINT'---------------------------------------------------------';

		SET @batch_start_time=GETDATE();
		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_crm\cust_info.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		SET @end_time=GETDATE();
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';

		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_crm\prd_info.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';

		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_crm\sales_details.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		PRINT'---------------------------------------------------------';
		PRINT'Loading CRM Tables';
		PRINT'----------------------------------------------------------';

		
		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_erp\CUST_AZ12.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';


		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_ERP\loc_a101.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';

		SET @start_time=GETDATE();
		PRINT'>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT'>>Inserting Data Into :bronze.crm_cust_info';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\smitd\Desktop\Projects\datasets\source_ERP\px_cat_g1v2.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
			);
		PRINT'>> Loding duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
		PRINT'--------------------';

		SET @batch_end_time=GETDATE();
		PRINT'===============================================';
		PRINT'Loding Bronze Layer is completed.';
		PRINT'- Total Load Duration:'+ CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'Seconds'; 
		PRINT'===============================================';
	END TRY
	BEGIN CATCH
		PRINT'==============================================='
		PRINT'ERROR OCCURE DURING LOADING BRONZE LAYER'
		PRINT'Error Message : '  + CAST(ERROR_MESSAGE() AS NVARCHAR)
		PRINT'Error State : ' + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT'==============================================='
	END CATCH
END;