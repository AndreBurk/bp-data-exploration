BP dataset exploration
=====================

The bp-data-app visualizes the statistical review workbook from [BP](http://www.bp.com/en/global/corporate/about-bp/energy-economics/statistical-review-of-world-energy.html) and gives an overview of the european gas prices for the different market areas.

## Data source
The BP dataset was loaded via [Quandl](https://www.quandl.com/data/BP?keyword=), processed and then pushed to GitHub as csv (processing code also available here). Total data like "Total Europe" etc. have been removed for better visualization of country specific data. Historical prices from the BP dataset have also been excluded.

The prices for the european gas market are taken from [PEGAS/Powernext](http://www.powernext.com) and [CEGH](http://www.cegh.at).

## Visualization
The first tab of the app gives an overview of european gas prices with its market areas.

The second tab visualizes the BP dataset via Google's MotionChart.

The third tab visualizes the BP dataset via Google's GeoChart.