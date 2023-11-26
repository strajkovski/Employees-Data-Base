CREATE DATABASE WinterProject
GO

USE WinterProject
GO

---CREATE TABLE SENIORITY LEVEL

CREATE TABLE  dbo.Senioritylevel(
Id int identity(1,1) not null,
Name nvarchar(100)not null,
CONSTRAINT PK_Senioritylevel PRIMARY KEY CLUSTERED (Id ASC)
)

select * from dbo.Senioritylevel

----CREATE LOCATION TABLE

CREATE TABLE dbo.Location(
Id int identity (1,1) not null,
CountryName nvarchar(100) null,
Continent nvarchar (100) null,
Region nvarchar (100) null,
CONSTRAINT PK_Location PRIMARY KEY CLUSTERED (Id asc))

select * from dbo.Location

-----CREATE TABLE DEPARTMENTS

CREATE TABLE dbo.Department(
Id int identity (1,1)not null,
Name nvarchar(100) not null,
CONSTRAINT PK_Department PRIMARY KEY CLUSTERED (Id asc))

select * from dbo.Department


------CREATE TABLE EMPLOYEE 


CREATE TABLE dbo.Employee(
Id int identity (1,1) not null,
FirstName nvarchar (100) not null,
LastName nvarchar (100) not null,
LocationId int not null,
SenioritylevelId int not null,
DepartmentId int not null,
CONSTRAINT PK_Employee Primary Key CLUSTERED (Id asc))

select * from dbo.Employee 

----CREATE SALARY TABLE


CREATE TABLE dbo.Salary(
Id bigint identity(1,1) not null,
EmployeeId int not null,
Month smallint not null,
Year smallint not null,
GrossAmount decimal(18,2) not null,
NetAmount decimal(18,2) not null,
RegularWorkAmount decimal(18,2)not null,
BonusAmount decimal(18,2) not null,
OvertimeAmount decimal(18,2) not null,
VacationDays smallint not null,
SickLeaveDays smallint not null,
CONSTRAINT PK_Salary Primary Key CLUSTERED (Id asc))

select * from dbo.Salary


---====ADD FOREIGN KEYS

ALTER TABLE dbo.Employee 
ADD CONSTRAINT FK_Senioritylevel_Employee FOREIGN KEY (SenioritylevelId)
REFERENCES dbo.Senioritylevel (Id)


ALTER TABLE dbo.Employee 
ADD CONSTRAINT FK_Location_Employee FOREIGN KEY (LocationId)
REFERENCES dbo.Location (Id)


ALTER TABLE dbo.Employee 
ADD CONSTRAINT FK_Department_Employee FOREIGN KEY (DepartmentId)
REFERENCES dbo.Department (Id)


ALTER TABLE dbo.Salary
ADD CONSTRAINT FK_Employee_Salary FOREIGN KEY (EmployeeId)
REFERENCES dbo.Employee(Id)




--========================INSERT DATA=============================

-----POPULATE SENIORITY LEVEL

INSERT INTO dbo.Senioritylevel(Name)
Values('Junior'),('Intermidiate'),('Senior'),('Lead'),('Project Manager'),('Division Manager'),('Office Manager'),('CEO'),('CTO'),('CIO')

select * from dbo.Senioritylevel


-----POPULATE LOCATION
CREATE OR ALTER PROCEDURE dbo.InsertLocation 
AS 
BEGIN
  INSERT INTO dbo.Location(CountryName,Continent,Region)
  SELECT  CountryName,Continent,Region
  FROM WideWorldImporters.Application.Countries
END 

BEGIN TRAN
EXEC dbo.InsertLocation
SELECT * FROM DBO.Location

COMMIT

select * from dbo.Location



----POPULATE DEPARTMENTS

INSERT INTO dbo.Department(Name)
VALUES('Personal Banking & Operations'),('Digital Banking Department'),('Retail Banking & Marketing Department'),('Wealth Managment & Third Party Products'),
('International Banking Division & DFB'),('Treasury'),('Information Techonlogy'),('Corporate Communications'),('Support Services & Branch Expansion'),('Human Recourses')

Select * from dbo.Department



-----POPULATE EMPLOYEE
 CREATE OR ALTER PROCEDURE dbo.InsertingEmployeesNames
 AS
 BEGIN

     INSERT INTO dbo.Employee(FirstName,LastName,LocationId,SenioritylevelId,DepartmentId)
	
	SELECT  PreferredName as FirstName , right(fullname,len (fullname)-charindex(' ',FullName)) as LastName,
	NTILE(190)OVER (Order by personid) as LocationId,NTILE (10) OVER(Order by phonenumber) as SenioritylevelId,
	NTILE(10)OVER(Order by fullname) AS DepartmentId 
    FROM WideWorldImporters.Application.People
	WHERE PersonID <> 1 
	ORDER BY PersonID
	
END

 BEGIN  TRAN
 EXEC dbo.InsertingEmployeesNames
 SELECT * FROM dbo.Employee AS e
 COMMIT

 ---------POPULATE SALARY

--INSERT INTO dbo.Salary(Id,EmployeeId,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount,VacationDays,SickLeaveDays)
---CREATE TEMP TABLS
---Create Date Table

CREATE TABLE #MonthYears (
[Month] smallint not null,
[Year] smallint not null

)

SELECT * FROM #MonthYears


INSERT INTO #MonthYears([Month],[Year])
SELECT DISTINCT [Month] , [Year]
FROM BrainsterDW.dimensions.Date
WHERE [Month] between 1 and 12 and [Year] between 2001 and 2020
ORDER BY  [Month],[Year]


