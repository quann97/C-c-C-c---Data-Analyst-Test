-- Database used: MySQL

-- 1) Write a query to return all employees still working for the company with last names starting with "Smith" sorted by last name then first name.

SELECT * 
FROM employee
WHERE TerminationDate IS NULL
AND LastName REGEXP '^Smith'
ORDER BY LastName, FirstName;

-- 2) Given the `Employee` and `AnnualReviews` tables, write a query to return all employees who have never had a review sorted by HireDate.

SELECT e.*, r.ReviewDate
FROM employee AS e
LEFT JOIN annualreviews AS r ON e.ID = r.EmpID
WHERE ReviewDate IS NULL
ORDER BY HireDate; 

-- 3) Write a query to calculate the difference (in days) between the most and least tenured employee still working for the company

SELECT DATEDIFF(MAX(HireDate),MIN(HireDate)) AS DateDiff
FROM employee
WHERE TerminationDate IS NULL;

-- 4) Given the employee table above, write a query to calculate the longest period (in days) that the company has gone without a hiring or firing anyone
-- Solution: put together all the hire dates (when headcount increases) and all the termination dates (when headcount decreases) using UNION ALL, arrange them in increasing order, measure the differences between consecutive dates using LAG() or LEAD(), and take the max (this does not include the case where the longest period without a change is up to the current period)

SELECT MAX(Intervals) AS MaxInterval 
FROM (SELECT Dates, DATEDIFF(Dates, LAG(Dates) OVER(ORDER BY Dates)) AS Intervals
FROM (SELECT HireDate AS Dates FROM employee
UNION ALL
SELECT TerminationDate AS Dates FROM employee
WHERE TerminationDate IS NOT NULL
ORDER BY Dates) d) d;

-- 5) Write a query that returns each employee and for each row/employee include the greatest number of employees that worked for the company at any time during their tenure and the first date that maximum was reached. Extra points for not using cursors
-- Step 1: caculate changes in headcount overtime by creating new column filled with '1' value for each hire date and '-1' value for each termination date, null values mean no changes, then put together all the dates and added values.
-- Step 2: caculate a accumulative sum of the changes to get the total number of employees at any point in time.
-- Step 3: join the employee table with the caculated fields on the condition that the timepoint is between the hire date and the termination date (if not use current date) of a each employee
-- Step 4: ranking the rows group by each employee, order by the number of employees (descending) and timepoints (ascending), the rows ranking 1st will indicate the maximum number of employees at the earliest timepoint (the first date that reached maximum).

SELECT DISTINCT * 
FROM (SELECT *, RANK() OVER (PARTITION BY ID ORDER BY MaxEmp DESC, Reach_date ASC) AS Ranking
FROM employee 
JOIN (SELECT SUM(Headcount_Change) OVER(ORDER BY Reach_date) AS MaxEmp, Reach_date
FROM (SELECT HireDate AS Reach_date, 1 AS Headcount_Change FROM employee
UNION ALL
SELECT TerminationDate, -1 FROM employee
WHERE TerminationDate IS NOT NULL) a) b
ON Reach_date BETWEEN HireDate AND COALESCE(TerminationDate, CURDATE())
) c
WHERE Ranking = 1
ORDER BY ID;



