/*
Covid-19 Data Exploration Project
---------------------------------
Skills Demonstrated: 
- Joins
- Common Table Expressions (CTEs)
- Temporary Tables
- Window Functions
- Aggregate Functions
- Views
- Data Type Conversion

This project explores global Covid-19 data, focusing on cases, deaths, population impact, 
and vaccinations. It provides insights at the country and continent level, using SQL best practices.
*/

/* -------------------------------
   Step 1: Preview the dataset
   ------------------------------- */
-- Select all data for rows where continent is not null
-- This helps to quickly explore the structure and columns
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;  -- Ordered by 3rd and 4th columns (likely date & total_cases)

/* -------------------------------
   Step 2: Focused data selection
   ------------------------------- */
-- Selecting key columns for initial analysis
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;  -- Ordered by Location and Date

/* -------------------------------
   Step 3: Death rate analysis
   ------------------------------- */
-- Shows likelihood of dying if you contract COVID in a country
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY 1,2;

/* -------------------------------
   Step 4: Infection rate relative to population
   ------------------------------- */
SELECT Location, date, Population, total_cases,  
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

/* -------------------------------
   Step 5: Countries with highest infection rate
   ------------------------------- */
SELECT Location, Population, 
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

/* -------------------------------
   Step 6: Countries with highest death count
   ------------------------------- */
SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

/* -------------------------------
   Step 7: Deaths broken down by continent
   ------------------------------- */
SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

/* -------------------------------
   Step 8: Global Covid-19 numbers
   ------------------------------- */
-- Total global cases, deaths, and overall death percentage
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths,
       SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

/* -------------------------------
   Step 9: Vaccinations vs Population
   ------------------------------- */
-- Shows cumulative vaccinations per country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) 
       OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

/* -------------------------------
   Step 10: Using CTE for vaccination calculations
   ------------------------------- */
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CONVERT(INT, vac.new_vaccinations)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
      ON dea.location = vac.location
      AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

/* -------------------------------
   Step 11: Using Temp Table for vaccination calculations
   ------------------------------- */
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) 
       OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

/* -------------------------------
   Step 12: Creating a View for visualizations
   ------------------------------- */
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(INT, vac.new_vaccinations)) 
       OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
