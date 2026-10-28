// One entrance per section element; native scroll stays in control.
(() => {
  if (!document.querySelector('.marc-product-home') ||
      !Element.prototype.animate || !('IntersectionObserver' in window)) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const active = new Set();
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      observer.unobserve(entry.target);
      if (reduced.matches) return;
      const node = entry.target;
      const animation = node.animate([
        {opacity: .15, transform: 'translateY(16px)'},
        {opacity: 1, transform: 'translateY(0)'}
      ], {duration: 560, easing: 'cubic-bezier(.2,.8,.2,1)', fill: 'backwards'});
      active.add(animation);
      animation.finished.catch(() => {}).finally(() => active.delete(animation));
    });
  }, {threshold: 0, rootMargin: '0px 0px -24px 0px'});
  document.querySelectorAll('#faq-title, .marc-faq-list, #download-title, .mt-mobile-copy')
    .forEach(node => observer.observe(node));
  function cancel() { active.forEach(animation => animation.cancel()); }
  reduced.addEventListener('change', () => { if (reduced.matches) cancel(); });
  document.addEventListener('focusin', event => {
    active.forEach(animation => {
      if (animation.effect?.target?.contains(event.target)) animation.cancel();
    });
  });
  addEventListener('pagehide', cancel);
})();

// MARC responsive navigation
(() => {
  const header = document.querySelector('.marc-header');
  const toggle = header?.querySelector('.marc-menu-toggle');
  const links = document.getElementById('marc-nav-links');
  if (!header || !toggle || !links) return;

  const mobile = window.matchMedia('(max-width: 640px)');
  const actions = header.querySelector('.marc-nav-actions');
  const download = header.querySelector('.marc-nav-download');

  const menuReduced = matchMedia('(prefers-reduced-motion: reduce)');
  let menuAnimation;

  function setOpen(open, animate = true) {
    open = mobile.matches && open;
    const expanded = toggle.getAttribute('aria-expanded') === 'true';
    if (mobile.matches && open === expanded &&
        (menuAnimation || links.hidden === !open)) return;

    const from = links.hidden ? 0 : links.getBoundingClientRect().height;
    const style = getComputedStyle(links);
    const opacity = links.hidden ? 0 : parseFloat(style.opacity);
    const paddingTop = links.hidden ? '0px' : style.paddingTop;
    const paddingBottom = links.hidden ? '0px' : style.paddingBottom;
    menuAnimation?.cancel();
    menuAnimation = null;
    links.style.overflow = '';
    links.inert = false;
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close navigation menu' : 'Open navigation menu');

    if (!mobile.matches || !animate || menuReduced.matches || !links.animate) {
      links.hidden = mobile.matches && !open;
      return;
    }
    links.hidden = false;
    const natural = getComputedStyle(links);
    const to = open ? links.scrollHeight : 0;
    const toTop = open ? natural.paddingTop : '0px';
    const toBottom = open ? natural.paddingBottom : '0px';
    links.inert = !open;
    links.style.overflow = 'hidden';
    const animation = links.animate([
      {height: from + 'px', opacity, paddingTop, paddingBottom},
      {height: to + 'px', opacity: open ? 1 : 0, paddingTop: toTop, paddingBottom: toBottom}
    ], {duration: open ? 260 : 190, easing: 'cubic-bezier(.2,.8,.2,1)'});
    menuAnimation = animation;
    animation.onfinish = () => {
      if (menuAnimation !== animation) return;
      menuAnimation = null;
      links.hidden = !open;
      links.inert = false;
      links.style.overflow = '';
    };
  }

  function syncLayout() {
    const focused = document.activeElement;
    const restoreMenuFocus = mobile.matches &&
      (links.contains(focused) || focused === download);
    const restoreDownloadFocus = !mobile.matches && focused === toggle;
    // Move the same link so keyboard order follows its visible position.
    if (download && actions) {
      if (mobile.matches) links.append(download);
      else actions.prepend(download);
    }
    toggle.hidden = !mobile.matches;
    setOpen(false, false);
    if (restoreMenuFocus) toggle.focus();
    else if (restoreDownloadFocus) download?.focus();
  }

  toggle.addEventListener('click', () => {
    setOpen(toggle.getAttribute('aria-expanded') !== 'true');
  });

  header.addEventListener('click', event => {
    if (event.target.closest('a') && mobile.matches) setOpen(false);
  });

  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' &&
      toggle.getAttribute('aria-expanded') === 'true') {
      setOpen(false);
      toggle.focus();
    }
  });

  document.addEventListener('click', event => {
    if (mobile.matches && !header.contains(event.target)) setOpen(false);
  });

  header.addEventListener('focusout', () => {
    requestAnimationFrame(() => {
      if (mobile.matches && !header.contains(document.activeElement)) {
        setOpen(false);
      }
    });
  });

  menuReduced.addEventListener('change', () => {
    if (menuReduced.matches) menuAnimation?.finish();
  });
  mobile.addEventListener('change', syncLayout);
  syncLayout();
})();

