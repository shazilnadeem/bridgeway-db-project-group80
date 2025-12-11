using System.Web;

namespace Bridgeway.Web.Services
{
    public static class AuthService
    {
        private const string SessionUserIdKey   = "CurrentUserId";
        private const string SessionUserRoleKey = "CurrentUserRole";
        private const string SessionUserNameKey = "CurrentUserName";

        public static void SignIn(HttpContextBase httpContext, int userId, string role, string fullName)
        {
            if (httpContext == null || httpContext.Session == null)
            {
                return;
            }

            httpContext.Session[SessionUserIdKey]   = userId;
            httpContext.Session[SessionUserRoleKey] = role;
            httpContext.Session[SessionUserNameKey] = fullName;
        }

        public static void SignOut(HttpContextBase httpContext)
        {
            if (httpContext == null || httpContext.Session == null)
            {
                return;
            }

            httpContext.Session.Clear();
        }

        public static int GetCurrentUserId(HttpContextBase httpContext)
        {
            if (httpContext == null || httpContext.Session == null)
            {
                return 0;
            }

            var value = httpContext.Session[SessionUserIdKey];
            return value is int id ? id : 0;
        }

        public static string GetCurrentUserRole(HttpContextBase httpContext)
        {
            if (httpContext == null || httpContext.Session == null)
            {
                return null;
            }

            return httpContext.Session[SessionUserRoleKey] as string;
        }

        public static string GetCurrentUserName(HttpContextBase httpContext)
        {
            if (httpContext == null || httpContext.Session == null)
            {
                return null;
            }

            return httpContext.Session[SessionUserNameKey] as string;
        }

        public static bool IsLoggedIn(HttpContextBase httpContext)
        {
            return GetCurrentUserId(httpContext) > 0;
        }

        public static bool IsInRole(HttpContextBase httpContext, string role)
        {
            var currentRole = GetCurrentUserRole(httpContext);
            return !string.IsNullOrEmpty(currentRole) &&
                   currentRole.Equals(role, System.StringComparison.OrdinalIgnoreCase);
        }
    }
}
