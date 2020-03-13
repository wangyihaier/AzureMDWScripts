--Total precipitation and acres burned per year in California
SELECT	f.fipsInt AS StateFipsCode,
		c.StateName,
		f.FiscalYear AS ObservationYear,
		SUM(a.ObservationValue) AS TotalPrecipitation_mm,
		SUM(f.TotalAcres) AS TotalAcresBurned
FROM	prod.factWeatherMeasurements a
JOIN	prod.dimUSFIPSCodes c on (c.fipscode = a.fipscountycode)
JOIN	prod.factFireEvents f on (f.fipsint = c.statefipscode)
WHERE	a.ObservationTypeCode IN ('PRCP','SNOW') AND f.FiscalYear = YEAR(a.ObservationDate) AND c.fipscode like '06%' AND f.fiscalyear > 2014
GROUP	BY f.fipsInt, c.StateName, f.FiscalYear
ORDER	BY c.StateName, ObservationYear ASC
OPTION (LABEL = 'WeatherMonitorFast')
