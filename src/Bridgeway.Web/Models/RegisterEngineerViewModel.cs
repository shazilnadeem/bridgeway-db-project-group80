using System.ComponentModel.DataAnnotations;

namespace Bridgeway.Web.Models
{
    public class RegisterEngineerViewModel
    {
        [Required]
        [Display(Name = "Full Name")]
        [StringLength(150)]
        public string FullName { get; set; }

        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [StringLength(255, MinimumLength = 6)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [Compare("Password", ErrorMessage = "Passwords do not match.")]
        [Display(Name = "Confirm Password")]
        public string ConfirmPassword { get; set; }

        [Range(0, 50)]
        [Display(Name = "Years of Experience")]
        public int YearsExperience { get; set; }

        [Display(Name = "Timezone")]
        [StringLength(64)]
        public string Timezone { get; set; }
    }
}
