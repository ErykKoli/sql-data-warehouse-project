

create or alter procedure silver.load_silver as 
begin
	print '>> truncating table silver.crm_cust_info'
	truncate table silver.crm_cust_info
	print '>> inserting data into silver.crm_cust_info'
	insert into silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_material_status,
	cst_gndr,
	cst_create_date)

	select
	cst_id,
	cst_key,
	trim(cst_firstname) as cst_firstname, -- removing spaces
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_material_status)) = 'S' then 'Single' -- making marital status readable
		when upper(trim(cst_material_status)) = 'M' then 'Married'
		else 'n/a'
	end cst_material_status,
	case when upper(trim(cst_gndr)) = 'F' then 'female' -- making gender status readable
		when upper(trim(cst_gndr)) = 'M' then 'male'
		else 'n/a'
	end cst_gndr,
	cst_create_date
	from(
	select
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id order by cst_create_date desc) as flag_last 
	from bronze.crm_cust_info
	where cst_id is not null
	)t 
	where flag_last = 1 -- selecting most recent record per customer

	print '>> truncating table silver.crm_prd_info'
	truncate table silver.crm_prd_info
	print '>> inserting data into silver.crm_prd_info'

	insert into silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select
	prd_id,
	replace(substring(prd_key, 1, 5), '-', '_') as cat_id, --extract category id
	substring(prd_key, 7, len(prd_key)) as prd_key, --extract product key
	prd_nm,
	isnull(prd_cost, 0) as prd_cost,
	case upper(trim(prd_line))
		 when 'M' then 'Mountain'
		 when 'R' then 'Road'
		 when 'S' then 'Other Sales'
		 when 'T' then 'Touring'
		 else 'n/a'
	end as prd_line, --map product line codes to descriptive values
	cast (prd_start_dt as date) as prd_start_dt,
	cast(
		lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 
		as date
	) as prd_end_dt -- calculate end date as one day before the next start date
	from bronze.crm_prd_info

	print '>> truncating table silver.crm_sales_details'
	truncate table silver.crm_sales_details
	print '>> inserting data into silver.crm_sales_details'

	insert into silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	select
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null -- changing dates
		 else cast(cast(sls_order_dt as varchar) as date)
	end as sls_order_dt,
	case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null -- changing dates
		 else cast(cast(sls_ship_dt as varchar) as date)
	end as sls_ship_dt,
	case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null -- changing dates
		 else cast(cast(sls_due_dt as varchar) as date)
	end as sls_due_dt,
	CASE 
					WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
						THEN sls_quantity * ABS(sls_price)
					ELSE sls_sales
				END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
				sls_quantity,
				CASE 
					WHEN sls_price IS NULL OR sls_price <= 0 
						THEN sls_sales / NULLIF(sls_quantity, 0)
					ELSE sls_price  -- Derive price if original value is invalid
				END AS sls_price
	from bronze.crm_sales_details

	print '>> truncating table silver.erp_cust_az12'
	truncate table silver.erp_cust_az12
	print '>> inserting data into silver.erp_cust_az12'

	insert into silver.erp_cust_az12 (cid, bdate, gen)
	select
	case when cid like 'NAS%' then substring(cid, 4, len(cid)) -- remove NAS prefix
		else cid
	end as cid,
	case when bdate > getdate() then null
		else bdate
	end as bdate, -- set future birthdates to null
	case when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
		 when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		 else 'n/a'
	end as gen -- normalize gender values and handle unknown
	from bronze.erp_cust_az12

	print '>> truncating table silver.erp_loc_a101'
	truncate table silver.erp_loc_a101
	print '>> inserting data into silver.erp_loc_a101'

	insert into silver.erp_loc_a101
	(cid, cntry)
	select
	replace(cid, '-', '') cid,
	case when trim(cntry) = 'DE' then 'Germany'
		 when trim(cntry) in ('US', 'USA') then 'United States'
		 when trim(cntry) = '' or cntry is null then 'n/a'
		 else trim(cntry)
	end as cntry -- normalize countries
	from bronze.erp_loc_a101

	print '>> truncating table silver.erp_px_cat_g1v2'
	truncate table silver.erp_px_cat_g1v2
	print '>> inserting data into silver.erp_px_cat_g1v2'

	insert into silver.erp_px_cat_g1v2
	(id, cat, subcat, maintenance)
	select
	id,
	cat,
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2
end
