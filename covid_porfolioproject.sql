select * 
from PortfolioProject.dbo.CovidDeaths_2
order by 3,4

--select * 
--from PortfolioProject.dbo.CovidVaccinations

-- Select data we will be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths_2
Where continent is not null 
order by 1,2



-- Looking at total cases vs Total Deaths
Select Location, date, total_deaths,total_cases, (total_deaths/total_cases) *100 as DeathPercentage
From PortfolioProject..CovidDeaths_2
WHERE location like '%states%'
order by 1, 2 ASC

Select Location, date, total_cases,total_deaths, ISNULL(CONVERT(FLOAT,total_deaths)/NULLIF(CONVERT(FLOAT,total_cases),0),0) *100 as DeathPercentage
From PortfolioProject..CovidDeaths_2
Where location like '%states%'
and continent is not null 
order by 1,2

-- DROP TABLE PortfolioProject.dbo.CovidDeaths

-- looking at total cases vs population
Select Location,total_cases, population, ISNULL(CONVERT(FLOAT,total_cases)/NULLIF(CONVERT(FLOAT,population),0),0) *100 as PercentCasesPerPop
From PortfolioProject..CovidDeaths_2
WHERE location like '%states%'
order by 1,2 ASC

Select Location,population, MAX(total_cases) as HighestInfectedCount,  MAX(ISNULL(CONVERT(FLOAT,total_cases)/NULLIF(CONVERT(FLOAT,population),0),0)) *100 as PercPopInfected
From PortfolioProject..CovidDeaths_2
-- WHERE location like '%states%'
Group by Location, Population 
order by PercPopInfected DESC

--Break things down by continent
Select continent,MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths_2
where continent != ' '
Group by continent 
order by TotalDeathCount DESC


-- showing countries with highest death count per population 
Select Location,MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths_2
where continent = ' '
Group by Location 
order by TotalDeathCount DESC


-- showing cotinents with highest death count per population
Select continent,MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths_2
where continent != ' '
Group by continent 
order by TotalDeathCount DESC

-- Global numbers

Select  SUM(new_cases) as totalcases,
		SUM(new_deaths) as total_deaths, 
		SUM(cast(new_deaths as FLOAT))/ ISNULL(NULLIF(SUM(cast(new_cases as FLOAT)),0),1) *100 as death_percentage
From PortfolioProject..CovidDeaths_2
where continent != ' '
--Group By date
order by 1, 2  ASC

Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths_2 dea
INNER JOIN PortfolioProject..CovidVaccinations_2 vac
	ON dea.location=vac.location and dea.date=vac.date
where dea.continent != ' ' and dea.location='Albania' 
order by 2,3 

-- use CTE
with popvsvac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
,SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location,dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths_2 dea
INNER JOIN PortfolioProject..CovidVaccinations_2 vac
	ON dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 PercVaccPerPop
FROM popvsvac
where Population != 0




-- TEMP TABLE----------------------------
Drop table if exists #PercentPopulationVaccinate
Create Table #PercentPopulationVaccinate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinate
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER  (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths_2 dea
INNER JOIN PortfolioProject..CovidVaccinations_2 vac
	ON dea.location=vac.location and dea.date=vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 PercVaccPerPop
FROM  #PercentPopulationVaccinate
where Population != 0

------------------------

--Creating view to store data for later visualizations
Create View PercentPopulationVacc as
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER  (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths_2 dea
INNER JOIN PortfolioProject..CovidVaccinations_2 vac
	ON dea.location=vac.location and dea.date=vac.date
where dea.continent is not null

select * from PercentPopulationVacc

--add something here