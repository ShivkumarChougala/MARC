const screens = {
  "status": {
    "label": "Status",
    "title": "Your Mac at a glance.",
    "description": "See live CPU, memory, network, disk, battery, and storage readings alongside alerts.",
    "src": "assets/status.webp"
  },
  "system": {
    "label": "System",
    "title": "Look closer at your Mac.",
    "description": "Explore CPU cores, memory, uptime, and other system details.",
    "src": "assets/system.webp"
  },
  "statistics": {
    "label": "Statistics",
    "title": "Understand performance over time.",
    "description": "Review CPU, load, memory, network, and disk activity history.",
    "src": "assets/statistics.webp"
  },
  "processes": {
    "label": "Processes",
    "title": "Find what is using resources.",
    "description": "Search running processes, compare CPU and memory use, and inspect what is active.",
    "src": "assets/processes.webp"
  },
  "files": {
    "label": "Files",
    "title": "Work with your Mac files.",
    "description": "Browse folders, preview content, manage files, and transfer over SFTP.",
    "src": "assets/files.webp"
  },
  "terminal": {
    "label": "Terminal",
    "title": "An SSH terminal on your iPhone.",
    "description": "Use multiple terminal sessions, handy shortcut keys, and optional AI command suggestions.",
    "src": "assets/terminal.webp"
  },
  "control": {
    "label": "Control Center",
    "title": "Everyday controls, close at hand.",
    "description": "Manage supported Wi-Fi and Bluetooth controls, audio, brightness, playback, and quick launch.",
    "src": "assets/control.webp"
  },
  "settings": {
    "label": "Settings",
    "title": "Make MARC your own.",
    "description": "Manage saved Macs, connection settings, appearance, refresh rate, and available security options.",
    "src": "assets/settings.webp"
  }
};
const tabs = [...document.querySelectorAll('[data-screen]')];
const picture = document.getElementById('screen-image');
let selection = 0;
let screenRequest = 0;
let screenAnimations = [];
let displayedScreen = 0;
async function selectScreen(index, focus = false) {
  const tab = tabs[index];
  const screen = tab && screens[tab.dataset.screen];
  if (!screen || !picture) return;

  const direction = index >= selection ? 1 : -1;
  const request = ++screenRequest;
  selection = index;
  screenAnimations.forEach(a => a.cancel());
  screenAnimations = [];

  const panel = document.getElementById('showcase-panel');
  const copy = panel.querySelector('.showcopy');
  const setTabs = current => tabs.forEach((button, i) => {
    button.setAttribute('aria-selected', String(i === current));
    button.tabIndex = i === current ? 0 : -1;
  });

  setTabs(index);
  panel.setAttribute('aria-labelledby', tab.id);
  if (focus) tab.focus();

  if (index === displayedScreen) {
    panel.setAttribute('aria-busy', 'false');
    return;
  }

  panel.setAttribute('aria-busy', 'true');
  const next = new Image();
  next.src = screen.src;

  try {
    await next.decode();
  } catch {
    if (request === screenRequest) {
      selection = displayedScreen;
      setTabs(displayedScreen);
      panel.setAttribute('aria-labelledby', tabs[displayedScreen].id);
      panel.setAttribute('aria-busy', 'false');
    }
    return;
  }

  if (request !== screenRequest) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');

  if (!reduced.matches && picture.animate) {
    screenAnimations = [picture, copy].filter(Boolean).map(node =>
      node.animate([{
        opacity: 1
      }, {
        opacity: 0
      }], {
        duration: 110,
        easing: 'ease-out',
        fill: 'forwards'
      })
    );
    await Promise.all(
      screenAnimations.map(a => a.finished.catch(() => {}))
    );
    if (request !== screenRequest) return;
  }

  screenAnimations.forEach(a => a.cancel());
  screenAnimations = [];

  document.getElementById('screen-label').textContent = screen.label;
  document.getElementById('screen-title').textContent = screen.title;
  document.getElementById('screen-description').textContent =
    screen.description;

  picture.removeAttribute('srcset');
  picture.removeAttribute('sizes');
  picture.src = screen.src;
  picture.alt = 'MARC ' + screen.label + ' app screenshot';
  displayedScreen = index;
  panel.setAttribute('aria-busy', 'false');

  if (!reduced.matches && picture.animate) {
    screenAnimations = [picture, copy].filter(Boolean).map((node, i) =>
      node.animate([{
        opacity: 0,
        transform: 'translateX(' + (direction * (i ? 10 : 5)) + 'px)'
      }, {
        opacity: 1,
        transform: 'translateX(0)'
      }], {
        duration: 320,
        easing: 'cubic-bezier(.2,.8,.2,1)'
      })
    );
  }
}

