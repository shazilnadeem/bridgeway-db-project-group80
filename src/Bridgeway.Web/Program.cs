using Bridgeway.Web.Services;
using Bridgeway.BLL.EF; // Needed for EF Database initializer if you use it

var builder = WebApplication.CreateBuilder(args);

// 1. Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();

// 2. Read Connection String
var connectionString = builder.Configuration.GetConnectionString("BridgewayDb");

// 3. Initialize ServiceFactory (SP Layer)
ServiceFactory.Initialize(connectionString);

// 4. (Optional) Initialize EF Context connection if needed explicitly, 
//    but EF6 usually reads from config or needs the string passed to constructor.
//    For now, ServiceFactory handles the logic.

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