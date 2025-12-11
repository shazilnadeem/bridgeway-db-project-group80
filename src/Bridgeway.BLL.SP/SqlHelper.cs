using System;
using System.Data;
using System.Data.SqlClient;

namespace Bridgeway.BLL.SP
{
    public static class SqlHelper
    {
        public static string ConnectionString { get; set; }

        public static SqlConnection GetOpenConnection()
        {
            var conn = new SqlConnection(ConnectionString);
            conn.Open();
            return conn;
        }

        // ------------------------------------------------------------
        // 1. Execute Stored Procedure (No Return Value)
        // ------------------------------------------------------------
        public static int ExecuteNonQuery(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var conn = GetOpenConnection())
            using (var cmd = new SqlCommand(storedProcedure, conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                return cmd.ExecuteNonQuery();
            }
        }

        // ------------------------------------------------------------
        // 2. Execute Raw SQL Text (No Return Value) -- [NEW & CRITICAL]
        // ------------------------------------------------------------
        public static int ExecuteNonQueryText(string sql, params SqlParameter[] parameters)
        {
            using (var conn = GetOpenConnection())
            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.CommandType = CommandType.Text; // This allows "INSERT INTO..." to work
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                return cmd.ExecuteNonQuery();
            }
        }

        // ------------------------------------------------------------
        // 3. Execute Scalar (Stored Procedure)
        // ------------------------------------------------------------
        public static object ExecuteScalar(string storedProcedure, params SqlParameter[] parameters)
        {
            using (var conn = GetOpenConnection())
            using (var cmd = new SqlCommand(storedProcedure, conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                return cmd.ExecuteScalar();
            }
        }

        // ------------------------------------------------------------
        // 4. Execute Reader (Stored Procedure)
        // ------------------------------------------------------------
        public static SqlDataReader ExecuteReader(string storedProcedure, params SqlParameter[] parameters)
        {
            var conn = GetOpenConnection();
            var cmd = new SqlCommand(storedProcedure, conn)
            {
                CommandType = CommandType.StoredProcedure
            };
            if (parameters != null) cmd.Parameters.AddRange(parameters);
            return cmd.ExecuteReader(CommandBehavior.CloseConnection);
        }

        // ------------------------------------------------------------
        // 5. Execute Reader (Raw SQL Text)
        // ------------------------------------------------------------
        public static SqlDataReader ExecuteReaderText(string sql, params SqlParameter[] parameters)
        {
            var conn = GetOpenConnection();
            var cmd = new SqlCommand(sql, conn)
            {
                CommandType = CommandType.Text
            };
            if (parameters != null) cmd.Parameters.AddRange(parameters);
            return cmd.ExecuteReader(CommandBehavior.CloseConnection);
        }

        public static bool TestConnection()
        {
            try
            {
                using (var conn = GetOpenConnection()) return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Connection Failed: {ex.Message}");
                return false;
            }
        }
    }
}