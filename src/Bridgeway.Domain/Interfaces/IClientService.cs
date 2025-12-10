// Interfaces/IClientService.cs
using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IClientService
    {
        ClientDto GetById(int clientId);
        void RegisterClient(int userId);
        IList<JobDto> GetClientJobs(int clientId);
    }
}
