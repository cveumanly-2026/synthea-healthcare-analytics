/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' tables
===============================================================================
*/

IF OBJECT_ID ('silver.ehr_conditions' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_conditions;
GO
CREATE TABLE silver.ehr_conditions 
(
	start_dt DATE,
	stop_dt DATE,
	px_id NVARCHAR(36),
	encntr_id NVARCHAR(36), 
	cond_code NVARCHAR(50),
	cond_desc NVARCHAR(255),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_encounters' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_encounters;
GO
CREATE TABLE silver.ehr_encounters
(
    encntr_id NVARCHAR(36),
    start_dt DATETIME2(7),
    stop_dt DATETIME2(7),
    px_id NVARCHAR(36),
    org_id NVARCHAR(36),
    provider_id NVARCHAR(36),
    payer_id NVARCHAR(36),
    encntr_class NVARCHAR(50),
    encntr_code NVARCHAR(50),
    encntr_desc NVARCHAR(255),
    base_encntr_cost DECIMAL(18,2),
    total_claim_cost DECIMAL(18,2),
    payer_coverage DECIMAL(18,2),
    reason_code NVARCHAR(50),
    reason_desc NVARCHAR(255)
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_medications' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_medications;
GO
CREATE TABLE silver.ehr_medications
(
    start_dt DATETIME2(0),
    stop_dt DATETIME2(0),
    px_id NVARCHAR(36),
    payer_id NVARCHAR(36),
    encntr_id NVARCHAR(36),
    med_code NVARCHAR(50),
    med_desc NVARCHAR(1000),
    base_cost DECIMAL(18,2),
    payer_coverage DECIMAL(18,2),
    dispenses INT,
    total_cost DECIMAL(18,2),
    reason_code NVARCHAR(50),
    reason_desc NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_observations' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_observations;
GO
CREATE TABLE silver.ehr_observations
(
    obs_dt DATETIME2(0),
    px_id NVARCHAR(36),
    encntr_id NVARCHAR(36),
    category NVARCHAR(50),
    code NVARCHAR(50),
    obs_desc NVARCHAR(500),
    obs_value NVARCHAR(500),
    obs_value_numeric DECIMAL(18,4),
    units NVARCHAR(100),
    obs_type NVARCHAR(30),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_org' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_org;
GO
CREATE TABLE silver.ehr_org
(
    org_id NVARCHAR(36),
    name NVARCHAR(200),
    address NVARCHAR(250),
    city NVARCHAR(100),
    state NVARCHAR(2),
    zip NVARCHAR(10),
    lat DECIMAL(9,6),
    lon DECIMAL(9,6),
    phone NVARCHAR(50),
    revenue DECIMAL(18,2),
    utilization BIGINT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_patients' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_patients;
GO
CREATE TABLE silver.ehr_patients
(
    px_id NVARCHAR(36),
    birth_dt DATE,
    death_dt DATE,
    marital_status NVARCHAR(20),
    race NVARCHAR(50),
    ethnicity NVARCHAR(50),
    gender NVARCHAR(20),
    state NVARCHAR(100),
    healthcare_expenses DECIMAL(18,2),
    healthcare_coverage DECIMAL(18,2),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_procedures' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_procedures;
GO
CREATE TABLE silver.ehr_procedures
(
    start_dt DATETIME2(0),
    stop_dt DATETIME2(0),
    px_id NVARCHAR(36),
    encntr_id NVARCHAR(36),
    proc_code NVARCHAR(50),
    proc_desc NVARCHAR(1000),
    base_cost DECIMAL(18,2),
    reason_code NVARCHAR(50),
    reason_desc NVARCHAR(500),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID ('silver.ehr_providers' , 'U') IS NOT NULL
	DROP TABLE silver.ehr_providers;
GO
CREATE TABLE silver.ehr_providers
(
    provider_id NVARCHAR(36),
    org_id NVARCHAR(36),
    gender NVARCHAR(20),
    specialty NVARCHAR(100),
    state NVARCHAR(100),
    utilization INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);




