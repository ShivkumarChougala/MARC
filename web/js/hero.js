/* Upright phone; gentle text entrance only. */
(() => {
  const hero = document.querySelector('.mr-hero');
  if (!hero) return;

  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const animations = [];

  if (!reduced.matches) {
    hero.querySelectorAll(
      '.mr-intro h1 > span, .mr-description'
    ).forEach((node, index) => {
      if (!node.animate) return;
      animations.push(node.animate([
        {opacity: .35, translate: '0 10px'},
        {opacity: 1, translate: '0 0'}
      ], {
        duration: 650,
        delay: index * 70,
        easing: 'cubic-bezier(.16,1,.3,1)',
        fill: 'backwards'
      }));
    });
  }

  reduced.addEventListener('change', () => {
    if (reduced.matches) {
      animations.forEach(animation => animation.cancel());
    }
  });
})();
