using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IEngineerService
    {
        void RegisterEngineer(int userId);

        // Renamed to match EngineerServiceSp.GetById
        EngineerDto GetById(int engineerId);

        EngineerDto GetCurrentEngineerProfile(int userId);

        void UpdateEngineerProfile(EngineerDto engineer);

        IList<EngineerDto> SearchEngineers(EngineerSearchFilter filter);
    }
}