function showSuccessModal() {
  const modal = document.getElementById('successModal');
  modal.style.display = 'flex';
}

function closeModal() {
  const modal = document.getElementById('successModal');
  modal.style.display = 'none';
  window.location.href = 'index.html';
}

// Close modal when clicking outside of it
window.onclick = function(event) {
  const modal = document.getElementById('successModal');
  if (event.target === modal) {
    closeModal();
  }
}
