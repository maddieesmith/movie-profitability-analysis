/* =====================================================================
   Movie Profitability Analysis (2015–2025) — BigQuery SQL
  
   Dataset:
     `movie-analysis-capstone.movie_analysis.movies_final`

   ===================================================================== */


/* ---------------------------------------------------------------------
   0) Data completeness check
------------------------------------------------------------------------ */
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(budget_usd IS NOT NULL) AS movies_with_budget,
  COUNTIF(roi IS NOT NULL) AS movies_with_roi,
  COUNTIF(gross_worldwide IS NOT NULL) AS movies_with_worldwide_gross,
  COUNTIF(release_month IS NOT NULL) AS movies_with_release_month,
  COUNTIF(genres IS NOT NULL AND genres != '') AS movies_with_genres
FROM `movie-analysis-capstone.movie_analysis.movies_final`;


/* ---------------------------------------------------------------------
   1) Overall correlations
------------------------------------------------------------------------ */
-- Overall averages
SELECT
  ROUND(AVG(budget_usd), 0) AS avg_budget,
  ROUND(AVG(gross_worldwide), 0) AS avg_revenue,
  ROUND(AVG(profit), 0) AS avg_profit,
  ROUND(AVG(roi), 2) AS avg_roi
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE roi IS NOT NULL;

-- Correlation: Budget vs Revenue
SELECT
  CORR(budget_usd, gross_worldwide) AS budget_revenue_correlation
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE budget_usd IS NOT NULL
  AND gross_worldwide IS NOT NULL;

-- Correlation: Budget vs ROI
SELECT
  CORR(budget_usd, roi) AS budget_roi_correlation
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE budget_usd IS NOT NULL
  AND roi IS NOT NULL;


/* ---------------------------------------------------------------------
   2) Budget tiers (avg and median ROI)
------------------------------------------------------------------------ */
-- Avg ROI + Avg revenue by budget category
SELECT
  CASE
    WHEN budget_usd < 20000000 THEN 'Low Budget (<$20M)'
    WHEN budget_usd < 75000000 THEN 'Mid Budget ($20M–$75M)'
    ELSE 'High Budget (>$75M)'
  END AS budget_category,
  COUNT(*) AS movie_count,
  ROUND(AVG(roi), 2) AS avg_roi,
  ROUND(AVG(gross_worldwide), 0) AS avg_revenue
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE roi IS NOT NULL
  AND budget_usd IS NOT NULL
GROUP BY budget_category
ORDER BY avg_roi DESC;

-- Median ROI by budget category
SELECT
  CASE
    WHEN budget_usd < 20000000 THEN 'Low Budget (<$20M)'
    WHEN budget_usd < 75000000 THEN 'Mid Budget ($20M–$75M)'
    ELSE 'High Budget (>$75M)'
  END AS budget_category,
  COUNT(*) AS movie_count,
  ROUND(APPROX_QUANTILES(roi, 2)[OFFSET(1)], 2) AS median_roi
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE roi IS NOT NULL
  AND budget_usd IS NOT NULL
GROUP BY budget_category
ORDER BY median_roi DESC;


/* ---------------------------------------------------------------------
   3) Genre ROI (split multi-genre strings, created "core" genres, 
    then compute avg/median)
------------------------------------------------------------------------ */
-- A) ROI by detailed genre (only genres with >= 20 movies)
WITH genre_cleaned AS (
  SELECT
    roi,
    TRIM(genre) AS genre
  FROM `movie-analysis-capstone.movie_analysis.movies_final`,
  UNNEST(
    SPLIT(
      REPLACE(
        REPLACE(
          REPLACE(genres, '[', ''),
        ']', ''),
      "'", ''),
    ',')
  ) AS genre
)
SELECT
  genre,
  COUNT(*) AS movie_count,
  ROUND(AVG(roi), 2) AS avg_roi,
  ROUND(APPROX_QUANTILES(roi, 2)[OFFSET(1)], 2) AS median_roi
FROM genre_cleaned
WHERE roi IS NOT NULL
GROUP BY genre
HAVING movie_count >= 20
ORDER BY median_roi DESC;

-- B) ROI only buckets with >= 30 movies
WITH genre_cleaned AS (
  SELECT
    roi,
    TRIM(genre) AS genre
  FROM `movie-analysis-capstone.movie_analysis.movies_final`,
  UNNEST(
    SPLIT(
      REPLACE(
        REPLACE(
          REPLACE(genres, '[', ''),
        ']', ''),
      "'", ''),
    ',')
  ) AS genre
),
genre_bucketed AS (
  SELECT
    roi,
    CASE
      WHEN genre LIKE '%Horror%' THEN 'Horror'
      WHEN genre LIKE '%Comedy%' THEN 'Comedy'
      WHEN genre LIKE '%Drama%' THEN 'Drama'
      WHEN genre LIKE '%Action%' THEN 'Action'
      WHEN genre LIKE '%Sci-Fi%' THEN 'Sci-Fi'
      WHEN genre LIKE '%Fantasy%' THEN 'Fantasy'
      WHEN genre LIKE '%Romance%' THEN 'Romance'
      WHEN genre LIKE '%Adventure%' THEN 'Adventure'
      WHEN genre LIKE '%Thriller%' THEN 'Thriller'
      WHEN genre LIKE '%Animation%' THEN 'Animation'
      WHEN genre LIKE '%Family%' THEN 'Family'
      ELSE 'Other'
    END AS core_genre
  FROM genre_cleaned
)
SELECT
  core_genre,
  COUNT(*) AS movie_count,
  ROUND(AVG(roi), 2) AS avg_roi,
  ROUND(APPROX_QUANTILES(roi, 2)[OFFSET(1)], 2) AS median_roi
FROM genre_bucketed
WHERE roi IS NOT NULL
GROUP BY core_genre
HAVING movie_count >= 30
ORDER BY median_roi DESC;


/* ---------------------------------------------------------------------
   4) Budget tier x core genre (median ROI)
------------------------------------------------------------------------ */
WITH genre_cleaned AS (
  SELECT
    budget_usd,
    roi,
    TRIM(genre) AS genre
  FROM `movie-analysis-capstone.movie_analysis.movies_final`,
  UNNEST(
    SPLIT(
      REPLACE(
        REPLACE(
          REPLACE(genres, '[', ''),
        ']', ''),
      "'", ''),
    ',')
  ) AS genre
),
genre_bucketed AS (
  SELECT
    budget_usd,
    roi,
    CASE
      WHEN genre LIKE '%Horror%' THEN 'Horror'
      WHEN genre LIKE '%Comedy%' THEN 'Comedy'
      WHEN genre LIKE '%Drama%' THEN 'Drama'
      WHEN genre LIKE '%Action%' THEN 'Action'
      WHEN genre LIKE '%Sci-Fi%' THEN 'Sci-Fi'
      WHEN genre LIKE '%Fantasy%' THEN 'Fantasy'
      WHEN genre LIKE '%Romance%' THEN 'Romance'
      WHEN genre LIKE '%Adventure%' THEN 'Adventure'
      WHEN genre LIKE '%Thriller%' THEN 'Thriller'
      WHEN genre LIKE '%Animation%' THEN 'Animation'
      WHEN genre LIKE '%Family%' THEN 'Family'
      ELSE 'Other'
    END AS core_genre
  FROM genre_cleaned
),
budget_categorized AS (
  SELECT
    roi,
    core_genre,
    CASE
      WHEN budget_usd < 20000000 THEN 'Low Budget (<$20M)'
      WHEN budget_usd < 75000000 THEN 'Mid Budget ($20M–$75M)'
      ELSE 'High Budget (>$75M)'
    END AS budget_category
  FROM genre_bucketed
  WHERE roi IS NOT NULL
    AND budget_usd IS NOT NULL
)
SELECT
  budget_category,
  core_genre,
  COUNT(*) AS movie_count,
  ROUND(APPROX_QUANTILES(roi, 2)[OFFSET(1)], 2) AS median_roi
FROM budget_categorized
GROUP BY budget_category, core_genre
HAVING movie_count >= 20
ORDER BY budget_category, median_roi DESC;


/* ---------------------------------------------------------------------
   5) ROI by release month
------------------------------------------------------------------------ */
SELECT
  release_month,
  COUNT(*) AS movie_count,
  ROUND(AVG(roi), 2) AS avg_roi,
  ROUND(APPROX_QUANTILES(roi, 2)[OFFSET(1)], 2) AS median_roi,
  ROUND(AVG(gross_worldwide), 0) AS avg_revenue
FROM `movie-analysis-capstone.movie_analysis.movies_final`
WHERE roi IS NOT NULL
  AND release_month IS NOT NULL
GROUP BY release_month
ORDER BY release_month;