tabs.forEach((tab, index) => {
  tab.addEventListener('click', () => selectScreen(index));
  tab.addEventListener('keydown', event => {
    let next = index;
    if (event.key === 'ArrowRight') next = (index + 1) % tabs.length;
    else if (event.key === 'ArrowLeft') next = (index + tabs.length - 1) % tabs.length;
    else if (event.key === 'Home') next = 0;
    else if (event.key === 'End') next = tabs.length - 1;
    else return;
    event.preventDefault();
    selectScreen(next, true)
  })
});

// MARC screenshot enlargement
(() => {
  const image = document.getElementById('screen-image');
  if (!image || document.querySelector('.marc-lightbox')) return;

  const trigger = document.createElement('button');
  trigger.type = 'button';
  trigger.className = 'screen-zoom-button';
  trigger.setAttribute('aria-label', 'Enlarge the selected app screenshot');
  trigger.setAttribute('aria-haspopup', 'dialog');
  image.before(trigger);
  trigger.append(image);

  const dialog = document.createElement('dialog');
  dialog.className = 'marc-lightbox';
  dialog.setAttribute('aria-label', 'Enlarged MARC screenshot');
  dialog.innerHTML = `
    <div class="lightbox-toolbar">
      <span>App screenshot</span>
      <button type="button" class="lightbox-close"
              aria-label="Close enlarged screenshot">×</button>
    </div>
    <img alt="">
  `;
  document.body.append(dialog);

  trigger.addEventListener('click', () => {
    const enlarged = dialog.querySelector('img');
    enlarged.src = image.src;
    enlarged.alt = image.alt;
    dialog.querySelector('.lightbox-toolbar span').textContent =
      document.getElementById('screen-label')?.textContent || 'App screenshot';
    dialog.showModal();
  });

  dialog.querySelector('.lightbox-close').addEventListener(
    'click', () => dialog.close()
  );

  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const box = dialog.getBoundingClientRect();
    if (
      event.clientX < box.left || event.clientX > box.right ||
      event.clientY < box.top || event.clientY > box.bottom
    ) dialog.close();
  });

  dialog.addEventListener('close', () => trigger.focus());
})();

// MARC keep selected mobile tab visible
(() => {
  const row = document.querySelector('.showtabs');
  if (!row) return;

  function revealSelected() {
    if (!window.matchMedia('(max-width: 800px)').matches) return;
    const selected = row.querySelector('[aria-selected="true"]');
    if (!selected) return;

    const left = selected.offsetLeft - row.offsetLeft;
    const target = left - (row.clientWidth - selected.offsetWidth) / 2;
    const reduced = window.matchMedia(
      '(prefers-reduced-motion: reduce)'
    ).matches;

    row.scrollTo({
      left: Math.max(0, target),
      behavior: reduced ? 'instant' : 'smooth'
    });
  }

  new MutationObserver(revealSelected).observe(row, {
    subtree: true,
    attributes: true,
    attributeFilter: ['aria-selected']
  });

  window.addEventListener('resize', revealSelected);
})();

