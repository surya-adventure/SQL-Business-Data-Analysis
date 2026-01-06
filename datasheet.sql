-- Restaurants
CREATE TABLE Restaurants (
  RestaurantID INTEGER PRIMARY KEY,
  Name TEXT,
  Cuisine TEXT
);

INSERT INTO Restaurants (RestaurantID, Name, Cuisine) VALUES
(1, 'Spice Garden', 'Indian'),
(2, 'Mama Pizza', 'Italian'),
(3, 'Sushi Central', 'Japanese'),
(4, 'Green Vegan', 'Vegan'),
(5, 'Burger Hub', 'Fast Food');

-- Customers
CREATE TABLE Customers (
  CustomerID INTEGER PRIMARY KEY,
  FullName TEXT,
  Email TEXT,
  SignupDate DATE
);

INSERT INTO Customers (CustomerID, FullName, Email, SignupDate) VALUES
(101, 'Anita Rao', 'anita@example.com', '2024-01-12'),
(102, 'Rohit Mehra', 'rohit@example.com', '2024-03-05'),
(103, 'Leena Patel', 'leena@example.com', '2024-02-20'),
(104, 'Sanjay Kumar', 'sanjay@example.com', '2024-04-01'),
(105, 'Maya Singh', 'maya@example.com', '2024-04-15'),
(106, 'Arjun Das', 'arjun@example.com', '2024-05-10');

-- Orders
CREATE TABLE Orders (
  OrderID INTEGER PRIMARY KEY,
  CustomerID INTEGER,
  RestaurantID INTEGER,
  OrderDate TIMESTAMP,
  Amount NUMERIC,
  FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
  FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID)
);

INSERT INTO Orders (OrderID, CustomerID, RestaurantID, OrderDate, Amount) VALUES
(1001, 101, 1,  '2024-07-01 12:05:00', 320.00),
(1002, 102, 2,  '2024-07-01 19:20:00', 450.00),
(1003, 103, 3,  '2024-07-02 13:30:00', 780.00),
(1004, 101, 1,  '2024-07-05 20:10:00', 290.00),
(1005, 104, 4,  '2024-07-05 18:45:00', 250.00),
(1006, 105, 5,  '2024-07-06 12:15:00', 180.00),
(1007, 101, 2,  '2024-07-07 21:05:00', 520.00),
(1008, 102, 2,  '2024-07-08 13:40:00', 410.00),
(1009, 103, 3,  '2024-07-08 19:00:00', 860.00),
(1010, 106, 4,  '2024-07-09 12:50:00', 230.00),
(1011, 101, 1,  '2024-07-10 12:10:00', 310.00),
(1012, 105, 1,  '2024-07-10 20:30:00', 340.00);

-- Ratings
CREATE TABLE Ratings (
  RatingID INTEGER PRIMARY KEY,
  CustomerID INTEGER,
  RestaurantID INTEGER,
  Score INTEGER,  -- 1..5
  RatingDate DATE,
  FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
  FOREIGN KEY (RestaurantID) REFERENCES Restaurants(RestaurantID)
);

INSERT INTO Ratings (RatingID, CustomerID, RestaurantID, Score, RatingDate) VALUES
(5001, 101, 1, 5, '2024-07-02'),
(5002, 102, 2, 4, '2024-07-02'),
(5003, 103, 3, 5, '2024-07-03'),
(5004, 101, 1, 4, '2024-07-06'),
(5005, 105, 1, 5, '2024-07-11'),
(5006, 102, 2, 3, '2024-07-09'),
(5007, 104, 4, 4, '2024-07-07'),
(5008, 103, 3, 4, '2024-07-09');
