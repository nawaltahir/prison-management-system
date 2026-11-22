/* =====================================================
   Prison Management System (PMS) - SQL Server script
   Run in SSMS: New Query -> paste -> Execute (F5)
   ===================================================== */

IF DB_ID('PrisonManagementSystem') IS NOT NULL
BEGIN
    ALTER DATABASE PrisonManagementSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PrisonManagementSystem;
END
GO
CREATE DATABASE PrisonManagementSystem;
GO
USE PrisonManagementSystem;
GO

/* ---------- 1. Staff ---------- */
CREATE TABLE Staff (
    staff_id    INT IDENTITY(1,1) CONSTRAINT PK_Staff PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(30)  NOT NULL,
    rank        VARCHAR(30)  NULL,
    phone       VARCHAR(20)  NULL,
    hire_date   DATE         NOT NULL CONSTRAINT DF_Staff_hire DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Staff_role CHECK (role IN ('Warden','Guard','Doctor','Admin','Other'))
);

/* ---------- 2. Inmate ---------- */
CREATE TABLE Inmate (
    inmate_id       INT IDENTITY(1,1) CONSTRAINT PK_Inmate PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    national_id     VARCHAR(20)  NOT NULL CONSTRAINT UQ_Inmate_national UNIQUE,
    date_of_birth   DATE         NOT NULL,
    gender          CHAR(1)      NOT NULL,
    admission_date  DATE         NOT NULL CONSTRAINT DF_Inmate_adm DEFAULT (CAST(GETDATE() AS DATE)),
    status          VARCHAR(20)  NOT NULL CONSTRAINT DF_Inmate_status DEFAULT ('Active'),
    CONSTRAINT CK_Inmate_gender CHECK (gender IN ('M','F','O')),
    CONSTRAINT CK_Inmate_status CHECK (status IN ('Active','Released','Transferred','Deceased')),
    CONSTRAINT CK_Inmate_dates  CHECK (admission_date >= date_of_birth)
);

/* ---------- 3. Block ---------- */
CREATE TABLE Block (
    block_id       INT IDENTITY(1,1) CONSTRAINT PK_Block PRIMARY KEY,
    block_name     VARCHAR(50) NOT NULL CONSTRAINT UQ_Block_name UNIQUE,
    capacity       INT NOT NULL,
    supervisor_id  INT NULL,
    CONSTRAINT CK_Block_cap CHECK (capacity > 0),
    CONSTRAINT FK_Block_Staff FOREIGN KEY (supervisor_id) REFERENCES Staff(staff_id)
);

/* ---------- 4. Cell ---------- */
CREATE TABLE Cell (
    cell_id    INT IDENTITY(1,1) CONSTRAINT PK_Cell PRIMARY KEY,
    block_id   INT NOT NULL,
    cell_no    VARCHAR(10) NOT NULL,
    capacity   INT NOT NULL,
    type       VARCHAR(30) NOT NULL CONSTRAINT DF_Cell_type DEFAULT ('General'),
    CONSTRAINT UQ_Cell_block_no UNIQUE (block_id, cell_no),
    CONSTRAINT CK_Cell_cap  CHECK (capacity > 0),
    CONSTRAINT CK_Cell_type CHECK (type IN ('General','Solitary','Medical','High-Security')),
    CONSTRAINT FK_Cell_Block FOREIGN KEY (block_id) REFERENCES Block(block_id)
);

/* ---------- 5. Case_File ---------- */
CREATE TABLE Case_File (
    case_id      INT IDENTITY(1,1) CONSTRAINT PK_Case_File PRIMARY KEY,
    inmate_id    INT NOT NULL,
    court_name   VARCHAR(100) NOT NULL,
    filing_date  DATE NOT NULL,
    status       VARCHAR(20) NOT NULL CONSTRAINT DF_Case_status DEFAULT ('Open'),
    CONSTRAINT CK_Case_status CHECK (status IN ('Open','Closed','Appealed')),
    CONSTRAINT FK_Case_Inmate FOREIGN KEY (inmate_id) REFERENCES Inmate(inmate_id)
);

/* ---------- 6. Offense ---------- */
CREATE TABLE Offense (
    offense_id  INT IDENTITY(1,1) CONSTRAINT PK_Offense PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    category    VARCHAR(50)  NOT NULL,
    severity    INT NOT NULL,
    CONSTRAINT CK_Offense_sev CHECK (severity BETWEEN 1 AND 10)
);

/* ---------- 7. Sentence (1:1 with Case_File) ---------- */
CREATE TABLE Sentence (
    sentence_id   INT IDENTITY(1,1) CONSTRAINT PK_Sentence PRIMARY KEY,
    case_id       INT NOT NULL CONSTRAINT UQ_Sentence_case UNIQUE,
    start_date    DATE NOT NULL,
    term_months   INT  NOT NULL,
    release_date  DATE NULL,
    CONSTRAINT CK_Sentence_term CHECK (term_months > 0),
    CONSTRAINT CK_Sentence_rel  CHECK (release_date IS NULL OR release_date >= start_date),
    CONSTRAINT FK_Sentence_Case FOREIGN KEY (case_id) REFERENCES Case_File(case_id)
);

