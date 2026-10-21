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

IF OBJECT_ID ('bronze.ehr_patients' , 'U') IS NOT NULL -- HIPAA-informed data minimization
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

IF OBJECT_ID ('bronze.ehr_providers' , 'U') IS NOT NULL -- HIPAA-informed data minimization
	DROP TABLE bronze.ehr_providers;
CREATE TABLE bronze.ehr_providers (
    provider_id  NVARCHAR(36)  NULL,
	org_id       NVARCHAR(36)  NULL,
	gender       NVARCHAR(20)  NULL,
	specialty    NVARCHAR(100) NULL,
	state        NVARCHAR(100) NULL,
	utilization  INT           NULL
);
GO

