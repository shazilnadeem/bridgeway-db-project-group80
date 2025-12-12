using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.ConsoleApp; 

class Program
{
    // Global State to track who is logged in
    static int CurrentUserId = 0;
    static string CurrentUserRole = "";
    static string CurrentUserName = ""; 

    static void Main(string[] args)
    {
        Console.WriteLine("=== BRIDGEWAY TERMINAL (PHASE 3: FINAL) ===");
        
        // 1. Mode Selection (The "Factory Pattern" Requirement)
        Console.Write("Select Mode (1=EF, 2=SP) [Default SP]: ");
        var modeInput = Console.ReadLine();
        ConsoleFactory.IsEfMode = (modeInput == "1");
        Console.WriteLine($"System initialized in {(ConsoleFactory.IsEfMode ? "EF" : "SP")} mode.");
        Console.WriteLine("-------------------------------------------");

        // 2. Main Loop
        while (true)
        {
            if (CurrentUserId == 0) ShowAuthMenu();
            else
            {
                if (CurrentUserRole == "client") ShowClientMenu();
                else if (CurrentUserRole == "engineer") ShowEngineerMenu();
                else if (CurrentUserRole == "admin") ShowAdminMenu();
                else 
                { 
                    Console.WriteLine($"Unknown Role '{CurrentUserRole}'. Logging out."); 
                    CurrentUserId = 0; 
                }
            }
        }
    }

    // =========================================================
    // 1. AUTHENTICATION & REGISTRATION
    // =========================================================
    static void ShowAuthMenu()
    {
        Console.WriteLine("\n--- WELCOME ---");
        Console.WriteLine("1. Login");
        Console.WriteLine("2. Register Client");
        Console.WriteLine("3. Register Engineer");
        Console.WriteLine("4. Exit");
        Console.Write("Choice: ");
        var input = Console.ReadLine();

        if (input == "4") Environment.Exit(0);
        
        if (input == "1") // LOGIN
        {
            Console.Write("Email: "); var em = Console.ReadLine();
            Console.Write("Password: "); var pw = Console.ReadLine();
            
            // Helper fetches ID, Role, and Name in one go
            if (AuthHelperExtensions.LoginWithProfile(em, pw, out int id, out string role, out string name))
            {
                CurrentUserId = id;
                CurrentUserRole = role;
                CurrentUserName = name;
                Console.WriteLine($"Login Success! Welcome, {name}.");
            }
            else Console.WriteLine("Invalid credentials.");
        }
        else if (input == "2" || input == "3") // REGISTER
        {
            Console.Write("Full Name: "); var name = Console.ReadLine() ?? "";
            Console.Write("Email: "); var em = Console.ReadLine() ?? "";
            Console.Write("Password: "); var pw = Console.ReadLine() ?? "";
            
            string role = (input == "2") ? "client" : "engineer";
            try 
            {
                int newUserId = AuthHelper.RegisterUser(name, em, pw, role);
                Console.WriteLine($"User created (ID: {newUserId}). Completing Profile...");

                if (role == "client")
                {
                    Console.Write("Company Name: ");
                    string comp = Console.ReadLine() ?? "Default Co";
                    AuthHelperExtensions.UpdateClientProfile(newUserId, comp);
                    ConsoleFactory.GetClientService().RegisterClient(newUserId);
                }
                else
                {
                    // Create empty profile for engineer
                    ConsoleFactory.GetEngineerService().RegisterEngineer(newUserId);
                }
                Console.WriteLine("Registration Complete! Please Login.");
            }
            catch (Exception ex) { Console.WriteLine($"Error: {ex.Message}"); }
        }
    }

