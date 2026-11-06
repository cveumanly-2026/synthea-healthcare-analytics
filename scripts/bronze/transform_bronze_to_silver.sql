-- =====================================================================
-- 1. TRANSFORMING 'bronze.ehr_patients'
-- =====================================================================

-- Inspect the raw patient data from bronze.ehr_patients
SELECT TOP 1000 *
FROM bronze.ehr_patients;

-- Investigate NULLs or duplicate patient IDs
-- Expected Results: No Results
SELECT
    px_id,
    COUNT(*) AS record_count
FROM bronze.ehr_patients
GROUP BY px_id
HAVING COUNT(*) > 1 OR px_id IS NULL;

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results

SELECT * 
FROM bronze.ehr_patients
WHERE px_id != TRIM(px_id) 
      OR birth_dt != TRIM(birth_dt)
      OR death_dt != TRIM(death_dt)
      OR marital_status != TRIM(marital_status)
      OR race != TRIM(race)
      OR ethnicity != TRIM(ethnicity)
      OR gender != TRIM(gender)
      OR state != TRIM(state)
      OR healthcare_expenses != TRIM(healthcare_expenses)
      OR healthcare_coverage != TRIM(healthcare_coverage);

-- Investigate NULLS or illogical date in birth_dt
-- Expected Results: No Results
SELECT
    px_id,
    birth_dt
FROM bronze.ehr_patients
WHERE birth_dt IS NULL OR birth_dt > '2030-01-01';

-- Change NULLS in death_dt into 'N/A' and convert to DATE 
SELECT ISNULL(CAST(TRY_CONVERT(DATE, death_dt) AS VARCHAR(10)), 'N/A') AS death_dt
FROM bronze.ehr_patients;

-- Investigate marital_status, race, ethnicity, gender, state
SELECT DISTINCT marital_status
FROM bronze.ehr_patients;

SELECT DISTINCT race
FROM bronze.ehr_patients;

SELECT DISTINCT ethnicity
FROM bronze.ehr_patients;

SELECT DISTINCT gender
FROM bronze.ehr_patients;

SELECT DISTINCT state
FROM bronze.ehr_patients;

SELECT DISTINCT state
FROM bronze.ehr_patients;

-- Preview standardized providers attributes prior insert to silver.ehr_patients
-- M -> Married; S -> Single
-- F -> Female; M -> Male
-- NULL, Unrecognized or missing values -> N/A
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
    CASE WHEN TRIM(state) = 'Massachusetts' THEN 'MA'
    	 ELSE TRIM(state)
	END AS state,
    healthcare_expenses,
    healthcare_coverage   
FROM bronze.ehr_patients

-- =====================================================================
-- 2. TRANSFORMING 'bronze.ehr_providers'
-- =====================================================================

-- Inspect the raw provider data from bronze.ehr_providers
SELECT TOP 1000 *
FROM bronze.ehr_providers;

-- Investigate NULLs or duplicate customer IDs
-- Expected Results: No Results

SELECT *
FROM bronze.ehr_providers
WHERE provider_id IS NULL 
    OR org_id IS NULL
    OR gender IS NULL
    OR specialty IS NULL
    OR state IS NULL
    OR utilization IS NULL

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results

SELECT * 
FROM bronze.ehr_providers
WHERE provider_id != TRIM(provider_id) 
      OR org_id != TRIM(org_id)
      OR gender != TRIM(gender)
      OR specialty != TRIM(specialty)
      OR state != TRIM(state)

-- Investigate gender, specialty, state
SELECT DISTINCT gender
FROM bronze.ehr_providers;

SELECT DISTINCT specialty
FROM bronze.ehr_providers;

SELECT DISTINCT state
FROM bronze.ehr_providers;

-- Preview standardized patient attributes prior insert to silver.ehr_patients
-- F -> Female; M -> Male
SELECT 
    provider_id,
    org_id,
    CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE gender 
    END AS gender,
    specialty,
    state,
    utilization
FROM bronze.ehr_providers

-- =====================================================================
-- 3. TRANSFORMING 'bronze.ehr_conditions'
-- =====================================================================

-- Inspect the raw patient conditions from bronze.ehr_conditions
SELECT TOP 1000 *
FROM bronze.ehr_conditions;

-- Test candidate composite primary key
-- Expected Results: No Results
SELECT
    px_id,
    encntr_id,
    cond_code,
    start_dt,
    COUNT(*) AS duplicate_count
FROM bronze.ehr_conditions
GROUP BY
    px_id,
    encntr_id,
    cond_code,
    start_dt
HAVING COUNT(*) > 1;

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_conditions
WHERE px_id != TRIM(px_id) 
      OR encntr_id != TRIM(encntr_id)
      OR cond_code != TRIM(cond_code)
      OR cond_desc != TRIM(cond_desc);
      
-- Investigate NULLs
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_conditions
WHERE start_dt IS NULL
   OR px_id IS NULL
   OR encntr_id IS NULL
   OR cond_code IS NULL

-- Checking if px_id is NOT IN px_id from bronze.ehr_patients
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_conditions
WHERE px_id NOT IN (SELECT px_id FROM bronze.ehr_patients);

