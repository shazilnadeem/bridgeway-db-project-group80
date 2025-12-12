using System;
using Bridgeway.BLL.EF;
using Bridgeway.BLL.SP;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.Web.Services
{
    public static class ServiceFactory
    {
        public static BllMode CurrentMode { get; set; } = BllMode.Ef;

        // Call this from Program.cs to set up the DB connection
        public static void Initialize(string connectionString)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException("Connection string cannot be empty.");
            }
            
            // 1. Set the SP layer connection string
            SqlHelper.ConnectionString = connectionString;

            // 2. Set the EF layer connection string (NEW LINE)
            BridgewayDbContext.ConnectionString = connectionString;
        }

        public static IEngineerService CreateEngineerService()
        {
            return CurrentMode == BllMode.Ef ? new EngineerServiceEf() : new EngineerServiceSp();
        }

        public static IClientService CreateClientService()
        {
            return CurrentMode == BllMode.Ef ? new ClientServiceEf() : new ClientServiceSp();
        }

        public static IJobService CreateJobService()
        {
            return CurrentMode == BllMode.Ef ? new JobServiceEf() : new JobServiceSp();
        }

        public static IApplicationService CreateApplicationService()
        {
            return CurrentMode == BllMode.Ef ? new ApplicationServiceEf() : new ApplicationServiceSp();
        }

        public static IVettingService CreateVettingService()
        {
            return CurrentMode == BllMode.Ef ? new VettingServiceEf() : new VettingServiceSp();
        }

        public static IAnalyticsService CreateAnalyticsService()
        {
            return CurrentMode == BllMode.Ef ? new AnalyticsServiceEf() : new AnalyticsServiceSp();
        }
    }
}