    // =========================================================
    // 2. CLIENT DASHBOARD
    // =========================================================
    static void ShowClientMenu()
    {
        var jobService = ConsoleFactory.GetJobService();
        var clientService = ConsoleFactory.GetClientService();
        var engineerService = ConsoleFactory.GetEngineerService();

        // Fetch latest profile data
        var clientProfile = clientService.GetByUserId(CurrentUserId);
        if(clientProfile == null) { Console.WriteLine("Profile Error. Contact Admin."); CurrentUserId = 0; return; }
        int clientId = clientProfile.ClientId; 

        Console.WriteLine($"\n--- CLIENT DASHBOARD: {clientProfile.CompanyName} ---");
        Console.WriteLine("1. Create New Job");
        Console.WriteLine("2. View Matches (Hire Engineers)");
        Console.WriteLine("3. Active Contracts (Rate Engineers)");
        Console.WriteLine("4. Edit Company Profile"); // <--- NEW OPTION
        Console.WriteLine("5. View Detailed Profile (Any Engineer)"); 
        Console.WriteLine("6. Logout");
        Console.Write("Choice: ");
        
        var choice = Console.ReadLine();
        if (choice == "6") { CurrentUserId = 0; return; }

        if (choice == "1") // CREATE JOB
        {
            Console.Write("Job Title: "); var title = Console.ReadLine() ?? "";
            Console.Write("Description: "); var desc = Console.ReadLine() ?? "";

            Console.WriteLine("\n--- Available Skills ---");
            var skills = HelperMethods.GetAllSkills();
            foreach (var s in skills) Console.Write($"[{s.Key}] {s.Value}  ");
            
            Console.WriteLine("\n\nEnter Skill IDs comma separated (e.g. 1, 5): ");
            string skillInput = Console.ReadLine() ?? "";
            List<int> selectedSkills = new List<int>();
            foreach(var part in skillInput.Split(',')) if (int.TryParse(part.Trim(), out int sid)) selectedSkills.Add(sid);

            var dto = new JobCreateDto { 
                ClientId = clientId, Title = title, Description = desc,
                JobType = "Contract", Budget = 0, SkillIds = selectedSkills
            };

            var createdJob = jobService.CreateJob(dto);
            if (!ConsoleFactory.IsEfMode && createdJob != null && selectedSkills.Count > 0)
                HelperMethods.ManuallySaveJobSkills(createdJob.JobId, selectedSkills);

            Console.WriteLine("Job Created Successfully!");
        }
        else if (choice == "2") // VIEW MATCHES
        {
            var jobs = jobService.GetJobsForClient(clientId);
            foreach (var j in jobs)
            {
                if (j.Status != "open") continue;

                Console.WriteLine($"\n[Job ID: {j.JobId}] {j.Title} ({j.Status})");
                Console.WriteLine("   -> 1. Find Candidates");
                Console.WriteLine("   -> 2. Skip");
                
                if (Console.ReadLine() == "1")
                {
                    Console.WriteLine("Running Match Algorithm...");
                    jobService.RunMatching(j.JobId, 10);
                    
                    var candidates = jobService.GetRankedCandidates(j.JobId);
                    if (candidates.Count == 0) 
                    {
                        Console.WriteLine("   (No matching candidates found.)");
                        continue;
                    }

                    Console.WriteLine("   --- TOP CANDIDATES ---");
                    foreach (var c in candidates)
                        Console.WriteLine($"   [ID: {c.EngineerId}] {c.FullName} | Score: {c.MatchScore}% | Status: {c.ApplicationStatus ?? "Pending"}");

                    Console.Write("\nEnter Engineer ID to view Profile (or 0): ");
                    if (int.TryParse(Console.ReadLine(), out int engId) && engId > 0)
                    {
                        HelperMethods.DisplayFullEngineerProfile(engId);
                        Console.WriteLine($"\nMatch Score: {HelperMethods.GetMatchScore(j.JobId, engId)}%");
                        Console.WriteLine("1. Accept Application (Hire)");
                        Console.WriteLine("2. Reject Application");
                        Console.WriteLine("3. Back");
                        
                        var action = Console.ReadLine();
                        if(action == "1") {
                            HelperMethods.UpdateApplicationStatus(j.JobId, engId, "accepted");
                            Console.WriteLine("SUCCESS: Engineer Hired! Job moved to 'Active Contracts'.");
                        }
                        else if (action == "2") {
                            HelperMethods.UpdateApplicationStatus(j.JobId, engId, "rejected");
                            Console.WriteLine("Candidate Rejected.");
                        }
                    }
                }
            }
        }
        else if (choice == "3") // ACTIVE CONTRACTS
        {
            var contracts = HelperMethods.GetClientContracts(clientId);
            if (contracts.Count == 0) Console.WriteLine("No active contracts.");

            foreach(var c in contracts)
            {
                Console.WriteLine($"\nJob: {c.JobTitle} | Engineer: {c.EngineerName} | Status: {c.JobStatus.ToUpper()}");
                
                if (c.JobStatus == "closed")
                {
                    if (c.IsRated) Console.WriteLine("   [Rating Submitted]");
                    else 
                    {
                        Console.WriteLine("   [!] JOB FINISHED. Please Rate Engineer.");
                        Console.Write("   Enter Stars (1-5): ");
                        if (int.TryParse(Console.ReadLine(), out int stars) && stars >= 1 && stars <= 5) {
                            HelperMethods.SubmitRating(clientId, c.EngineerId, stars);
                            Console.WriteLine("Rating Submitted!");
                        }
                    }
                }
                else Console.WriteLine("   (Work in progress)");
            }
        }
        else if (choice == "4") // EDIT PROFILE (NEW FEATURE)
        {
            Console.WriteLine($"\n--- EDIT PROFILE ---");
            Console.WriteLine($"Current Company Name: {clientProfile.CompanyName}");
            Console.Write("New Company Name (Enter to keep current): ");
            string newName = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(newName)) newName = clientProfile.CompanyName;

            Console.WriteLine($"Current Industry: {clientProfile.Industry ?? "N/A"}");
            Console.Write("New Industry (Enter to keep/skip): ");
            string newInd = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(newInd)) newInd = clientProfile.Industry ?? "";

            try {
                AuthHelperExtensions.UpdateClientProfile(CurrentUserId, newName, newInd);
                Console.WriteLine("Profile Updated Successfully!");
            } catch (Exception ex) { Console.WriteLine($"Error: {ex.Message}"); }
        }
        else if (choice == "5") // VIEW ANY ENGINEER PROFILE
        {
            Console.Write("Enter Engineer ID: ");
            if (int.TryParse(Console.ReadLine(), out int eid)) HelperMethods.DisplayFullEngineerProfile(eid);
        }
    }

    // =========================================================
    // 3. ENGINEER DASHBOARD
    // =========================================================
    static void ShowEngineerMenu()
    {
        var engService = ConsoleFactory.GetEngineerService();
        var appService = ConsoleFactory.GetApplicationService();
        var myProfile = engService.GetCurrentEngineerProfile(CurrentUserId);
        
        if (myProfile == null) { Console.WriteLine("Profile Error."); CurrentUserId = 0; return; }

        Console.WriteLine($"\n--- ENGINEER DASHBOARD: {myProfile.FullName} ---");
        Console.WriteLine($"Email: {myProfile.Email}");
        Console.WriteLine($"Rating: {myProfile.AvgRating:F1}/5.0 | Vet Status: {myProfile.VetStatus}");
        
        Console.WriteLine("1. Edit Profile (Skills/Bio)");
        Console.WriteLine("2. View My Applications");
        Console.WriteLine("3. Active Jobs (Mark Finished)");
        Console.WriteLine("4. Logout");
        Console.Write("Choice: ");

        var choice = Console.ReadLine();
        if (choice == "4") { CurrentUserId = 0; return; }

        if (choice == "1") // EDIT
        {
            Console.WriteLine($"Current Experience: {myProfile.YearsExperience}y");
            Console.Write("New Experience (Enter to skip): ");
            if (int.TryParse(Console.ReadLine(), out int exp)) myProfile.YearsExperience = exp;

            Console.WriteLine($"Current Bio/Portfolio: {myProfile.PortfolioLink}");
            Console.Write("New Bio (Enter to skip): ");
            var bio = Console.ReadLine();
            if(!string.IsNullOrWhiteSpace(bio)) myProfile.PortfolioLink = bio;

            engService.UpdateEngineerProfile(myProfile);

            Console.WriteLine("\n--- Update Skills ---");
            Console.WriteLine("Enter ALL skill IDs you possess (comma separated):");
            var skills = HelperMethods.GetAllSkills();
            foreach (var s in skills) Console.Write($"[{s.Key}] {s.Value}  ");
            
            string skillInput = Console.ReadLine() ?? "";
            List<int> newSkills = new List<int>();
            foreach(var part in skillInput.Split(',')) if (int.TryParse(part.Trim(), out int sid)) newSkills.Add(sid);

            if (newSkills.Count > 0)
            {
                HelperMethods.UpdateEngineerSkills(CurrentUserId, newSkills);
                Console.WriteLine("Profile & Skills Updated!");
            }
        }
        else if (choice == "2")
        {
            Console.WriteLine("\n--- My Applications ---");
            var apps = appService.GetApplicationsForEngineer(myProfile.EngineerId);
            foreach(var app in apps)
                Console.WriteLine($"- {app.JobTitle} at {app.CompanyName}: {app.Status.ToUpper()}");
        }
        else if (choice == "3")
        {
            Console.WriteLine("\n--- CURRENT JOBS ---");
            var activeJobs = HelperMethods.GetEngineerActiveJobs(myProfile.EngineerId);
            
            if (activeJobs.Count == 0) Console.WriteLine("No active jobs.");

            foreach(var job in activeJobs)
            {
                Console.WriteLine($"\nJob: {job.JobTitle} | Client: {job.ClientName}");
                Console.WriteLine("-> 1. Mark as Finished (Allow Rating)");
                Console.WriteLine("-> 2. Back");
                
                if (Console.ReadLine() == "1")
                {
                    HelperMethods.MarkJobAsFinished(job.JobId);
                    Console.WriteLine("Job Closed! Client has been notified to rate you.");
                }
            }
        }
    }

    // =========================================================
    // 4. ADMIN DASHBOARD
    // =========================================================
    static void ShowAdminMenu()
    {
        var vettingService = ConsoleFactory.GetVettingService();
        var analyticsService = ConsoleFactory.GetAnalyticsService(); 
        
        Console.WriteLine("\n--- ADMIN DASHBOARD ---");
        Console.WriteLine("1. Vetting Queue (Approve Engineers)");
        Console.WriteLine("2. User Management (Impersonate)"); // NEW FEATURE
        Console.WriteLine("3. Platform Analytics"); 
        Console.WriteLine("4. Logout");
        Console.Write("Choice: ");

        var choice = Console.ReadLine();
        if (choice == "4") { CurrentUserId = 0; return; }

        if (choice == "1") // VETTING
        {
            var queue = vettingService.GetVettingQueue();
            Console.WriteLine("\n--- PENDING ENGINEERS ---");
            if (queue.Count == 0) Console.WriteLine("No engineers pending vetting.");

            foreach(var q in queue)
                Console.WriteLine($"ID: {q.EngineerId} | Name: {q.EngineerName} | Calculated Score: {q.VettingScore}");

            Console.Write("\nEnter Engineer ID to Vet (or 0): ");
            if (int.TryParse(Console.ReadLine(), out int engId) && engId > 0)
            {
                HelperMethods.DisplayFullEngineerProfile(engId); // View details first

                Console.WriteLine("\nDecision: 1. Approve  2. Reject");
                var input = Console.ReadLine();
                // FIX: "recommended" is the magic word for your SQL logic to hit 100% score
                var decision = (input == "1") ? "recommended" : "rejected"; 
                
                string reason = "";
                if (decision == "rejected")
                {
                    Console.Write("Rejection Reason: ");
                    reason = Console.ReadLine() ?? "Does not meet criteria";
                }

                var review = new VettingReviewDto
                {
                    EngineerId = engId,
                    ReviewerUserId = CurrentUserId, 
                    Decision = decision,
                    SkillsVerified = true,
                    ExperienceVerified = true,
                    PortfolioVerified = true,
                    ReviewNotes = "Console Vetting",
                    RejectionReason = reason
                };

                try {
                    vettingService.CreateVettingReview(review); 
                    Console.WriteLine($"Review Submitted! Status set to {decision}.");
                }
                catch (Exception ex) { Console.WriteLine($"Error: {ex.Message}"); }
            }
        }
        else if (choice == "2") // IMPERSONATION
        {
            Console.WriteLine("\n--- ALL USERS ---");
            var users = HelperMethods.GetAllUsers();
            foreach(var u in users)
                Console.WriteLine($"ID: {u.Id} | Role: {u.Role,-10} | Name: {u.Name}");

            Console.Write("\nEnter User ID to Login as them (or 0): ");
            if (int.TryParse(Console.ReadLine(), out int targetId) && targetId > 0)
            {
                var target = users.Find(u => u.Id == targetId);
                if (target != null)
                {
                    CurrentUserId = target.Id;
                    CurrentUserRole = target.Role;
                    CurrentUserName = target.Name;
                    Console.WriteLine($"\n*** IMPERSONATING: {target.Name} ***");
                    Console.WriteLine("Returning to main menu as this user...");
                    // Loop restarts with new role
                }
            }
        }
        else if (choice == "3") // ANALYTICS
        {
            try {
                var stats = analyticsService.GetMonthlyPlatformStats(2025); 
                Console.WriteLine("\nMonth | New Eng | New Jobs | Apps | Avg Match");
                Console.WriteLine("---------------------------------------------");
                foreach (var s in stats)
                    Console.WriteLine($"{s.MonthNumber,-5} | {s.NewEngineers,-7} | {s.NewJobs,-8} | {s.TotalApplications,-4} | {s.AvgMatchScore:F1}%");
            } catch { Console.WriteLine("Error loading stats."); }
        }
    }
}

