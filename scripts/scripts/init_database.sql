/*
============================================================
Create Database and Schemas
============================================================

Project:
    Synthea Healthcare Analytics

Script Purpose:
    This script initializes the SQL Server database for the
    Synthea Healthcare Analytics project.

    It creates the database 'Synthea_Healthcare_Analytics'
    and three schemas representing the Medallion Architecture:

        - bronze: Raw source data imported from Synthea CSV files.
        - silver: Cleaned and standardized healthcare data.
        - gold: Analytics-ready data models for reporting.

WARNING:
    If the database already exists, this script will DROP it
    and recreate it.

    ALL existing tables, data, views, and other database
    objects inside this database will be permanently deleted.

    Run this script only when you intend to initialize or reset
    the project database. Back up any data you need to retain.
============================================================
*/

USE master;
GO

-- Drop and recreate the 'Synthea' database
IF EXISTS (SELECT 1 FROM sys.database WHERE name = 'Synthea')
BEGIN
	ALTER DATABASE Synthea SET SINGLE_USE WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Synthea;
END;
GO

-- Create Database 'Synthea'
CREATE DATABASE Synthea;
GO 

USE Synthea;

-- Create Schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
