using System;
using System.Configuration;
using Bridgeway.BLL.EF;
using Bridgeway.BLL.SP;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.Web.Services
{
    public static class ServiceFactory
    {
        // Default mode = EF; Admin UI can toggle this at runtime
        public static BllMode CurrentMode { get; set; } = BllMode.Ef;

        static ServiceFactory()
        {
            // Set SP layer connection string once
            var connStrSettings = ConfigurationManager.ConnectionStrings["BridgewayDb"];
            if (connStrSettings == null || string.IsNullOrWhiteSpace(connStrSettings.ConnectionString))
            {
                throw new InvalidOperationException(
                    "Connection string 'BridgewayDb' is missing from Web.config.");
            }

            var connStr = connStrSettings.ConnectionString;

            // This assumes Haider's SP layer exposes a SqlHelper with static ConnectionString
            SqlHelper.ConnectionString = connStr;
        }

        public static IEngineerService CreateEngineerService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new EngineerServiceEf();
            }

            return new EngineerServiceSp();
        }

        public static IClientService CreateClientService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new ClientServiceEf();
            }

            return new ClientServiceSp();
        }

        public static IJobService CreateJobService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new JobServiceEf();
            }

            return new JobServiceSp();
        }

        public static IApplicationService CreateApplicationService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new ApplicationServiceEf();
            }

            return new ApplicationServiceSp();
        }

        public static IVettingService CreateVettingService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new VettingServiceEf();
            }

            return new VettingServiceSp();
        }

        public static IAnalyticsService CreateAnalyticsService()
        {
            if (CurrentMode == BllMode.Ef)
            {
                return new AnalyticsServiceEf();
            }

            return new AnalyticsServiceSp();
        }
    }
}
