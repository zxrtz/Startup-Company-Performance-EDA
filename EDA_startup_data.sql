
-- Startups Data

-- staging step 1
SELECT *
FROM startup_data;

DROP TABLE startup_data_staging1;

CREATE TABLE startup_data_staging1
LIKE startup_data;

INSERT INTO startup_data_staging1
SELECT * FROM startup_data;

SELECT *
FROM startup_data_staging1;


-- standardize data step 2

ALTER TABLE startup_data_staging1
RENAME COLUMN `Funding Amount (M USD)` TO funding_amount,
RENAME COLUMN `Startup Name` TO startup_name,
RENAME COLUMN `Funding Rounds` TO funding_rounds,
RENAME COLUMN `Valuation (M USD)` TO valuation,
RENAME COLUMN `Revenue (M USD)` TO revenue,
RENAME COLUMN `Market Share (%)` TO market_share_percentage,
RENAME COLUMN `Year Founded` TO year_founded,
RENAME COLUMN `Exit Status` TO exit_status;

SELECT *
FROM startup_data_staging1;

-- exploration phase 3
SELECT startup_name,industry, valuation, revenue, market_share_percentage, funding_rounds
FROM startup_data_staging1
ORDER BY valuation DESC, revenue DESC, market_share_percentage DESC;





-- ranks valuation of companies by industry in north america
-- easy to see that the top startups in valuation that are profitable are e commerce
-- cybersec, edtech, and healthtech are all not very profitable for the top valuation companies
WITH industry_rank AS 
(
SELECT Industry, startup_name, valuation, Profitable,
DENSE_RANK() OVER(PARTITION BY industry ORDER BY valuation DESC) AS valuation_industry_rank
FROM startup_data_staging1
WHERE Region = 'North America'
)
SELECT *
FROM industry_rank
WHERE valuation_industry_rank <= 5
;






-- calculates averages
SELECT industry, SUBSTR(AVG(Valuation), 1, 7) avg_valuation, 
				SUBSTR(AVG(Revenue), 1, 5) avg_revenue, 
                SUBSTR(AVG(funding_amount), 1, 6) avg_funding,
                AVG(Profitable) profitability
FROM startup_data_staging1
GROUP BY industry
ORDER BY 2 DESC;


SELECT industry, AVG(Profitable) profitability_chance
FROM startup_data_staging1
GROUP BY industry;




-- showing the probablity of profitability of startups in america based on industry
WITH profitability_ranker AS
(
SELECT industry, SUBSTR(AVG(Valuation), 1, 7) avg_valuation, 
				SUBSTR(AVG(Revenue), 1, 5) avg_revenue, 
                SUBSTR(AVG(funding_amount), 1, 6) avg_funding,
                AVG(Profitable) profitability_chance,
				SUBSTR(AVG(valuation)/AVG(funding_amount), 1, 5) valuation_funding_ratio
FROM startup_data_staging1
WHERE Region = 'North America'
GROUP BY industry
)
SELECT industry, profitability_chance, avg_funding, avg_valuation, valuation_funding_ratio
FROM profitability_ranker
ORDER BY profitability_chance DESC
;

/*--------------------------------------------------------------------------*/
-- expansion 2: adding profitability to all metrics

SELECT *
FROM startup_data_staging1;

DROP TABLE startup_data_staging2;

CREATE TABLE startup_data_staging2
LIKE startup_data_staging1;

INSERT INTO startup_data_staging2
SELECT * FROM startup_data_staging1;

ALTER TABLE startup_data_staging2
ADD Profitable_or_not CHAR(3) NULL;

UPDATE startup_data_staging2
SET Profitable_or_not = 'No'
WHERE Profitable = 0;

UPDATE startup_data_staging2
SET Profitable_or_not = 'Yes'
WHERE Profitable = 1;


WITH industry_profitability_cte AS
(
SELECT industry, CONCAT(AVG(Profitable), " ", industry) AS industry_profit_chance
FROM startup_data_staging2 
GROUP BY industry
), joined_profitability_cte AS
(
SELECT t1.*, t2.industry_profit_chance 
FROM startup_data_staging2 t1
JOIN industry_profitability_cte t2
WHERE t1.industry = t2.industry
), top_5_profitability_valuation_cte AS
(
SELECT *,
DENSE_RANK() OVER(PARTITION BY industry ORDER BY valuation DESC) AS valuation_industry_rank
FROM joined_profitability_cte
WHERE Region = 'North America'
)
SELECT startup_name, Profitable_or_not, industry, valuation, industry_profit_chance, valuation_industry_rank
FROM top_5_profitability_valuation_cte
WHERE valuation_industry_rank <6 ;



