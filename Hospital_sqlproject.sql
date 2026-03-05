-- HOSPITAL PATIENT RECORD SYSTEM 

create database HospitalDB;
use HospitalDB;


-- create tables of patients, doctors, appointments, treatments, billing
CREATE TABLE Patients (
  PatientID INT PRIMARY KEY,
  FirstName VARCHAR(50),
  LastName VARCHAR(50),
  Gender ENUM('Male','Female','Other'),
  DOB DATE,
  Phone VARCHAR(30),
  Address VARCHAR(255),
  AdmissionDate DATE,
  BloodGroup VARCHAR(5),
  EmergencyContact VARCHAR(30)
);

CREATE TABLE Doctors (
  DoctorID INT PRIMARY KEY,
  FirstName VARCHAR(50),
  LastName VARCHAR(50),
  Specialty VARCHAR(80),
  Phone VARCHAR(30),
  Email VARCHAR(100),
  Department VARCHAR(50)
);

CREATE TABLE Appointments (
  AppointmentID INT PRIMARY KEY,
  PatientID INT,
  DoctorID INT,
  AppointmentDate DATETIME,
  Reason VARCHAR(200),
  Status ENUM('Scheduled','Completed','Cancelled'),
  FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
  FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);

CREATE TABLE Treatments (
  TreatmentID INT PRIMARY KEY,
  PatientID INT,
  DoctorID INT,
  TreatmentDate DATE,
  Diagnosis VARCHAR(255),
  Prescription VARCHAR(255),
  Notes TEXT,
  FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
  FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);

CREATE TABLE Billing (
  BillID INT AUTO_INCREMENT PRIMARY KEY,
  PatientID INT,
  BillDate DATE,
  Amount DECIMAL(10,2),
  Status ENUM('Paid','Unpaid','Pending'),
  PaymentMethod VARCHAR(30),
  FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

-- count of the columns from patients, doctors, appointments, treatments, billing
SELECT COUNT(*) as Total FROM Patients;
SELECT COUNT(*) as Total FROM Doctors;
SELECT COUNT(*) as Total FROM Appointments;
SELECT COUNT(*) as Total FROM Treatments;
SELECT COUNT(*) as Total FROM Billing;


-- Show tables in HospitalDb database
show tables;

-- 1. Show preview of patient table
SELECT * FROM Patients LIMIT 10;

-- 2. Count total records from each table
SELECT 
  (SELECT COUNT(*) FROM Patients) AS Patients,
  (SELECT COUNT(*) FROM Doctors) AS Doctors,
  (SELECT COUNT(*) FROM Appointments) AS Appointments,
  (SELECT COUNT(*) FROM Billing) AS Bills;
  
-- 3. Check appointment by status
SELECT Status, COUNT(*) AS cnt FROM Appointments GROUP BY Status;

-- 4. Find total number of bills and revenue
SELECT COUNT(*) AS NumBills, SUM(Amount) AS TotalRevenue FROM Billing;

-- 5. Find patients by genders
SELECT Gender, COUNT(*) as Total FROM Patients GROUP BY Gender;

-- 6. Find how many patients are older than age 60
SELECT PatientID, FirstName, LastName, TIMESTAMPDIFF(YEAR, DOB, CURDATE()) AS Age FROM Patients 
WHERE TIMESTAMPDIFF(YEAR, DOB, CURDATE()) > 60;

-- 7. Find upcoming appointments in next 7 days 
SELECT * FROM Appointments WHERE AppointmentDate BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY) ORDER BY AppointmentDate;

-- 8. Find how many appointment are monthly
SELECT DATE_FORMAT(AppointmentDate,'%Y-%m') AS YearMonth, COUNT(*) AS ApptCount FROM Appointments GROUP BY 
YearMonth ORDER BY YearMonth;

