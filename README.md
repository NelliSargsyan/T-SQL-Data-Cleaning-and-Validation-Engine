This is a T-SQL project which migrates messy customer legacy data and invoice data into a relational schema. It in done in MS SQL Server. It uses two types of data cleansing: set-based (CTEs, window functions) and row-based (a WHILE loop).

What the project does:
• Firstly, tables are created which are dropped and recreated after each run. Tables intentionally have invalid and messy data points to be able to practice and demonstrate dealing with them.

• Catches bad data points such as duplicate ID, malformed emails, wrong phone number and currency formats, and inconsistent dates and fixes them through T-SQL functions. 

• sp_RunTargetMigrationPipeline is the core ETL procedure which deduplicates legacy ID (Using ROW_NUMBER() window functions), trims names, fixes phone number formats, and filters out any structurally invalid emails. It also converts loose strings into dates, using TRY_CONVERT. Drops the rows that fail transaction. It runs inside a transaction with TRT/CATCH so that the program doesn't crash.

• sp_RunGranularValidationAudit catches the data quality issues and puts them into MigrationErrorLog.


What is needed to run: SQl Server, compatible with SSMS or Azure Data Studio

How to Run: Execute the script top to bottom. It is fully rerunnable.

The output is 3 tables which showcase insights about the data quality:
• Record Counts in a table (number of records that were loaded sucessfully)
• This is the orphan anomaly report. Customers who are in the Legacy tables but not in the Staging Customers ones. In simpler terms, catches customers who were in older (legacy) customer tables, but are not in the invoice ones.
• Full log of validation issues in MigrationErrorLog