-- Check for Invalid Dates ehr_conditions
-- Expected Results: Zero
SELECT 
    COUNT(*) AS total_invalid_date
FROM bronze.ehr_conditions
WHERE 
    (start_dt < '1900-01-01' OR start_dt > '2050-01-01')
    OR 
    (stop_dt < '1900-01-01' OR stop_dt > '2050-01-01');

SELECT 
	start_dt,
	CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' THEN NULL
        ELSE start_dt
    END AS start_dt,
    CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01' THEN NULL
        ELSE stop_dt
    END AS stop_dt
FROM bronze.ehr_conditions

-- Preview standardized ehr_conditions prior insert to silver.ehr_conditions
-- Transformed table bronze.ehr_conditions
SELECT 
    CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' THEN NULL
        ELSE start_dt
    END AS start_dt,
    CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01' THEN NULL
        ELSE stop_dt
    END AS stop_dt,
    px_id,
    encntr_id,
    cond_code,
    cond_desc
FROM bronze.ehr_conditions

-- =====================================================================
-- 4. TRANSFORMING 'bronze.ehr_encounters'
-- =====================================================================

-- Inspect the raw encounters with providers from bronze.ehr_encounters
SELECT TOP 1000 *
FROM bronze.ehr_encounters;

-- Test candidate composite primary key
-- Expected Results: No Results
SELECT
    encntr_id,
    COUNT(*) AS duplicate_occurences
FROM bronze.ehr_encounters
GROUP BY encntr_id
HAVING COUNT(*) > 1;

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_encounters
WHERE encntr_id != TRIM(encntr_id)
      OR px_id != TRIM(px_id)
      OR org_id != TRIM(org_id)
      OR provider_id != TRIM(provider_id)
      OR payer_id != TRIM(payer_id)
      OR encntr_class != TRIM(encntr_class)
      OR encntr_code != TRIM(encntr_code)
      OR encntr_desc != TRIM(encntr_desc)
      OR reason_code != TRIM(reason_code)
      OR reason_desc != TRIM(reason_desc);
      
-- Investigate NULLs
-- Expected Results: zero 
SELECT *
FROM bronze.ehr_encounters
WHERE encntr_id IS NULL
   OR px_id IS NULL
   OR org_id IS NULL
   OR provider_id IS NULL
   OR payer_id IS NULL
   OR encntr_class IS NULL
   OR encntr_code IS NULL;

-- Checking if px_id is NOT IN px_id from bronze.ehr_patients
-- Expected Results: No Results
SELECT px_id 
FROM bronze.ehr_encounters
WHERE px_id NOT IN (SELECT px_id FROM bronze.ehr_patients);

SELECT provider_id
FROM bronze.ehr_encounters
WHERE provider_id NOT IN (SELECT provider_id FROM bronze.ehr_providers);

SELECT org_id
FROM bronze.ehr_encounters
WHERE org_id NOT IN (SELECT org_id FROM bronze.ehr_providers);

-- Investigate description variations in Bronze
SELECT
    encntr_class,
    encntr_code,
    encntr_desc,
    COUNT(*) AS total_records
FROM bronze.ehr_encounters
GROUP BY
    encntr_class,
    encntr_code,
    encntr_desc
HAVING encntr_desc LIKE '%(procedure)%'
ORDER BY
    encntr_class,
    encntr_code;

-- Investigate descriptions that will be standardized into one description
SELECT
    encntr_class,
    encntr_code,
    TRIM(REPLACE(encntr_desc, '(procedure)', ''))
        AS standardized_description,
    COUNT(DISTINCT encntr_desc) AS original_variations,
    COUNT(*) AS total_records
FROM bronze.ehr_encounters
GROUP BY
    encntr_class,
    encntr_code,
    TRIM(REPLACE(encntr_desc, '(procedure)', ''))
HAVING COUNT(DISTINCT encntr_desc) > 1
ORDER BY
    encntr_class,
    encntr_code;

-- Investigate description variations in Bronze
SELECT
    encntr_class,
    encntr_code,
    encntr_desc,
    COUNT(*) AS total_records
FROM bronze.ehr_encounters
GROUP BY
    encntr_class,
    encntr_code,
    encntr_desc
HAVING encntr_desc LIKE '%(procedure)%'
ORDER BY
    encntr_class,
    encntr_code;

-- Investigate descriptions that will be standardized into one description
SELECT
    encntr_class,
    encntr_code,
    TRIM(REPLACE(encntr_desc, '(procedure)', ''))
        AS standardized_description,
    COUNT(DISTINCT encntr_desc) AS original_variations,
    COUNT(*) AS total_records
FROM bronze.ehr_encounters
GROUP BY
    encntr_class,
    encntr_code,
    TRIM(REPLACE(encntr_desc, '(procedure)', ''))
HAVING COUNT(DISTINCT encntr_desc) > 1
ORDER BY
    encntr_class,
    encntr_code;

-- Preview original and standardized encounter descriptions
SELECT
    encntr_class,
    encntr_code,
    encntr_desc AS original_description,
    TRIM(REPLACE(encntr_desc, '(procedure)', '')) AS standardized_description,
    COUNT(*) AS total_records