// MARC unified scroll navigation: one passive listener, one frame, changed-state writes.
(() => {
  const header = document.querySelector('.marc-header');
  if (!header) return;
  const pagePath = path => path.replace(/\/index(?:\.html)?$/, '/').replace(/\.html$/, '').replace(/\/$/, '') || '/';
  const currentPath = pagePath(location.pathname);
  const links = [...header.querySelectorAll('a[href]')].map(node => {
    const url = new URL(node.href, location.href);
    return {
      node,
      samePage: url.origin === location.origin && pagePath(url.pathname) === currentPath,
      hash: url.hash,
      page: url.pathname !== '/'
    };
  });
  const sections = ['preview', 'features', 'faq', 'download'].map(id => document.getElementById(id)).filter(Boolean);
  let pending = false;
  let previousActive;
  let previousScrolled;
  let inset = 100;

  function measure() {
    // The first row stays the same height when the mobile menu expands.
    const logo = header.querySelector('.logo-brand').getBoundingClientRect();
    const actions = header.querySelector('.marc-nav-actions').getBoundingClientRect();
    inset = Math.ceil(Math.max(logo.bottom, actions.bottom) + 24);
    document.documentElement.style.setProperty('--marc-anchor-inset', inset + 'px');
    schedule();
  }

  function update() {
    pending = false;
    const scrolled = scrollY > 8;
    const line = inset + 56;
    let active = null;
    for (const section of sections) {
      const box = section.getBoundingClientRect();
      if (box.top <= line && box.bottom > line) active = section.id;
    }
    // The final section may be too short to reach the activation line.
    const last = sections[sections.length - 1];
    if (last && scrollY + innerHeight >= document.documentElement.scrollHeight - 2 &&
      last.getBoundingClientRect().top < innerHeight) active = last.id;
    if (scrolled !== previousScrolled) {
      header.classList.toggle('is-scrolled', scrolled);
      previousScrolled = scrolled;
    }
    if (active === previousActive) return;
    previousActive = active;
    for (const link of links) {
      const value = !link.samePage ? null : link.hash ?
        (link.hash === '#' + active ? 'location' : null) : link.page ? 'page' : null;
      if (value) link.node.setAttribute('aria-current', value);
      else link.node.removeAttribute('aria-current');
    }
  }

  function schedule() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(update);
  }
  window.addEventListener('scroll', schedule, {
    passive: true
  });
  window.addEventListener('resize', measure, {
    passive: true
  });
  window.addEventListener('hashchange', schedule);
  window.addEventListener('pageshow', measure);
  measure();
})();

(() => {
  const faq = document.querySelector("#faq");
  if (!faq || faq.dataset.motionReady) return;
  if (!Element.prototype.animate) return;

  faq.dataset.motionReady = "true";

  const items = [...faq.querySelectorAll("details")];
  const states = new WeakMap();
  const reduced = matchMedia("(prefers-reduced-motion: reduce)");

  function toggle(item, opening) {
    const summary = item.querySelector("summary");
    const answer = item.querySelector("p");
    const previous = states.get(item);
    const from = item.getBoundingClientRect().height;

    previous?.height?.cancel();
    previous?.fade?.cancel();

    item.style.height = "";
    item.style.overflow = "";
    item.open = true;

    const to = opening ?
      item.getBoundingClientRect().height :
      summary.getBoundingClientRect().height +
      parseFloat(getComputedStyle(item).borderTopWidth) +
      parseFloat(getComputedStyle(item).borderBottomWidth);

    const state = {
      opening,
      height: null,
      fade: null
    };
    states.set(item, state);

    if (reduced.matches) {
      item.open = opening;
      return;
    }

    item.style.overflow = "hidden";

    state.height = item.animate(
      [{
        height: `${from}px`
      }, {
        height: `${to}px`
      }], {
        duration: 220,
        easing: "cubic-bezier(.2,.7,.2,1)"
      }
    );

    if (opening && answer) {
      state.fade = answer.animate(
        [{
          opacity: 0
        }, {
          opacity: 1
        }], {
          duration: 180,
          easing: "ease-out"
        }
      );
    }

    state.height.onfinish = () => {
      if (states.get(item) !== state) return;
      item.open = opening;
      item.style.height = "";
      item.style.overflow = "";
      state.height = null;
      state.fade = null;
    };
  }

  reduced.addEventListener('change', () => {
    if (!reduced.matches) return;
    items.forEach(item => {
      const state = states.get(item);
      state?.height?.cancel();
      state?.fade?.cancel();
      item.open = !!state?.opening;
      item.style.height = '';
      item.style.overflow = '';
    });
  });

  // Manage exclusivity here so the previous answer can animate closed.
  items.forEach(item => {
    item.removeAttribute("name");
    states.set(item, {
      opening: item.open,
      height: null,
      fade: null
    });

    item.querySelector("summary").addEventListener("click", event => {
      event.preventDefault();
      const opening = !states.get(item).opening;

      if (opening) {
        items.forEach(other => {
          if (other !== item && states.get(other).opening) {
            toggle(other, false);
          }
        });
      }

      toggle(item, opening);
    });
  });
})();

