/* Chapter activation follows natural scroll; variants load on request. */
(() => {
const screens = {
  "status": {
    "label": "Status",
    "description": "Check CPU and memory, follow network and disk activity, and see services and top processes in one place.",
    "src": "assets/status.webp"
  },
  "system": {
    "label": "System",
    "description": "Explore CPU cores, memory, uptime, and other system details.",
    "src": "assets/system.webp"
  },
  "statistics": {
    "label": "Statistics",
    "description": "Review CPU, load, memory, network, and disk activity history.",
    "src": "assets/statistics.webp"
  },
  "processes": {
    "label": "Processes",
    "description": "Search running processes, compare CPU and memory use, and inspect what is active.",
    "src": "assets/processes.webp"
  },
  "files": {
    "label": "Files",
    "description": "Find a file on your Mac. Preview it, download it to iPhone, share it, or rename and move it over SFTP.",
    "src": "assets/files.webp"
  },
  "terminal": {
    "label": "Terminal",
    "description": "Use multiple terminal sessions, handy shortcut keys, and optional AI command suggestions.",
    "src": "assets/terminal.webp"
  },
  "control": {
    "label": "Control Center",
    "description": "Manage supported Wi-Fi and Bluetooth controls, audio, brightness, playback, and quick launch.",
    "src": "assets/control.webp"
  },
  "fileDetails": {"label": "File details", "description": "Inspect size, dates, permissions and ownership. Preview, download, share, rename or move a file from one sheet.", "src": "assets/file-details.webp"},
  "settings": {
    "label": "Settings",
    "description": "Manage saved Macs, connection settings, appearance, refresh rate, and available security options.",
    "src": "assets/settings.webp"
  }
};
  const tour = document.querySelector('.mt-tour');
  if (!tour) return;
  const scenes = [...tour.querySelectorAll('.mt-scene')];
  const links = [...tour.querySelectorAll('.mt-nav a')];
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const desktop = matchMedia('(min-width: 801px) and (min-height: 651px)');
  const state = new WeakMap();
  const dialog = tour.querySelector('dialog');
  const status = tour.querySelector('.mt-status');
  let active = -1, frame = 0, visible = true, reveal, opener;

  function mark(index) {
    if (index === active) return;
    active = index;
    reveal?.cancel();
    links.forEach((link, i) => {
      if (i === index) link.setAttribute('aria-current', 'step');
      else link.removeAttribute('aria-current');
    });
    const summary = links[index]?.nextElementSibling;
    if (!reduced.matches && desktop.matches && summary?.animate) {
      reveal = summary.animate([{opacity: .35, translate: '0 7px'}, {opacity: 1, translate: '0 0'}], {duration: 320, easing: 'ease-out'});
    }
  }
  function draw() {
    frame = 0;
    if (!visible || !desktop.matches) return;
    const focus = (innerHeight + 90) / 2;
    const distances = scenes.map(scene => {
      const r = scene.querySelector('.mt-device').getBoundingClientRect();
      return Math.abs(r.top + r.height / 2 - focus);
    });
    mark(distances.indexOf(Math.min(...distances)));
  }
  function request() {
    if (visible && desktop.matches && !frame) frame = requestAnimationFrame(draw);
  }
  tour.classList.add('is-ready');
  mark(0);
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      if (visible) request();
    }, {rootMargin: '100px'}).observe(tour);
  }
  addEventListener('scroll', request, {passive: true});
  addEventListener('resize', request, {passive: true});
  addEventListener('pageshow', request);
  desktop.addEventListener('change', request);
  reduced.addEventListener('change', () => {
    reveal?.cancel();
    scenes.forEach(scene => {
      const current = state.get(scene);
      current?.animations.forEach(a => a.cancel());
      current?.ghost?.remove();
    });
  });
  request();

  // Decode first, then crossfade both screens without a dark flash.
  async function select(button) {
    const scene = button.closest('.mt-scene');
    const screen = screens[button.dataset.tourScreen];
    if (!screen) return;
    const previous = state.get(scene);
    previous?.animations.forEach(a => a.cancel());
    previous?.ghost?.remove();
    const current = {animations: [], ghost: null};
    state.set(scene, current);
    if (button.getAttribute('aria-pressed') === 'true') {
      scene.setAttribute('aria-busy', 'false');
      return;
    }
    scene.setAttribute('aria-busy', 'true');
    status.textContent = '';
    const image = scene.querySelector('.mt-device img:not(.mt-outgoing)');
    const incoming = new Image();
    incoming.src = screen.src;
    try { await incoming.decode(); }
    catch {
      if (state.get(scene) === current) {
        scene.setAttribute('aria-busy', 'false');
        status.textContent = 'That screen could not load. Please try again.';
      }
      return;
    }
    if (state.get(scene) !== current) return;
    const animate = !reduced.matches && !!image.animate;
    if (animate) {
      const ghost = image.cloneNode();
      ghost.className = 'mt-outgoing';
      ghost.alt = '';
      ghost.setAttribute('aria-hidden', 'true');
      ghost.removeAttribute('id');
      image.parentElement.append(ghost);
      current.ghost = ghost;
    }
    image.removeAttribute('srcset');
    image.removeAttribute('sizes');
    image.src = screen.src;
    image.alt = 'MARC ' + screen.label + ' app screen';
    scene.querySelectorAll('[data-tour-screen]').forEach(b => b.setAttribute('aria-pressed', String(b === button)));
    const caption = scene.querySelector('.mt-screen-caption');
    caption.textContent = screen.description;
    scene.querySelector('.mt-zoom').setAttribute('aria-label', 'Enlarge ' + screen.label + ' screenshot');
    scene.setAttribute('aria-busy', 'false');
    status.textContent = screen.label + ' view selected.';
    if (animate) {
      const options = {duration: 320, easing: 'cubic-bezier(.2,.8,.2,1)'};
      current.animations = [
        image.animate([{opacity: 0}, {opacity: 1}], options),
        current.ghost.animate([{opacity: 1}, {opacity: 0}], options),
        caption.animate([{opacity: .3, translate: '0 4px'}, {opacity: 1, translate: '0 0'}], options)
      ];
      Promise.all(current.animations.map(a => a.finished.catch(() => {})))
        .then(() => { current.ghost?.remove(); current.ghost = null; });
    }
  }
  tour.querySelectorAll('[data-tour-screen]').forEach(button => button.addEventListener('click', () => select(button)));
  tour.querySelectorAll('.mt-options').forEach(group => group.addEventListener('keydown', event => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
    const buttons = [...group.querySelectorAll('[data-tour-screen]')];
    const index = buttons.indexOf(event.target);
    if (index < 0) return;
    event.preventDefault();
    const next = event.key === 'Home' ? 0 : event.key === 'End' ? buttons.length - 1 :
      (index + (event.key === 'ArrowRight' ? 1 : -1) + buttons.length) % buttons.length;
    buttons[next].focus({preventScroll: true});
    select(buttons[next]);
  }));
  tour.querySelectorAll('.mt-zoom').forEach(button => button.addEventListener('click', () => {
    opener = button;
    const source = button.querySelector('img');
    const enlarged = dialog.querySelector('img');
    enlarged.src = source.currentSrc || source.src;
    enlarged.alt = source.alt;
    dialog.showModal();
  }));
  dialog.querySelector('button').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const r = dialog.getBoundingClientRect();
    if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => opener?.focus({preventScroll: true}));
})();

