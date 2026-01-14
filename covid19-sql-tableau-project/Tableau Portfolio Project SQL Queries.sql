/*
Tableau Portfolio Project – SQL Data Preparation
------------------------------------------------
Purpose:
This SQL script prepares aggregated and cleaned datasets 
to be exported to Excel and used in Tableau dashboards.

The queries focus on global COVID-19 metrics such as:
- Total cases and deaths
- Death percentages
- Infection rates by country
- Continent-level comparisons

Skills demonstrated:
- Aggregations
- Data filtering
- Data consistency checks
- Preparing reporting-ready datasets
*/


/* =====================================================
   Query 1: Global COVID-19 numbers
   -----------------------------------------------------
   Provides total cases, total deaths, and death percentage
   across all countries (excluding null continents).
   Used for global KPI cards in Tableau.
   ===================================================== */

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortofolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


/*
Data validation note:
A secondary query using location = 'World' was tested.
Results were nearly identical, confirming data consistency.
The main query was kept for alignment with other datasets.
*/


/* =====================================================
   Query 2: Total deaths by continent / region
   -----------------------------------------------------
   Excludes 'World', 'European Union', and 'International'
   to maintain consistency with global calculations.
   Used for bar charts in Tableau.
   ===================================================== */

SELECT 
    location, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM PortofolioProject.dbo.CovidDeaths
WHERE continent IS NULL
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


/* =====================================================
   Query 3: Countries with highest infection rate
   -----------------------------------------------------
   Calculates the highest recorded infection count
   and percentage of population infected per country.
   Used for ranking and comparison visuals.
   ===================================================== */

SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM PortofolioProject.dbo.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


/* =====================================================
   Query 4: Infection rate over time (by country)
   -----------------------------------------------------
   Shows how infection percentages evolved by date.
   Useful for time-series and trend analysis in Tableau.
   ===================================================== */

SELECT 
    Location, 
    Population,
    date, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM PortofolioProject.dbo.CovidDeaths
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC;


/* =====================================================
   Additional Queries (Optional / Extended Analysis)
   -----------------------------------------------------
   These queries were initially used but excluded from
   the final Tableau video to keep it concise.
   They are kept here for reference and deeper analysis.
   ===================================================== */


/* -----------------------------------------------------
   Vaccination progress per country
   ----------------------------------------------------- */

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    MAX(vac.total_vaccinations) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population
ORDER BY 1,2,3;


/* -----------------------------------------------------
   Country-level COVID overview
   ----------------------------------------------------- */

SELECT 
    Location, 
    date, 
    population, 
    total_cases, 
    total_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


/* -----------------------------------------------------
   CTE: Population vs Vaccination Analysis
   -----------------------------------------------------
   Calculates rolling vaccination totals and percentage
   of population vaccinated.
   ----------------------------------------------------- */

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
        AS RollingPeopleVaccinated
    FROM PortfolioProject.dbo.CovidDeaths dea
    JOIN PortfolioProject.dbo.CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPeopleVaccinated
FROM PopvsVac;


/* =====================================================
   End of Script
   -----------------------------------------------------
   All queries are designed to be exported to Excel
   and directly connected to Tableau for visualization.
   ===================================================== */