FROM bronze.ehr_encounters
WHERE encntr_desc LIKE '%(procedure)%'
GROUP BY
    encntr_class,
    encntr_code,
    encntr_desc
ORDER BY
    encntr_class,
    encntr_code;

-- Check for Invalid Dates ehr_encounters
-- Expected Result: No Results
SELECT 
    encntr_id,
	CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' THEN NULL
        ELSE CAST(start_dt AS DATETIME2(0))
    END AS start_dt,
    CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01' THEN NULL
        ELSE CAST(stop_dt AS DATETIME2(0))
    END AS stop_dt
FROM bronze.ehr_encounters;

-- Investigate encntr_class, reason_code, reason_desc
-- Expected Results : No NULLS, No blank space
SELECT DISTINCT encntr_class
FROM bronze.ehr_encounters;

SELECT DISTINCT reason_code
FROM bronze.ehr_encounters; -- Results: There's NULL

SELECT DISTINCT reason_desc
FROM bronze.ehr_encounters; -- Results: There's NULL

-- Preview standardized encounters attributes prior insert to silver.ehr_encounters
-- Validate and standardize encounter dates
-- Correct identified encounter codes
-- Remove '(procedure)' from descriptions
-- Replace NULL reason values with 'N/A'
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
    CASE WHEN encntr_code = '1853470'  -- Standardize identified encounter code
		AND encntr_class = 'ambulatory' 
		AND encntr_desc = 'Encounter for problem (procedure)'
        THEN '185347001' ELSE encntr_code
    END AS encntr_code,
    TRIM(REPLACE(encntr_desc, '(procedure)', '')) AS encntr_desc, -- Remove '(procedure)' from descriptions
    base_encntr_cost,
    total_claim_cost,
    payer_coverage,
    CASE WHEN reason_code IS NULL THEN 'N/A' ELSE reason_code  -- Replace NULL reason code with N/A
    END AS reason_code, 
    CASE WHEN reason_desc IS NULL THEN 'N/A' ELSE reason_desc  -- Replace NULL reason description with N/A
    END AS reason_desc
FROM bronze.ehr_encounters;

-- =====================================================================
-- 5. TRANSFORMING 'bronze.ehr_medications'
-- =====================================================================

-- Inspect the raw medications data from bronze.ehr_medications
SELECT TOP 1000 *
FROM bronze.ehr_medications;

-- Investigate NULLs 
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_medications
WHERE start_dt IS NULL
    OR px_id IS NULL 
    OR payer_id IS NULL
    OR encntr_id IS NULL;

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results
SELECT * 
FROM bronze.ehr_medications
WHERE px_id != TRIM(px_id) 
      OR payer_id != TRIM(payer_id)
      OR encntr_id != TRIM(encntr_id)
      OR med_code != TRIM(med_code)
      OR med_desc != TRIM(med_desc)
      OR reason_code != TRIM(reason_code)
      OR reason_desc != TRIM(reason_desc);

-- Checking if px_id is NOT IN px_id from bronze.ehr_patients
-- Expected Results: No Results
SELECT px_id 
FROM bronze.ehr_medications
WHERE px_id NOT IN (SELECT px_id FROM bronze.ehr_patients);

-- Evaluate data duplications
-- Assign a chronological visit number to each patient
-- based on distinct calendar dates in start_dt, from earliest to latest.
-- Medications on the same date share the same visit number.
-- Partition by px_id and order by DATE(start_dt).
SELECT *,
    DENSE_RANK() OVER (PARTITION BY px_id ORDER BY  CAST(start_dt AS DATE) ASC
       ) AS visit_number
FROM (
    SELECT DISTINCT *
    FROM bronze.ehr_medications
    WHERE px_id IS NOT NULL
) AS t;

-- Investigate gender, specialty, state
SELECT DISTINCT med_code
FROM bronze.ehr_medications
ORDER BY med_code;

SELECT DISTINCT med_desc
FROM bronze.ehr_medications;

SELECT DISTINCT reason_code
FROM bronze.ehr_medications
ORDER BY reason_code; -- There's NULL value

SELECT DISTINCT reason_desc
FROM bronze.ehr_medications
ORDER BY reason_desc; -- There's NULL value

-- Preview standardized medication data prior insert to silver.ehr_medications
-- NULL --> 'N/A'
-- Transform table bronze.ehr_medications
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
FROM (SELECT DISTINCT *
    FROM bronze.ehr_medications
    WHERE px_id IS NOT NULL
) AS t

-- =====================================================================
-- 6. TRANSFORMING 'bronze.ehr_procedures'
-- =====================================================================

-- Inspect the raw procedures data from bronze.ehr_procedures
SELECT TOP 1000 *
FROM bronze.ehr_procedures;

-- Investigate NULLs 
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_procedures
WHERE start_dt IS NULL 
    OR px_id IS NULL
    OR encntr_id IS NULL;

