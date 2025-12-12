function saveChanges() {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = 'saved-notification';
  notification.textContent = 'Changes Saved!';
  document.body.appendChild(notification);
  
  // Show notification
  notification.style.display = 'block';
  
  // Hide notification after 2 seconds and redirect
  setTimeout(() => {
    notification.style.display = 'none';
    window.location.href = 'user-info.html';
  }, 2000);
}
