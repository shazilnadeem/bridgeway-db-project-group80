// User info page interactivity

document.addEventListener('DOMContentLoaded', function() {
  const saveButton = document.getElementById('saveButton');
  const nameInput = document.querySelector('.rectangle-24');
  const emailInput = document.querySelector('.rectangle-27');
  const companyInput = document.querySelector('.rectangle-25');
  
  // Make input fields editable
  [nameInput, emailInput, companyInput].forEach(input => {
    if (input) {
      input.contentEditable = true;
      input.style.cursor = 'text';
      input.style.padding = '10px';
      
      input.addEventListener('focus', function() {
        this.style.outline = '2px solid #0088ff';
      });
      
      input.addEventListener('blur', function() {
        this.style.outline = 'none';
      });
    }
  });
  
  // Save button functionality
  if (saveButton) {
    saveButton.style.cursor = 'pointer';
    saveButton.style.transition = 'all 0.3s ease';
    
    saveButton.addEventListener('mouseenter', function() {
      this.style.transform = 'scale(1.05)';
      this.style.backgroundColor = '#0077dd';
    });
    
    saveButton.addEventListener('mouseleave', function() {
      this.style.transform = 'scale(1)';
      this.style.backgroundColor = '#0088ff';
    });
    
    saveButton.addEventListener('click', function() {
      // Simulate saving
      this.style.backgroundColor = '#00aa00';
      showNotification('Information saved successfully!');
      
      setTimeout(() => {
        this.style.backgroundColor = '#0088ff';
      }, 1000);
    });
  }
});

function showNotification(message) {
  const notification = document.createElement('div');
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: #00aa00;
    color: white;
    padding: 15px 25px;
    border-radius: 10px;
    font-family: 'DM Sans', Helvetica;
    font-weight: 700;
    font-size: 18px;
    z-index: 10000;
    animation: slideIn 0.3s ease;
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
`;
document.head.appendChild(style);