-- Investigate unwanted spaces in each column 
-- Expected Results: No Results
SELECT * 
FROM bronze.ehr_procedures
WHERE px_id != TRIM(px_id) 
      OR encntr_id != TRIM(encntr_id)
      OR proc_code != TRIM(proc_code)
      OR proc_desc != TRIM(proc_desc)
      OR reason_code != TRIM(reason_code)
      OR reason_desc != TRIM(reason_desc);

-- Checking if px_id is NOT IN px_id from bronze.ehr_patients
-- Expected Results: No Results
SELECT px_id 
FROM bronze.ehr_procedures
WHERE px_id NOT IN (SELECT px_id FROM bronze.ehr_patients);

-- Evaluate data duplications
-- Assign a chronological visit number to each patient
-- based on distinct calendar dates in start_dt, from earliest to latest.
-- Procedures on the same date share the same visit number.
-- Partition by px_id and order by DATE(start_dt).
SELECT *,
    DENSE_RANK() OVER (PARTITION BY px_id ORDER BY  CAST(start_dt AS DATE) ASC
       ) AS visit_number
FROM (
    SELECT DISTINCT *
    FROM bronze.ehr_procedures
    WHERE px_id IS NOT NULL
) AS t;

-- Investigate proc_code, prod_desc, reason_code, reason_desc
SELECT DISTINCT proc_code
FROM bronze.ehr_procedures
ORDER BY proc_code;

SELECT DISTINCT proc_desc
FROM bronze.ehr_procedures
ORDER BY proc_desc;

SELECT DISTINCT reason_code
FROM bronze.ehr_procedures
ORDER BY reason_code; -- There's NULL value

SELECT DISTINCT reason_desc
FROM bronze.ehr_procedures
ORDER BY reason_desc; -- There's NULL value

-- Preview standardized procedures data prior insert to silver.ehr_procedures
-- NULL --> 'N/A'
-- Transform table bronze.ehr_procedures
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
FROM (SELECT DISTINCT *
    FROM bronze.ehr_procedures
    WHERE px_id IS NOT NULL
) AS t;


-- =====================================================================
-- 7. TRANSFORMING 'bronze.ehr_org'
-- =====================================================================

-- Inspect the source data from bronze.ehr_org
SELECT TOP 100 *
FROM bronze.ehr_org;

-- Count source records
SELECT COUNT(*) AS total_source_rows
FROM bronze.ehr_org;

-- Checking for NULLs and duplicate organization IDs
-- Expected Results: No Results
SELECT
    Id,
    COUNT(*) AS record_count
FROM bronze.ehr_org
GROUP BY Id
HAVING COUNT(*) > 1 OR Id IS NULL; 

-- Check for missing required values in other columns.
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_org
WHERE NAME IS NULL
    OR CITY IS NULL
    OR STATE IS NULL
    OR REVENUE IS NULL
    OR UTILIZATION IS NULL;

-- Check for unwanted spaces
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_org
WHERE Id != TRIM(Id)
    OR NAME    != TRIM(NAME)
    OR ADDRESS != TRIM(ADDRESS)
    OR CITY    != TRIM(CITY)
    OR STATE   != TRIM(STATE)
    OR ZIP     != TRIM(ZIP)
    OR PHONE   != TRIM(PHONE)

-- Check for duplicate organization names and addresses
-- Expected Results: No Results
SELECT
    NAME,
    ADDRESS,
    CITY,
    STATE,
    COUNT(*) AS duplicate_count
FROM bronze.ehr_org
GROUP BY
    NAME,
    ADDRESS,
    CITY,
    STATE
HAVING COUNT(*) > 1;

-- Identify organization IDs with duplicate names and addresses
-- Expected Results: Only potential duplicate records
WITH duplicate_org AS (
    SELECT
        Id,
        NAME,
        ADDRESS,
        CITY,
        STATE,
        COUNT(*) OVER (PARTITION BY NAME, ADDRESS, CITY, STATE) AS duplicate_count
    FROM bronze.ehr_org
)
SELECT *
FROM duplicate_org
WHERE duplicate_count > 1
ORDER BY NAME, ADDRESS, CITY, STATE, Id;

-- Investigate potential duplicate organizations
-- Compare additional attributes before deciding on deduplication
-- The same name, address, city, state, zip but different ID but 
WITH duplicate_org AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY NAME, ADDRESS, CITY, STATE) AS duplicate_count
    FROM bronze.ehr_org
)
SELECT
    Id,
    NAME,
    ADDRESS,
    CITY,
    STATE,
    ZIP,
    PHONE, -- There's NULL
    REVENUE,
    UTILIZATION,
    duplicate_count
FROM duplicate_org
WHERE duplicate_count > 1
ORDER BY NAME, ADDRESS, Id;

-- Check organizations without matching providers
-- Relationship: Organizations → Providers
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_org o
WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.ehr_providers p
    WHERE p.org_id = o.Id
);

-- Check for invalid organization references in providers
-- Relationship: Providers → Organizations 
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_providers p
WHERE p.org_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM bronze.ehr_org o
        WHERE o.Id = p.org_id
    );

-- Check for negative revenue and utilization
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_org
WHERE REVENUE < 0
   OR UTILIZATION < 0;

-- =====================================================================
-- 8. TRANSFORMING 'bronze.ehr_observations'
-- =====================================================================

