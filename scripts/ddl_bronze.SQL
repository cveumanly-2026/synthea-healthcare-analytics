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
	DROP TABLE IF EXISTS bronze.ehr_conditions;
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
	DROP TABLE IF EXISTS bronze.ehr_encounters;
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
	DROP TABLE IF EXISTS bronze.ehr_medications;
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
	DROP TABLE IF EXISTS bronze.ehr_procedures;
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

-- Create the first patients table in bronze layer
IF OBJECT_ID ('bronze.ehr_patients_old' , 'U') IS NOT NULL
	DROP TABLE IF EXISTS bronze.ehr_patients_old;
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
GO 

-- Create the second patients table in bronze layer 
IF OBJECT_ID ('bronze.ehr_patients' , 'U') IS NOT NULL 
	DROP TABLE IF EXISTS bronze.ehr_patients;
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
GO

-- Create the first providers table in bronze layer
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
GO

-- Create the second providers table in bronze layer
IF OBJECT_ID ('bronze.ehr_providers' , 'U') IS NOT NULL 
	DROP TABLE IF EXISTS bronze.ehr_providers;
CREATE TABLE bronze.ehr_providers (
    provider_id  NVARCHAR(36)  NULL,
	org_id       NVARCHAR(36)  NULL,
	gender       NVARCHAR(20)  NULL,
	specialty    NVARCHAR(100) NULL,
	state        NVARCHAR(100) NULL,
	utilization  INT           NULL
);

IF OBJECT_ID ('bronze.ehr_org' , 'U') IS NOT NULL
	DROP TABLE IF EXISTS bronze.ehr_org;
CREATE TABLE bronze.ehr_org (
    Id          VARCHAR(36)    NULL,
    NAME        VARCHAR(200)   NULL,
    ADDRESS     VARCHAR(250)   NULL,
    CITY        VARCHAR(100)   NULL,
    STATE       VARCHAR(2)     NULL,
    ZIP         VARCHAR(10)    NULL,
    LAT         DECIMAL(9,6)   NULL,
    LON         DECIMAL(9,6)   NULL,
    PHONE       VARCHAR(50)    NULL,
    REVENUE     DECIMAL(18,2)  NULL,
    UTILIZATION BIGINT         NULL
);
GO

IF OBJECT_ID ('bronze.ehr_claims' , 'U') IS NOT NULL
	DROP TABLE IF EXISTS bronze.ehr_claims;
CREATE TABLE bronze.ehr_claims (
    Id                          VARCHAR(36)   NULL,
    PATIENTID                   VARCHAR(36)   NULL,
    PROVIDERID                  VARCHAR(36)   NULL,
    PRIMARYPATIENTINSURANCEID   VARCHAR(36)   NULL,
    SECONDARYPATIENTINSURANCEID VARCHAR(36)   NULL,
    DEPARTMENTID                VARCHAR(36)   NULL,
    PATIENTDEPARTMENTID         VARCHAR(36)   NULL,
    DIAGNOSIS1                  VARCHAR(36)   NULL,
    DIAGNOSIS2                  VARCHAR(36)   NULL,
    DIAGNOSIS3                  VARCHAR(36)   NULL,
    DIAGNOSIS4                  VARCHAR(36)   NULL,
    DIAGNOSIS5                  VARCHAR(36)   NULL,
    DIAGNOSIS6                  VARCHAR(36)   NULL,
    DIAGNOSIS7                  VARCHAR(36)   NULL,
    DIAGNOSIS8                  VARCHAR(36)   NULL,
    REFERRINGPROVIDERID         VARCHAR(36)   NULL,
    APPOINTMENTID               VARCHAR(36)   NULL,
    CURRENTILLNESSDATE          DATETIME2(0)  NULL,
    SERVICEDATE                 DATETIME2(0)  NULL,
    SUPERVISINGPROVIDERID       VARCHAR(36)   NULL,
    STATUS1                     VARCHAR(20)   NULL,
    STATUS2                     VARCHAR(20)   NULL,
    STATUSP                     VARCHAR(20)   NULL,
    OUTSTANDING1                DECIMAL(18,2) NULL,
    OUTSTANDING2                DECIMAL(18,2) NULL,
    OUTSTANDINGP                DECIMAL(18,2) NULL,
    LASTBILLEDDATE1             DATETIME2(0)  NULL,
    LASTBILLEDDATE2             DATETIME2(0)  NULL,
    LASTBILLEDDATEP             DATETIME2(0)  NULL,
    HEALTHCARECLAIMTYPEID1      INT           NULL,
    HEALTHCARECLAIMTYPEID2      INT           NULL
);
GO

