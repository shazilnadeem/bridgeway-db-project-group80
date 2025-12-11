using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IClientService
    {
        // Changed signature to match ClientServiceSp.RegisterClient(int)
        void RegisterClient(int userId);

        // Renamed from GetClientById to match ClientServiceSp.GetById
        ClientDto GetById(int clientId);

        // Renamed from GetClientByUserId to match ClientServiceSp.GetByUserId
        ClientDto GetByUserId(int userId);

        IList<JobDto> GetClientJobs(int clientId);
    }
}