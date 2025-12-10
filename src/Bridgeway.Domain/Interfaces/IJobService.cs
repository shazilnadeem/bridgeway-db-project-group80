// Interfaces/IJobService.cs
using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IJobService
    {
        JobDto CreateJob(JobCreateDto dto);
        JobDto GetJob(int jobId);
        IList<JobDto> GetJobsForClient(int clientId);
        void RunMatching(int jobId, int? topN = null);
        IList<EngineerDto> GetRankedCandidates(int jobId);
    }
}
