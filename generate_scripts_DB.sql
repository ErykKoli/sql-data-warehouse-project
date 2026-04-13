USE [master]
GO
/****** Object:  Database [DataWarehouse]    Script Date: 10.04.2026 14:42:40 ******/
CREATE DATABASE [DataWarehouse]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DataWarehouse', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\DataWarehouse.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DataWarehouse_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\DataWarehouse_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [DataWarehouse] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DataWarehouse].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DataWarehouse] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DataWarehouse] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DataWarehouse] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DataWarehouse] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DataWarehouse] SET ARITHABORT OFF 
GO
ALTER DATABASE [DataWarehouse] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [DataWarehouse] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DataWarehouse] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DataWarehouse] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DataWarehouse] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DataWarehouse] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DataWarehouse] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DataWarehouse] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DataWarehouse] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DataWarehouse] SET  ENABLE_BROKER 
GO
ALTER DATABASE [DataWarehouse] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DataWarehouse] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DataWarehouse] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DataWarehouse] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DataWarehouse] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DataWarehouse] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DataWarehouse] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DataWarehouse] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [DataWarehouse] SET  MULTI_USER 
GO
ALTER DATABASE [DataWarehouse] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DataWarehouse] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DataWarehouse] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DataWarehouse] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [DataWarehouse] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [DataWarehouse] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [DataWarehouse] SET QUERY_STORE = ON
GO
ALTER DATABASE [DataWarehouse] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [DataWarehouse]
GO
/****** Object:  Schema [bronze]    Script Date: 10.04.2026 14:42:40 ******/
CREATE SCHEMA [bronze]
GO
/****** Object:  Schema [gold]    Script Date: 10.04.2026 14:42:40 ******/
CREATE SCHEMA [gold]
GO
/****** Object:  Schema [silver]    Script Date: 10.04.2026 14:42:40 ******/
CREATE SCHEMA [silver]
GO
/****** Object:  Table [silver].[erp_loc_a101]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[erp_loc_a101](
	[cid] [nvarchar](50) NULL,
	[cntry] [nvarchar](50) NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [silver].[erp_cust_az12]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[erp_cust_az12](
	[cid] [nvarchar](50) NULL,
	[bdate] [date] NULL,
	[gen] [nvarchar](50) NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [silver].[crm_cust_info]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[crm_cust_info](
	[cst_id] [int] NULL,
	[cst_key] [nvarchar](50) NULL,
	[cst_firstname] [nvarchar](50) NULL,
	[cst_lastname] [nvarchar](50) NULL,
	[cst_material_status] [nvarchar](50) NULL,
	[cst_gndr] [nvarchar](50) NULL,
	[cst_create_date] [date] NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  View [gold].[dim_customers]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [gold].[dim_customers] as 
select
	row_number() over (order by cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_material_status marital_status,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr --CRM is master for gender info
		else coalesce(ca.gen, 'n/a')
	end as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
from silver.crm_cust_info as ci
left join silver.erp_cust_az12 as ca
on ci.cst_key = ca.cid
left join silver.erp_loc_a101 as la
on ci.cst_key = la.cid
GO
/****** Object:  Table [silver].[erp_px_cat_g1v2]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[erp_px_cat_g1v2](
	[id] [nvarchar](50) NULL,
	[cat] [nvarchar](50) NULL,
	[subcat] [nvarchar](50) NULL,
	[maintenance] [nvarchar](50) NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [silver].[crm_prd_info]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[crm_prd_info](
	[prd_id] [int] NULL,
	[cat_id] [nvarchar](50) NULL,
	[prd_key] [nvarchar](50) NULL,
	[prd_nm] [nvarchar](50) NULL,
	[prd_cost] [int] NULL,
	[prd_line] [nvarchar](50) NULL,
	[prd_start_dt] [date] NULL,
	[prd_end_dt] [date] NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  View [gold].[dim_products]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [gold].[dim_products] as
select 
    row_number() over (order by pn.prd_start_dt, pn.prd_key) as product_key,
    pn.prd_id       as product_id,
    pn.prd_key      as product_number,
    pn.prd_nm       as product_name,
    pn.cat_id       as category_id,
    pc.cat          as category,
    pc.subcat       as subcategory,
    pc.maintenance  as maintenance,
    pn.prd_cost     as cost,
    pn.prd_line     as product_line,
    pn.prd_start_dt as start_date
from silver.crm_prd_info as pn
left join silver.erp_px_cat_g1v2 as pc
on pn.cat_id = pc.id
where prd_end_dt is null -- filter out old data
GO
/****** Object:  Table [silver].[crm_sales_details]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [silver].[crm_sales_details](
	[sls_ord_num] [nvarchar](50) NULL,
	[sls_prd_key] [nvarchar](50) NULL,
	[sls_cust_id] [int] NULL,
	[sls_order_dt] [date] NULL,
	[sls_ship_dt] [date] NULL,
	[sls_due_dt] [date] NULL,
	[sls_sales] [int] NULL,
	[sls_quantity] [int] NULL,
	[sls_price] [int] NULL,
	[dwh_create_date] [datetime2](7) NULL
) ON [PRIMARY]
GO
/****** Object:  View [gold].[fact_sales]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [gold].[fact_sales] as
select
    sd.sls_ord_num  as order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt as order_date,
    sd.sls_ship_dt  as shipping_date,
    sd.sls_due_dt   as due_date,
    sd.sls_sales    as sales_amount,
    sd.sls_quantity as quantity,
    sd.sls_price    as price
from silver.crm_sales_details as sd
left join gold.dim_products as pr
on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu
on sd.sls_cust_id = cu.customer_id
GO
/****** Object:  Table [bronze].[crm_cust_info]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[crm_cust_info](
	[cst_id] [int] NULL,
	[cst_key] [nvarchar](50) NULL,
	[cst_firstname] [nvarchar](50) NULL,
	[cst_lastname] [nvarchar](50) NULL,
	[cst_material_status] [nvarchar](50) NULL,
	[cst_gndr] [nvarchar](50) NULL,
	[cst_create_date] [date] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [bronze].[crm_prd_info]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[crm_prd_info](
	[prd_id] [int] NULL,
	[prd_key] [nvarchar](50) NULL,
	[prd_nm] [nvarchar](50) NULL,
	[prd_cost] [int] NULL,
	[prd_line] [nvarchar](50) NULL,
	[prd_start_dt] [datetime] NULL,
	[prd_end_dt] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [bronze].[crm_sales_details]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[crm_sales_details](
	[sls_ord_num] [nvarchar](50) NULL,
	[sls_prd_key] [nvarchar](50) NULL,
	[sls_cust_id] [int] NULL,
	[sls_order_dt] [int] NULL,
	[sls_ship_dt] [int] NULL,
	[sls_due_dt] [int] NULL,
	[sls_sales] [int] NULL,
	[sls_quantity] [int] NULL,
	[sls_price] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [bronze].[erp_cust_az12]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[erp_cust_az12](
	[cid] [nvarchar](50) NULL,
	[bdate] [date] NULL,
	[gen] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [bronze].[erp_loc_a101]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[erp_loc_a101](
	[cid] [nvarchar](50) NULL,
	[cntry] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [bronze].[erp_px_cat_g1v2]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bronze].[erp_px_cat_g1v2](
	[id] [nvarchar](50) NULL,
	[cat] [nvarchar](50) NULL,
	[subcat] [nvarchar](50) NULL,
	[maintenance] [nvarchar](50) NULL
) ON [PRIMARY]
GO
ALTER TABLE [silver].[crm_cust_info] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
ALTER TABLE [silver].[crm_prd_info] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
ALTER TABLE [silver].[crm_sales_details] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
ALTER TABLE [silver].[erp_cust_az12] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
ALTER TABLE [silver].[erp_loc_a101] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
ALTER TABLE [silver].[erp_px_cat_g1v2] ADD  DEFAULT (getdate()) FOR [dwh_create_date]
GO
/****** Object:  StoredProcedure [bronze].[load_bronze]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create   procedure [bronze].[load_bronze] as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time DATETIME, @batch_end_time DATETIME;
	begin try
		SET @batch_start_time = GETDATE();
		print'==================================================';
		print 'Loading Bronze Layer';
		print'==================================================';

		print '-----------------------------------';
		print 'Loading CRM Tables';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.crm_cust_info'
		truncate table bronze.crm_cust_info

		print '>> Inserting Data Into: bronze.crm_cust_info'
		bulk insert bronze.crm_cust_info
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.crm_prd_info'
		truncate table bronze.crm_prd_info

		print '>> Inserting Data Into: bronze.crm_prd_info'
		bulk insert bronze.crm_prd_info
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.crm_sales_details'
		truncate table bronze.crm_sales_details

		print '>> Inserting Data Into: bronze.crm_sales_details'
		bulk insert bronze.crm_sales_details
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '-----------------------------------';

		print '-----------------------------------';
		print 'Loading ERP Tables';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.erp_cust_az12'
		truncate table bronze.erp_cust_az12

		print '>> Inserting Data Into: bronze.erp_cust_az12'
		bulk insert bronze.erp_cust_az12
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.erp_loc_a101'
		truncate table bronze.erp_loc_a101

		print '>> Inserting Data Into: bronze.erp_loc_a101'
		bulk insert bronze.erp_loc_a101
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '-----------------------------------';

		SET @start_time = getdate();
		print '>> Truncating Table: bronze.erp_px_cat_g1v2'
		truncate table bronze.erp_px_cat_g1v2

		print '>> Inserting Data Into: bronze.erp_px_cat_g1v2'
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\Eryk\Desktop\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @end_time = getdate();
		print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='

	end try
	begin catch
		print '=============================';
		print 'ERROR IN CODE DURING LOADING BRONZE LAYER';
		print 'Error Message' + ERROR_MESSAGE();
		print 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		print 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		print '=============================';
	end catch
end
GO
/****** Object:  StoredProcedure [silver].[load_silver]    Script Date: 10.04.2026 14:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create   procedure [silver].[load_silver] as 
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
GO
USE [master]
GO
ALTER DATABASE [DataWarehouse] SET  READ_WRITE 
GO
