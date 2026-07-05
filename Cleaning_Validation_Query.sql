

-- removing the tables to not have problems when we rerun



DROP TABLE IF EXISTS MigrationErrorLog;
DROP TABLE  IF EXISTS Target_Invoices;
DROP TABLE IF EXISTS Target_Customers;
DROP TABLE  IF EXISTS Staging_Invoices;
DROP TABLE IF EXISTS Staging_Customers;
DROP PROCEDURE IF EXISTS sp_RunTargetMigrationPipeline;
DROP PROCEDURE IF EXISTS sp_RunGranularValidationAudit

GO
-- Creating a production relational model


CREATE TABLE Target_Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    LegacyID INT UNIQUE NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    CleanedPhone CHAR(10),
    Email VARCHAR(100) NOT NULL,
    MigrationTimestamp DATETIME DEFAULT GETDATE()

);


CREATE TABLE Target_Invoices (
    InvoiceID INT IDENTITY(1000,1) PRIMARY KEY,
    LegacyInvoiceID INT UNIQUE NOT NULL,
    CustomerID INT NOT NULL,
    AMOUNT DECIMAL(10,2) NOT NULL,
    InvoiceDate DATE NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Target_Customers(CustomerID)

);

CREATE TABLE Staging_Customers (
    LegacyID INT,
    CustomerName VARCHAR(255),
    Phone VARCHAR(50),
    Email VARCHAR(255)

);

CREATE TABLE Staging_Invoices(
    LegacyInvoiceID INT,
    LegacyCustomerID INT,
    Amount VARCHAR(50),
    InvoiceDate VARCHAR(50)

);

CREATE TABLE MigrationErrorLog (

    ExceptionLogID INT IDENTITY(1,1) PRIMARY KEY,
    LegacyID INT,
    ValidationIssue VARCHAR(500),
    EvaluationTimestamp DATETIME DEFAULT GETDATE()

);

GO

PRINT 'Ingesting raw data source extracts.';

INSERT INTO Staging_Customers (LegacyID, CustomerName, Phone, Email) VALUES
(1, 'John Doe ', '(555) 123-4567', 'john.doe@email.com'),
(1, 'John Doe', '5551234567', 'john.doe@email.com'), -- Duplicate ID & Name
(2, 'ACME Industrial Corp.', '123-456-7890', 'invalid-email-format'), -- Bad Email
(3, 'Jane Smith', NULL, 'jane@smith.com'), -- Missing Phone (Allowable but flagged)
(4, 'Bob Evans', ' 444-555-6666 ', 'bob@evans.net'),
(5, 'TechSolutions LLC', '777.888.9999', 'info@techsol.com'),
(6, 'Alice Wonderland', '1112223333', 'alice@wonder.com'),
(7, 'Charlie Brown', '222-333-4444', 'charlie@@brown.com'), -- Structural Email Error
(8, 'Delta Air', '333 444 5555', 'contact@delta.org'),
(9, 'Echo Corp', '4445556666', 'echo@corp.com'),
(10, 'Foxtrot Inc.', '555-666-7777', 'fox@trot.com'),
(11, 'Golf Masters', '666-777-8888', 'golf@masters.com'),
(12, 'Hotel Transylvania', '777-888-9999', ''), -- Empty Email String
(13, 'India Paper Co.', '888-999-0000', 'india@paper.com'),
(14, 'Juliet Bravo', '999-000-1111', 'juliet@bravo.com'),
(15, 'Kilo Industries', '000-111-2222', 'kilo@ind.com'),
(16, 'Lima Logistics', '111-222-3333', 'lima@log.com'),
(17, 'Mike Uniform', '222-333-4444', 'mike@un.com'),
(18, 'November Rain Ltd.', '333-444-5555', 'november@rain.com'),
(19, 'Oscar Meyer', '444-555-6666', 'oscar@meyer.com'),
(20, 'Papa John', '555-666-7777', 'papa@john.com'),
(21, 'Quebec Rail', '666-777-8888', 'quebec@rail.com'),
(22, 'Romeo Sierra', '777-888-9999', 'romeo@sierra.com'),
(23, 'Tango Cash', '888-999-0000', 'tango@cash.com'),
(24, 'Uniform Store', '999-000-1111', 'uniform@store.com'),
(25, 'Victor Cleaning', '000-111-2222', 'victor@clean.com'),
(26, 'Whiskey Distillers', '111-222-3333', 'whiskey@dist.com'),
(27, 'X-Ray Imaging', '222-333-4444', 'xray@img.com'),
(28, 'Yankee Stadium', '333-444-5555', 'yankee@stadium.com'),
(29, 'Zulu Nation', '444-555-6666', 'zulu@nation.com'),
(30, 'Apex Systems', '555-666-7777', 'apex@sys.com');

