using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IVettingService
    {
        // Changed return type to match VettingServiceSp
        IList<VettingQueueItemDto> GetVettingQueue();

        void CreateVettingReview(VettingReviewDto dto);
    }
}