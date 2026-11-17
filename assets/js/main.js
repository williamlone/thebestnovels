(function () {
  'use strict';
  var root = document.documentElement;

  var toggle = document.getElementById('theme-toggle');
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = root.dataset.theme === 'dark' ? 'light' : 'dark';
      root.dataset.theme = next;
      localStorage.setItem('tnb-theme', next);
    });
  }

  var bar = document.getElementById('reading-progress');
  var ticking = false;
  function updateProgress() {
    var height = document.documentElement.scrollHeight - window.innerHeight;
    var percent = height > 0 ? (window.scrollY / height) * 100 : 0;
    if (bar) bar.style.width = Math.max(0, Math.min(100, percent)) + '%';
    ticking = false;
  }
  window.addEventListener('scroll', function () {
    if (!ticking) {
      window.requestAnimationFrame(updateProgress);
      ticking = true;
    }
  }, { passive: true });
  updateProgress();

  var input = document.getElementById('book-search');
  var cards = Array.prototype.slice.call(document.querySelectorAll('.book-card'));
  var status = document.getElementById('search-status');
  var noResults = document.getElementById('no-results');
  if (input) {
    input.addEventListener('input', function () {
      var query = input.value.trim().toLowerCase();
      var shown = 0;
      cards.forEach(function (card) {
        var text = card.dataset.title || card.textContent;
        var match = !query || text.toLowerCase().indexOf(query) !== -1;
        card.hidden = !match;
        if (match) shown += 1;
      });
      if (status) status.textContent = 'Showing ' + shown + ' novel' + (shown === 1 ? '' : 's');
      if (noResults) noResults.hidden = shown !== 0;
    });
  }

  var fontSize = parseFloat(localStorage.getItem('tnb-font-size')) || 19;
  function setFontSize(size) {
    fontSize = Math.max(16, Math.min(24, size));
    root.style.setProperty('--reader-font', fontSize + 'px');
    localStorage.setItem('tnb-font-size', String(fontSize));
  }
  var decrease = document.getElementById('font-decrease');
  var increase = document.getElementById('font-increase');
  if (decrease) decrease.addEventListener('click', function () { setFontSize(fontSize - 1); });
  if (increase) increase.addEventListener('click', function () { setFontSize(fontSize + 1); });

  document.addEventListener('keydown', function (event) {
    if (event.altKey || event.ctrlKey || event.metaKey) return;
    var tag = (event.target.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea' || event.target.isContentEditable) return;
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    var selector = event.key === 'ArrowLeft' ? 'a[data-key="prev"]' : 'a[data-key="next"]';
    var link = document.querySelector(selector);
    if (link) {
      event.preventDefault();
      window.location.href = link.href;
    }
  });
})();
