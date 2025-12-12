using System;
using System.Data.SqlClient;

namespace Bridgeway.ConsoleApp
{
    public static class AuthHelper
    {
        // Returns UserID if successful, 0 if failed. Out parameter returns the Role.
        public static int Login(string email, string password, out string role)
        {
            role = "";
            using (var conn = new SqlConnection(ConsoleFactory.ConnString))
            {
                conn.Open();
                string query = "SELECT user_id, role FROM tbl_User WHERE email = @e AND password = @p";
                using (var cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@e", email);
                    cmd.Parameters.AddWithValue("@p", password);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            role = reader["role"].ToString();
                            return (int)reader["user_id"];
                        }
                    }
                }
            }
            return 0;
        }

        public static int RegisterUser(string name, string email, string password, string role)
        {
            using (var conn = new SqlConnection(ConsoleFactory.ConnString))
            {
                conn.Open();
                string query = "INSERT INTO tbl_User (full_name, email, password, role) OUTPUT INSERTED.user_id VALUES (@n, @e, @p, @r)";
                using (var cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@n", name);
                    cmd.Parameters.AddWithValue("@e", email);
                    cmd.Parameters.AddWithValue("@p", password);
                    cmd.Parameters.AddWithValue("@r", role);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }
    }
}