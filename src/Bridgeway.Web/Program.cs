using Bridgeway.Web.Services;
using Bridgeway.BLL.EF; // Needed for BridgewayDbContext

var builder = WebApplication.CreateBuilder(args);

// 1. Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();

// 2. Read Connection String
var connectionString = builder.Configuration.GetConnectionString("BridgewayDb");

// --- FIX START: Pass connection string to EF6 Context ---
BridgewayDbContext.ConnectionString = connectionString;
// --- FIX END ---

// 3. Initialize ServiceFactory (SP Layer)
ServiceFactory.Initialize(connectionString);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();
app.UseSession();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();