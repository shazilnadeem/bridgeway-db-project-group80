using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.SP
{
    public class ClientServiceSp : IClientService
    {
        public ClientDto GetByUserId(int userId)
        {
            return GetById(userId);
        }

        public ClientDto GetById(int clientId)
        {
            string sql = @"
                SELECT cp.client_id, cp.company_name, cp.industry, u.email, u.full_name
                FROM tbl_Client_Profile cp
                JOIN tbl_User u ON cp.client_id = u.user_id
                WHERE cp.client_id = @ClientId";

            using (var reader = SqlHelper.ExecuteReaderText(sql, new SqlParameter("@ClientId", clientId)))
            {
                if (!reader.Read()) return null;
                return new ClientDto
                {
                    ClientId = Convert.ToInt32(reader["client_id"]),
                    CompanyName = reader["company_name"].ToString(),
                    Industry = reader["industry"]?.ToString(),
                    Email = reader["email"]?.ToString(),
                    ContactName = reader["full_name"]?.ToString()
                };
            }
        }

        public void RegisterClient(int userId)
        {
            string sql = @"
                INSERT INTO tbl_Client_Profile (client_id, company_name, industry, created_at)
                VALUES (@ClientId, 'Pending Setup', NULL, SYSDATETIME())";

            SqlHelper.ExecuteNonQueryText(sql, new SqlParameter("@ClientId", userId));
        }

        public IList<JobDto> GetClientJobs(int clientId)
        {
            return GetJobsForClient(clientId);
        }

        public IList<JobDto> GetJobsForClient(int clientId)
        {
            var list = new List<JobDto>();
            string sql = "SELECT * FROM vw_JobWithClientAndSkills WHERE client_id = @ClientId ORDER BY created_at DESC";

            using (var reader = SqlHelper.ExecuteReaderText(sql, new SqlParameter("@ClientId", clientId)))
            {
                while (reader.Read())
                {
                    list.Add(new JobDto
                    {
                        JobId = Convert.ToInt32(reader["job_id"]),
                        Title = reader["job_title"].ToString(),
                        Description = reader["job_description"]?.ToString(),
                        Status = reader["job_status"].ToString(),
                        ClientId = Convert.ToInt32(reader["client_id"]),
                        ClientName = reader["company_name"]?.ToString(),
                        CreatedAt = Convert.ToDateTime(reader["created_at"])
                    });
                }
            }
            return list;
        }
    }
}