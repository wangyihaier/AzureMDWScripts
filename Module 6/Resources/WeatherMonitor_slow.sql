--Total precipitation and acres burned per year in California
SELECT	c.StateName,
		f.FiscalYear AS ObservationYear,
		SUM(a.ObservationValueCorrected) AS TotalPrecipitation_mm,
		SUM(f.TotalAcres) AS TotalAcresBurned
FROM	prod.factWeatherMeasurements a
JOIN	prod.dimUSFIPSCodes c on (c.fipscode = a.fipscountycode)
JOIN	prod.factFireEvents f on (f.fipsint = c.statefipscode)
WHERE	a.ObservationTypeCode IN ('PRCP','SNOW') AND f.FiscalYear = YEAR(a.ObservationDate) AND c.StateName = 'California' AND f.fiscalyear > 2014
GROUP	BY c.StateName, f.FiscalYear
ORDER	BY c.StateName, ObservationYear ASC
OPTION (LABEL = 'WeatherMonitorSlow')

