// EngineerServiceEf.cs
using System;
using System.Collections.Generic;
using Bridgeway.Domain.DTOs;
using Bridgeway.Domain.Interfaces;

namespace Bridgeway.BLL.EF
{
    public class EngineerServiceEf : IEngineerService
    {
        public EngineerDto GetById(int engineerId)
        {
            throw new NotImplementedException();
        }

        public IList<EngineerDto> SearchEngineers(EngineerSearchFilter filter)
        {
            throw new NotImplementedException();
        }

        public void RegisterEngineer(int userId)
        {
            throw new NotImplementedException();
        }

        public EngineerDto GetCurrentEngineerProfile(int userId)
        {
            throw new NotImplementedException();
        }

        public void UpdateEngineerProfile(EngineerDto dto)
        {
            throw new NotImplementedException();
        }
    }
}
