SELECT *
FROM CovidDeaths1
ORDER BY 3,4
;
SELECT *
FROM CovidVaccinations1
ORDER BY 3,4
;
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths1
where continent IS NULL
ORDER BY 1,2
;
--Looking at Total Cases VS total Death

SELECT location,date,total_cases,total_deaths, 
(try_cast(total_deaths as decimal) /(try_cast(total_cases as int)))*100 as DeathPercent
FROM CovidDeaths1
WHERE total_deaths != 0 AND total_cases != 0
AND location LIKE '%states%'
ORDER BY 1,2


--Looking at Total Cases VS Population
--Show what percentage of population got covid

SELECT location,date,total_cases,population,
(try_cast(total_cases as decimal(12,2)) /(try_cast(population as int)))*100 as PercentPopulationInfected
FROM CovidDeaths1
WHERE total_deaths != 0 AND total_cases != 0
AND location LIKE '%states%'
ORDER BY 1,2


--Looking at countries with highest infection rate compared to Population

SELECT location,population, 
MAX(total_cases) AS HighestInfectionCount,
MAX((try_cast(total_cases as decimal(12,2)) /(try_cast(population as int))))*100 as PercentPopulationInfected
FROM CovidDeaths1
WHERE total_cases != 0
AND location LIKE 'A%'
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

--Showing countries with the highest deathcount per population

SELECT location,MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths1
where continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Let's break things down by continent

SELECT continent,MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths1
where continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers

SELECT SUM(cast(new_cases AS int)) as totalcases, SUM(cast (new_deaths AS decimal)) as totaldeaths,
SUM(cast (new_deaths AS decimal))/SUM(cast(new_cases AS int))*100 AS DeathPercentage
FROM CovidDeaths1
WHERE new_cases != 0 AND new_deaths != 0 
AND continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at totalpopulation vs vaccination

SELECT *
FROM CovidVaccinations1
ORDER BY 3,4

SELECT dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaciinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths1 dea
JOIN CovidVaccinations1 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Use CTE

With PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths1 dea
JOIN CovidVaccinations1 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT*, (RollingPeopleVaccinated/(try_cast(population as decimal(12,2))))*100
FROM PopvsVac
WHERE RollingPeopleVaccinated !=0 AND new_vaccinations !=0

--Temp Table

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date varchar(50),
Population varchar(50),
New_vaccinations varchar(50),
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaciinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths1 dea
JOIN CovidVaccinations1 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT*, (RollingPeopleVaccinated/(try_cast(population as decimal(12,2))))*100
FROM #PercentPopulationVaccinated

--Creating View to store data for visualization later

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaciinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths1 dea
JOIN CovidVaccinations1 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated