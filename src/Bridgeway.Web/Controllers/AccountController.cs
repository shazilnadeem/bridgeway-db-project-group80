using System;
using System.Configuration;
using System.Data.SqlClient;
using Microsoft.AspNetCore.Mvc;
using Bridgeway.Domain.Interfaces;
using Bridgeway.Web.Models;
using Bridgeway.Web.Services;

namespace Bridgeway.Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly string _connStr;

        // Inject IConfiguration to get the connection string safely
        public AccountController(IConfiguration config)
        {
            _connStr = config.GetConnectionString("BridgewayDb");
            
            if (string.IsNullOrEmpty(_connStr))
            {
                throw new InvalidOperationException("Connection string 'BridgewayDb' is not found.");
            }
        }

        // -------------------
        // LOGIN
        // -------------------

        [HttpGet]
        public ActionResult Login()
        {
            return View(new LoginViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Login(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            using (var conn = new SqlConnection(_connStr))
            using (var cmd = new SqlCommand(@"
                SELECT user_id, full_name, role, password
                FROM dbo.tbl_User
                WHERE email = @Email;", conn))
            {
                cmd.Parameters.AddWithValue("@Email", model.Email);

                conn.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    if (!reader.Read())
                    {
                        ModelState.AddModelError(string.Empty, "Invalid email or password.");
                        return View(model);
                    }

                    int userId = (int)reader["user_id"];
                    string fullName = (string)reader["full_name"];
                    string role = (string)reader["role"];
                    string storedPassword = (string)reader["password"];

                    // For this project, plaintext is acceptable (though not secure).
                    if (!string.Equals(storedPassword, model.Password, StringComparison.Ordinal))
                    {
                        ModelState.AddModelError(string.Empty, "Invalid email or password.");
                        return View(model);
                    }

                    AuthService.SignIn(HttpContext, userId, role, fullName);

                    // redirect by role
                    if (role.Equals("admin", StringComparison.OrdinalIgnoreCase))
                    {
                        return RedirectToAction("Dashboard", "Admin");
                    }

                    if (role.Equals("engineer", StringComparison.OrdinalIgnoreCase))
                    {
                        return RedirectToAction("Dashboard", "Engineer");
                    }

                    if (role.Equals("client", StringComparison.OrdinalIgnoreCase))
                    {
                        return RedirectToAction("Dashboard", "Client");
                    }

                    // Fallback
                    return RedirectToAction("Login");
                }
            }
        }

        // -------------------
        // REGISTER ENGINEER
        // -------------------

        [HttpGet]
        public ActionResult RegisterEngineer()
        {
            return View(new RegisterEngineerViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult RegisterEngineer(RegisterEngineerViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            if (!string.Equals(model.Password, model.ConfirmPassword, StringComparison.Ordinal))
            {
                ModelState.AddModelError(string.Empty, "Passwords do not match.");
                return View(model);
            }

            int newUserId;

            // 1) Insert into tbl_User
            using (var conn = new SqlConnection(_connStr))
            using (var cmd = new SqlCommand(@"
                INSERT INTO dbo.tbl_User (full_name, email, password, role)
                VALUES (@FullName, @Email, @Password, 'engineer');
                SELECT SCOPE_IDENTITY();", conn))
            {
                cmd.Parameters.AddWithValue("@FullName", model.FullName);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@Password", model.Password);

                conn.Open();
                object scalar = cmd.ExecuteScalar();
                newUserId = Convert.ToInt32(scalar);
            }

            // 2) Create engineer profile via BLL
            IEngineerService engineerService = ServiceFactory.CreateEngineerService();
            engineerService.RegisterEngineer(newUserId);

            // 3) Optionally update additional fields
            if (model.YearsExperience > 0 || !string.IsNullOrWhiteSpace(model.Timezone))
            {
                var engineer = engineerService.GetCurrentEngineerProfile(newUserId);
                if (engineer != null)
                {
                    engineer.YearsExperience = model.YearsExperience;
                    engineer.Timezone = model.Timezone;
                    engineerService.UpdateEngineerProfile(engineer);
                }
            }

            TempData["Message"] = "Engineer registered successfully. Please login.";
            return RedirectToAction("Login");
        }

        // -------------------
        // REGISTER CLIENT
        // -------------------

        [HttpGet]
        public ActionResult RegisterClient()
        {
            return View(new RegisterClientViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult RegisterClient(RegisterClientViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            if (!string.Equals(model.Password, model.ConfirmPassword, StringComparison.Ordinal))
            {
                ModelState.AddModelError(string.Empty, "Passwords do not match.");
                return View(model);
            }

            int newUserId;

            // 1) Insert into tbl_User as 'client'
            using (var conn = new SqlConnection(_connStr))
            using (var cmd = new SqlCommand(@"
                INSERT INTO dbo.tbl_User (full_name, email, password, role)
                VALUES (@FullName, @Email, @Password, 'client');
                SELECT SCOPE_IDENTITY();", conn))
            {
                cmd.Parameters.AddWithValue("@FullName", model.ContactName);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@Password", model.Password);

                conn.Open();
                object scalar = cmd.ExecuteScalar();
                newUserId = Convert.ToInt32(scalar);
            }

            // 2) Create client profile via BLL
            IClientService clientService = ServiceFactory.CreateClientService();
            
            // -------------------------------------------------------------
            // FIX IS HERE: We only pass 'newUserId' to match IClientService
            // -------------------------------------------------------------
            clientService.RegisterClient(newUserId);

            TempData["Message"] = "Client registered successfully. Please login.";
            return RedirectToAction("Login");
        }

        // -------------------
        // LOGOUT
        // -------------------

        public ActionResult Logout()
        {
            AuthService.SignOut(HttpContext);
            return RedirectToAction("Login");
        }
    }
}