-- 9. Find top 10 patients by number of visits 
SELECT p.PatientID, CONCAT(p.FirstName,' ',p.LastName) AS Patient, COUNT(*) AS Visits FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID GROUP BY p.PatientID ORDER BY Visits DESC LIMIT 10;

-- 10. Find top 10 doctors by number of appointments schedule
SELECT d.DoctorID, CONCAT(d.FirstName,' ',d.LastName) AS Doctor, COUNT(*) AS NumAppts FROM Appointments a 
JOIN Doctors d ON a.DoctorID = d.DoctorID GROUP BY d.DoctorID ORDER BY NumAppts DESC LIMIT 10;

-- 11. Find Monthly revenue of hospital
SELECT DATE_FORMAT(BillDate,'%Y-%m') AS YearMonth, SUM(Amount) AS Revenue FROM Billing GROUP BY YearMonth ORDER BY YearMonth;

-- 12. Find average bill per patient who came repeadtly
SELECT b.PatientID, CONCAT(p.FirstName,' ',p.LastName) AS Patient, ROUND(AVG(b.Amount),2) AS AvgBill
FROM Billing b JOIN Patients p ON b.PatientID = p.PatientID GROUP BY b.PatientID ORDER BY AvgBill DESC LIMIT 20;

-- 13. Find patients with unpaid totals amount 
SELECT b.PatientID, CONCAT(p.FirstName,' ',p.LastName) AS Patient, SUM(b.Amount) AS UnpaidTotal
FROM Billing b JOIN Patients p ON b.PatientID = p.PatientID WHERE b.Status = 'Unpaid' GROUP BY b.PatientID 
HAVING UnpaidTotal > 0 ORDER BY UnpaidTotal DESC;

-- 14. Find treatments with all patients & doctors with names
SELECT t.TreatmentID, t.TreatmentDate, t.Diagnosis, t.Prescription,
CONCAT(p.FirstName,' ',p.LastName) AS Patient,
CONCAT(d.FirstName,' ',d.LastName) AS Doctor
FROM Treatments t JOIN Patients p ON t.PatientID = p.PatientID JOIN Doctors d ON t.DoctorID = d.DoctorID
ORDER BY t.TreatmentDate DESC LIMIT 50;

-- 15. Find most common diagnosis treatment done by patients
SELECT Diagnosis, COUNT(*) AS cnt FROM Treatments GROUP BY Diagnosis ORDER BY cnt DESC LIMIT 10;

-- 16. Find patients billed but never had an appointment
SELECT DISTINCT b.PatientID, CONCAT(p.FirstName,' ',p.LastName) AS Patient
FROM Billing b
JOIN Patients p ON b.PatientID = p.PatientID
WHERE NOT EXISTS (SELECT 1 FROM Appointments a WHERE a.PatientID = b.PatientID);

