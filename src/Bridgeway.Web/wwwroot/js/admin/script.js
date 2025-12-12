// Dashboard interactivity

// Mode selection buttons
document.addEventListener('DOMContentLoaded', function() {
  const efButton = document.getElementById('efButton');
  const spButton = document.getElementById('spButton');
  
  if (efButton) {
    efButton.addEventListener('click', function() {
      this.style.backgroundColor = '#4a90e2';
      if (spButton) spButton.style.backgroundColor = '#ededed';
      showNotification('Engineer Finder mode activated');
    });
  }
  
  if (spButton) {
    spButton.addEventListener('click', function() {
      this.style.backgroundColor = '#4a90e2';
      if (efButton) efButton.style.backgroundColor = '#ededed';
      showNotification('Service Provider mode activated');
    });
  }

  // Add hover effects to stat cards
  const statCards = document.querySelectorAll('.group-2, .group-3, .group-4, .group-5');
  statCards.forEach(card => {
    card.style.cursor = 'pointer';
    card.style.transition = 'transform 0.3s ease, box-shadow 0.3s ease';
    
    card.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-5px)';
      this.querySelector('.rectangle-18, .rectangle-19').style.boxShadow = '0 10px 30px rgba(120, 123, 158, 0.4)';
    });
    
    card.addEventListener('mouseleave', function() {
      this.style.transform = 'translateY(0)';
      this.querySelector('.rectangle-18, .rectangle-19').style.boxShadow = 'none';
    });
  });

  // Add click handlers for action links
  const actionLinks = document.querySelectorAll('.action-link');
  actionLinks.forEach(link => {
    link.style.cursor = 'pointer';
    link.addEventListener('mouseenter', function() {
      this.style.opacity = '0.8';
    });
    link.addEventListener('mouseleave', function() {
      this.style.opacity = '1';
    });
  });
});

function showNotification(message) {
  const notification = document.createElement('div');
  notification.textContent = message;
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: #4a90e2;
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
