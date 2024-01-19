-- QUERIES TO USE IN TABLEAU VISUALIZATIONS


-- GLOBAL NUMBERS
-- 1) Shows worldwide likelihood of dying if one were to contract COVID
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- 2) Shows total death count by continent
SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NULL 
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- 3) Shows what percentage of each country's population has contracted COVID at some point
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population, continent
ORDER BY PercentInfected DESC;


-- 4) Same thing as previous query, but includes date field to show numbers for each date
SELECT continent, location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population, continent, date
ORDER BY PercentInfected DESC;



-- 5) Next two change data type initially so I don't have to do it each time in future queries
ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_cases float;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_deaths float;



-- VISUALIZATIONS TO POSSIBLY INCLUDE LATER

-- 6) Shows a rolling count of vaccinations in each country for every date
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM [Portfolio Project]..CovidVaccinations AS v
	JOIN [Portfolio Project]..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;


-- 7) Shows some basic info about various countries' populations, total cases, and total deaths as of various dates
SELECT Location, date, population, total_cases, total_deaths
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
WHERE continent is not null 
ORDER BY 1,2;



-- 8) Shows a rolling count of vaccinations in each country on each date, as well as a percent of the population that has been vaccinated
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingCountVaccinations)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM [Portfolio Project]..CovidVaccinations AS v
	JOIN [Portfolio Project]..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM PopVsVac;