/* ---------- 8. Visitor ---------- */
CREATE TABLE Visitor (
    visitor_id  INT IDENTITY(1,1) CONSTRAINT PK_Visitor PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    id_no       VARCHAR(20)  NOT NULL CONSTRAINT UQ_Visitor_idno UNIQUE,
    phone       VARCHAR(20)  NULL,
    relation    VARCHAR(30)  NULL
);

/* ---------- 9. Medical_Record ---------- */
CREATE TABLE Medical_Record (
    record_id     INT IDENTITY(1,1) CONSTRAINT PK_Medical PRIMARY KEY,
    inmate_id     INT NOT NULL,
    doctor_id     INT NOT NULL,
    checkup_date  DATE NOT NULL CONSTRAINT DF_Med_date DEFAULT (CAST(GETDATE() AS DATE)),
    diagnosis     VARCHAR(200) NULL,
    treatment     VARCHAR(200) NULL,
    CONSTRAINT FK_Med_Inmate FOREIGN KEY (inmate_id) REFERENCES Inmate(inmate_id),
    CONSTRAINT FK_Med_Staff  FOREIGN KEY (doctor_id) REFERENCES Staff(staff_id)
);

/* ---------- 10. Incident ---------- */
CREATE TABLE Incident (
    incident_id    INT IDENTITY(1,1) CONSTRAINT PK_Incident PRIMARY KEY,
    reported_by    INT NOT NULL,
    incident_date  DATE NOT NULL CONSTRAINT DF_Inc_date DEFAULT (CAST(GETDATE() AS DATE)),
    type           VARCHAR(50)  NOT NULL,
    description    VARCHAR(500) NULL,
    CONSTRAINT FK_Incident_Staff FOREIGN KEY (reported_by) REFERENCES Staff(staff_id)
);

/* ---------- 11. Cell_Assignment (junction Inmate-Cell) ---------- */
CREATE TABLE Cell_Assignment (
    assignment_id  INT IDENTITY(1,1) CONSTRAINT PK_CellAssign PRIMARY KEY,
    inmate_id      INT NOT NULL,
    cell_id        INT NOT NULL,
    from_date      DATE NOT NULL,
    to_date        DATE NULL,
    CONSTRAINT CK_CellAssign_dates CHECK (to_date IS NULL OR to_date >= from_date),
    CONSTRAINT FK_CA_Inmate FOREIGN KEY (inmate_id) REFERENCES Inmate(inmate_id),
    CONSTRAINT FK_CA_Cell   FOREIGN KEY (cell_id)   REFERENCES Cell(cell_id)
);

/* ---------- 12. Case_Offense (junction Case_File-Offense) ---------- */
CREATE TABLE Case_Offense (
    case_id     INT NOT NULL,
    offense_id  INT NOT NULL,
    CONSTRAINT PK_Case_Offense PRIMARY KEY (case_id, offense_id),
    CONSTRAINT FK_CO_Case    FOREIGN KEY (case_id)    REFERENCES Case_File(case_id),
    CONSTRAINT FK_CO_Offense FOREIGN KEY (offense_id) REFERENCES Offense(offense_id)
);

/* ---------- 13. Visit (junction Inmate-Visitor, approved by Staff) ---------- */
CREATE TABLE Visit (
    visit_id     INT IDENTITY(1,1) CONSTRAINT PK_Visit PRIMARY KEY,
    inmate_id    INT NOT NULL,
    visitor_id   INT NOT NULL,
    approved_by  INT NULL,
    visit_date   DATE NOT NULL,
    status       VARCHAR(20) NOT NULL CONSTRAINT DF_Visit_status DEFAULT ('Pending'),
    CONSTRAINT CK_Visit_status CHECK (status IN ('Pending','Approved','Rejected','Completed')),
    CONSTRAINT FK_Visit_Inmate  FOREIGN KEY (inmate_id)   REFERENCES Inmate(inmate_id),
    CONSTRAINT FK_Visit_Visitor FOREIGN KEY (visitor_id)  REFERENCES Visitor(visitor_id),
    CONSTRAINT FK_Visit_Staff   FOREIGN KEY (approved_by) REFERENCES Staff(staff_id)
);

/* ---------- 14. Incident_Inmate (junction Incident-Inmate) ---------- */
CREATE TABLE Incident_Inmate (
    incident_id  INT NOT NULL,
    inmate_id    INT NOT NULL,
    involvement  VARCHAR(100) NULL,
    CONSTRAINT PK_Incident_Inmate PRIMARY KEY (incident_id, inmate_id),
    CONSTRAINT FK_II_Incident FOREIGN KEY (incident_id) REFERENCES Incident(incident_id),
    CONSTRAINT FK_II_Inmate   FOREIGN KEY (inmate_id)   REFERENCES Inmate(inmate_id)
);
GO

/* ---------- Verify ---------- */
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME;  -- expect 14 rows
GO
