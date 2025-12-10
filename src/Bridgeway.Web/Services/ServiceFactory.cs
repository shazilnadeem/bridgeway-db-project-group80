// Services/ServiceFactory.cs
using System.Configuration;
using Bridgeway.BLL.EF;
using Bridgeway.BLL.SP;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.Web.Services
{
    public static class ServiceFactory
    {
        public static BllMode CurrentMode { get; set; } = BllMode.Ef;

        static ServiceFactory()
        {
            // read SQL connection string from Web.config
            var conn = ConfigurationManager.ConnectionStrings["BridgewayDb"].ConnectionString;
            SqlHelper.ConnectionString = conn;
        }

        public static IEngineerService CreateEngineerService()
        {
            if (CurrentMode == BllMode.Ef)
                return new EngineerServiceEf();
            else
                return new EngineerServiceSp();
        }

        public static IClientService CreateClientService()
        {
            if (CurrentMode == BllMode.Ef)
                return new ClientServiceEf();
            else
                return new ClientServiceSp();
        }

        // same idea for IJobService, IApplicationService, IVettingService, IAnalyticsService
    }
}