-- Inspect the source data from bronze.ehr_observations
SELECT TOP 100 *
FROM bronze.ehr_observations;

-- Count source records
-- Total: 531144
SELECT COUNT(*) AS total_source_rows
FROM bronze.ehr_observations;

-- Investigate exact duplicate observation records
-- Expected Results: No Results (if no exact duplicates exist)
SELECT
    [DATE],
    PATIENT,
    ENCOUNTER,
    CATEGORY,
    CODE,
    DESCRIPTION,
    VALUE,
    UNITS,
    [TYPE],
    COUNT(*) AS duplicate_count
FROM bronze.ehr_observations
GROUP BY
    [DATE],
    PATIENT,
    ENCOUNTER,
    CATEGORY,
    CODE,
    DESCRIPTION,
    VALUE,
    UNITS,
    [TYPE]
HAVING COUNT(*) > 1;

-- Investigate exact duplicate observation records
-- Display duplicated records for further assessment
WITH CTE_duplicate_observations AS
(
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY [DATE], PATIENT, ENCOUNTER, CATEGORY, CODE, DESCRIPTION, VALUE, UNITS, [TYPE]) AS duplicate_count
    FROM bronze.ehr_observations
)
SELECT *
FROM CTE_duplicate_observations
WHERE duplicate_count > 1
ORDER BY PATIENT, ENCOUNTER, [DATE]; -- Results: Presence of duplicate_count > 1

-- Investigate duplicate records by CATEGORY
WITH CTE_duplicate_observations AS
(
    SELECT
        CATEGORY,
        [DATE],
        PATIENT,
        ENCOUNTER,
        CODE,
        DESCRIPTION,
        VALUE,
        UNITS,
        [TYPE],
        COUNT(*) AS duplicate_count
    FROM bronze.ehr_observations
    GROUP BY
        CATEGORY,
        [DATE],
        PATIENT,
        ENCOUNTER,
        CODE,
        DESCRIPTION,
        VALUE,
        UNITS,
        [TYPE]
    HAVING COUNT(*) > 1
)
SELECT
    CATEGORY,
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count) AS total_records,
    SUM(duplicate_count - 1) AS potential_excess_records
FROM CTE_duplicate_observations
GROUP BY CATEGORY
ORDER BY duplicate_groups DESC;
-- Results:
-- 249 exact duplicate groups (498 records) were identified across two categories.
-- Laboratory accounted for 247 duplicate groups (494 records).
-- Vital-signs accounted for 2 duplicate groups (4 records).
-- No exact duplicates were found in other categories.
-- Deduplication is pending source verification before Silver transformation.

-- Investigate unwanted spaces in each column
-- Expected Results: No Results
-- Investigate unwanted spaces in each column
-- Expected Results: No Results
SELECT *
FROM bronze.ehr_observations
WHERE
    (PATIENT IS NOT NULL AND DATALENGTH(PATIENT) != DATALENGTH(TRIM(PATIENT)))
    OR (ENCOUNTER IS NOT NULL AND DATALENGTH(ENCOUNTER) != DATALENGTH(TRIM(ENCOUNTER)))
    OR (CATEGORY IS NOT NULL AND DATALENGTH(CATEGORY) != DATALENGTH(TRIM(CATEGORY)))
    OR (CODE IS NOT NULL AND DATALENGTH(CODE) != DATALENGTH(TRIM(CODE)))
    OR (DESCRIPTION IS NOT NULL AND DATALENGTH(DESCRIPTION) != DATALENGTH(TRIM(DESCRIPTION)))
    OR (VALUE IS NOT NULL AND DATALENGTH(VALUE) != DATALENGTH(TRIM(VALUE)))
    OR (UNITS IS NOT NULL AND DATALENGTH(UNITS) != DATALENGTH(TRIM(UNITS)))
    OR ([TYPE] IS NOT NULL AND DATALENGTH([TYPE]) != DATALENGTH(TRIM([TYPE])));

-- Investigate NULL values in important observation attributes
-- Expected Results: Review the results
SELECT *
FROM bronze.ehr_observations
WHERE DATE IS NULL
    OR PATIENT IS NULL
    OR ENCOUNTER IS NULL;
-- Results:
-- 31,662 records (5.96%) had both ENCOUNTER and CATEGORY values missing.
-- No records had only one of these attributes missing.
-- The remaining 499,482 records had both attributes populated.
-- Both NULL values will be preserved pending further investigation.

-- Analyze NULL combinations in ENCOUNTER and CATEGORY
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN ENCOUNTER IS NULL THEN 1 ELSE 0
    END) AS null_encounter,
    SUM(CASE WHEN CATEGORY IS NULL THEN 1 ELSE 0
    END) AS null_category,
    SUM(CASE WHEN ENCOUNTER IS NULL AND CATEGORY IS NULL THEN 1 ELSE 0
    END) AS null_both,
    SUM(CASE WHEN ENCOUNTER IS NULL AND CATEGORY IS NOT NULL THEN 1 ELSE 0
    END) AS null_encounter_only,
    SUM(CASE WHEN ENCOUNTER IS NOT NULL AND CATEGORY IS NULL THEN 1 ELSE 0
    END) AS null_category_only