IF OBJECT_ID ('bronze.ehr_claims_trans' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_claims_trans;
CREATE TABLE bronze.ehr_claims_trans (
    ID                    VARCHAR(36)    NULL,
    CLAIMID               VARCHAR(36)    NULL,
    CHARGEID              VARCHAR(36)    NULL,
    PATIENTID             VARCHAR(36)    NULL,
    [TYPE]                VARCHAR(20)    NULL,
    AMOUNT                DECIMAL(18,2)  NULL,
    METHOD                VARCHAR(50)    NULL,
    FROMDATE              DATETIME2(0)   NULL,
    TODATE                DATETIME2(0)   NULL,
    PLACEOFSERVICE        VARCHAR(100)   NULL,
    PROCEDURECODE         VARCHAR(20)    NULL,
    MODIFIER1             VARCHAR(20)    NULL,
    MODIFIER2             VARCHAR(20)    NULL,
    DIAGNOSISREF1         VARCHAR(36)    NULL,
    DIAGNOSISREF2         VARCHAR(36)    NULL,
    DIAGNOSISREF3         VARCHAR(36)    NULL,
    DIAGNOSISREF4         VARCHAR(36)    NULL,
    UNITS                 DECIMAL(10,2)  NULL,
    DEPARTMENTID          VARCHAR(36)    NULL,
    NOTES                 VARCHAR(1000)  NULL,
    UNITAMOUNT            DECIMAL(18,2)  NULL,
    TRANSFEROUTID         VARCHAR(36)    NULL,
    TRANSFERTYPE          VARCHAR(30)    NULL,
    PAYMENTS              DECIMAL(18,2)  NULL,
    ADJUSTMENTS            DECIMAL(18,2)  NULL,
    TRANSFERS             DECIMAL(18,2)  NULL,
    OUTSTANDING           DECIMAL(18,2)  NULL,
    APPOINTMENTID         VARCHAR(36)    NULL,
    LINENOTE              VARCHAR(500)   NULL,
    PATIENTINSURANCEID    VARCHAR(36)    NULL,
    FEESCHEDULEID         VARCHAR(36)    NULL,
    PROVIDERID            VARCHAR(36)    NULL,
    SUPERVISINGPROVIDERID VARCHAR(36)    NULL
);
GO

IF OBJECT_ID ('bronze.ehr_payer_trans' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_payer_trans;
CREATE TABLE bronze.ehr_payer_trans (
    PATIENT         VARCHAR(36)  NULL,
    MEMBERID        VARCHAR(36)  NULL,
    START_YEAR      DATE         NULL,
    END_YEAR        DATE         NULL,
    PAYER           VARCHAR(36)  NULL,
    SECONDARY_PAYER VARCHAR(36)  NULL,
    OWNERSHIP       VARCHAR(50)  NULL,
    OWNERNAME       VARCHAR(200) NULL
);
GO

IF OBJECT_ID ('bronze.ehr_payers' , 'U') IS NOT NULL
	DROP TABLE bronze.ehr_payers;
CREATE TABLE bronze.ehr_payers (
    Id                       VARCHAR(36)    NULL,
    NAME                     VARCHAR(200)   NULL,
    ADDRESS                  VARCHAR(250)   NULL,
    CITY                     VARCHAR(100)   NULL,
    STATE_HEADQUARTERED      VARCHAR(2)     NULL,
    ZIP                      VARCHAR(10)    NULL,
    PHONE                    VARCHAR(25)    NULL,
    AMOUNT_COVERED           DECIMAL(18,2)  NULL,
    AMOUNT_UNCOVERED         DECIMAL(18,2)  NULL,
    REVENUE                  DECIMAL(18,2)  NULL,
    COVERED_ENCOUNTERS       BIGINT         NULL,
    UNCOVERED_ENCOUNTERS     BIGINT         NULL,
    COVERED_MEDICATIONS      BIGINT         NULL,
    UNCOVERED_MEDICATIONS    BIGINT         NULL,
    COVERED_PROCEDURES       BIGINT         NULL,
    UNCOVERED_PROCEDURES     BIGINT         NULL,
    COVERED_IMMUNIZATIONS    BIGINT         NULL,
    UNCOVERED_IMMUNIZATIONS  BIGINT         NULL,
    UNIQUE_CUSTOMERS         BIGINT         NULL,
    QOLS_AVG                 DECIMAL(12,6)  NULL,
    MEMBER_MONTHS            BIGINT         NULL
);
GO
