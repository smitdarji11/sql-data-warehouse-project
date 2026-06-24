
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
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE UPPER(TRIM(cst_material_status))
	WHEN 'S' THEN 'Single'
	WHEN 'M' THEN 'Married'
	ELSE 'N/A'
	END AS cst_material_status,
	CASE UPPER(TRIM(cst_gndr))
	WHEN 'F' THEN 'Female'
	WHEN 'M' THEN 'Male'
	ELSE 'N/A'
	END AS cst_gndr,
	cst_create_date
FROM
(SELECT *,
	RANK() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS last_flag
FROM bronze.crm_cust_info
WHERE cst_id IS Not NULL) t
WHERE last_flag=1;