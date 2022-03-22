--SELECT * 
--FROM PortfolioProject..CovidDeaths
--ORDER BY 3, 4

--Rename column with no name
--exec sp_rename '..CovidDeaths. ', 'population', 'COLUMN';

--Select Data that i'm going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM ..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

--Looking at Total Cases vs Total Deaths
--Shows likelyhood of dying if you got infected with Covid 19
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as InfectedDeathPercentage
FROM ..CovidDeaths
WHERE location like '%pola%' 
ORDER BY 1, 2

--Total Cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, population, total_cases, new_cases, (total_cases/population)*100 as InfectedPercentage
FROM ..CovidDeaths
WHERE location like '%pola%' and continent is not null
ORDER BY 1, 2

--Looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPercentage
FROM ..CovidDeaths
--WHERE location like '%pola%'
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectedPercentage desc

--Shows countries with the highest death rate compared to population
SELECT location, population, MAX(cast(total_deaths as int)) as HighestDeathCount, MAX((total_deaths/population))*100 as PopulationDeathPercentage
FROM ..CovidDeaths
--WHERE location like '%pola%'
WHERE continent is not null
GROUP BY location, population
ORDER BY PopulationDeathPercentage desc

---------------------------------------------------------------------
-- PROPER LOCATION --
--Shows continents with the highest death count
SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM ..CovidDeaths
--WHERE location like '%pola%'
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathCount desc
-- PROPER LOCATION --

-- FOR VISUALIZATION --
--Shows continents with the highest death count
SELECT continent, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM ..CovidDeaths
--WHERE location like '%pola%'
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount desc
-- FOR VISUALIZATION --
---------------------------------------------------------------------

-- Numbers globally (For later visualization purposes) --

--Shows daily new cases, new deaths and death percentage across the world
SELECT date, SUM(new_cases) as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as PopulationDeathPercentage
FROM ..CovidDeaths
WHERE continent is not null
GROUP BY date			-- NOTE: To use a 'group by' statement on something, You need to aggregate the data in a way that allows it. --
ORDER BY 1

-- VACCINATIONS --

--Looking at number of people vaccinated in the context of a total population 
SELECT cDea.continent, cDea.location, cDea.date, cDea.population, cVac.new_vaccinations
, SUM(cast(cVac.new_vaccinations as bigint)) OVER (PARTITION BY cDea.location ORDER BY cDea.location, cDea.date) as VaccSum
FROM ..CovidDeaths cDea
JOIN ..CovidVaccinations cVac
	ON cDea.location = cVac.location
	AND cDea.date = cVac.date
WHERE cDea.location like '%pola%' and cDea.continent is not null
ORDER BY 2, 3

	-- USE CTE --
	WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, VaccSum)
	AS
	(
		SELECT cDea.continent, cDea.location, cDea.date, cDea.population, cVac.new_vaccinations
		, SUM(cast(cVac.new_vaccinations as bigint)) OVER (PARTITION BY cDea.location ORDER BY cDea.location, cDea.date) as VaccSum
		FROM ..CovidDeaths cDea
		JOIN ..CovidVaccinations cVac
			ON cDea.location = cVac.location
			AND cDea.date = cVac.date
		WHERE cDea.location like '%pola%' and cDea.continent is not null
		--ORDER BY 2, 3
	)

	SELECT *, (VaccSum/Population)*100 as VaccinatedPercentage
	FROM PopVsVac

	-- TEMP TABLE --
	DROP TABLE IF EXISTS PercentPopulationVaccinated
	SELECT cDea.continent, cDea.location, cDea.date, cDea.population, cVac.new_vaccinations
	, SUM(cast(cVac.new_vaccinations as bigint)) OVER (PARTITION BY cDea.location ORDER BY cDea.location, cDea.date) as VaccSum
	INTO PercentPopulationVaccinated
		FROM ..CovidDeaths cDea
		JOIN ..CovidVaccinations cVac
			ON cDea.location = cVac.location
			AND cDea.date = cVac.date
		WHERE cDea.location like '%pola%' and cDea.continent is not null
		--ORDER BY 2, 3

	SELECT *, (VaccSum/Population)*100 as VaccinatedPercentage
	FROM PercentPopulationVaccinated
---------------------------------------------------------------------

--Creating example View
CREATE VIEW ViewPercPopVac
AS
(
	SELECT cDea.continent, cDea.location, cDea.date, cDea.population, cVac.new_vaccinations
	, SUM(cast(cVac.new_vaccinations as bigint)) OVER (PARTITION BY cDea.location ORDER BY cDea.location, cDea.date) as VaccSum
	FROM ..CovidDeaths cDea
	JOIN ..CovidVaccinations cVac
		ON cDea.location = cVac.location
		AND cDea.date = cVac.date
	WHERE cDea.location like '%pola%' and cDea.continent is not null
	--ORDER BY 2, 3
);

SELECT *
FROM ViewPercPopVac
