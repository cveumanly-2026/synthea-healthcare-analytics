/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
Creates Bronze tables for the Synthea Healthcare Analytics project.
The Bronze layer stores approved synthetic EHR data ingested from CSV files.

Data Privacy:
An explicit column allowlist is applied before Bronze ingestion.
Unnecessary identifying fields are excluded before entering Bronze.
Silver handles data cleaning, standardization, and validation.

===============================================================================
*/
===============================================================================
*/

IF OBJECT_ID ('bronze.ehr_conditions' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_conditions;
CREATE TABLE bronze.ehr_conditions (
    start_dt    DATE            NULL,
    stop_dt     DATE            NULL,
    px_id       NVARCHAR(36)    NULL,
    encntr_id   NVARCHAR(36)    NULL,
    cond_code   NVARCHAR(50)    NULL,
    cond_desc   NVARCHAR(255)   NULL
);
GO

IF OBJECT_ID ('bronze.ehr_encounters' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_encounters;
CREATE TABLE bronze.ehr_encounters (
    encntr_id           NVARCHAR(36)    NULL,
    start_dt            DATETIME2       NULL,
    stop_dt             DATETIME2       NULL,
    px_id               NVARCHAR(36)    NULL,
    org_id              NVARCHAR(36)    NULL,
    provider_id         NVARCHAR(36)    NULL,
    payer_id            NVARCHAR(36)    NULL,
    encntr_class        NVARCHAR(50)    NULL,
    encntr_code         NVARCHAR(50)    NULL,
    encntr_desc         NVARCHAR(255)   NULL,
    base_encntr_cost    DECIMAL(18,2)   NULL,
    total_claim_cost    DECIMAL(18,2)   NULL,
    payer_coverage      DECIMAL(18,2)   NULL,
    reason_code         NVARCHAR(50)    NULL,
    reason_desc         NVARCHAR(255)   NULL
);
GO

IF OBJECT_ID ('bronze.ehr_medications' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_medications;
CREATE TABLE bronze.ehr_medications (
    start_dt        DATETIME2(0)    NULL,
    stop_dt         DATETIME2(0)    NULL,
    px_id           NVARCHAR(36)    NULL,
    payer_id        NVARCHAR(36)    NULL,
    encntr_id       NVARCHAR(36)    NULL,
    med_code        NVARCHAR(50)    NULL,
    med_desc        NVARCHAR(1000)  NULL,
    base_cost       DECIMAL(18,2)   NULL,
    payer_coverage  DECIMAL(18,2)   NULL,
    dispenses       INT             NULL,
    total_cost      DECIMAL(18,2)   NULL,
    reason_code     NVARCHAR(50)    NULL,
    reason_desc     NVARCHAR(500)   NULL
);
GO

IF OBJECT_ID ('bronze.ehr_procedures' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_procedures;
CREATE TABLE bronze.ehr_procedures (
    start_dt       DATETIME2(0)    NULL,
    stop_dt        DATETIME2(0)    NULL,
    px_id          NVARCHAR(36)    NULL,
    encntr_id      NVARCHAR(36)    NULL,
    proc_code      NVARCHAR(50)    NULL,
    proc_desc      NVARCHAR(1000)  NULL,
    base_cost      DECIMAL(18,2)   NULL,
    reason_code    NVARCHAR(50)    NULL,
    reason_desc    NVARCHAR(500)   NULL
);
GO

===============================================================================
HIPAA-Informed Patient Data Minimization
	This process creates a staging table (ehr_patients_old) containing the original 
	patient dataset, then removes selected direct identifiers and personal information. 
	A refined table (ehr_patients) is subsequently created with a reduced set of columns
	to minimize unnecessary exposure of sensitive patient information.

Note: This is a data-minimization step, not proof of HIPAA compliance. 
The remaining patient ID, birth/death dates, and geographic information may still 
constitute PHI. Further de-identification and validation are required before 
the dataset can be considered HIPAA-compliant.
===============================================================================

IF OBJECT_ID ('bronze.ehr_patients_old' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_patients_old;
CREATE TABLE bronze.ehr_patients_old ( -- Create the first patient table in bronze layer
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
GO 
TRUNCATE TABLE bronze.ehr_patients_old; -- Insert the original ehr.patient 
BULK INSERT bronze.ehr_patients_old
FROM 'C:\SyntheaTM\EHR\patients.csv'
WITH (
	FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO
ALTER TABLE bronze.ehr_patients_old -- Drop columns contain PHI
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
GO

-- Create the second provider table in bronze layer 
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
    county                NVARCHAR(100)  NULL,
    healthcare_expenses   NVARCHAR(50)   NULL,
    healthcare_coverage   NVARCHAR(50)   NULL
);

--------------------------------------------------------------

IF OBJECT_ID ('bronze.ehr_providers_old' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_providers_old;
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
GO
TRUNCATE TABLE bronze.ehr_providers_old
BULK INSERT bronze.ehr_providers_old -- Insert the original ehr.providers
FROM 'C:\SyntheaTM\EHR\providers.csv'
WITH (
	FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO
ALTER TABLE bronze.ehr_providers_old -- Drop columns contain PHI
DROP COLUMN
    provider_name,
    address,
    city,
    zip_code,
    latitude,
    longitude;
GO

-- Create the second provider table in bronze layer
IF OBJECT_ID ('bronze.ehr_providers' , 'U') IS NOT NULL 
	DROP TABLE bronze.ehr_providers;
CREATE TABLE bronze.ehr_providers (
    provider_id  NVARCHAR(36)  NULL,
	org_id       NVARCHAR(36)  NULL,
	gender       NVARCHAR(20)  NULL,
	specialty    NVARCHAR(100) NULL,
	state        NVARCHAR(100) NULL,
	utilization  INT           NULL
);