// MARC coordinated text and image entrances.
// Content stays readable if scripting, observers, or animation support is absent.
(() => {
  const hero = document.querySelector('.marc-hero-v2');
  if (!hero || !Element.prototype.animate || !('IntersectionObserver' in window)) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  if (reduced.matches) return;
  const active = new Set();
  const seen = new WeakSet();
  const ease = 'cubic-bezier(.2,1,.3,1)';

  function play(node, frames, duration, delay = 0) {
    if (reduced.matches) return;
    const animation = node.animate(frames, {
      duration,
      delay,
      easing: ease,
      fill: 'backwards'
    });
    active.add(animation);
    animation.finished.catch(() => {}).finally(() => active.delete(animation));
  }

  function textReveal(element, byLetter = false) {
    if (!element || seen.has(element)) return;
    seen.add(element);
    if (byLetter) element.setAttribute('aria-label', element.getAttribute('aria-label') || element.innerText.replace(/\s+/g, ' ').trim());
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    const pieces = [];
    for (const node of nodes) {
      const fragment = document.createDocumentFragment();
      // Keep words intact at line wraps, and retain existing <br> and accent spans.
      for (const token of node.textContent.split(/(\s+)/)) {
        if (!token) continue;
        if (/^\s+$/.test(token)) {
          fragment.append(document.createTextNode(token));
          continue;
        }
        const word = document.createElement('span');
        word.className = 'marc-motion-word';
        if (byLetter) word.setAttribute('aria-hidden', 'true');
        if (byLetter) {
          for (const letter of Array.from(token)) {
            const part = document.createElement('span');
            part.className = 'marc-motion-letter';
            part.textContent = letter;
            word.append(part);
            pieces.push(part);
          }
        } else {
          word.textContent = token;
          pieces.push(word);
        }
        fragment.append(word);
      }
      node.replaceWith(fragment);
    }
    // Cap total staggering so long descriptions remain quick to read.
    const step = Math.min(byLetter ? 28 : 32, 380 / Math.max(pieces.length - 1, 1));
    pieces.forEach((part, index) => play(part, [{
      opacity: 0,
      transform: 'translateY(10px)',
      filter: byLetter ? 'blur(6px)' : 'blur(3px)'
    }, {
      opacity: 1,
      transform: 'translateY(0)',
      filter: 'blur(0)'
    }], byLetter ? 640 : 560, index * step));
  }

  textReveal(document.getElementById('hero-title'), true);
  textReveal(hero.querySelector('.lead'));
  // Leave the main screenshots opaque so their first paint isn't delayed.
  hero.querySelectorAll('.mh-device').forEach((node, index) => play(node, [{
    translate: `0 ${22 + index * 8}px`
  }, {
    translate: '0 0'
  }], 850, index * 90));
  [hero.querySelector('.eyebrow'), hero.querySelector('.mh-download'),
    hero.querySelector('.mh-benefits')
  ].filter(Boolean).forEach((node, index) => play(node, [{
    opacity: .35,
    translate: '0 8px'
  }, {
    opacity: 1,
    translate: '0 0'
  }], 600, index * 70));

  const targets = new Map();
  document.querySelectorAll('#preview .sectionhead h2, .story-heading h2, .story-copy h3, #download-title')
    .forEach(node => targets.set(node, 'text'));
  document.querySelectorAll('#preview .sectionhead p, .story-heading p, .story-copy > p, .md-description')
    .forEach(node => targets.set(node, 'words'));
  document.querySelectorAll('#preview .showcase, .story-phone, .story-features article, .md-logo, .md-actions, #faq .sectionhead')
    .forEach(node => targets.set(node, 'block'));
  let remaining = targets.size;
  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      observer.unobserve(entry.target);
      if (--remaining === 0) observer.disconnect();
      if (reduced.matches) continue;
      const mode = targets.get(entry.target);
      if (mode !== 'block') textReveal(entry.target);
      else {
        const siblings = [...entry.target.parentElement.children];
        const delay = entry.target.matches('.story-features article') ? siblings.indexOf(entry.target) * 65 : 0;
        play(entry.target, [{
          opacity: 0,
          translate: '0 22px'
        }, {
          opacity: 1,
          translate: '0 0'
        }], 720, delay);
      }
    }
  }, {
    threshold: 0,
    rootMargin: '0px 0px 30px 0px'
  });
  targets.forEach((mode, node) => observer.observe(node));

  function stop() {
    observer.disconnect();
    active.forEach(animation => animation.cancel());
    active.clear();
  }
  reduced.addEventListener('change', event => {
    if (event.matches) stop();
  });
  // Keyboard navigation must never land on an animating, transparent control.
  document.addEventListener('focusin', event => {
    active.forEach(animation => {
      if (animation.effect?.target?.contains(event.target)) animation.cancel();
    });
  });
  window.addEventListener('pagehide', stop, {
    once: true
  });
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

  function setOpen(open) {
    open = mobile.matches && open;
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute(
      'aria-label', open ? 'Close navigation menu' : 'Open navigation menu'
    );
    links.hidden = mobile.matches && !open;
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
    setOpen(false);
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

(() => {
  const hero = document.querySelector('.hero-scene');
  const visual = hero?.querySelector('.mh-visual');
  const phones = visual?.querySelectorAll('.mh-device');
  if (!hero || !visual || phones.length !== 2) return;

  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let frame = 0,
    top = 0,
    height = 1;
  const clamp = n => Math.max(0, Math.min(1, n));

  function draw() {
    frame = 0;
    const p = reduced.matches ?
      0 :
      clamp((scrollY - top) / (height * .85));

    const x = p * (innerWidth <= 700 ? 10 : 34);

    phones[0].style.transform =
      'translate3d(' + (-x) + 'px,' + (p * 12) +
      'px,0) rotate(' + (-p * .8) + 'deg)';

    phones[1].style.transform =
      'translate3d(' + x + 'px,' + (-p * 10) +
      'px,0) rotate(' + (p * .8) + 'deg)';

    const fade = clamp((p - .45) / .55);
    visual.style.opacity =
      String(1 - fade * fade * (3 - 2 * fade));

    visual.style.willChange =
      p > 0 && p < 1 ? 'opacity' : 'auto';
  }

  function request() {
    if (!frame) frame = requestAnimationFrame(draw);
  }

  function measure() {
    top = hero.getBoundingClientRect().top + scrollY;
    height = hero.offsetHeight;
    request();
  }

  addEventListener('scroll', request, {
    passive: true
  });
  addEventListener('resize', measure, {
    passive: true
  });
  addEventListener('pageshow', measure);
  reduced.addEventListener('change', measure);

  if ('ResizeObserver' in window) {
    new ResizeObserver(measure).observe(hero);
  }

  measure();
})();

(() => {
  if (!document.querySelector('.hero-scene') ||
    !('IntersectionObserver' in window)) return;

  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const nodes = [...document.querySelectorAll(
    '#preview .showbody > .phone, ' +
    '#features .story-featured, ' +
    '#features .story-features article, ' +
    '#download .md-logo'
  )];

  const visible = new Set();
  const offsets = new WeakMap();
  let frame = 0;

  function draw() {
    frame = 0;
    const distance = innerWidth <= 700 ? 7 : 14;
    const updates = [];

    visible.forEach(node => {
      const box = node.getBoundingClientRect();
      const top = box.top - (offsets.get(node) || 0);
      const p = Math.max(0, Math.min(1,
        (innerHeight - top) / (innerHeight + box.height)
      ));
      const y = reduced.matches ? 0 : (1 - 2 * p) * distance;
      updates.push([node, y]);
    });

    updates.forEach(([node, y]) => {
      offsets.set(node, y);
      node.style.transform =
        'translate3d(0,' + y.toFixed(2) + 'px,0)';
    });
  }

  function request() {
    if (!frame && visible.size) {
      frame = requestAnimationFrame(draw);
    }
  }

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        visible.add(entry.target);
      } else {
        visible.delete(entry.target);
        offsets.delete(entry.target);
        entry.target.style.removeProperty('transform');
      }
    });
    request();
  }, {
    rootMargin: '60px 0px'
  });

  nodes.forEach(node => observer.observe(node));
  addEventListener('scroll', request, {
    passive: true
  });
  addEventListener('resize', request, {
    passive: true
  });

  reduced.addEventListener('change', () => {
    nodes.forEach(node => {
      node.style.removeProperty('transform');
      offsets.delete(node);
    });
    request();
  });
})();
