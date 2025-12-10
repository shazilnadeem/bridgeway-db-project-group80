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
    }
}
