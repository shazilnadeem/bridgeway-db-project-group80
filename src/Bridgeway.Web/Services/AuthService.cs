using Microsoft.AspNetCore.Http;
using System;

namespace Bridgeway.Web.Services
{
    public static class AuthService
    {
        private const string SessionUserIdKey = "CurrentUserId";
        private const string SessionUserRoleKey = "CurrentUserRole";
        private const string SessionUserNameKey = "CurrentUserName";

        public static void SignIn(HttpContext httpContext, int userId, string role, string fullName)
        {
            if (httpContext == null || httpContext.Session == null) return;

            httpContext.Session.SetInt32(SessionUserIdKey, userId);
            httpContext.Session.SetString(SessionUserRoleKey, role);
            httpContext.Session.SetString(SessionUserNameKey, fullName);
        }

        public static void SignOut(HttpContext httpContext)
        {
            if (httpContext == null || httpContext.Session == null) return;
            httpContext.Session.Clear();
        }

        public static int GetCurrentUserId(HttpContext httpContext)
        {
            if (httpContext == null || httpContext.Session == null) return 0;
            return httpContext.Session.GetInt32(SessionUserIdKey) ?? 0;
        }

        public static string GetCurrentUserRole(HttpContext httpContext)
        {
            if (httpContext == null || httpContext.Session == null) return null;
            return httpContext.Session.GetString(SessionUserRoleKey);
        }

        public static string GetCurrentUserName(HttpContext httpContext)
        {
            if (httpContext == null || httpContext.Session == null) return null;
            return httpContext.Session.GetString(SessionUserNameKey);
        }

        public static bool IsLoggedIn(HttpContext httpContext)
        {
            return GetCurrentUserId(httpContext) > 0;
        }

        public static bool IsInRole(HttpContext httpContext, string role)
        {
            var currentRole = GetCurrentUserRole(httpContext);
            return !string.IsNullOrEmpty(currentRole) &&
                   currentRole.Equals(role, StringComparison.OrdinalIgnoreCase);
        }
    }
}