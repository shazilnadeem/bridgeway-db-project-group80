// Interfaces/IVettingService.cs
using System.Collections.Generic;
using Bridgeway.Domain.DTOs;

namespace Bridgeway.Domain.Interfaces
{
    public interface IVettingService
    {
        IList<VettingReviewDto> GetVettingQueue();   // from view vw_VettingQueue
        void CreateVettingReview(VettingReviewDto review);
    }
}