-- 17. Find moving 3-month average revenue
WITH rev AS (SELECT DATE_FORMAT(BillDate,'%Y-%m') AS ym, SUM(Amount) AS revenue FROM Billing GROUP BY ym)
SELECT ym, revenue, ROUND(AVG(revenue) OVER (ORDER BY ym ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS MovingAvg3
FROM rev ORDER BY ym;

-- 18. Find month over month % change
WITH rev AS (SELECT DATE_FORMAT(BillDate,'%Y-%m') AS ym, SUM(Amount) AS revenue FROM Billing GROUP BY ym)
SELECT ym, revenue, ROUND((revenue - LAG(revenue) OVER (ORDER BY ym)) / NULLIF(LAG(revenue) OVER (ORDER BY ym),0) * 100,2) 
AS pct_change FROM rev ORDER BY ym;
-- check 

-- 19. Find last appointment date for each of patient
SELECT PatientID, MAX(AppointmentDate) AS LastVisit FROM Appointments GROUP BY PatientID;

-- 20. Find patients with visit within next 15 days 
SELECT DISTINCT x.PatientID,CONCAT(p.FirstName,' ',p.LastName) AS Patient
FROM (SELECT PatientID, AppointmentDate,LAG(AppointmentDate) OVER (PARTITION BY PatientID ORDER BY AppointmentDate) AS PrevDate
FROM Appointments) x
JOIN Patients p ON x.PatientID = p.PatientID WHERE x.PrevDate IS NOT NULL
AND DATEDIFF(x.AppointmentDate, x.PrevDate) <= 15;


-- 21. Find approximate revenue attributed to most recent doctors 
SELECT d.DoctorID, CONCAT(d.FirstName,' ',d.LastName) AS Doctor, ROUND(SUM(b.Amount),2) AS AttributedRevenue
FROM Billing b
JOIN Doctors d ON d.DoctorID = (SELECT a.DoctorID FROM Appointments a 
WHERE a.PatientID = b.PatientID AND a.AppointmentDate <= b.BillDate
ORDER BY a.AppointmentDate DESC LIMIT 1)
GROUP BY d.DoctorID ORDER BY AttributedRevenue DESC LIMIT 20;

-- 22. Find or detect duplicate patient records like same name + DOB
SELECT FirstName, LastName, DOB, COUNT(*) AS dup_count, GROUP_CONCAT(PatientID) AS ids
FROM Patients GROUP BY FirstName, LastName, DOB HAVING dup_count > 1;
 
-- 23. Find patients grouped by Blood Group
SELECT BloodGroup, COUNT(*) AS NumPatients
FROM Patients
GROUP BY BloodGroup
ORDER BY NumPatients DESC;


-- 24. Create a Patient Summary view with appointments, treatments, total billed, lastvisit
CREATE OR REPLACE VIEW vw_PatientSummary AS
SELECT p.PatientID, CONCAT(p.FirstName,' ',p.LastName) AS PatientName, p.Gender, p.DOB, p.AdmissionDate,
  (SELECT COUNT(*) FROM Appointments a WHERE a.PatientID = p.PatientID) AS NumAppointments,
  (SELECT COUNT(*) FROM Treatments t WHERE t.PatientID = p.PatientID) AS NumTreatments,
  (SELECT IFNULL(SUM(b.Amount),0) FROM Billing b WHERE b.PatientID = p.PatientID) AS TotalBilled,
  (SELECT MAX(a.AppointmentDate) FROM Appointments a WHERE a.PatientID = p.PatientID) AS LastVisit
FROM Patients p;
-- then query it:
SELECT * FROM vw_PatientSummary WHERE TotalBilled > 0 ORDER BY TotalBilled DESC LIMIT 20;


-- 25. Stored Procedure: Add a new bill and return new BillID

USE HospitalDB;
DROP PROCEDURE IF EXISTS sp_mark_bill_paid;

DELIMITER //
CREATE PROCEDURE sp_mark_bill_paid(IN pBillID INT)
BEGIN
  -- Update the status to Paid
  UPDATE Billing
  SET Status = 'Paid'
  WHERE BillID = pBillID;

  -- Return the updated bill row
  SELECT * FROM Billing WHERE BillID = pBillID;
END //
DELIMITER ;

SHOW PROCEDURE STATUS WHERE Db = 'HospitalDB' AND Name = 'sp_mark_bill_paid';
CALL sp_mark_bill_paid(1);
SELECT BillID FROM Billing LIMIT 5;


-- 26. Find each patient’s last 3 appointments with doctor details
WITH ranked_appointments AS (SELECT 
a.PatientID,
CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
a.DoctorID,
CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
a.AppointmentDate,
ROW_NUMBER() OVER (PARTITION BY a.PatientID ORDER BY a.AppointmentDate DESC) AS visit_rank
FROM Appointments a JOIN Patients p ON a.PatientID = p.PatientID JOIN Doctors d ON a.DoctorID = d.DoctorID)
SELECT * FROM ranked_appointments WHERE visit_rank <= 3 ORDER BY PatientID, visit_rank;


























-- 26. 

























  
  