// =========================================================
// HELPER CLASSES & DTOs
// =========================================================

public class ContractDto
{
    public int JobId { get; set; }
    public string JobTitle { get; set; }
    public string JobStatus { get; set; }
    public int EngineerId { get; set; }
    public string EngineerName { get; set; }
    public string ClientName { get; set; }
    public bool IsRated { get; set; }
}

public class UserSummaryDto { public int Id; public string Name; public string Role; }

public static class HelperMethods
{
    // --- DISPLAY HELPERS ---
    public static void DisplayFullEngineerProfile(int engineerId)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            // Complex join to get everything: Profile, User details, and concatenated Skills
            string sql = @"
                SELECT u.full_name, u.email, ep.years_experience, ep.vet_status, ep.portfolio_link, ep.timezone,
                       (SELECT STRING_AGG(s.skill_name, ', ') 
                        FROM tbl_Engineer_Skills es 
                        JOIN tbl_Skill s ON es.skill_id = s.skill_id 
                        WHERE es.engineer_id = u.user_id) as skills
                FROM tbl_User u
                JOIN tbl_Engineer_Profile ep ON u.user_id = ep.engineer_id
                WHERE u.user_id = @id";

            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@id", engineerId);
                using(var r = cmd.ExecuteReader())
                {
                    if (r.Read())
                    {
                        Console.WriteLine("\n==========================================");
                        Console.WriteLine($"   ENGINEER PROFILE: {r["full_name"]}");
                        Console.WriteLine("==========================================");
                        Console.WriteLine($"Email:       {r["email"]}");
                        Console.WriteLine($"Experience:  {r["years_experience"]} Years");
                        Console.WriteLine($"Location:    {r["timezone"]}");
                        Console.WriteLine($"Vet Status:  {r["vet_status"]}");
                        Console.WriteLine($"Bio/Link:    {r["portfolio_link"]}");
                        Console.WriteLine($"Skills:      {r["skills"]}"); // Shows skill names
                        Console.WriteLine("==========================================");
                    }
                    else Console.WriteLine("Engineer not found.");
                }
            }
        }
    }

    // --- DATA HELPERS ---
    public static List<UserSummaryDto> GetAllUsers()
    {
        var list = new List<UserSummaryDto>();
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            var cmd = new SqlCommand("SELECT user_id, full_name, role FROM tbl_User ORDER BY user_id DESC", conn);
            using(var r = cmd.ExecuteReader())
            {
                while(r.Read()) 
                    list.Add(new UserSummaryDto { Id=(int)r[0], Name=r[1].ToString(), Role=r[2].ToString() });
            }
        }
        return list;
    }

    public static List<ContractDto> GetClientContracts(int clientId)
    {
        var list = new List<ContractDto>();
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            string sql = @"
                SELECT j.job_id, j.job_title, j.status, u.full_name, u.user_id,
                       CASE WHEN r.rating IS NOT NULL THEN 1 ELSE 0 END as is_rated
                FROM tbl_Job j
                JOIN tbl_Job_Application ja ON j.job_id = ja.job_id
                JOIN tbl_User u ON ja.engineer_id = u.user_id
                LEFT JOIN tbl_Endorsement_Ratings r ON r.client_id = j.client_id AND r.engineer_id = ja.engineer_id
                WHERE j.client_id = @cid AND ja.status = 'accepted' AND j.status IN ('in_progress', 'closed')";

            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@cid", clientId);
                using(var r = cmd.ExecuteReader())
                {
                    while(r.Read())
                    {
                        list.Add(new ContractDto {
                            JobId = (int)r["job_id"],
                            JobTitle = r["job_title"].ToString(),
                            JobStatus = r["status"].ToString(),
                            EngineerName = r["full_name"].ToString(),
                            EngineerId = (int)r["user_id"],
                            IsRated = (int)r["is_rated"] == 1
                        });
                    }
                }
            }
        }
        return list;
    }

    public static List<ContractDto> GetEngineerActiveJobs(int engineerId)
    {
        var list = new List<ContractDto>();
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            string sql = @"
                SELECT j.job_id, j.job_title, c.company_name
                FROM tbl_Job j
                JOIN tbl_Job_Application ja ON j.job_id = ja.job_id
                JOIN tbl_Client_Profile c ON j.client_id = c.client_id
                WHERE ja.engineer_id = @eid AND ja.status = 'accepted' AND j.status = 'in_progress'";

            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@eid", engineerId);
                using(var r = cmd.ExecuteReader())
                {
                    while(r.Read())
                    {
                        list.Add(new ContractDto {
                            JobId = (int)r["job_id"],
                            JobTitle = r["job_title"].ToString(),
                            ClientName = r["company_name"].ToString()
                        });
                    }
                }
            }
        }
        return list;
    }

    public static void MarkJobAsFinished(int jobId)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            try {
                using (var cmd = new SqlCommand("sp_UpdateJobStatus", conn)) {
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@JobId", jobId);
                    cmd.Parameters.AddWithValue("@NewStatus", "closed");
                    cmd.ExecuteNonQuery();
                }
            } catch {
                new SqlCommand($"UPDATE tbl_Job SET status='closed' WHERE job_id={jobId}", conn).ExecuteNonQuery();
            }
        }
    }

    public static void SubmitRating(int clientId, int engineerId, int rating)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            string sql = @"
                IF EXISTS (SELECT 1 FROM tbl_Endorsement_Ratings WHERE client_id=@c AND engineer_id=@e)
                   UPDATE tbl_Endorsement_Ratings SET rating=@r, date=GETDATE() WHERE client_id=@c AND engineer_id=@e
                ELSE
                   INSERT INTO tbl_Endorsement_Ratings (client_id, engineer_id, rating, comment, verified, date) 
                   VALUES (@c, @e, @r, 'Console Rating', 1, GETDATE())";
            
            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@c", clientId);
                cmd.Parameters.AddWithValue("@e", engineerId);
                cmd.Parameters.AddWithValue("@r", rating);
                cmd.ExecuteNonQuery();
            }
        }
    }

    public static Dictionary<int, string> GetAllSkills()
    {
        var dict = new Dictionary<int, string>();
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            using (var cmd = new SqlCommand("SELECT skill_id, skill_name FROM tbl_Skill ORDER BY skill_name", conn))
            using (var r = cmd.ExecuteReader())
            {
                while(r.Read()) dict.Add((int)r["skill_id"], r["skill_name"].ToString());
            }
        }
        return dict;
    }

    public static void ManuallySaveJobSkills(int jobId, List<int> skillIds)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            foreach (var sid in skillIds)
            {
                string q = "IF NOT EXISTS (SELECT 1 FROM tbl_Job_Skills WHERE job_id=@j AND skill_id=@s) " +
                           "INSERT INTO tbl_Job_Skills (job_id, skill_id, importance_level) VALUES (@j, @s, 'required')";
                using (var cmd = new SqlCommand(q, conn)) {
                    cmd.Parameters.AddWithValue("@j", jobId);
                    cmd.Parameters.AddWithValue("@s", sid);
                    cmd.ExecuteNonQuery();
                }
            }
        }
    }

    public static void UpdateEngineerSkills(int engineerId, List<int> skillIds)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            new SqlCommand($"DELETE FROM tbl_Engineer_Skills WHERE engineer_id={engineerId}", conn).ExecuteNonQuery();
            foreach (var sid in skillIds)
            {
                string q = "INSERT INTO tbl_Engineer_Skills (engineer_id, skill_id, proficiency_score) VALUES (@e, @s, 10)";
                using (var cmd = new SqlCommand(q, conn)) {
                    cmd.Parameters.AddWithValue("@e", engineerId);
                    cmd.Parameters.AddWithValue("@s", sid);
                    cmd.ExecuteNonQuery();
                }
            }
        }
    }

    public static void UpdateApplicationStatus(int jobId, int engId, string status)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            using (var cmd = new SqlCommand("sp_UpdateApplicationStatus", conn))
            {
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@EngineerId", engId);
                cmd.Parameters.AddWithValue("@JobId", jobId);
                cmd.Parameters.AddWithValue("@NewStatus", status);
                cmd.Parameters.AddWithValue("@UpdatedBy", 1);
                cmd.ExecuteNonQuery();
            }
        }
    }

    public static decimal GetMatchScore(int jobId, int engId)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            string q = "SELECT match_score FROM tbl_Job_Application WHERE job_id=@j AND engineer_id=@e";
            using (var cmd = new SqlCommand(q, conn))
            {
                cmd.Parameters.AddWithValue("@j", jobId);
                cmd.Parameters.AddWithValue("@e", engId);
                var res = cmd.ExecuteScalar();
                return res != null && res != DBNull.Value ? Convert.ToDecimal(res) : 0;
            }
        }
    }
}

