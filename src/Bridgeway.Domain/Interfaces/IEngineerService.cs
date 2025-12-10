// Interfaces/IEngineerService.cs
using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IEngineerService
    {
        EngineerDto GetById(int engineerId);
        IList<EngineerDto> SearchEngineers(EngineerSearchFilter filter);
        void RegisterEngineer(int userId); // user already exists in tbl_User
        EngineerDto GetCurrentEngineerProfile(int userId);
        void UpdateEngineerProfile(EngineerDto dto);
    }
}