/* Word brightness follows scroll position; text remains selectable and readable. */
(() => {
  const intro = document.querySelector('[data-scroll-intro]');
  if (!intro) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const words = [];
  const walker = document.createTreeWalker(intro, NodeFilter.SHOW_TEXT);
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);
  nodes.forEach(node => {
    if (!node.textContent.trim()) return;
    const fragment = document.createDocumentFragment();
    node.textContent.split(/(\s+)/).forEach(token => {
      if (!token) return;
      if (/^\s+$/.test(token)) fragment.append(document.createTextNode(token));
      else {
        const word = document.createElement('span');
        word.className = 'mt-word';
        word.textContent = token;
        words.push(word);
        fragment.append(word);
      }
    });
    node.replaceWith(fragment);
  });
  let frame = 0, visible = true, previous = -1;
  function paint() {
    frame = 0;
    if (reduced.matches || !visible) return;
    const rect = intro.getBoundingClientRect();
    const progress = Math.max(0, Math.min(1,
      (innerHeight * .88 - rect.top) / (rect.height + innerHeight * .38)
    ));
    const count = Math.ceil(progress * words.length);
    if (count === previous) return;
    const start = previous < 0 ? 0 : Math.min(previous, count);
    const end = previous < 0 ? words.length : Math.max(previous, count);
    for (let i = start; i < end; i++) words[i].classList.toggle('is-lit', i < count);
    previous = count;
  }
  function request() {
    if (!reduced.matches && visible && !frame) frame = requestAnimationFrame(paint);
  }
  function preferences() {
    if (frame) cancelAnimationFrame(frame);
    frame = 0;
    previous = -1;
    intro.classList.toggle('is-enhanced', !reduced.matches);
    if (!reduced.matches) request();
  }
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      if (visible) request();
    }, {rootMargin: '80px'}).observe(intro);
  }
  addEventListener('scroll', request, {passive: true});
  addEventListener('resize', request, {passive: true});
  addEventListener('pageshow', request);
  reduced.addEventListener('change', preferences);
  preferences();
})();
