# Data exploration (discover the shape & problems

-- Exploration → Cleaning → Restaurant performance → Customer loyalty → Order trends → Optimization & next steps.

-- 1. row counts

SELECT 'Customers' AS table_name, COUNT(*) FROM Customers
UNION ALL
SELECT 'Restaurants', COUNT(*) FROM Restaurants
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'Ratings', COUNT(*) FROM Ratings;

-- 2. preview 
SELECT * FROM Orders ORDER BY OrderDate LIMIT 10;

-- 3. check data types and nulls.

-- check nulls per column 
-- Check nulls per column (Postgres/SQLite SQL compatible)
SELECT
  SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customers,
  SUM(CASE WHEN RestaurantID IS NULL THEN 1 ELSE 0 END) AS null_restaurants,
  SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS null_dates,
  SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS null_amounts
FROM Orders;

-- 4. check for orphan foregin keys.
-- orders with non-existing customers

SELECT o.* FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

-- orders with non-existing resturant.
SELECT o.* FROM Orders o
LEFT JOIN Restaurants r ON o.RestaurantID = r.RestaurantID
WHERE r.RestaurantID IS NULL;

# DATA CLEANING AND TRANSFORMATIONS
-- 1 Remove duplicates (eg orders if duplicates exist) using CTE Expression
DELETE FROM Orders
WHERE OrderID IN (
  SELECT OrderID
  FROM (
    SELECT OrderID,
           ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY OrderID) AS rn
    FROM Orders
  ) t
  WHERE t.rn > 1
);