FROM bronze.ehr_observations;
-- Results:
-- A total of 31,662 records (5.96%) were identified with both ENCOUNTER and CATEGORY values missing.
-- No records were found with only one of these two attributes missing.
-- The remaining 499,482 records contained populated ENCOUNTER and CATEGORY values.
-- Both NULL attributes will be preserved pending further investigation of their observation codes and clinical relevance.

-- Investigate observations with NULL ENCOUNTER and CATEGORY
SELECT
    CODE,
    DESCRIPTION,
    [TYPE],
    UNITS,
    COUNT(*) AS total_records,
    COUNT(DISTINCT PATIENT) AS total_patients
FROM bronze.ehr_observations
WHERE ENCOUNTER IS NULL AND CATEGORY IS NULL
GROUP BY
    CODE,
    DESCRIPTION,
    [TYPE],
    UNITS
ORDER BY total_records DESC;
-- Results:
-- Total affected records: 31,662 (5.96%).
-- Affected columns: ENCOUNTER and CATEGORY.
-- Identified codes: QOLS, QALY, and DALY.
-- Each code contains 10,554 records and 1,049 unique patients.

-- Check if PATIENT does not exist in bronze.ehr_patients
-- Expected Results: 0
SELECT COUNT(*) AS invalid_patient_records
FROM bronze.ehr_observations o
LEFT JOIN bronze.ehr_patients p
ON o.patient = p.px_id
WHERE o.patient is not null
    and p.px_id is null;
-- Results: 
-- No invalid PATIENT references were identified in the Observation dataset.
-- All non-NULL PATIENT identifiers matched existing records in bronze.ehr_patients.
-- The referential integrity check passed.
-- No patient reference correction is required.

-- Check if ENCOUNTER does not exist in bronze.ehr_encounters
-- Expected Results: 0
SELECT COUNT(*) AS invalid_encounter_records
FROM bronze.ehr_observations o
LEFT JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE o.ENCOUNTER IS NOT NULL AND e.encntr_id IS NULL;

-- Check patient and encounter relationship
-- Expected Results: 0
SELECT COUNT(*) AS mismatched_patient_encounters
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE o.PATIENT IS NOT NULL
    AND o.ENCOUNTER IS NOT NULL
    AND o.PATIENT != e.px_id;

-- Investigate invalid observation dates
-- Expected Results: 0
SELECT COUNT(*) as invalid_observation_dates
FROM bronze.ehr_observations
WHERE [DATE] < '1900-01-01'
    or [DATE] > GETDATE();

-- investigate observation dates against encounter dates
-- expected results: 0
SELECT COUNT(*) AS invalid_encounter_date_records
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.encounter = e.encntr_id
WHERE (e.start_dt IS NOT NULL AND o.DATE < e.start_dt)
    OR (e.stop_dt IS NOT NULL AND o.DATE > e.stop_dt); -- Results: 221483

-- investigate observation and encounter date discrepancies
SELECT 
    COUNT(*) AS total_observations,
    SUM(CASE WHEN o.[DATE] < e.start_dt THEN 1 ELSE 0
    END) AS before_encounter_start,
    SUM(CASE WHEN e.stop_dt IS NOT NULL AND o.[DATE] > e.stop_dt THEN 1 ELSE 0
    END) AS after_encounter_start,
    SUM(CASE WHEN e.stop_dt IS NULL THEN 1 ELSE 0 
    END) AS null_encounter_end,
    SUM(CASE WHEN o.[DATE] >= e.start_dt AND (e.stop_dt IS NULL OR o.[DATE] <= e.stop_dt) 
    THEN 1 ELSE 0
    END) AS within_encounter_period
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE o.[DATE] IS NOT NULL;
-- Results: 
-- total_observations = 499482
-- before_encounter_start = 8472
-- after_encounter_start = 213011
-- null_encounter_end = 0
-- within_encounter_period = 277999

-- investigate observations after encounter end
SELECT 
    o.PATIENT,
    o.ENCOUNTER,
    o.[DATE] AS observation_date,
    e.start_dt AS encounter_start,
    e.stop_dt AS encounter_end,
    o.CATEGORY,
    o.CODE,
    o.[DESCRIPTION]
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE e.stop_dt IS NOT NULL AND o.[DATE] > e.stop_dt
ORDER BY o.[DATE];
-- Results: observation_date, encounter_start, encounter_end : YEAR 1934 sd/ 2021 

-- investigate observation date range
SELECT
    MIN([date]) as earliest_observation,
    MAX([date]) as latest_observation,
    COUNT(*) as total_records,
    SUM(CASE WHEN YEAR([DATE]) < 2000 THEN 1 ELSE 0
    END) AS records_before_2000,
    SUM(CASE WHEN YEAR([DATE]) >= 2000 THEN 1 ELSE 0
    END) AS records_from_2000
FROM bronze.ehr_observations;
-- Results: 
-- Total_records = 531144
-- Records before year 2000 = 53589 (10.09%)
-- Records after year 2000 = 477555 (89.91%)
-- Earliest_observation = 1932-06-21
-- Latest_observation = 2021-11-19

