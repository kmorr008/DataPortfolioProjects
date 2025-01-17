/*
SQL Portfolio Project
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Show all the data from the CovidDeaths table and sort by location, then by date
Select *
From PortfolioProject..CovidDeaths
order by 3,4

-- Show all the data from the CovidVaccinations table and sort by location, then by date
Select *
From PortfolioProject..CovidVaccinations
order by 3,4



-- DATA EXPLORATION


-- How have total cases and total deaths changed over time?
Select location, date, total_cases, total_deaths
From PortfolioProject..CovidDeaths
order by 1, 2


-- What is the likliehood of dying if you contract Covid19 in your country?
-- Calculate death percentage using total deaths and total cases
Select location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
-- this will only show data for the US
Where location like '%states%'
order by 1, 2


-- What percent of the population got Covid?
Select location, date, total_cases, population, (CAST(total_cases AS FLOAT)/population)*100 as CasePercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1, 2


-- What countries have the highest infection rate?
-- find the highest percent infected for each country then list the data in descending order to view the countries with the highest rate
Select location, population,  MAX(total_cases) as HighestInfectionCount, MAX((CAST(total_cases AS FLOAT)/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by location, population
order by PercentPopulationInfected desc


-- What countries hae the highest death count?
Select location,  MAX(total_deaths) as TotalDeathCountCount
From PortfolioProject..CovidDeaths
-- Ensure that whole continents do not appear in this query
Where continent is not null
Group by location
order by TotalDeathCountCount desc


-- What continents have the highest death count?
Select location,  MAX(total_deaths) as TotalDeathCountCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by TotalDeathCountCount desc


-- What are the total new cases per day, globally, compared to deaths per day?
Select date, SUM(new_cases) as newCasesPerDay, SUM(new_deaths) as newDeathsPerDay, CAST(SUM(new_deaths) as float)/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1, 2


-- JOINING TWO TABLES

-- View full dataset from Deaths table and Vaccinations table
Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
	

-- How many people are vaccinated each day in each country?
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
order by 2, 3


-- USE CTE (Common Table Expression) to find the percent of the population vaccinated by country
With PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated

From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null
--order by 2, 3
)
Select *, (CAST(RollingPeopleVaccinated AS float)/ population)*100 as PercentVaccinated
From PopVsVac



-- USE TEMP TABLE to find the percent of the population vaccinated by country
-- Prevent an error
DROP Table if exists #PercentPopulationVaccinated
-- Create the table and specify names data types of each column
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)
-- add data to the table
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null

-- The table is created, so now we can select from the table
Select *, (CAST(RollingPeopleVaccinated AS float)/ population)*100 as PercentVaccinated
From #PercentPopulationVaccinated



-- CREATE VIEWS TO STORE DATA FOR LATER VISUALIZATIONS

-- What percent of each country is vaccinated?
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null


-- What are the vaccination rates of the countries with the highest death rates (deaths vs population)?
Create View DeathAndVaccVsPop as
With MaxDeathsPerCountry 
as 
(
Select dea.continent, dea.location, dea.population, MAX(dea.total_deaths) AS MaxDeaths
From PortfolioProject..CovidDeaths dea
Where dea.continent IS NOT NULL
Group by dea.continent, dea.location, dea.population
)
Select mdc.continent, mdc.location, mdc.population, CAST(mdc.MaxDeaths as float) / mdc.population as DeathPercentage, CAST(vac.total_vaccinations as float) / mdc.population as VaccPercentage
From MaxDeathsPerCountry mdc
Join PortfolioProject..CovidVaccinations vac
    ON mdc.location = vac.location
Where vac.date = (Select MAX(date) From PortfolioProject..CovidVaccinations Where location = mdc.location)
--order by DeathPercentage desc




--Project Built with Alex the Analyst https://www.youtube.com/watch?v=qfyynHBFOsM&t=574s
