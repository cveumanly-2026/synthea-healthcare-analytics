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
Edit dulu ini yang dibawah:::
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
        PRINT '>> Truncating Table: bronze.ehr_patients_old'; 
        TRUNCATE TABLE bronze.ehr_patients_old;

        PRINT '>> Inserting Data Into: bronze.ehr_patients_old';
        BULK INSERT bronze.ehr_patients_old
        FROM 'C:\SyntheaTM\EHR\patients.csv'
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
        SELECT * FROM bronze.ehr_patients_old

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

        -- Transfer data into the second table
        INSERT INTO bronze.ehr_patients (
            px_id,
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
