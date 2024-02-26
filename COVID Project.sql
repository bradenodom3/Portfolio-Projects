-- COVID PROJECT OVERVIEW

-- Contents:
	-- Showed worldwide likelihood of dying if one were to contract COVID
	-- Found total death count by continent
	-- Calculated what percentage of each country's population has contracted COVID at some point
	-- Fixed data types
	-- Created a rolling count of vaccinations in each country for every date
	-- Showed basic info about various countries' populations, total cases, and total deaths as of various dates
	-- Provided a total number of vaccinations given in each country as of the most recent date they have data for, as well as a percent of the population that has been vaccinated
	-- Included data to find correlation on various factors and a country's death percentage (age, diabetes prevalence, number of hospital beds, etc.)


-- Note: Data was cleaned using Excel/Power Query before analyzing in SQL

------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1) Shows worldwide likelihood of dying if one were to contract COVID
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- 2) Shows total death count by continent
SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NULL 
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- 3) Shows what percentage of each country's population has contracted COVID at some point
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentInfected
FROM Portfolio..CovidDeaths
GROUP BY location, population, continent
ORDER BY PercentInfected DESC;


-- 4) Same thing as previous query, but includes date field to show numbers for each date
SELECT continent, location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentInfected
FROM Portfolio..CovidDeaths
GROUP BY location, population, continent, date
ORDER BY PercentInfected DESC;


-- 5) Next two change data type initially so I don't have to do it each time in future queries
ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN total_cases float;

ALTER TABLE Portfolio..CovidDeaths
ALTER COLUMN total_deaths float;


-- 6) Shows a rolling count of vaccinations in each country for every date
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;


-- 7) Shows some basic info about various countries' populations, total cases, and total deaths as of various dates
SELECT Location, date, population, total_cases, total_deaths
FROM Portfolio..CovidDeaths
--Where location like '%states%'
WHERE continent is not null 
ORDER BY 1,2;



-- 8) Shows a total number of vaccinations given in each country as of the most recent date they have data for, as well as a percent of the population that has been vaccinated
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingCountVaccinations)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT location, MAX(date) AS Most_recent_date, MAX(RollingCountVaccinations) AS Total_Vaccinations, MAX(population) AS Population, MAX(RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM PopVsVac
GROUP BY location
ORDER BY percent_vaccinated DESC;

 

-- CORRELATION QUERIES
-- 9) Effect of Aging population on death percentage
SELECT v.continent, v.location, ROUND(AVG(v.aged_70_older),2) AS 'Percent 70+', (SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent
ORDER BY [Percent 70+] DESC;


-- 10) Effect of people fully vaccinated on death percentage
SELECT v.continent, v.location, AVG(d.population) AS Population, 
	ROUND(AVG(CAST(v.people_fully_vaccinated AS float)),0) AS Total_Ppl_Vaxed, 
	ROUND(AVG(CAST(v.people_fully_vaccinated AS float)),0)/AVG(d.population)*100 AS PercentVaxed,
	100 - (ROUND(AVG(CAST(v.people_fully_vaccinated AS float)),0)/AVG(d.population)*100) AS PercentUnvaxed,
	(SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent
ORDER BY PercentVaxed DESC;

-- 11) Effect of diabetes
SELECT v.continent, v.location, v.diabetes_prevalence, (SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent, v.diabetes_prevalence
ORDER BY v.diabetes_prevalence DESC;

-- 12) Effect of smoking
SELECT v.continent, v.location, (AVG(CAST(v.male_smokers AS float)) + AVG(CAST(v.female_smokers AS float))) AS Smokers, (SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent
ORDER BY Smokers DESC;

-- 13) Effect of poverty
SELECT v.continent, v.location, AVG(CAST(extreme_poverty AS float)) AS poverty_rate, (SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent
ORDER BY poverty_rate DESC;

-- 14) Effect of available hospital beds
SELECT v.continent, v.location, AVG(hospital_beds_per_thousand) AS Hospital_beds_per_thousand, (SUM(d.new_deaths)/SUM(d.new_cases))*100 AS DeathPercentage
FROM Portfolio..CovidVaccinations AS v
	JOIN Portfolio..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
	AND d.new_cases IS NOT NULL
	AND d.new_cases NOT LIKE '0' -- Eliminate countries with no new cases
GROUP BY v.location, v.continent
ORDER BY Hospital_beds_per_thousand DESC;