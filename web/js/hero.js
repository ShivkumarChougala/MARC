/* A gentle entrance and scroll-linked straighten; never takes over scrolling. */
(() => {
  const hero = document.querySelector('.mr-hero');
  const phone = hero?.querySelector('.mr-phone');
  const motion = hero?.querySelector('.mr-phone-motion');
  if (!hero || !phone || !motion) return;

  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let frame = 0;
  let visible = true;
  let entrance;
  const textAnimations = [];

  function draw() {
    frame = 0;
    if (reduced.matches || !visible) return;
    const rect = hero.getBoundingClientRect();
    const progress = Math.max(0, Math.min(1, -rect.top / (rect.height * .7)));
    phone.style.setProperty('--mr-angle', `${7 * (1 - progress)}deg`);
  }

  function request() {
    if (!reduced.matches && visible && !frame) frame = requestAnimationFrame(draw);
  }

  function preferences() {
    if (reduced.matches) {
      if (frame) cancelAnimationFrame(frame);
      frame = 0;
      entrance?.cancel();
      textAnimations.forEach(animation => animation.cancel());
      phone.style.removeProperty('--mr-angle');
    } else request();
  }

  if ('IntersectionObserver' in window) {
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      if (visible) request();
    }).observe(hero);
  }

  addEventListener('scroll', request, {passive: true});
  addEventListener('resize', request, {passive: true});
  addEventListener('pageshow', request);
  reduced.addEventListener('change', preferences);
  request();

  if (!reduced.matches && motion.animate) {
    hero.querySelectorAll('.mr-intro h1 > span, .mr-description').forEach((node, index) => {
      textAnimations.push(node.animate([
        {opacity: .15, translate: '0 12px'},
        {opacity: 1, translate: '0 0'}
      ], {
        duration: 750,
        delay: index * 90,
        easing: 'cubic-bezier(.16,1,.3,1)',
        fill: 'backwards'
      }));
    });
    entrance = motion.animate([
      {translate: '0 32px'},
      {translate: '0 0'}
    ], {duration: 1000, easing: 'cubic-bezier(.16,1,.3,1)'});
  }
})();
