// One-time reading entrances. No content is hidden in the stylesheet.
(() => {
  if (!Element.prototype.animate || !('IntersectionObserver' in window)) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  if (reduced.matches) return;
  const active = new Set();
  const nodes = [...document.querySelectorAll('.article-body > section, .policy-heading, .policy-summary, .policy-article > section, .docs-layout main > h1')];
  let remaining = nodes.length;
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      observer.unobserve(entry.target);
      if (--remaining === 0) observer.disconnect();
      if (reduced.matches || entry.target.contains(document.activeElement)) continue;
      const animation = entry.target.animate([{
        opacity: .6,
        translate: '0 12px'
      }, {
        opacity: 1,
        translate: '0 0'
      }], {
        duration: 480,
        easing: 'cubic-bezier(.2,1,.3,1)'
      });
      active.add(animation);
      animation.finished.catch(() => {}).finally(() => active.delete(animation));
    }
  }, {
    rootMargin: '0px 0px 25px 0px',
    threshold: 0
  });
  nodes.forEach(node => observer.observe(node));
  reduced.addEventListener('change', () => {
    if (!reduced.matches) return;
    observer.disconnect();
    active.forEach(animation => animation.cancel());
  });
  document.addEventListener('focusin', event => active.forEach(animation => {
    if (animation.effect?.target?.contains(event.target)) animation.cancel();
  }));
})();
