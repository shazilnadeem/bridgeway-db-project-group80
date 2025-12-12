# Bridgeway Database Project - Phase 3 Submission
**Group Number:** 80

## Project Overview & Implementation Strategy

This submission represents the culmination of our database system design, focusing on the integration of a .NET application with our SQL Server backend.

**Note on Frontend Implementation:**
Our development roadmap initially targeted a full ASP.NET Core MVC web interface (CSHTML). While significant progress was made on the web layer, we encountered integration complexities that threatened the stability of the core business logic within the submission timeline. 

To ensure we delivered a **robust, error-free, and fully compliant application** that meets all critical Phase 3 requirements (Factory Pattern, dynamic BLL switching, Stored Procedures, and complex database interactions), we pivoted to a **minimalistic Console Application**. This approach allowed us to rigorously test and perfect the backend logic and database integrity without the overhead of debugging UI-specific issues. We intend to finalize the web interface in future development cycles.

## Key Features Implemented

* **Factory Design Pattern:** Dynamic runtime selection between Entity Framework (EF) and Stored Procedure (SP) data access layers.
* **Role-Based Access Control:** Distinct workflows for Admins, Clients, and Engineers.
* **Complex Database Operations:** Utilization of Stored Procedures, Triggers, Views, and User-Defined Functions.
* **Interactive Workflows:** Full lifecycle support for Vetting, Job Creation, Matching Algorithms, Hiring, and Performance Rating.

---

## Setup Instructions

### 1. Database Configuration
Before running the application, the database must be initialized and populated.

1.  Open **SQL Server Management Studio (SSMS)**.
2.  Open the file located at: `PROJECT/sql/phase2DB.sql`.
3.  Execute the script entirely. This will:
    * Create the `BridgewayDB` database.
    * Create all tables, constraints, and relationships.
    * Define all Stored Procedures, Views, Triggers, and Functions.
    * Populate the database with initial seed/dummy data.

### 2. Application Configuration
The application source code is located in the `src` directory. The key projects are:
* `Bridgeway.ConsoleApp`: The presentation layer (Entry Point).
* `Bridgeway.BLL.EF`: Business Logic Layer using Entity Framework.
* `Bridgeway.BLL.SP`: Business Logic Layer using ADO.NET/Stored Procedures.
* `Bridgeway.Domain`: Shared DTOs and Interfaces.

**Connection String:**
Ensure your local SQL Server connection string is correctly set in `src/Bridgeway.ConsoleApp/ConsoleFactory.cs`. The default is configured for a local instance:
`Server=localhost,1433;Database=BridgewayDB;User Id=sa;Password=YourPassword;TrustServerCertificate=True;`

---

## How to Run the Application

You can run the application directly using the .NET CLI.

1.  Open your terminal or command prompt.
2.  Navigate to the project source folder:
    ```bash
    cd "PROJECT/src"
    ```
3.  Execute the Console Application:
    ```bash
    dotnet run --project Bridgeway.ConsoleApp/Bridgeway.ConsoleApp.csproj
    ```

### Using the Application
Upon launch, you will be prompted to select a Data Access Mode:
* **Type '1':** To use Entity Framework (EF).
* **Type '2':** To use Stored Procedures (SP).

Once initialized, you may log in using the seed credentials provided in the database script or register new users directly through the console interface.