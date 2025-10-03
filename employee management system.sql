-- Employement Management System --
-- creating database--

create database if not exists employee_management_system;

-- using the database --
use employee_management_system;

-- job departemnt --
create table JobDepartment ( Job_ID INT PRIMARY KEY,
                             jobdept varchar(50),
                             name varchar(100),
                             description text,
                             salaryrange varchar(50));

-- salary/bonus 
create table SalaryBonus (salary_ID int primary key,
						 Job_ID INT,
                         amount decimal(10,2),
                         annual decimal(10,2),
                         bonus decimal(10,2),
                         constraint fk_salary_job foreign key (job_ID)
					references JobDepartment(Job_ID) on delete cascade on update cascade );
								
-- Employee --
create table Employee (emp_ID INT primary key ,
                        firstname varchar(50),
                        lastname varchar(50),
                        gender varchar(10),
                        age int,
                        contact_add varchar(100),
                        emp_email varchar(100) unique,
                        emp_pass varchar(50),
                        Job_ID int ,
                        constraint fk_employee_job foreign key(Job_ID) References JobDepartment(Job_ID) on delete set null on update cascade );

-- Qualification --
create table Qualification( QualID Int primary key,
                            Emp_ID int,
                            Position  varchar(255),requirements  varchar(255),
                            Date_In Date,
					constraint fk_qualification_emp foreign  key(Emp_ID) references Employee(emp_ID) on delete cascade on update cascade );

-- leaves --
create table Leaves(leave_ID int primary key ,
                    emp_ID int,
                    date date,
                    reason text,
                    constraint fk_leave_emp foreign key (emp_ID) references Employee(emp_ID) on delete cascade on update cascade);

-- payroll --
create table payroll(payroll_ID int  primary key,
                      emp_ID int,job_ID int,
                      salary_ID INT ,
                      leave_ID int,
                      date date,
                      report text ,
                      total_amount decimal(10,2),
					constraint fk_payroll_emp foreign key (emp_ID) references Employee(emp_ID) on delete cascade on update cascade,
                    constraint fk_payroll_job foreign key (job_ID) references JobDepartment(job_ID) on delete cascade on update cascade,
                    constraint fk_payroll_salary foreign key (salary_ID) references SalaryBonus(salary_ID) on delete cascade on update cascade,
                    constraint fk_payroll_leave foreign key (leave_ID) references Leaves(leave_ID) on delete  cascade on update cascade);




select * from JobDepartment ;

select * from SalaryBonus;

select * from  Employee ;

select * from Qualification;

select * from Leaves;

select * from payroll;

-- insights on the employee --

-- 1 how many unique emmployees are currently in the system 

select  count(distinct emp_ID) as unique_employees from Employee ;

-- 2 which departments have the highest number of employees
select   jb.jobdept ,
         count(emp.emp_ID) as max_employees  
		from Employee as emp 
        join JobDepartment as jb on emp.Job_ID =jb.Job_ID 
        group by jb.jobdept order by max_employees desc limit 2;

-- here we have different case i.e if the highest no of employees got tie (which means more than 1 dept has the same highest number )
-- so in this situation use this --

SELECT jd.jobdept AS Department, COUNT(e.emp_ID) AS total_employees
FROM Employee e
JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
HAVING COUNT(e.emp_ID) = (
    SELECT COUNT(e2.emp_ID) 
    FROM Employee e2
    JOIN JobDepartment jd2 ON e2.Job_ID = jd2.Job_ID
    GROUP BY jd2.jobdept
    ORDER BY COUNT(e2.emp_ID) DESC
    LIMIT 1);

-- 3 what is the avg  salary per department 

SELECT jd.jobdept AS Department,
       round(AVG(sb.amount),2) AS avg_salary
FROM Employee e
JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
GROUP BY jd.jobdept;

-- 4 Who are the top 5 highest-paid employees?

SELECT e.emp_ID,
       CONCAT(e.firstname, ' ', e.lastname) AS Employee_Name,
       jd.jobdept AS Department,
       sb.amount AS Salary,
       sb.bonus AS Bonus,
       sb.annual AS Annual_Pay
FROM Employee e
JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
ORDER BY sb.amount DESC
LIMIT 5;

-- What is the total salary expenditure across the company?

SELECT SUM(sb.amount + IFNULL(sb.bonus,0)) AS Total_Salary_Expenditure
FROM SalaryBonus sb;

-- job role and department analysis

-- 1 How many different job roles exist in each department?

SELECT jd.jobdept AS Department,
       COUNT(DISTINCT jd.name) AS total_job_roles
FROM JobDepartment jd
GROUP BY jd.jobdept;



-- 2 What is the average salary range per department?