-- investigate observation records by year
SELECT 
    YEAR([DATE]) AS observation_year,
    COUNT(*) AS total_records,
    COUNT (DISTINCT PATIENT) AS total_patients
FROM bronze.ehr_observations
WHERE YEAR([DATE]) < 2000
GROUP BY YEAR([DATE]) 
ORDER BY YEAR([DATE]);
-- Results: 
-- The number of records increases gradually over the years.
-- In 1932, there were only 11 records from 1 patient.
-- In 1999, there were 2,474 records from 36 patients.
-- This pattern shows that pre-2000 data is spread across multiple patients, rather than being caused by a single isolated date error.

-- investigate observation dates before patient birth dates
SELECT 
    o.PATIENT,
    p.birth_dt,
    o.[DATE] AS observation_date,
    o.CODE,
    o.DESCRIPTION
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_patients p
ON o.PATIENT = p.px_id
WHERE o.[DATE] < p.birth_dt
ORDER BY o.[DATE]; 
-- Results: 
-- No observation records were found with dates earlier than patient birth dates.
-- All observation dates were chronologically consistent with patient birth dates.
-- No date correction is required.

-- investigate observation dates after encounter end by category
SELECT 
    o.CATEGORY,
    COUNT(*) AS total_records
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE e.stop_dt IS NOT NULL AND o.[DATE] > e.stop_dt
GROUP BY o.CATEGORY
ORDER BY COUNT(*) DESC;
-- Results: surver 194924, laboratory 13187, vital-signs 4822, procedure 70, exam 5, therapy 3

-- investigate time differences between observation and encounter end
SELECT
    o.CATEGORY,
    COUNT(*) AS total_records,
    MIN(DATEDIFF(DAY, e.stop_dt, o.[DATE])) AS min_days_after,
    MAX(DATEDIFF(DAY, e.stop_dt, o.[DATE])) AS max_days_after,
    AVG(CAST(DATEDIFF(DAY, e.stop_dt, o.[DATE]) AS decimal(18,2))) AS avg_days_after
FROM bronze.ehr_observations o
INNER JOIN bronze.ehr_encounters e
ON o.ENCOUNTER = e.encntr_id
WHERE e.stop_dt IS NOT NULL AND o.[DATE] > e.stop_dt
GROUP BY o.CATEGORY
ORDER BY COUNT(*) DESC;
-- Results:
-- Survey had the highest number of records (194,924), averaging 0.22 days.
-- Laboratory and vital-signs averaged 1.57 and 3.70 days, respectively.
-- Therapy had the longest average difference (21.67 days), with only 3 records.
-- Date discrepancies will be preserved pending source validation.

-- investigate observation category and type distribution
SELECT 
    CATEGORY,
    [TYPE],
    COUNT(*) AS total_records
FROM bronze.ehr_observations
GROUP BY CATEGORY, [TYPE]
ORDER BY COUNT(*); 

-- investigate VALUE conversion based on TYPE
SELECT
    [TYPE],
    COUNT(*) AS total_records,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,4), TRIM(VALUE)) IS NOT NULL THEN 1 ELSE 0
    END) AS convertible_values,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,4), TRIM(VALUE)) IS NULL THEN 1 ELSE 0
    END) AS non_convertible_values
FROM bronze.ehr_observations
WHERE [TYPE] = 'numeric' AND VALUE IS NOT NULL
GROUP BY [TYPE];
-- Results: 
-- All 331,164 numeric values were successfully converted.
-- No non-convertible numeric values were identified.
-- No numeric format correction was required.

-- investigate NULL and blank numeric values
SELECT
    COUNT(*) AS total_numeric_records,
    SUM(CASE WHEN VALUE IS NULL THEN 1 ELSE 0
    END) AS null_values,
    SUM(CASE WHEN TRIM(VALUE) = '' THEN 1 ELSE 0
    END) AS blank_values,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,4), TRIM(VALUE)) IS NOT NULL THEN 1 ELSE 0
    END) AS convertible_values
FROM bronze.ehr_observations
WHERE [TYPE] = 'numeric';
-- Results:
-- All 331,164 numeric records contained valid values.
-- No NULL or blank numeric values were identified.
-- All numeric values were successfully converted.
-- No numeric value correction was required.

-- inspect sample text observation values
SELECT
    CATEGORY,
    CODE,
    [DESCRIPTION],
    [VALUE],
    UNITS
FROM bronze.ehr_observations
WHERE [TYPE] = 'text'
ORDER BY category, code;
-- Results:
-- Text observations contained categorical values labeled as {nominal}.
-- Nominal values represent text-based categories, not numerical measurements.
-- No numeric conversion is required for text observations.
-- Nominal units will be preserved during Silver transformation.

-- investigate UNITS values in text observations
SELECT
    UNITS,
    COUNT(*) AS total_records
FROM bronze.ehr_observations
WHERE [TYPE] = 'text'
GROUP BY UNITS
ORDER BY COUNT(*) DESC;
-- Results:
-- Seven distinct UNITS values were identified across 199,980 text records.
-- Most records (184,538) had NULL units.
-- Nominal units accounted for 6,068 records.
-- Unusual unit values require further investigation before standardization.

