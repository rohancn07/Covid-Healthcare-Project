Select *
From CovidProject..CovidDeaths
where continent is not null
order by 3,4

UPDATE CovidDeaths
SET continent = NULLIF(continent, ''),
	new_cases = NULLIF(new_cases, ''),
	new_deaths = NULLIF(new_deaths, ''),
	total_cases = NULLIF(total_cases, ''),
	total_deaths = NULLIF(total_deaths, ''),
	population = NULLIF(population, '');

--Select *
--From CovidProject..CovidVaccinations
--order by 3,4

UPDATE CovidVaccinations
SET new_vaccinations = NULLIF(new_vaccinations, ''),
	new_tests = NULLIF(new_tests, '');


--Select Data that we're going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
Order by 1

--Looking at Total Cases vs Total Deaths
--Shows us the likilihood of dying if you get Covid in your country

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
From CovidProject..CovidDeaths
Order by 1


--Looking at the Total Cases vs Population
--Shows what Proportion of a country gets Covid

Select location, date, Population, total_cases, (total_cases/population)*100 as InfectionRate
From CovidProject..CovidDeaths
Order by 1


--Countries with Highest Infection Rate (Day)

Select Location, Population, MAX(total_cases) as MaxInfectionCount, MAX(total_cases/population)*100 as MaxInfectionRate
From CovidProject..CovidDeaths
group by location, population
Order by MaxInfectionRate desc

--Showing Countries with Highest Death Count per Capita

Select Location, MAX(total_deaths/population)*100 as MaxDeathRate
From CovidProject..CovidDeaths
where continent is not null
group by location
Order by MaxDeathRate desc

--Breaking it down: Death Count per Capita by Continent

Select location, MAX(total_deaths/population)*100 as MaxDeathRate
From CovidProject..CovidDeaths
where continent is null	
group by location
Order by MaxDeathRate desc

--Showing Countries with Total Death Count

Select Location, MAX(total_deaths/population)*100 as MaxDeathRate
From CovidProject..CovidDeaths
where continent is not null
group by location
Order by MaxDeathRate desc

--Breaking it down: Total Death Count by Continent

Select location, MAX(total_deaths/population)*100 as MaxDeathRate
From CovidProject..CovidDeaths
where continent is null
group by location
Order by MaxDeathRate desc


--India's Numbers
Select Location, MAX(total_cases) as MaxInfectionCount, MAX(total_cases/population)*100 as MaxInfectionRate, MAX(total_deaths) as TotalDeathCount, MAX(total_deaths/population)*100 as MaxDeathRate
From CovidProject..CovidDeaths
where location like '%India%'
group by location, population
Order by MaxInfectionRate desc


--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Rolling count to see Total Vaccines Administered.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as vaccinations_administered
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Rolling count of Proportion of Population that have been Vaccinated
--Using a CTE

With PopvsVac (continent, location, date, population, new_vaccinations, vaccinations_administered)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as vaccinations_administered 
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select * , (vaccinations_administered/population)*100 as percentage_administered_to
from PopvsVac


--Constructing a Temp Table


DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated	
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
vaccinations_administered numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as vaccinations_administered
	From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

	
Select * , (vaccinations_administered/population)*100 as percentage_administered_to
from #PercentPopulationVaccinated


--Creating view to store data for later visulizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as vaccinations_administered
	From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--We can now Query off the View

Select * 
From PercentPopulationVaccinated
