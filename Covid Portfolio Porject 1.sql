
SELECT *
FROM Portfolio..CovidDeaths


SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM [Portfolio].[dbo].[CovidDeaths]
  WHERE continent is not null
  order by 1,2


  -- Total Cases vs Total Deaths
  --Shows the likelihood of dying if you contract Covid-19 by location

  SELECT location, date, total_cases, total_deaths, (Cast(total_deaths as float)/Cast(total_cases as float))*100 as DeathPercentage
  FROM [Portfolio].[dbo].[CovidDeaths]
  --where location like '%states%'
  order by 1,2


  --Looking at Total Cases Vs Population
  --Shows what percentage of population contracted Covid-19

SELECT location, date, total_cases, population, (Cast(total_cases as float)/Cast(population as float))*100 as PercentPopulationInfected
  FROM [Portfolio].[dbo].[CovidDeaths]
  WHERE continent is not null
  --where location like '%states%'
  order by 1,2

  --Looking at Countries with Highest Infection Rate compared to Population
  
SELECT location, population, MAX(Cast(total_cases as int)) as HighestInfectionCount, MAX((Cast(total_cases as float)/Cast(population as float)))*100 as PercentPopulationInfected
  FROM [Portfolio].[dbo].[CovidDeaths]
  WHERE continent is not null
  --where location like '%states%'
  Group by location, population
  order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio].[dbo].[CovidDeaths]
WHERE continent is not null
  --where location like '%states%'
  Group by location
  order by TotalDeathCount desc

-- LET'S BREAK THINGS DOWN BY CONTINENT


-- Showing the continents with the highest death count

SELECT location, MAX(Cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio].[dbo].[CovidDeaths]
WHERE continent is null and location not like '%income'
  --where location like '%states%'
  Group by location
  order by TotalDeathCount desc


-- GLOBAL NUMBERS


  SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(New_deaths as int))/ SUM(NULLIF(New_cases, 0)))*100 as DeathPercentage
  FROM [Portfolio].[dbo].[CovidDeaths]
  where continent is not null
  group by date
  order by 1,2

-- Looking at Total Population vs Vaccinations

  SELECT DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(NULLIF(CAST(vac.new_vaccinations AS BIGINT), 0)) OVER (PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION, DEA.DATE) AS RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/dea.population) * 100
  FROM Portfolio..CovidDeaths dea
  JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE

WITH PopvsVac (Continent, location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
  SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY DEA.LOCATION 
  ORDER BY DEA.LOCATION, DEA.DATE) AS RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/dea.population) * 100
  FROM Portfolio..CovidDeaths dea
  JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population) * 100 from PopvsVac 

-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
  SELECT  dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY DEA.LOCATION 
  ORDER BY DEA.LOCATION, DEA.DATE) AS RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/dea.population) * 100
  FROM Portfolio..CovidDeaths dea
  JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population) * 100 
from #PercentPopulationVaccinated 



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as

  SELECT  dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY DEA.LOCATION 
  ORDER BY DEA.LOCATION, DEA.DATE) AS RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/dea.population) * 100
  FROM Portfolio..CovidDeaths dea
  JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

