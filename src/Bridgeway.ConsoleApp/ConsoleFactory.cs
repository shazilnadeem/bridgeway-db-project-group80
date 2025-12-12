using Bridgeway.BLL.EF;
using Bridgeway.BLL.SP;
using Bridgeway.Domain.Interfaces;
using System.Configuration;

namespace Bridgeway.ConsoleApp
{
    public static class ConsoleFactory
    {
        // 1. UPDATED CONNECTION STRING
        public static string ConnString = "Server=localhost,1433;Database=BridgewayDB;User Id=sa;Password=Shazee03!;TrustServerCertificate=True;";
        
        public static bool IsEfMode { get; set; } = false; // Default to SP

        static ConsoleFactory()
        {
            // 2. CRITICAL: Initialize BOTH layers so they can connect
            BridgewayDbContext.ConnectionString = ConnString;
            SqlHelper.ConnectionString = ConnString; 
        }

        // --- Service Factory Methods ---

        public static IJobService GetJobService()
        {
            if (IsEfMode) return new JobServiceEf();
            return new JobServiceSp();
        }

        public static IClientService GetClientService()
        {
            if (IsEfMode) return new ClientServiceEf();
            return new ClientServiceSp();
        }

        public static IEngineerService GetEngineerService()
        {
            if (IsEfMode) return new EngineerServiceEf();
            return new EngineerServiceSp();
        }

        public static IVettingService GetVettingService()
        {
            if (IsEfMode) return new VettingServiceEf();
            return new VettingServiceSp();
        }

        public static IApplicationService GetApplicationService()
        {
            if (IsEfMode) return new ApplicationServiceEf();
            return new ApplicationServiceSp();
        }

        public static IAnalyticsService GetAnalyticsService()
        {
            if (IsEfMode) return new AnalyticsServiceEf();
            return new AnalyticsServiceSp();
        }
    }
}