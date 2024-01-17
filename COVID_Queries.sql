--SELECT * 
--FROM [Portfolio Project]..CovidVaccinations
--ORDER BY 3,4

-- Select all the data that we will be using

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_deaths numeric

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in the USA
SELECT continent, location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like'%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population has contracted COVID at some point
SELECT continent, location, date, total_cases, population, (total_cases/population)*100 AS PercentOfPop
FROM [Portfolio Project]..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- What countries have highest infection rates compared to population?
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentOfPop
FROM [Portfolio Project]..CovidDeaths
	--WHERE location LIKE '%states%'
GROUP BY location, population, continent
ORDER BY PercentOfPop DESC;

-- What countries have highest death rate (Per Case & Per Population)?
ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_cases float;

SELECT continent, location, population, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeathCount, ROUND(MAX(total_deaths)/MAX(total_cases)*100,2) AS DeathPct_byCase, ROUND(MAX(total_deaths)/population*100,2) AS DeathPct_byPop
FROM [Portfolio Project]..CovidDeaths
	--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population, continent
ORDER BY DeathPct_byCase ASC;

-- Same thing, but by Continent
SELECT continent, MAX(population) AS pop, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeathCount, ROUND(MAX(total_deaths)/MAX(total_cases)*100,2) AS DeathPct_byCase, CAST(MAX(total_deaths)/MAX(population)*100 AS numeric(10,8)) AS DeathPct_byPop 
FROM [Portfolio Project]..CovidDeaths
	--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathPct_byCase ASC;

SELECT continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



-- Looking at Total Population vs. Vaccination
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations,
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM [Portfolio Project]..CovidVaccinations AS v
	JOIN [Portfolio Project]..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;


-- Use CTE
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



-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingCountVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM [Portfolio Project]..CovidVaccinations AS v
	JOIN [Portfolio Project]..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
--WHERE d.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM #PercentPopulationVaccinated;


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinations
	-- RollingCountVaccinations/population)*100 AS percent_vaccinated
FROM [Portfolio Project]..CovidVaccinations AS v
	JOIN [Portfolio Project]..CovidDeaths AS d
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated