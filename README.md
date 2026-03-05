# movie-profitability-analysis
Tableau and Kaggle analysis of movie ROI (2015–2025). My project explores profitability trends in films released between 2015 and 2025. I looked at how factors such as production budget, genre, and release timing influence return on investment. 

## Key Questions
• Do larger budgets lead to higher profits?
• Which film genres generate the highest return on investment?
• Are certain release months more profitable than others?

### Budget vs Worldwide Revenue
I chose a scatter plot to explore the relationship between the budget spent on a film vs its worldwide revenue. Higher budgets do tend to generate higher revenue overall but the chart also shows that large budgets do not guarantee profitability.

### Median ROI by Genre
This chart compares median return on investment across film genres. 
Horror films show the highest ROI, while genres like romance and adventure tend to generate lower returns relative to their budget. 

### ROI by Release Month
I created this chart to explore what months have the highest ROI. I found that summer months (especially June and July) tend to show higher median ROI.

### Average vs Median ROI by Budget Tier
Here we are looking at both the average and median ROI across different budget categories. 
The difference between average and median ROI suggests that a small number of extremely profitable films may influence the average values.

## SQL Analysis

SQL was used to explore profitability trends and calculate key metrics such as ROI, budget tiers, and seasonal performance.

The SQL queries used during analysis can be found in the `/sql` folder.

## Data Source

The dataset used in this analysis comes from Kaggle.
Movie Dataset: https://www.kaggle.com/datasets/raedaddala/imdb-movies-from-1960-to-2023