public static class AuthHelperExtensions 
{
    // Updated to support Industry (Optional)
    public static void UpdateClientProfile(int userId, string compName, string industry = null)
    {
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            // Updates Name and Industry if profile exists, otherwise inserts new
            string q = @"
                IF EXISTS (SELECT 1 FROM tbl_Client_Profile WHERE client_id=@u)
                   UPDATE tbl_Client_Profile SET company_name=@c, industry=@i WHERE client_id=@u
                ELSE
                   INSERT INTO tbl_Client_Profile (client_id, company_name, industry) VALUES (@u, @c, @i)";
            
            using (var cmd = new SqlCommand(q, conn)) {
                cmd.Parameters.AddWithValue("@c", compName);
                cmd.Parameters.AddWithValue("@i", (object)industry ?? DBNull.Value); // Handle nulls
                cmd.Parameters.AddWithValue("@u", userId);
                cmd.ExecuteNonQuery();
            }
        }
    }

    public static bool LoginWithProfile(string email, string password, out int id, out string role, out string name)
    {
        id = 0; role = ""; name = "";
        using (var conn = new SqlConnection(ConsoleFactory.ConnString))
        {
            conn.Open();
            string query = "SELECT user_id, role, full_name FROM tbl_User WHERE email = @e AND password = @p";
            using (var cmd = new SqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("@e", email);
                cmd.Parameters.AddWithValue("@p", password);
                using (var reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        id = (int)reader["user_id"];
                        role = reader["role"].ToString();
                        name = reader["full_name"].ToString();
                        return true;
                    }
                }
            }
        }
        return false;
    }
}