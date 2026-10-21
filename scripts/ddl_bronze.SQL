/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    Creates Bronze tables for the Synthea Healthcare Analytics project
    to store synthetic EHR data from CSV files, including raw and
    privacy-filtered tables.

Source data includes fields that resemble HIPAA-defined identifiers.
    These fields will be assessed and filtered during Silver-layer
    transformation to remove unnecessary identifying information.
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

IF OBJECT_ID ('bronze.ehr_patients_old' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_patients_old;
CREATE TABLE bronze.ehr_patients_old (
    px_id                 NVARCHAR(36)    NULL,
    birth_dt              DATE            NULL,
    death_dt              DATE            NULL,
    ssn                   NVARCHAR(50)    NULL,
    drivers               NVARCHAR(50)    NULL,
    passport              NVARCHAR(50)    NULL,
    name_prefix           NVARCHAR(50)    NULL,
    first_name            NVARCHAR(100)   NULL,
    last_name             NVARCHAR(100)   NULL,
    name_suffix           NVARCHAR(50)    NULL,
    maiden_name           NVARCHAR(100)   NULL,
    marital_status        NVARCHAR(20)    NULL,
    race                  NVARCHAR(50)    NULL,
    ethnicity             NVARCHAR(50)    NULL,
    gender                NVARCHAR(20)    NULL,
    birthplace             NVARCHAR(255)  NULL,
    address               NVARCHAR(255)   NULL,
    city                  NVARCHAR(100)   NULL,
    state                 NVARCHAR(100)   NULL,
    county                NVARCHAR(100)   NULL,
    zip_code              NVARCHAR(20)    NULL,
    latitude              DECIMAL(10,7)   NULL,
    longitude             DECIMAL(11,7)   NULL,
    healthcare_expenses   DECIMAL(18,2)   NULL,
    healthcare_coverage   DECIMAL(18,2)   NULL
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

IF OBJECT_ID ('bronze.ehr_providers_old' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_providers_old;
CREATE TABLE bronze.ehr_providers_old (
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

