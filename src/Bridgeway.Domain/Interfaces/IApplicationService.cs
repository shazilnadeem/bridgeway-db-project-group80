using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IApplicationService
    {
        void ApplyToJob(int engineerId, int jobId);

        void UpdateApplicationStatus(int engineerId, int jobId, string newStatus, int updatedByUserId);

        IList<ApplicationDto> GetApplicationsForEngineer(int engineerId);
        IList<ApplicationDto> GetApplicationsForJob(int jobId);
    }
}
