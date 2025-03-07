SELECT *
FROM CovidPortfolioProject..CovidDeaths2
ORDER BY 2,3

SELECT location,date,population,total_cases,total_deaths,new_cases
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL
ORDER BY 1,2



--Lokking at Total cases vs total deaths

SELECT location,
date,
population, total_cases,total_deaths,
(try_cast (total_deaths as decimal(12,2)))/(try_cast (total_cases as decimal(12,2)))*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL 
--AND location LIKE '%states%'
ORDER BY 1,2


--Looking at Total cases vs population
--Show what percentage of population got covid

SELECT location,date,population, total_cases,
(try_cast (total_cases as decimal(12,2)))/(try_cast (population as decimal(12,2)))*100 AS PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at countries with highest infected rate

SELECT location,population, MAX(total_cases) AS HighestInfectionCount,
MAX(try_cast (total_cases as decimal(12,2)))/(try_cast (population as decimal(12,2)))*100 AS PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

--Showing countries with the highest deathcount per population

SELECT location,MAX(total_deaths) AS Totaldeathcount
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highestdeathcount  DESC

--Let's Break things down by continent

SELECT continent,MAX(total_deaths) AS Totaldeathcount
FROM CovidPortfolioProject..CovidDeaths2
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Totaldeathcount  DESC

--Global Numbers

SELECT SUM(try_cast(new_cases AS decimal(12,2))) as totalcases, SUM(try_cast (new_deaths AS decimal(12,2))) as totaldeaths,
SUM(try_cast (new_deaths AS decimal(12,2)))/SUM(try_cast(new_cases AS decimal(12,2)))*100 AS DeathPercentage
FROM CovidDeaths2
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at total population vs vaccination

SELECT *
FROM CovidPortfolioProject..CovidVaccinations2
ORDER BY 2,3

SELECT dea.location,dea.date,dea.population,vac.new_vaccinations
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
Where dea.continent IS NOT NULL
ORDER BY 1,2

--Using rolling count to look at total population vs vaccination

SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(try_cast (vac.new_vaccinations AS decimal(12,2))) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
Where dea.continent IS NOT NULL
ORDER BY 1,2

--To compute for RollingPeopleVaccinated/population

--Use CTE

With PopvsVac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
AS
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(try_cast (vac.new_vaccinations AS decimal(12,2))) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
Where dea.continent IS NOT NULL
--ORDER BY 1,2
)
SELECT *,(RollingPeopleVaccinated/(try_cast(population AS decimal(12,2))))*100
FROM PopvsVac

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
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(try_cast (vac.new_vaccinations AS decimal(12,2))) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
Where dea.continent IS NOT NULL
--ORDER BY 1,2

SELECT *,(RollingPeopleVaccinated/(try_cast(population AS decimal(12,2))))*100
FROM #PercentPopulationVaccinated

--Creating View to store data for visualization later

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(try_cast (vac.new_vaccinations AS decimal(12,2))) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths2 dea
JOIN CovidVaccinations2 vac
	ON dea.location=vac.location
	AND dea.date=vac.date
Where dea.continent IS NOT NULL
--ORDER BY 1,2

SELECT *
FROM PercentPopulationVaccinated