// MARC weighted desktop wheel scrolling.
(() => {
  const desktop = matchMedia('(min-width: 901px) and (hover: hover) and (pointer: fine)');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let frame = 0, target = 0, last = 0, previousTime = 0;

  function stop() {
    cancelAnimationFrame(frame);
    frame = 0;
    previousTime = 0;
  }
  function limit() {
    return Math.max(0, document.documentElement.scrollHeight - innerHeight);
  }
  function draw(time) {
    if (!desktop.matches || reduced.matches || document.hidden ||
        Math.abs(scrollY - last) > 3) { stop(); return; }
    const dt = previousTime ? Math.min(time - previousTime, 40) : 16;
    previousTime = time;
    target = Math.max(0, Math.min(target, limit()));
    const remaining = target - scrollY;
    const next = Math.abs(remaining) < .75 ? target :
      scrollY + remaining * (1 - Math.exp(-dt / 90));
    window.scrollTo({top: next, behavior: 'instant'});
    last = scrollY;
    if (Math.abs(target - last) < .75) { stop(); return; }
    frame = requestAnimationFrame(draw);
  }
  function nestedScroll(event) {
    for (const node of event.composedPath()) {
      if (!(node instanceof Element)) continue;
      if (node === document.body || node === document.documentElement) break;
      if (node.matches('dialog, input, textarea, select, [contenteditable]:not([contenteditable="false"]), [role="slider"]')) return true;
      const css = getComputedStyle(node);
      if (/(auto|scroll|overlay)/.test(css.overflowY) &&
          node.scrollHeight > node.clientHeight + 1) return true;
    }
    return false;
  }
  addEventListener('wheel', event => {
    if (!desktop.matches || reduced.matches || event.defaultPrevented ||
        !event.cancelable || event.ctrlKey || event.metaKey || event.shiftKey ||
        !event.deltaY || Math.abs(event.deltaX) > Math.abs(event.deltaY) ||
        document.querySelector('dialog[open]') || nestedScroll(event)) {
      stop(); return;
    }
    const delta = event.deltaY * (event.deltaMode === 1 ? 20 :
      event.deltaMode === 2 ? innerHeight : 1);
    const current = scrollY;
    if (!frame) target = current;
    // Direction changes respond immediately, without the old momentum.
    if ((target - current) * delta < 0) target = current;
    const next = Math.max(0, Math.min(limit(), target + Math.max(-600, Math.min(600, delta))));
    if (next === current && !frame) return;
    event.preventDefault();
    target = next;
    if (!frame) {
      last = current;
      previousTime = 0;
      frame = requestAnimationFrame(draw);
    }
  }, {passive: false});
  // Native anchors, keyboard, touch, and scrollbar dragging retain control.
  addEventListener('keydown', stop);
  addEventListener('pointerdown', stop, {passive: true});
  addEventListener('touchstart', stop, {passive: true});
  addEventListener('focusin', stop);
  addEventListener('hashchange', stop);
  addEventListener('resize', stop, {passive: true});
  addEventListener('pagehide', stop);
  document.addEventListener('visibilitychange', stop);
  desktop.addEventListener('change', stop);
  reduced.addEventListener('change', stop);
})();
