/*----All CREATE EXTERNAL TABLE scripts for Module 3----*/
--WeatherData 

--factWeatherMeasurements 
CREATE EXTERNAL TABLE [STG].[factWeatherMeasurements] 
( 
	[StationId] [nvarchar](12) NOT NULL, 
	[ObservationTypeCode] [nvarchar](4) NOT NULL, 
	[ObservationValueCorrected] [real] NOT NULL, 
	[ObservationValue] [real] NOT NULL, 
	[ObservationDate] [date] NOT NULL, 
	[ObservationSourceFlag] [nvarchar](2) NULL, 
	[fipscountycode] [varchar](5) NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSWeatherEvents, 
	LOCATION = '/factWeatherMeasurements/', 
	FILE_FORMAT = TextFileFormat 
); 
 
--dimWeatherObservationTypes 
CREATE EXTERNAL TABLE [STG].[dimWeatherObservationTypes] 
( 
	[ObservationTypeCode] [nvarchar](5) NOT NULL, 
	[ObservationTypeName] [nvarchar](100) NOT NULL, 
	[ObservationUnits] [nvarchar](5) NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSWeatherEvents, 
	LOCATION = '/dimWeatherObservationTypes/', 
	FILE_FORMAT = TextFileFormat 
); 
 
--dimUSFIPSCodes 
CREATE EXTERNAL TABLE [STG].[dimUSFIPSCodes] 
( 
	[FIPSCode] [varchar](5) NOT NULL, 
	[StateFIPSCode] [smallint] NOT NULL, 
	[CountyFIPSCode] [smallint] NOT NULL, 
	[StatePostalCode] [varchar](2) NOT NULL, 
	[CountyName] [varchar](35) NOT NULL, 
	[StateName] [varchar](30) NOT NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSWeatherEvents, 
	LOCATION = '/dimUSFIPSCodes/', 
	FILE_FORMAT = TextFileFormat 
); 
 
--dimWeatherObservationSites 
CREATE EXTERNAL TABLE [STG].[dimWeatherObservationSites] 
( 
	[StationId] [nvarchar](20) NOT NULL, 
	[SourceAgency] [nvarchar](10) NOT NULL, 
	[StationName] [nvarchar](150) NULL, 
	[CountryCode] [varchar](2) NULL, 
	[CountryName] [nvarchar](150) NULL, 
	[StatePostalCode] [varchar](3) NULL, 
	[FIPSCountyCode] [varchar](5) NULL, 
	[StationLatitude] [decimal](11, 8) NULL, 
	[StationLongitude] [decimal](11, 8) NULL, 
	[NWSRegion] [nvarchar](30) NULL, 
	[NWSWeatherForecastOffice] [nvarchar](20) NULL, 
	[GroundElevation_Ft] [real] NULL, 
	[UTCOffset] [nvarchar](10) NULL 
	) 
WITH 
( 
	DATA_SOURCE = USGSWeatherEvents, 
	LOCATION = '/dimWeatherObservationSites/', 
	FILE_FORMAT = TextFileFormat 
); 
 
/*----fireevents----*/ 
 
--dimOrganizationCode 
CREATE EXTERNAL TABLE [STG].[dimOrganizationCode]
( 
	[OrganizationCode] [nvarchar](5) NOT NULL, 
    [OrganizationName] [nvarchar](100) NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSFireEvents, 
	LOCATION = '/dbo.dimOrganizationCode.txt', 
	FILE_FORMAT = TextFileFormat 
); 
 
--dimAreaProtectionCategory 
CREATE EXTERNAL TABLE [STG].[dimAreaProtectionCategory] 
( 
	[ProtectionCategoryCode] [nvarchar](2) NOT NULL, 
    [ProtectionCategoryDescription] [nvarchar](150) NOT NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSFireEvents, 
	LOCATION = '/dbo.dimAreaProtectionCategory.txt', 
	FILE_FORMAT = TextFileFormat 
); 
 
--factFireEvents 
CREATE EXTERNAL TABLE [STG].[factFireEvents]
( 
    [ObjectId] [int] NOT NULL, 
    [OrganizationCode] [nvarchar](5) NOT NULL, 
    [ReportingFireUnit] [varchar](5) NOT NULL, 
    [ReportingFireSubUnitId] [nvarchar](10) NOT NULL, 
    [ReportingFireSubUnitName] [nvarchar](100) NOT NULL, 
    [FireId] [varchar](15) NOT NULL, 
    [FireName] [nvarchar](55) NOT NULL, 
    [USFSFireNumber] [varchar](20) NOT NULL, 
    [FireIncidentCode] [varchar](10) NOT NULL, 
    [HumanOrNaturalCause] [nvarchar](15) NOT NULL, 
    [PreciseCauseCode] [int] NOT NULL, 
    [StatisticalCauseCode] [int] NOT NULL, 
    [FireSizeClassCode] [nvarchar](5) NOT NULL, 
    [FireSizeClassNumber] [int] NOT NULL, 
    [FireResponseCode] [int] NOT NULL, 
    [AreaProtectionCategoryCode] [nvarchar](2) NOT NULL, 
    [FireManagementResponseCode] [nvarchar](2) NOT NULL, 
    [YearString] [varchar](5) NOT NULL, 
    [FiscalYear] [int] NOT NULL, 
    [FireDiscoveryTime] [datetime2](7) NULL, 
    [FireSupressTime] [datetime2](7) NULL, 
    [FireExtinguishTime] [datetime2](7) NULL, 
    [GeographicAreaCoordinationCenter] [varchar](5) NOT NULL, 
    [DispatchCenterName] [nvarchar](60) NOT NULL, 
    [StateName] [nvarchar](25) NOT NULL, 
    [StateFipsCode] [varchar](2) NOT NULL, 
    [FipsInt] [int] NOT NULL, 
    [FireLatitude] [varchar](20) NULL, 
    [FireLongitude] [varchar](20) NULL, 
    [TotalAcres] [float] NOT NULL, 
    [GeneralCauseCategoryCode] [int] NOT NULL, 
    [PreciseCauseCategoryCode] [int] NOT NULL, 
    [Duration_Days] [int] NULL, 
    [FireLongitudeDetail] [varchar](20) NULL, 
    [FireLatitudeDetail] [varchar](20) NULL 
) 
WITH 
( 
	DATA_SOURCE = USGSFireEvents, 
	LOCATION = '/dbo.factFireEvents.txt', 
	FILE_FORMAT = TextFileFormat 
); 