/*
===============================================================================
Stored Procedure: Load Bronze Layer (Staging Ingestion)
===============================================================================
Script Purpose:
    This stored procedure automates the ETL/Ingestion process for the Bronze layer.
    It truncates (empties) existing staging tables and bulk-loads raw data from 
    external CSV files (CRM and ERP source domains).

Features:
    - Truncate and load strategy for repeatable batch ingestion.
    - Column allowlisting before Bronze ingestion to exclude unnecessary
      identifying information.
    - Session tracking for individual table and total batch load duration.
    - TRY...CATCH error handling for ingestion failures.

Data Privacy:
    Applies HIPAA-informed data minimization principles.
    Only approved columns enter Bronze. This project uses synthetic data
    and does not claim formal HIPAA compliance.

Usage:
    EXEC bronze.load_bronze;
===============================================================================
*/   

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    -- Declare variables for tracking step duration and absolute batch time
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    
    BEGIN TRY
        -- Capture baseline starting timestamp for the entire batch
        SET @batch_start_time = GETDATE();
        
        PRINT '======================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '======================================================';

        PRINT '------------------------------------------------------';
        PRINT 'Loading EHR Tables';
        PRINT '------------------------------------------------------';

        -- 1. bronze.ehr_conditions Table Processing
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.ehr_conditions'; 
        TRUNCATE TABLE bronze.ehr_conditions;
   
        PRINT '>> Inserting Data Into: bronze.ehr_conditions'; 
        BULK INSERT bronze.ehr_conditions
        FROM 'C:\SyntheaTM\EHR\conditions.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            FIELDQUOTE = '"',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 

        -- 2. bronze.ehr_encounters Table Processing
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.ehr_encounters'; 
        TRUNCATE TABLE bronze.ehr_encounters;  
    
        PRINT '>> Inserting Data Into: bronze.ehr_encounters'; 
        BULK INSERT bronze.ehr_encounters 
        FROM 'C:\SyntheaTM\EHR\encounters.csv'
        WITH 
        (
	        FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            FIELDQUOTE = '"',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 

        -- 3. bronze.ehr_medications Table Processing
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.ehr_medications'; 
        TRUNCATE TABLE bronze.ehr_medications;

        PRINT '>> Inserting Data Into: bronze.ehr_medications';
        BULK INSERT bronze.ehr_medications
        FROM 'C:\SyntheaTM\EHR\medications.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            FIELDQUOTE = '"',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'; 

 		-- 4. bronze.ehr_procedures Table Processing
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.ehr_procedures'; 
        TRUNCATE TABLE bronze.ehr_procedures;

        PRINT '>> Inserting Data Into: bronze.ehr_procedures';
        BULK INSERT bronze.ehr_procedures
        FROM 'C:\SyntheaTM\EHR\procedures.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            FIELDQUOTE = '"',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

       	-- 5. bronze.ehr_patients_old Table Processing
        SET @start_time = GETDATE();
		-- Create first patients table to load the original csv data
        IF OBJECT_ID ('bronze.ehr_patients_old' , 'U') IS NOT NULL
			DROP TABLE bronze.ehr_patients_old;
		CREATE TABLE bronze.ehr_patients_old ( 
		    px_id                 NVARCHAR(36)   NULL,
		    birth_dt              NVARCHAR(30)   NULL,
		    death_dt              NVARCHAR(30)   NULL,
		    ssn                   NVARCHAR(20)   NULL,
		    drivers               NVARCHAR(50)   NULL,
		    passport              NVARCHAR(50)   NULL,
		    name_prefix           NVARCHAR(20)   NULL,
		    first_name            NVARCHAR(100)  NULL,
		    last_name             NVARCHAR(100)  NULL,
		    name_suffix           NVARCHAR(20)   NULL,
		    maiden_name           NVARCHAR(100)  NULL,
		    marital_status        NVARCHAR(20)   NULL,
		    race                  NVARCHAR(50)   NULL,
		    ethnicity             NVARCHAR(50)   NULL,
		    gender                NVARCHAR(20)   NULL,
		    birthplace            NVARCHAR(255)  NULL,
		    address               NVARCHAR(255)  NULL,
		    city                  NVARCHAR(100)  NULL,
		    state                 NVARCHAR(100)  NULL,
		    county                NVARCHAR(100)  NULL,
		    zip_code              NVARCHAR(20)   NULL,
		    latitude              NVARCHAR(50)   NULL,
		    longitude             NVARCHAR(50)   NULL,
		    healthcare_expenses   NVARCHAR(50)   NULL,
		    healthcare_coverage   NVARCHAR(50)   NULL
		);
		
		PRINT '>> Truncating Table: bronze.ehr_patients_old'; 
        TRUNCATE TABLE bronze.ehr_patients_old;

        PRINT '>> Inserting Data Into: bronze.ehr_patients_old';
        BULK INSERT bronze.ehr_patients_old
        FROM 'C:\SyntheaTM\EHR\patients.csv'
        WITH (
            DATAFILETYPE = 'char',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
        );
        
        -- Remove selected PHI-related columns
        ALTER TABLE bronze.ehr_patients_old
        DROP COLUMN
            ssn,
            drivers,
            passport,
            name_prefix,
            first_name,
            last_name,
            name_suffix,
            maiden_name,
            birthplace,
            address,
            city,
            county,
            zip_code,
            latitude,
            longitude;

		-- Create second patients table that follows HIPAA regulations
		IF OBJECT_ID ('bronze.ehr_patients' , 'U') IS NOT NULL 
			DROP TABLE bronze.ehr_patients;
		CREATE TABLE bronze.ehr_patients
		(
		    px_id                 NVARCHAR(36)   NULL,
		    birth_dt              NVARCHAR(30)   NULL,
		    death_dt              NVARCHAR(30)   NULL,
		    marital_status        NVARCHAR(20)   NULL,
		    race                  NVARCHAR(50)   NULL,
		    ethnicity             NVARCHAR(50)   NULL,
		    gender                NVARCHAR(20)   NULL,
		    state                 NVARCHAR(100)  NULL,
		    healthcare_expenses   NVARCHAR(50)   NULL,
		    healthcare_coverage   NVARCHAR(50)   NULL
		);
        -- Transfer data into the second table
        INSERT INTO bronze.ehr_patients (
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
			birth_dt,
    		death_dt,
            marital_status,
            race,
            ethnicity,
            gender,
            state,
            TRY_CONVERT(DECIMAL(18,2), healthcare_expenses),
            TRY_CONVERT(DECIMAL(18,2), healthcare_coverage)
        FROM bronze.ehr_patients_old;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 6. bronze.ehr_providers_old Table Processing
		SET @start_time = GETDATE();
		IF OBJECT_ID ('bronze.ehr_providers_old' , 'U') IS NOT NULL
		    DROP TABLE IF EXISTS bronze.ehr_providers_old;
		CREATE TABLE bronze.ehr_providers_old ( -- Create the first provider table in bronze layer
		    provider_id   NVARCHAR(36)   NULL,
		    org_id        NVARCHAR(36)   NULL,
		    provider_name NVARCHAR(255)  NULL,
		    gender        NVARCHAR(20)   NULL,
		    specialty     NVARCHAR(100)  NULL,
		    address       NVARCHAR(255)  NULL,
		    city          NVARCHAR(100)  NULL,
		    state         NVARCHAR(100)  NULL,
		    zip_code      NVARCHAR(20)   NULL,
		    latitude      DECIMAL(10,7)  NULL,
		    longitude     DECIMAL(11,7)  NULL,
		    utilization   INT            NULL
		    );
		
		PRINT '>> Truncating Table: bronze.ehr_providers_old'; 
		TRUNCATE TABLE bronze.ehr_providers_old;
		
		PRINT '>> Inserting Data Into: bronze.ehr_providers_old';
		BULK INSERT bronze.ehr_providers_old
		FROM 'C:\SyntheaTM\EHR\providers.csv'
	    WITH (
            DATAFILETYPE = 'char',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            CODEPAGE = '65001',
            TABLOCK
         );
		
		-- Remove selected PHI-related columns
		ALTER TABLE bronze.ehr_providers_old
		DROP COLUMN
		    provider_name,
		    address,
		    city,
		    zip_code,
		    latitude,
		    longitude;
		
		-- Transfer data into the second table
		INSERT INTO bronze.ehr_providers (
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
		    gender,
		    specialty,
		    state,
		    utilization
		FROM bronze.ehr_providers_old;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 7. bronze.ehr_org Table Processing
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_org'; 
		TRUNCATE TABLE bronze.ehr_org;
		
		PRINT '>> Inserting Data Into: bronze.ehr_org';
		BULK INSERT bronze.ehr_org
		FROM 'C:\SyntheaTM\EHR\organizations.csv'
		WITH
		(
		    FORMAT = 'CSV',
		    FIRSTROW = 2,
		    FIELDTERMINATOR = ',',
		    FIELDQUOTE = '"',
		    ROWTERMINATOR = '0x0a',
		    CODEPAGE = '65001',
		    TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 8. bronze.ehr_claims Table Processing 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_claims'; 
		TRUNCATE TABLE bronze.ehr_claims;
		
		PRINT '>> Inserting Data Into: bronze.ehr_claims';
		BULK INSERT bronze.ehr_claims
		FROM 'C:\SyntheaTM\EHR\claims.csv'
		WITH (
		    DATAFILETYPE = 'char',
		    FIELDTERMINATOR = ',',
		    ROWTERMINATOR = '0x0a',
		    FIRSTROW = 2,
		    CODEPAGE = '65001',
		    TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 9. bronze.ehr_claims_trans Table Processing 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_claims_trans'; 
		TRUNCATE TABLE bronze.ehr_claims_trans;
		
		PRINT '>> Inserting Data Into: bronze.ehr_claims_trans';
		BULK INSERT bronze.ehr_claims_trans
		FROM 'C:\SyntheaTM\EHR\claims_transactions.csv'
		WITH (
		    DATAFILETYPE = 'char',
		    FIELDTERMINATOR = ',',
		    ROWTERMINATOR = '0x0a',
		    FIRSTROW = 2,
		    CODEPAGE = '65001',
		    TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 10. bronze.ehr_payer_trans Table Processing 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_payer_trans'; 
		TRUNCATE TABLE bronze.ehr_payer_trans;
				
		PRINT '>> Inserting Data Into: bronze.ehr_payer_trans';
		BULK INSERT bronze.ehr_payer_trans
		FROM 'C:\SyntheaTM\EHR\payer_transitions.csv'
		WITH (
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			FIRSTROW = 2,
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))

		-- 11. bronze.ehr_observations Table Processing 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_observations'; 
		TRUNCATE TABLE bronze.ehr_observations;
						
		PRINT '>> Inserting Data Into: bronze.ehr_observations';
		BULK INSERT bronze.ehr_observations
		FROM 'C:\SyntheaTM\EHR\observations.csv'
		WITH (
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			FIRSTROW = 2,
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))
			
		-- 12. bronze.ehr_payers Table Processing 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ehr_payers'; 
		TRUNCATE TABLE bronze.ehr_payers;
				
		PRINT '>> Inserting Data Into: bronze.ehr_payers';
		BULK INSERT bronze.ehr_payers
		FROM 'C:\SyntheaTM\EHR\payers.csv'
		WITH (
			DATAFILETYPE = 'char',
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			FIRSTROW = 2,
			CODEPAGE = '65001',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10))
        PRINT '>> -------------';

        -- Calculate absolute batch end runtime metrics
        SET @batch_end_time = GETDATE();
        PRINT '======================================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time, @batch_end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '======================================================';

    END TRY
    BEGIN CATCH
        -- Capture and log structural execution failures safely without breaking terminal state
        PRINT '======================================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: '  + CAST (ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State: '   + CAST (ERROR_STATE() AS NVARCHAR(10));
        PRINT '======================================================';
    END CATCH
END;
