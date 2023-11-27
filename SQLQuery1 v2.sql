SELECT location,max(population) as population,continent
FROM CovidDeath
where continent = 'north america'
group by location,continent
order by 1


SELECT CONVERT(float, total_cases) as total_cases
FROM CovidDeath

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

/*SELECTING THE DATA WE ARE GOING TO USE*/
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeath
WHERE continent IS NOT NULL 
and location = 'france'
ORDER BY 1,2
/*
WE ARE GOING TO LOOK AT (TOTAL CASES VS. TOTAL DEATHS) EACH DAY 
THIS SHOWS THE LIKELIHOOD OF DYING IF YOU GOT COVID
*/
--In Turkey
SELECT location,date,total_cases,total_deaths, ((CONVERT(float, total_deaths)) / (CONVERT(float, total_cases)))*100 as DeathPercentageInTurkey
FROM CovidDeath
Where location like 'sweden'
ORDER BY 2 DESC
--In Sweden
SELECT location,date,total_cases,total_deaths, ((CONVERT(float, total_deaths)) / (CONVERT(float, total_cases)))*100 as DeathPercentageInSweden
FROM CovidDeath
Where location = 'turkey'
ORDER BY 2 DESC
--In the Whole world 
SELECT location,date,total_cases,CAST(total_deaths as int) as total_deaths, ((CONVERT(float, total_deaths)) / (CONVERT(float, total_cases)))*100 as DeathPercentageInTheWorld
FROM CovidDeath
Where continent is NOT NULL
ORDER BY 5

/*LOOKING AT TOTAL CASES VS POPULATION BY EACH DATE*/

SELECT location,date,population,total_cases, ((CONVERT(float, total_cases)) / (CONVERT(float, population)))*100 as InfectionRate 
FROM CovidDeath
Where location ='turkey'
ORDER BY 1,2

SELECT location,date,total_cases,population, (CONVERT(float, total_cases) / CONVERT(float, population)) *100 as InfectionRate 
FROM CovidDeath
Where location = 'sweden'
ORDER BY 5 DESC

SELECT location,date,total_cases,population, ((CONVERT(float, total_cases)) / (CONVERT(float, population)))*100 as InfectionRate 
FROM CovidDeath
Where continent IS NOT NULL
ORDER BY 5 DESC

/*HIGHEST INFECTION RATE IN THE WORLD*/

SELECT location,date,population,total_cases, (total_cases / population)*100 as InfectionRate 
FROM CovidDeath
WHERE continent IS NOT NULL
--GROUP BY location, population
ORDER BY 5 DESC


/*HIGHEST INFECTION RATE BY COUNTRY & ALSO THE WHOLE WORLD ,,, ALL THE DATES COMBINED  */
/*Total cases column was NVARCHAR, so i've changed it into float*/

ALTER TABLE CovidDeath
ALTER COLUMN total_cases FLOAT 


SELECT location,population,MAX(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as InfectionRate 
FROM CovidDeath
WHERE location = 'turkey'
GROUP BY location, population
ORDER BY 4 desc

SELECT location,population,MAX(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as InfectionRate 
FROM CovidDeath
WHERE location = 'sweden'
GROUP BY location, population
ORDER BY 4 desc

SELECT location,population,MAX(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as InfectionRate 
FROM CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 desc


/*HIGHEST DEATHCOUNT PER COUNTRY*/
/*We are using CAST because we need to change the data type from VARCHAR to INT*/

SELECT location,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeath
--WHERE location = 'united states'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--LET'S BREAK THING DOWN BY CONTINENT 
--showing contentents with highest death COUNTS

SELECT continent,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeath
--WHERE location = 'united states'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

--GLOBEL NUM OF (TOTAL_CASES VS. TOTAL DEATHS) --some of the divisors are ZERO thats whyive added CASE STATEMENT, to AVOID the zeros.

SELECT SUM(New_cases)as Total_Cases ,SUM(CAST(new_deaths as int)) as Total_deaths , CASE WHEN SUM(New_cases)=0 THEN 0 ELSE ((SUM(CAST(new_deaths as int))/SUM(New_cases)))*100 END AS DeathPercentage  --,CAST(total_deaths as int) as total_deaths, ((CONVERT(float, total_deaths)) / (CONVERT(float, total_cases)))*100 as DeathPercentageInTheWorld
FROM CovidDeath
Where continent is NOT NULL
--group by date
ORDER BY 1,2


/*Starting the JOINING between the two tables*/

SELECT *
FROM CovidDeath
JOIN CovidVaccinations
	ON CovidDeath.location = CovidVaccinations.location
	AND CovidDeath.date = CovidDeath.date

-- Looking at Total Population VS Vaccinations

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VACC.new_vaccinations
,SUM(CAST(VACC.new_vaccinations as bigint)) OVER (partition by DEA.location order by DEA.location, DEA.date ) as total_vacc_rolling
FROM CovidDeath DEA
JOIN CovidVaccinations VACC
	ON DEA.location = VACC.location
	AND DEA.date = VACC.date
	WHERE DEA.continent IS NOT NULL
		ORDER BY 2,3
 --Looking at Total Population VS Vaccinations(RATIO) Using CTE

WITH CTE_COVID AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VACC.new_vaccinations
,SUM(CAST(VACC.new_vaccinations as bigint)) OVER (partition by DEA.location order by DEA.location, DEA.date ) as total_vacc_rolling
FROM CovidDeath DEA
JOIN CovidVaccinations VACC
	ON DEA.location = VACC.location
	AND DEA.date = VACC.date
	WHERE DEA.continent IS NOT NULL
	--ORDER BY 2,3
	)
		SELECT *, (total_vacc_rolling/population)*100 AS VaccRatio
		FROM CTE_COVID
		ORDER BY 7 DESC


/*Looking at Total Population VS Vaccinations(RATIO) Using temp table*/
DROP TABLE IF EXISTS #PercentPopulationVacc
Create table #PercentPopulationVacc

(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
total_vacc_rolling numeric
)

INSERT INTO #PercentPopulationVacc

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VACC.new_vaccinations
,SUM(CAST(VACC.new_vaccinations as bigint)) OVER (partition by DEA.location order by DEA.location, DEA.date ) as total_vacc_rolling
FROM CovidDeath DEA
JOIN CovidVaccinations VACC
	ON DEA.location = VACC.location
	AND DEA.date = VACC.date
	WHERE DEA.continent IS NOT NULL
	--ORDER BY 2,3
	
		SELECT *, (total_vacc_rolling/population)*100 AS VaccRatio
		
		FROM #PercentPopulationVacc

		ORDER BY 7 DESC
		
--Creating View to store data for later visualizations

CREATE View PercentPopulationVacc as 


SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VACC.new_vaccinations
,SUM(CAST(VACC.new_vaccinations as bigint)) OVER (partition by DEA.location order by DEA.location, DEA.date ) as total_vacc_rolling
FROM CovidDeath DEA
JOIN CovidVaccinations VACC
	ON DEA.location = VACC.location
	AND DEA.date = VACC.date
	WHERE DEA.continent IS NOT NULL