INSERT INTO Staging_Invoices (LegacyInvoiceID, LegacyCustomerID, Amount, InvoiceDate) VALUES
(101, 1, '$150.00', '2026-01-10'),
(102, 1, '200.50', '2026-01-11'),
(103, 2, '50.00', '2026-02-15'), -- Associated with an invalid email customer
(104, 99, '999.99', '2026-01-12'), -- ORPHAN RECORD: Customer 99 does not exist
(105, 4, '$1,200.00', '2026-03-01'),
(106, 5, '450.75', '2026-03-02'),
(107, 6, '$95.00', '2026-03-03'),
(108, 7, '320.00', '2026-03-04'), -- Associated with a broken email customer
(109, 8, '1050.00', '03/05/2026'),
(110, 9, '$22.50', '2026-03-06'),
(111, 10, '180.00', '2026-03-07'),
(112, 11, '640.00', '2026-03-08'),
(113, 12, '$500.00', '2026-03-09'), -- Associated with empty email customer
(114, 13, '45.00', '2026-03-10'),
(115, 14, '$125.50', '2026-03-11'),
(116, 15, '85.00', '2026-03-12'),
(117, 16, '310.00', '2026-03-13'),
(118, 17, '$940.00', '2026-03-14'),
(119, 18, '120.00', '2026-03-15'),
(120, 19, '250.00', '2026-03-16'),
(121, 20, '$75.00', '2026-03-17'),
(122, 21, '430.00', '2026-03-18'),
(123, 22, '$60.00', '2026-03-19'),
(124, 23, '115.00', '2026-03-20'),
(125, 24, '800.00', '2026-03-21'),
(126, 25, '$345.00', '2026-03-22'),
(127, 26, '90.00', '2026-03-23'),
(128, 27, '$110.00', '2026-03-24'),
(129, 28, '720.00', '2026-03-25'),
(130, 29, '$135.00', '2026-03-26'),
(131, 30, '410.00', '2026-03-27'),
(132, 4, '55.00', '2026-11-31'); -- INVALID DATE EXTRACTION (Nov only has 30 days)
GO

CREATE PROCEDURE sp_RunTargetMigrationPipeline
AS
BEGIN
    SET NOCOUNT ON; -- nocount disables row count feedback messages

    DECLARE @InboundRecordCount INT; -- integer variable that holds the total number of incoming raw costumer records
    SELECT @InboundRecordCount = COUNT(*) FROM Staging_Customers;

    IF @InboundRecordCount = 0 
    BEGIN 
        PRINT 'Extraction anomaly found.';
        RETURN;
    END
    ELSE
    BEGIN   
        PRINT 'Validation is confirmed! There are:' + CAST(@InboundRecordCount AS VARCHAR(10)) + 'records';
    END;



    BEGIN TRY
        BEGIN TRANSACTION;
            
            PRINT 'Processing stage A';
            WITH DeduplicationCustomers AS (
                SELECT 
                    LegacyID, -- costumer's orginal ID from their older records

                    TRIM(CustomerName) AS CustomerName, -- strips any unnecessary spaces from names
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Phone, '(', ''), ')', ''), '-', ''), ' ', '' ), '.', '') AS CleanedPhone, -- replacing unformated phone numbers with structrued numbers with no addition characters

                    LOWER(TRIM(Email)) AS Email, --strip email spaces and make it lowercase

                    -- window function: groups data rows by legacID and numbers, to identify duplicates
                    ROW_NUMBER() OVER (PARTITION BY LegacyID ORDER BY LegacyID) as RowNum

                FROM Staging_Customers

            )


