/*
===============================================================================
Stored Procedure: Load Silver Layer (Synthea EHR Data)
===============================================================================
Script Purpose:
    Loads cleaned and transformed Synthea healthcare data from Bronze
    (Raw) into Silver (Cleaned and Standardized) for clinical and
    operational analytics.

Actions Performed:
    - Truncates Silver tables.
    - Removes exact duplicate records.
    - Standardizes column names and data types.
    - Converts numeric observation values to DECIMAL(18,4).
    - Preserves text observations, NULL values, and original UNITS.
    - Inserts transformed data into Silver tables.

Parameters:
    None.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 
	-- Declare variables for tracking step duration and absolute batch time
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		-- Capture baseline starting timestamp for the entire batch
        SET @batch_start_time = GETDATE();
        
        PRINT '======================================================';
        PRINT 'Loading Silver Layer';
        PRINT '======================================================';

        PRINT '------------------------------------------------------';
        PRINT 'Loading EHR Tables';
        PRINT '------------------------------------------------------'; 

		-- 1. Loading silver.ehr_conditions 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_conditions';
		TRUNCATE TABLE silver.ehr_conditions;

		PRINT '>> Inserting Data Into: silver.ehr_conditions';
		INSERT INTO silver.ehr_conditions (
			start_dt,
			stop_dt,
			px_id,
			encntr_id, 
			cond_code,
			cond_desc
		)
		SELECT 
			CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' THEN NULL ELSE start_dt
			END AS start_dt,
			CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01' THEN NULL ELSE stop_dt
			END AS stop_dt,
			px_id,
			encntr_id,
			cond_code,
			cond_desc
		FROM bronze.ehr_conditions;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 
		PRINT '>> -------------'

		-- 2. Loading silver.ehr_encounters 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_encounters ';
		TRUNCATE TABLE silver.ehr_encounters;

		PRINT '>> Inserting Data Into: silver.ehr_encounters';
		INSERT INTO silver.ehr_encounters  
		(
			encntr_id,
			start_dt,
			stop_dt,
			px_id,
			org_id,
			provider_id,
			payer_id,
			encntr_class,
			encntr_code,
			encntr_desc,
			base_encntr_cost,
			total_claim_cost,
			payer_coverage,
			reason_code,
			reason_desc
		)
		SELECT 
			encntr_id,
			CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' -- Standardize encounter dates
				THEN NULL ELSE CAST(start_dt AS DATETIME2(0))
			END AS start_dt, 
			CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01'
				THEN NULL ELSE CAST(stop_dt AS DATETIME2(0))
			END AS stop_dt,
			px_id,
			org_id,
			provider_id,
			payer_id,
			encntr_class,
			CASE WHEN encntr_code = '1853470'  
				 AND encntr_class = 'ambulatory' 
				 AND encntr_desc = 'Encounter for problem (procedure)'
				 THEN '185347001' ELSE encntr_code
			END AS encntr_code,
			TRIM(REPLACE(encntr_desc, '(procedure)', '')) AS encntr_desc, 
			base_encntr_cost,
			total_claim_cost,
			payer_coverage,
			CASE WHEN reason_code IS NULL THEN 'N/A' ELSE reason_code  
			END AS reason_code, 
			CASE WHEN reason_desc IS NULL THEN 'N/A' ELSE reason_desc 
			END AS reason_desc
		FROM bronze.ehr_encounters;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 
		PRINT '>> -------------'

		-- 3. Loading silver.ehr_medications 
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_medications';
		TRUNCATE TABLE silver.ehr_medications;

		PRINT '>> Inserting Data Into: silver.ehr_medications';
		INSERT INTO silver.ehr_medications 
		(
			start_dt,
			stop_dt,
			px_id,
			payer_id,
			encntr_id,
			med_code,
			med_desc,
			base_cost,
			payer_coverage,
			dispenses,
			total_cost,
			reason_code,
			reason_desc
		)
		SELECT 
			start_dt,
			stop_dt,        
			px_id,
			payer_id,
			encntr_id,
			med_code,
			med_desc,
			base_cost,
			payer_coverage,
			dispenses,
			total_cost,
			CASE WHEN reason_code IS NULL THEN 'N/A' ELSE reason_code 
			END AS reason_code,
			CASE WHEN reason_desc IS NULL THEN 'N/A' ELSE reason_desc
			END AS reason_desc
		FROM 
		(	SELECT DISTINCT * 
			FROM bronze.ehr_medications
			WHERE px_id IS NOT NULL
		) AS t;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 
		
		-- 4. Loading silver.ehr_observations
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_observations';
		TRUNCATE TABLE silver.ehr_observations;
		PRINT '>> Inserting Data Into: silver.ehr_observations';
		INSERT INTO silver.ehr_observations 
		(
			obs_dt,
			px_id,
			encntr_id,
			category,
			code,
			obs_desc,
			obs_value,
			obs_value_numeric,
			units,
			obs_type
		)
		SELECT
			[DATE],
			PATIENT,
			ENCOUNTER,
			CATEGORY,
			CODE,
			[DESCRIPTION],
			[VALUE],
			CASE WHEN [TYPE] = 'numeric' THEN TRY_CONVERT(DECIMAL(18,4), TRIM(VALUE)) ELSE NULL
			END AS VALUE_NUMERIC,
			UNITS,
			[TYPE]
		FROM
		(
			SELECT 
				*,
				ROW_NUMBER() OVER (PARTITION BY [DATE], PATIENT, ENCOUNTER, CATEGORY, CODE, [DESCRIPTION], [VALUE], UNITS, [TYPE]
				ORDER BY (SELECT NULL)) AS row_num
			FROM bronze.ehr_observations
		) AS ranked_observations
		WHERE row_num = 1; 
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 
		PRINT '>> -------------'

		-- 5. Loading silver.ehr_org 
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_org';
		TRUNCATE TABLE silver.ehr_org;
		
		PRINT '>> Inserting Data Into: silver.ehr_org';
		INSERT INTO silver.ehr_org 
		(
			org_id,
			name,
			address,
			city,
			state,
			zip,
			lat,
			lon,
			phone,
			revenue,
			utilization
		)
		SELECT
			Id,
			NAME,
			ADDRESS,
			CITY,
			STATE,
			ZIP,
			LAT,
			LON,
			PHONE,
			REVENUE,
			UTILIZATION
		FROM bronze.ehr_org;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';  
		PRINT '>> -------------'

		-- 6. Loading silver.ehr_patients
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_patients';
		TRUNCATE TABLE silver.ehr_patients;

		PRINT '>> Inserting Data Into: silver.ehr_patients';
		INSERT INTO silver.ehr_patients
		(
			px_id,
			birth_dt,
			death_dt,
			marital_status,
			race,
			ethnicity,
			gender,
			state,
			healthcare_expenses,
			healthcare_coverage
		)
		SELECT 
			px_id,
			TRY_CONVERT(DATE, birth_dt) AS birth_dt,
			TRY_CONVERT(DATE, death_dt) AS death_dt,
			CASE WHEN marital_status = 'M' THEN 'Married'
				 WHEN marital_status ='S' THEN 'Single'
				 WHEN marital_status IS NULL THEN 'N/A'
				 ELSE marital_status
			END AS marital_status,
			race,
			ethnicity,
			CASE WHEN gender = 'M' THEN 'Male'
				 WHEN gender ='F' THEN 'Female'
				 WHEN gender IS NULL THEN 'N/A'
				 ELSE gender
			END AS gender,
			state,
			healthcare_expenses,
			healthcare_coverage   
		FROM bronze.ehr_patients;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';  
		PRINT '>> -------------'

		-- 7. Loading silver.ehr_procedures
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_procedures';
		TRUNCATE TABLE silver.ehr_procedures;

		PRINT '>> Inserting Data Into: silver.ehr_procedures';
		INSERT INTO silver.ehr_procedures
		(
			start_dt,
			stop_dt,
			px_id,
			encntr_id,
			proc_code,
			proc_desc,
			base_cost,
			reason_code,
			reason_desc
		)
		SELECT
			start_dt,
			stop_dt,
			px_id,
			encntr_id,
			proc_code,
			proc_desc,
			base_cost,
			CASE WHEN reason_code IS NULL THEN 'N/A' ELSE reason_code 
			END AS reason_code,
			CASE WHEN reason_desc IS NULL THEN 'N/A' ELSE reason_desc
			END AS reason_desc
		FROM 
			(SELECT DISTINCT *
			FROM bronze.ehr_procedures
			WHERE px_id IS NOT NULL
			) AS t;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';  
		PRINT '>> -------------'

		-- 8. Loading silver.ehr_providers
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ehr_providers';
		TRUNCATE TABLE silver.ehr_providers;

		PRINT '>> Inserting Data Into: silver.ehr_providers';
		INSERT INTO silver.ehr_providers
		(
			provider_id,
			org_id,
			gender,
			specialty,
			state,
			utilization
		)
		SELECT 
			provider_id,
			org_id,
			CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE gender 
			END AS gender,
			specialty,
			state,
			utilization
		FROM bronze.ehr_providers;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';  
		PRINT '>> -------------'

		SET @batch_end_time = GETDATE();
        PRINT '======================================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time, @batch_end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '======================================================';

    END TRY
    BEGIN CATCH
        -- Capture and log structural execution failures safely without breaking terminal state
        PRINT '======================================================'
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: '  + CAST (ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State: '   + CAST (ERROR_STATE() AS NVARCHAR(10));
        PRINT '======================================================';
			
		THROW;
    END CATCH
END;