SELECT OrderID, COUNT(*) AS occurrences
FROM Orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- 2. fill small missing values (eg if amount null -> set to 0 or related to table

				UPDATE Orders
				SET Amount = 0
				WHERE Amount IS NULL;

-- 3. Create a derived column for order hour/day if you’ll use it often (materialized or via view)

			CREATE VIEW Orders_enriched AS
			SELECT
			  *,
			  HOUR(OrderDate) AS order_hour,
			  DAYOFWEEK(OrderDate) AS order_weekday  -- 1=Sunday, 7=Saturday in MySQL
			FROM Orders;

# 3 RESTURANT PERFORMANCE
-- TOP RESTURANTS BY ORDERS, REVENUE,AVERAGE RATING
-- 1. TOP BY TOTAL ORDERS

			SELECT r.RestaurantID, r.Name, r.Cuisine, COUNT(o.OrderID) AS total_orders
			FROM Restaurants r
			LEFT JOIN Orders o ON r.RestaurantID = o.RestaurantID
			GROUP BY r.RestaurantID, r.Name, r.Cuisine
			ORDER BY total_orders DESC;
            
-- 2. TOP BY REVENUE
            
			SELECT r.RestaurantID, r.Name, SUM(o.Amount) AS revenue
			FROM Restaurants r
			LEFT JOIN Orders o ON r.RestaurantID = o.RestaurantID
			GROUP BY r.RestaurantID, r.Name
			ORDER BY revenue DESC;
            
  -- 3. AVERAGE RATING PER RESTURANT 
  
			SELECT 
			  r.RestaurantID, 
			  r.Name, 
			  ROUND(AVG(rat.Score), 2) AS avg_rating, 
			  COUNT(rat.RatingID) AS rating_count
			FROM Restaurants r
			LEFT JOIN Ratings rat 
			  ON r.RestaurantID = rat.RestaurantID
			GROUP BY r.RestaurantID, r.Name
			ORDER BY 
			  (AVG(rat.Score) IS NULL),  -- places NULLs last
			  AVG(rat.Score) DESC;       -- sorts by highest average rating

-- 4. COMBINE REVENUE + AVG RATING
			SELECT
			  r.RestaurantID, r.Name,
			  COUNT(o.OrderID) AS total_orders,
			  SUM(o.Amount) AS revenue,
			  AVG(rat.Score) AS avg_rating
			FROM Restaurants r
			LEFT JOIN Orders o ON r.RestaurantID = o.RestaurantID
			LEFT JOIN Ratings rat ON r.RestaurantID = rat.RestaurantID
			GROUP BY r.RestaurantID, r.Name
			ORDER BY revenue DESC;
            
# 4. CUSTOMERS LOYALTY AND SEGMENTATIONS

-- FIND REPEAT CUSTOMERS , TOP SPENDERS , RANK CUSTOMERS

-- 1. COUNT ORDERS PER CUSTOMER.
			SELECT c.CustomerID, c.FullName, COUNT(o.OrderID) AS orders_count, SUM(o.Amount) AS total_spent
			FROM Customers c
			LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
			GROUP BY c.CustomerID, c.FullName
			ORDER BY orders_count DESC, total_spent DESC;
            
 -- 2. REPEAT CUSTOMERS ( CUSTOMERS WITH > 1 ORDER)           

			SELECT CustomerID, orders_count, total_spent FROM (
			  SELECT c.CustomerID, COUNT(o.OrderID) AS orders_count, SUM(o.Amount) AS total_spent
			  FROM Customers c
			  LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
			  GROUP BY c.CustomerID
			) t
			WHERE orders_count > 1
			ORDER BY orders_count DESC;
            
-- Use window functions to rank customers (Postgres example):

			 SELECT
			  CustomerID, FullName, orders_count, total_spent,
			  RANK() OVER (ORDER BY orders_count DESC) AS rank_by_orders,
			  RANK() OVER (ORDER BY total_spent DESC) AS rank_by_spend
			FROM (
			  SELECT c.CustomerID, c.FullName, COUNT(o.OrderID) AS orders_count, COALESCE(SUM(o.Amount),0) AS total_spent
			  FROM Customers c
			  LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
			  GROUP BY c.CustomerID, c.FullName
			) s;

-- 4. RFM-ISH (RECENCY,FREQUENCY,MONETARY)
-- DAY SINCE LAST OEDER
-- Recency: days since last order
			SELECT
			  c.CustomerID,
			  c.FullName,
			  MAX(o.OrderDate) AS last_order,
			  COUNT(o.OrderID) AS freq,
			  SUM(o.Amount) AS monetary,
			  DATEDIFF(NOW(), MAX(o.OrderDate)) AS days_since_last_order
			FROM Customers c
			LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
			GROUP BY c.CustomerID, c.FullName
			ORDER BY days_since_last_order ASC;

# 5. ORDER TRENDS 
 -- 1.PEAK HOURS( HOURS OF DAY WITH MOST ORDERS)

			SELECT 
			  HOUR(OrderDate) AS order_hour,
			  COUNT(*) AS orders_count
			FROM Orders
			GROUP BY order_hour
			ORDER BY orders_count DESC;
-- 2. PEEK WEEKDAYS
			SELECT 
			  HOUR(OrderDate) AS order_hour,
			  COUNT(*) AS orders_count
			FROM Orders
			GROUP BY order_hour
			ORDER BY orders_count DESC;
-- 3. Orders per day (time series):
			  SELECT date(OrderDate) AS date, 
              COUNT(*) AS orders_count, 
              SUM(Amount) AS daily_revenue
			FROM Orders
			GROUP BY date
			ORDER BY date;
-- 4. Hour vs cuisine heatmap (which cuisine is popular at which hour)
			SELECT 
			  r.Cuisine,
			  HOUR(o.OrderDate) AS hour,
			  COUNT(*) AS cnt
			FROM Orders o
			JOIN Restaurants r ON o.RestaurantID = r.RestaurantID
			GROUP BY r.Cuisine, hourCustomerID
			ORDER BY r.Cuisine, hour;
            
# 6. ADVANCE ANALYSES
-- INDEXING AND PERFORMANCE RECOMMENDATIONS
			CREATE INDEX idx_orders_customer ON Orders(CustomerID);
			CREATE INDEX idx_orders_restaurant ON Orders(RestaurantID);
			CREATE INDEX idx_orders_orderdate ON Orders(OrderDate);