SELECT jd.jobdept AS Department,
       round(AVG(sb.amount),2) AS avg_salary
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept;

-- 3 Which job roles offer the highest salary?

SELECT jd.name AS JobRole,
       jd.jobdept AS Department,
       MAX(sb.amount) AS highest_salary
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.name, jd.jobdept
ORDER BY highest_salary DESC limit 1;

-- 4 Which departments have the highest total salary allocation?

SELECT jd.jobdept AS Department,
       SUM(sb.amount + IFNULL(sb.bonus,0)) AS total_salary_allocation
FROM JobDepartment jd
JOIN SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY jd.jobdept
ORDER BY total_salary_allocation DESC;

-- 3. QUALIFICATION AND SKILLS ANALYSIS
-- How many employees have at least one qualification listed?
SELECT 
COUNT(DISTINCT Emp_ID) AS EmployeesWithQualification
FROM Qualification;

-- Which positions require the most qualifications?

SELECT Position, COUNT(QualID) AS NumQualifications
FROM Qualification
GROUP BY Position
ORDER BY NumQualifications DESC;

-- Which employees have the highest number of qualifications?
SELECT Q.Emp_ID, CONCAT(E.firstname, ' ', E.lastname) AS EmployeeName, COUNT(QualID) AS NumQualifications
FROM Qualification Q
JOIN Employee E ON Q.Emp_ID = E.emp_ID
GROUP BY Emp_ID, EmployeeName
ORDER BY NumQualifications DESC;


--  LEAVE AND ABSENCE PATTERNS

-- which  year had the most employees taking leaves?

SELECT YEAR(l.date) AS leave_year,
       COUNT(DISTINCT l.emp_ID) AS total_employees
FROM Leaves l
GROUP BY YEAR(l.date)
ORDER BY total_employees DESC
LIMIT 1;

-- What is the average number of leave days taken by its employees per department?
SELECT jd.jobdept AS Department,
       AVG(emp_leave.leave_count) AS avg_leave_days
FROM (
    SELECT e.emp_ID, COUNT(l.leave_ID) AS leave_count
    FROM Employee e
    LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
    GROUP BY e.emp_ID
) emp_leave
JOIN Employee e ON emp_leave.emp_ID = e.emp_ID
JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
GROUP BY jd.jobdept;

-- which employees have taken the most leaves?
SELECT e.emp_ID, CONCAT(e.firstname, ' ', e.lastname) AS Employee,
       COUNT(l.leave_ID) AS total_leaves
FROM Employee e
JOIN Leaves l ON e.emp_ID = l.emp_ID
GROUP BY e.emp_ID, e.firstname, e.lastname
ORDER BY total_leaves DESC
LIMIT 5;

-- What is the total number of leave days taken company-wide?
SELECT COUNT(*) AS total_leave_days
FROM Leaves;


-- How do leave days correlate with payroll amounts?

SELECT e.emp_ID, CONCAT(e.firstname, ' ', e.lastname) AS Employee,
       COUNT(l.leave_ID) AS total_leaves,
       SUM(p.total_amount) AS total_payroll
FROM Employee e
LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
LEFT JOIN Payroll p ON e.emp_ID = p.emp_ID
GROUP BY e.emp_ID, e.firstname, e.lastname
ORDER BY total_leaves DESC;


-- PAYROLL AND COMPENSATION ANALYSIS
-- 1 What is the total monthly payroll processed?

SELECT 
    YEAR(p.date) AS year,
    MONTH(p.date) AS month,
    SUM(p.total_amount) AS total_monthly_payroll
FROM payroll p
GROUP BY YEAR(p.date), MONTH(p.date)
ORDER BY year, month;

=
-- 2 What is the average bonus given per department?
SELECT jd.jobdept AS Department,
       round(AVG(sb.bonus),2) AS avg_bonus
FROM SalaryBonus sb
JOIN JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY jd.jobdept;


-- 3 Which department receives the highest total bonuses?
SELECT jd.jobdept AS Department,
       SUM(sb.bonus) AS total_bonus
FROM SalaryBonus sb
JOIN JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY total_bonus DESC
LIMIT 1;

-- 4 What is the average value of total_amount after considering leave deductions?

SELECT 
    ROUND(AVG(total_amount), 2) AS avg_net_pay
FROM Payroll;

-- 6. EMPLOYEE PERFORMANCE AND GROWTH
 -- Which year had the highest number of employee promotions?
 
 SELECT 
    YEAR(q.Date_In) AS Promotion_Year,
    COUNT(*) AS total_promotions
FROM Qualification q
GROUP BY YEAR(q.Date_In)
ORDER BY total_promotions DESC
LIMIT 1;




















