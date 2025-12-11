using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IJobService
    {
        // Changed return type from int to JobDto to match JobServiceSp
        JobDto CreateJob(JobCreateDto dto);

        // Renamed from GetJobById to match JobServiceSp.GetJob
        JobDto GetJob(int jobId);

        IList<JobDto> GetJobsForClient(int clientId);

        // Changed return type to match JobServiceSp implementation
        IList<JobOpenSummaryDto> GetOpenJobs();

        // Removed UpdateJobStatus (missing in SP)
        
        // Added methods present in JobServiceSp
        void RunMatching(int jobId, int? topN);
        IList<EngineerDto> GetRankedCandidates(int jobId);
    }
}