// Engineer vetting page interactivity

document.addEventListener('DOMContentLoaded', function() {
  const approveButton = document.getElementById('approveButton');
  const rejectButton = document.getElementById('rejectButton');
  const statusSelect = document.getElementById('statusSelect');
  
  // Approve button functionality
  if (approveButton) {
    approveButton.style.cursor = 'pointer';
    approveButton.style.transition = 'all 0.3s ease';
    
    approveButton.addEventListener('mouseenter', function() {
      this.style.transform = 'scale(1.05)';
      this.style.backgroundColor = '#d4edda';
    });
    
    approveButton.addEventListener('mouseleave', function() {
      this.style.transform = 'scale(1)';
      this.style.backgroundColor = '#ededed';
    });
    
    approveButton.addEventListener('click', function() {
      this.style.backgroundColor = '#28a745';
      this.querySelector('.text-4').style.color = '#ffffff';
      
      if (statusSelect) {
        statusSelect.value = 'approved';
        statusSelect.style.backgroundColor = '#28a745';
        statusSelect.style.color = '#ffffff';
      }
      
      showNotification('Engineer approved successfully!', '#28a745');
      
      setTimeout(() => {
        this.style.backgroundColor = '#ededed';
        this.querySelector('.text-4').style.color = '#0b6d1a';
      }, 2000);
    });
  }
  
  // Reject button functionality
  if (rejectButton) {
    rejectButton.style.cursor = 'pointer';
    rejectButton.style.transition = 'all 0.3s ease';
    
    rejectButton.addEventListener('mouseenter', function() {
      this.style.transform = 'scale(1.05)';
      this.style.backgroundColor = '#f8d7da';
    });
    
    rejectButton.addEventListener('mouseleave', function() {
      this.style.transform = 'scale(1)';
      this.style.backgroundColor = '#ededed';
    });
    
    rejectButton.addEventListener('click', function() {
      this.style.backgroundColor = '#dc3545';
      this.querySelector('.text-5').style.color = '#ffffff';
      
      if (statusSelect) {
        statusSelect.value = 'rejected';
        statusSelect.style.backgroundColor = '#dc3545';
        statusSelect.style.color = '#ffffff';
      }
      
      showNotification('Engineer rejected', '#dc3545');
      
      setTimeout(() => {
        this.style.backgroundColor = '#ededed';
        this.querySelector('.text-5').style.color = '#600b0b';
      }, 2000);
    });
  }
  
  // Status select functionality
  if (statusSelect) {
    statusSelect.style.cursor = 'pointer';
    statusSelect.style.fontSize = '25px';
    statusSelect.style.fontFamily = '"DM Sans", Helvetica';
    statusSelect.style.fontWeight = '700';
    statusSelect.style.color = '#ffffff';
    statusSelect.style.border = 'none';
    statusSelect.style.outline = 'none';
    
    statusSelect.addEventListener('change', function() {
      const value = this.value;
      switch(value) {
        case 'approved':
          this.style.backgroundColor = '#28a745';
          showNotification('Status changed to Approved', '#28a745');
          break;
        case 'rejected':
          this.style.backgroundColor = '#dc3545';
          showNotification('Status changed to Rejected', '#dc3545');
          break;
        case 'pending':
          this.style.backgroundColor = '#2c2e4a';
          showNotification('Status changed to Pending', '#ffc107');
          break;
      }
    });
  }
  
  // Make skill proficiency fields editable
  const skillFields = document.querySelectorAll('.text-wrapper-54, .text-wrapper-55, .text-wrapper-56');
  skillFields.forEach(field => {
    field.contentEditable = true;
    field.style.cursor = 'text';
    field.style.padding = '5px';
    
    field.addEventListener('focus', function() {
      this.style.outline = '2px solid #4a90e2';
      this.style.backgroundColor = 'rgba(74, 144, 226, 0.1)';
    });
    
    field.addEventListener('blur', function() {
      this.style.outline = 'none';
      this.style.backgroundColor = 'transparent';
    });
    
    field.addEventListener('input', function() {
      const value = parseInt(this.textContent);
      if (value >= 1 && value <= 10) {
        this.style.color = '#ffffff';
      } else {
        this.style.color = '#ff6b6b';
      }
    });
  });
  
  // Make personal info fields editable
  const infoFields = document.querySelectorAll('.rectangle-34, .rectangle-35, .rectangle-36, .rectangle-37, .rectangle-38, .rectangle-39');
  infoFields.forEach(field => {
    field.contentEditable = true;
    field.style.cursor = 'text';
    field.style.padding = '15px';
    field.style.display = 'flex';
    field.style.alignItems = 'center';
    field.style.fontSize = '25px';
    field.style.fontFamily = '"DM Sans", Helvetica';
    field.style.fontWeight = '700';
    field.style.color = '#120f0f9e';
    
    field.addEventListener('focus', function() {
      this.style.outline = '2px solid #0088ff';
      this.style.backgroundColor = '#ffffff';
    });
    
    field.addEventListener('blur', function() {
      this.style.outline = 'none';
      this.style.backgroundColor = '#d4d4d4';
    });
  });
});

function showNotification(message, color = '#4a90e2') {
  const notification = document.createElement('div');
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: ${color};
    color: white;
    padding: 15px 25px;
    border-radius: 10px;
    font-family: 'DM Sans', Helvetica;
    font-weight: 700;
    font-size: 18px;
    z-index: 10000;
    animation: slideIn 0.3s ease;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  `;
  
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.style.animation = 'slideOut 0.3s ease';
    setTimeout(() => notification.remove(), 300);
  }, 3000);
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn {
    from {
      transform: translateX(400px);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
  
  @keyframes slideOut {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(400px);
      opacity: 0;
    }
  }
  
  .rectangle-40 option {
    background-color: #2c2e4a;
    color: #ffffff;
    padding: 10px;
  }
`;
document.head.appendChild(style);