-- investigate unusual UNITS by CATEGORY
SELECT
    CATEGORY,
    UNITS,
    COUNT(*) AS total_records
FROM bronze.ehr_observations
WHERE [TYPE] = 'text' AND UNITS IS NOT NULL
GROUP BY 
    CATEGORY,
    UNITS
ORDER BY
    UNITS,
    COUNT(*) DESC;
-- Results:
-- Nine non-NULL UNITS combinations were identified across five categories.
-- Survey accounted for 8,886 records with `/a` units.
-- Nominal units were found across four categories (6,068 records).
-- Other unit values require further investigation before standardization.

-- investigate unusual UNITS values
SELECT
    CATEGORY,
    CODE,
    [DESCRIPTION],
    [VALUE],
    UNITS
FROM bronze.ehr_observations
WHERE [TYPE] = 'text' AND UNITS IN ('/a', 'null', 'n/a')
ORDER BY CATEGORY, UNITS, CODE

-- inspect unusual UNITS values
SELECT
    CATEGORY,
    CODE,
    [DESCRIPTION],
    [VALUE],
    UNITS
FROM bronze.ehr_observations
WHERE [TYPE] = 'text' AND UNITS IN ('/a', 'null', 'n/a')
ORDER BY CATEGORY, CODE, [DESCRIPTION], [VALUE], UNITS;

-- Preview transformed observation dataset before inserting into silver
-- Remove exact duplicates from the preview results.
-- Convert numeric VALUE entries to DECIMAL(18,4).
-- Preserve text VALUE entries.
-- Preserve original NULL values and UNITS values.
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
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [DATE], PATIENT, ENCOUNTER, CATEGORY, CODE, [DESCRIPTION], [VALUE], UNITS, [TYPE]
        ORDER BY (SELECT NULL)) AS row_num
    FROM bronze.ehr_observations
) AS ranked_observations
WHERE row_num = 1;

-- validate duplicate records excluded by ROW_NUMBER()
-- validate exact duplicate removal
SELECT
    COUNT(*) AS total_bronze_records,
    SUM(CASE WHEN row_num = 1 THEN 1 ELSE 0 END) AS retained_records,
    SUM(CASE WHEN row_num > 1 THEN 1 ELSE 0 END) AS excluded_duplicates
FROM
(
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                [DATE], PATIENT, ENCOUNTER, CATEGORY,
                CODE, [DESCRIPTION], [VALUE], UNITS, [TYPE]
            ORDER BY (SELECT NULL)
        ) AS row_num
    FROM bronze.ehr_observations
) AS ranked_observations;
-- Results: 
-- total_bronze_records = 53114
-- retained_records = 530895
-- excluded_duplicated = 249

-- validate numeric conversion and text preservation
SELECT
    [TYPE],
    COUNT(*) AS total_records,
    SUM(CASE WHEN [TYPE] = 'numeric' AND TRY_CONVERT(DECIMAL(18,4), TRIM([VALUE])) IS NOT NULL THEN 1 ELSE 0
    END) AS convertible_numeric,
    SUM(CASE WHEN [TYPE] = 'numeric' AND TRY_CONVERT(DECIMAL(18,4), TRIM([VALUE])) IS NULL THEN 1 ELSE 0
    END) AS non_convertible_numeric,
    SUM(CASE WHEN [TYPE] = 'text' AND [VALUE] IS NOT NULL THEN 1 ELSE 0 END) AS preserved_text_values
FROM
(
    SELECT *
    FROM
    (
        SELECT *,
            ROW_NUMBER() OVER (PARTITION BY [DATE], PATIENT, ENCOUNTER, CATEGORY,CODE, [DESCRIPTION], [VALUE], UNITS, [TYPE]
            ORDER BY (SELECT NULL)) AS row_num
        FROM bronze.ehr_observations
    ) AS ranked_observations
    WHERE row_num = 1
) AS preview_data
GROUP BY [TYPE];
-- Results:
-- total_records for text = 199980, convertible_numeric = 0, non_convertible_numeric = 0, preserved _text_values = 1999980
-- total_records for numeric = 330915, convertible_numeric = 330915, non_convertible_numeric = 0, preserved_text_values = 0

-- validate original source values are preserved
-- Expected Results: No Results
SELECT
    [DATE],
    PATIENT,
    ENCOUNTER,
    CATEGORY,
    CODE,
    [DESCRIPTION],
    [VALUE],
    UNITS,
    [TYPE]
FROM bronze.ehr_observations
EXCEPT
SELECT
    [DATE],
    PATIENT,
    ENCOUNTER,
    CATEGORY,
    CODE,
    [DESCRIPTION],
    [VALUE],
    UNITS,
    [TYPE]
FROM
(
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [DATE], PATIENT, ENCOUNTER, CATEGORY, CODE, [DESCRIPTION], [VALUE], UNITS, [TYPE]
            ORDER BY (SELECT NULL)) AS row_num
    FROM bronze.ehr_observations
) AS ranked_observations
WHERE row_num = 1; 

