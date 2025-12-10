using System.Data.Entity;

namespace Bridgeway.BLL.EF
{
    public class BridgewayDbContext : DbContext
    {
        public BridgewayDbContext() : base("name=BridgewayDb")
        {
        }

        // TODO: DbSet<T> properties (Taimur's job)
    }
}