WITH cte
AS
(
SELECT Id,m.Month,m.Year
FROM Employee
cross join 
#MonthYears AS m
)

SELECT *, 18000 + ABS(CHECKSUM(NewID())) % 40000 as GrossAmount
FROM cte
ORDER BY Id,[Month],[Year]

----GrossAmount


CREATE TABLE #GrossAmounts(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null)


SELECT * FROM #GrossAmounts

WITH cte
AS
(
SELECT Id,m.[Month],m.[Year]
FROM Employee
cross join 
#MonthYears AS m
)

INSERT INTO #GrossAmounts(Id,[Month],[Year],GrossAmount)

SELECT Id,[Month],[Year] ,18000 + ABS(CHECKSUM(NewID())) % 40000 AS GrossAmount
FROM cte
ORDER BY Id,[Month],[Year]

SELECT * FROM #GrossAmounts
ORDER BY Id,[Month],[Year]

-----------NetAmount

CREATE TABLE #GrossAmountNetAmounts(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null,
NetAmount int not null)


INSERT INTO #GrossAmountNetAmounts(Id,[Month],[Year],GrossAmount,NetAmount)

SELECT Id,[Month],[Year],GrossAmount,GrossAmount -(GrossAmount * 10/100) AS NetAmount
FROM #GrossAmounts
-----
SELECT *
FROM #GrossAmountNetAmounts

----RegularAmount

CREATE TABLE #RegularAmount(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null,
NetAmount int not null,
RegularWorkAmount int not null)

INSERT #RegularAmount(Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount)

SELECT Id,[Month],[Year],GrossAmount,NetAmount,NetAmount -(NetAmount * 20/100) as RegularWorkAmount
FROM #GrossAmountNetAmounts

SELECT * FROM #RegularAmount
ORDER BY id,[Month],[Year]

-------------BonusAmount
CREATE TABLE #BonusAmount(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null,
NetAmount int not null,
RegularWorkAmount int not null,
BonusAmount int not null
)
INSERT INTO #BonusAmount(Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount)

SELECT Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,NetAmount-RegularWorkAmount as BonusAmount
FROM #RegularAmount

BEGIN TRAN

UPDATE b
SET BonusAmount=0
FROM #BonusAmount as b
WHERE cast([Month] as int)%2=0 

SELECT * FROM  #BonusAmount

COMMIT


SELECT * FROM  #BonusAmount
WHERE [Month]  in (2,4,6,8,10,12)



---------------	OvertimeAmount
CREATE TABLE #OvertimeAmount(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null,
NetAmount int not null,
RegularWorkAmount int not null,
BonusAmount int not null,
OvertimeAmount int  not null
)

INSERT INTO #OvertimeAmount(Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount,OvertimeAmount)

SELECT Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount ,NetAmount-RegularWorkAmount as OvertimeAmount
FROM #BonusAmount

SELECT * FROM #OvertimeAmount


UPDATE o
SET OvertimeAmount=0
FROM #OvertimeAmount as o
WHERE [Month] not in (2,4,6,8,10,12)

SELECT * FROM #OvertimeAmount
ORDER BY id,[Month],[Year]



------------VICATIONDAYS, SICKDAYS

CREATE TABLE #VicationSickDaysALL(
Id int not null,
[Month] int not null,
[Year] int not null,
GrossAmount int not null,
NetAmount int not null,
RegularWorkAmount int not null,
BonusAmount int not null,
OvertimeAmount int  not null,
VacationDays int not null,
SickLeaveDays int not null
)

INSERT INTO #VicationSickDaysALL(Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount,OvertimeAmount,VacationDays,SickLeaveDays)

SELECT Id,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount , OvertimeAmount, 0 as VacationDays, 0 as SickLeaveDays
FROM #OvertimeAmount

SELECT * FROM #VicationSickDaysALL


-----------POPULATE SALARY
SELECT * FROM DBO.Salary

INSERT INTO Salary (EmployeeId,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount,OvertimeAmount,VacationDays,SickLeaveDays)

SELECT Id as EmployeeId,[Month],[Year],GrossAmount,NetAmount,RegularWorkAmount,BonusAmount,OvertimeAmount,VacationDays,SickLeaveDays
From #VicationSickDaysALL
ORDER BY Id,[Month],[Year]

SELECT *
FROM Salary

-------UPDATE SALARY
BEGIN TRAN
UPDATE s
SET VacationDays =FLOOR(RAND()*(30-20+1)+20)
--select VacationDays, MONTH
FROM Salary as s
WHERE [Month]=8 or [Month]=12

SELECT * FROM Salary
WHERE [Month] IN (8,12)

COMMIT



-------------

update dbo.salary set vacationDays = vacationDays + (EmployeeId % 2)
where  (employeeId + MONTH+ year)%5 = 1
GO
update dbo.salary set SickLeaveDays = EmployeeId%8, vacationDays = vacationDays + (EmployeeId % 3)
where  (employeeId + MONTH+ year)%5 = 2
GO



SELECT * FROM dbo.salary 
WHERE NetAmount <> (regularWorkAmount + BonusAmount + OverTimeAmount)

-----------------
SELECT * FROM dbo.Senioritylevel
SELECT * FROM dbo.Department
SELECT * FROM dbo.Location
SELECT * FROM dbo.Employee
SELECT * FROM dbo.Salary
