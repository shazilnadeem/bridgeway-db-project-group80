using System.ComponentModel.DataAnnotations;

namespace Bridgeway.Web.Models
{
    public class RegisterClientViewModel
    {
        [Required]
        [Display(Name = "Company Name")]
        [StringLength(200)]
        public string CompanyName { get; set; }

        [Required]
        [Display(Name = "Contact Name")]
        [StringLength(150)]
        public string ContactName { get; set; }

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
    }
}
