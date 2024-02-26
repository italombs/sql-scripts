--------------------------------------------------------------------------------------------
--Transform your result sets in a create table variables, temporary tables or physical table
--------------------------------------------------------------------------------------------

CREATE PROC sp_QueryToCreateSchema
(
	@objectDefinition NVARCHAR(MAX),
	@queryExpression NVARCHAR(MAX)
)
AS
	
	SELECT 
		@objectDefinition + ' (' +
		STUFF ((SELECT ',
	    '+	QUOTENAME(Coalesce(DuplicateNames.name+'_' 
		 + CONVERT(VARCHAR(5),f.column_ordinal),f.name))
	     + ' '+ System_type_name 
		 + CASE WHEN is_nullable = 0 THEN ' NOT' ELSE ''END+' NULL'
	   --+ CASE WHEN collation_name IS NULL THEN '' ELSE ' COLLATE '+collation_name END
	   AS ThePath
	  FROM sys.dm_exec_describe_first_result_set(@queryExpression, NULL, 1) AS f
	  LEFT JOIN(
			SELECT name AS name 
			FROM sys.dm_exec_describe_first_result_set(@queryExpression, NULL, 0) 
			WHERE is_hidden=0 
			GROUP 
			BY name 
			HAVING Count(*)>1
	  ) AS DuplicateNames
			ON DuplicateNames.name = f.name
	  WHERE f.is_hidden=0
	  ORDER BY column_ordinal
	  FOR XML PATH (''), TYPE).value('.', 'varchar(max)'),1,1,'')+')'
GO


/*HOW TO USE*/

--1. To generete temporary table
EXEC sp_QueryToCreateSchema
		@objectDefinition = 'CREATE TABLE #systemTables',
		@queryExpression =
		N'
		SELECT *
		FROM  sys.tables tbl
		INNER JOIN sys.schemas sch
			ON (tbl.[schema_id] = sch.[schema_id])'
GO


--2. To generete table variable
EXEC sp_QueryToCreateSchema
		@objectDefinition = 'DECLARE @systemTables TABLE',
		@queryExpression =
		N'
		SELECT *
		FROM  sys.tables tbl
		INNER JOIN sys.schemas sch
			ON (tbl.[schema_id] = sch.[schema_id])'
GO


--3. To generete physical table
EXEC sp_QueryToCreateSchema
		@objectDefinition = 'CREATE TABLE systemTables',
		@queryExpression =
		N'
		SELECT *
		FROM  sys.tables tbl
		INNER JOIN sys.schemas sch
			ON (tbl.[schema_id] = sch.[schema_id])'
GO