-- inserting from the CTE into our permanent table
            INSERT INTO Target_Customers (LegacyID, CustomerName, CleanedPhone, Email)
            SELECT LegacyID, CustomerName, CleanedPhone, Email
            FROM DeduplicationCustomers
            WHERE RowNum = 1
                AND Email LIKE '%_@__%.__%'
                AND LegacyID IS NOT NULL;

            PRINT 'Processing Stage B: Type Normalization';

-- inserting cleaned data intot the permanent/production table

            INSERT INTO Target_Invoices(LegacyInvoiceID, CustomerID, Amount, InvoiceDate)
            SELECT 
                LI.LegacyInvoiceID,

                TC.CustomerID,

                TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(LI.Amount, '$', ''), ',', '')) AS Amount,

                TRY_CONVERT(DATE, LI.InvoiceDate) AS InvoiceDate


            FROM Staging_Invoices LI

            INNER JOIN Target_Customers TC ON LI.LegacyCustomerID = TC.LegacyID

            WHERE TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(LI.Amount, '$', ''), ',', '')) IS NOT NULL -- converts amounts written with currency signs or commas to just the number
                AND TRY_CONVERT(DATE, LI.InvoiceDate) IS NOT NULL;


        COMMIT TRANSACTION;
        PRINT 'Set-based migration process finalized';
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;

        PRINT 'System Error:' + ERROR_MESSAGE(); -- Displays the error message

        PRINT 'Failure boundary line:' + CAST(ERROR_LINE() AS VARCHAR(5));
    END CATCH
END;

GO


CREATE PROCEDURE sp_RunGranularValidationAudit
AS
BEGIN

    SET NOCOUNT ON;
    
    --LOOPS

    DECLARE @IndexID INT; -- tracks current position in the loop
    DECLARE @BoundID INT; -- tracks the maximum id in the dataset (the loop's endpoint)
    DECLARE @TargetEmail VARCHAR(255) -- store email address string extracted from the row being checked

    SELECT @IndexID  = MIN(LegacyID), @BoundID = MAX(LegacyID) FROM Staging_Customers;

    PRINT 'Initializing diagnostic engine loops.';

    WHILE @IndexID IS NOT NULL AND @IndexID <= @BoundID
    BEGIN

        SELECT TOP 1 @TargetEmail = Email FROM Staging_Customers WHERE LegacyID = @IndexID;


        -- Quality Check 1: Find out if the required email property is missing or completely blank.
        IF @TargetEmail IS NULL OR @TargetEmail = ''
        BEGIN
            INSERT INTO MigrationErrorLog (LegacyID, ValidationIssue)
            VALUES (@IndexID, 'Data Cleaning exception - Null or blank character lengths inside required email properties.')

        END

      -- Quality Check 2: Evaluate if an email exists but fails basic structural character layout syntax.
        ELSE IF @TargetEmail NOT LIKE '%_@__%.__%'
        BEGIN 
            INSERT INTO MigrationErrorLog ( LegacyID, ValidationIssue)
            VALUES (@IndexID, 'Data Structural Exception: wrong email format (' + @TargetEmail + ').');

        END

        SELECT @IndexID = MIN(LegacyID) FROM Staging_Customers WHERE LegacyID > @IndexID;
    END;

END;

GO

EXEC  sp_RunTargetMigrationPipeline;

EXEC sp_RunGranularValidationAudit;
GO


PRINT 'Compiling Operational Quality Metrics';
GO


SELECT 'Target_Customers (Loaded Successfully)' AS Dimension, Count(*) as RecordCount FROM Target_Customers
UNION ALL
SELECT 'Target_Invoices (Loaded Successfully)' AS Dimenion, COUNT(*) FROM Target_Invoices;



-- Referential Integrity Breakdown (The Orphan Tracker)
-- Runs a LEFT JOIN to expose invoices referencing an unmapped customer ID that was never imported into the main system.
SELECT 
    SI.LegacyInvoiceID,
    SI.LegacyCustomerID,
    SI.Amount,
    'Orphan Anomaly: Declared Customer relationsal identity does not exist in master extract sources' AS OperationalContext

FROM Staging_Invoices SI
LEFT JOIN Staging_Customers SC ON SI.LegacyCustomerID = SC.LegacyID
WHERE SC.LegacyID IS NULL
SELECT LegacyID, ValidationIssue, EvaluationTimestamp FROM MigrationErrorLog






        
         

