-- =====================================================================
-- 1. TRANSFORMING 'bronze.ehr_patients'
-- =====================================================================

-- Inspect the raw patient data from bronze.ehr_patients
SELECT TOP 1000 *
FROM bronze.ehr_patients;

-- Investigate NULLs or duplicate customer IDs
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
    state,
    healthcare_expenses,
    healthcare_coverage   
FROM bronze.ehr_patients;

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
-- MA -> Massachusetts
SELECT 
    provider_id,
    org_id,
    CASE gender WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE gender 
    END AS gender,
    specialty,
    CASE WHEN state = 'MA' THEN 'Massachusetts' ELSE state 
    END AS state,
    utilization
FROM bronze.ehr_providers

-- =====================================================================
-- 3. TRANSFORMING 'bronze.ehr_conditions'
-- =====================================================================

-- Inspect the raw patient conditions from bronze.ehr_conditions
SELECT TOP *
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

-- Preview standardized customer attributes prior insert to silver.ehr_encounters
-- NULL --> 'N/A'
-- Transform table bronze.ehr_encounters
SELECT 
    encntr_id,
    CASE WHEN start_dt < '1900-01-01' OR start_dt > '2050-01-01' THEN NULL
        ELSE CAST(start_dt AS DATETIME2(0))
    END AS start_dt,
    CASE WHEN stop_dt < '1900-01-01' OR stop_dt > '2050-01-01' THEN NULL
        ELSE CAST(stop_dt AS DATETIME2(0))
    END AS stop_dt,
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
    CASE WHEN reason_code IS NULL THEN 'N/A'
        ELSE reason_code
    END AS reason_code,
    CASE WHEN reason_desc IS NULL THEN 'N/A'
        ELSE reason_desc
    END AS reason_desc
FROM bronze.ehr_encounters

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

