const screens={"status": {"label": "Status", "title": "Your Mac at a glance.", "description": "See live CPU, memory, network, disk, battery, and storage readings alongside alerts.", "src": "assets/status.webp?v=20261019"}, "system": {"label": "System", "title": "Look closer at your Mac.", "description": "Explore CPU cores, memory, uptime, and other system details.", "src": "assets/system.webp"}, "statistics": {"label": "Statistics", "title": "Understand performance over time.", "description": "Review CPU, load, memory, network, and disk activity history.", "src": "assets/statistics.webp?v=20261019b"}, "processes": {"label": "Processes", "title": "Find what is using resources.", "description": "Search running processes, compare CPU and memory use, and inspect what is active.", "src": "assets/processes.webp?v=20261019"}, "files": {"label": "Files", "title": "Work with your Mac files.", "description": "Browse folders, preview content, manage files, and transfer over SFTP.", "src": "assets/files.webp?v=20261019"}, "terminal": {"label": "Terminal", "title": "An SSH terminal on your iPhone.", "description": "Use multiple terminal sessions, handy shortcut keys, and optional AI command suggestions.", "src": "assets/terminal.webp?v=1792600875208255000"}, "control": {"label": "Control Center", "title": "Everyday controls, close at hand.", "description": "Manage supported Wi-Fi and Bluetooth controls, audio, brightness, playback, and quick launch.", "src": "assets/control.webp?v=20261019"}, "settings": {"label": "Settings", "title": "Make MARC your own.", "description": "Manage saved Macs, connection settings, appearance, refresh rate, and available security options.", "src": "assets/settings.webp?v=20261019"}};
const tabs=[...document.querySelectorAll('[data-screen]')];
const picture=document.getElementById('screen-image');let selection=0;
let screenRequest=0;
async function selectScreen(index,focus=false){
 const request=++screenRequest;selection=index;const tab=tabs[index],screen=screens[tab.dataset.screen];
 tabs.forEach((button,i)=>{button.setAttribute('aria-selected',String(i===index));button.tabIndex=i===index?0:-1});
 const panel=document.getElementById('showcase-panel');panel.setAttribute('aria-labelledby',tab.id);panel.setAttribute('aria-busy','true');
 if(focus)tab.focus();
 const next=new Image();next.src=screen.src;
 try{await next.decode()}catch(error){if(request===screenRequest)panel.setAttribute('aria-busy','false');return}
 if(request!==screenRequest)return;
 document.getElementById('screen-label').textContent=screen.label;
 document.getElementById('screen-title').textContent=screen.title;
 document.getElementById('screen-description').textContent=screen.description;
 picture.classList.remove('switching');picture.removeAttribute('srcset');picture.removeAttribute('sizes');picture.src=screen.src;picture.alt='MARC '+screen.label+' app screenshot';
 requestAnimationFrame(()=>{if(request===screenRequest)picture.classList.add('switching')});panel.setAttribute('aria-busy','false');
}

tabs.forEach((tab,index)=>{tab.addEventListener('click',()=>selectScreen(index));tab.addEventListener('keydown',event=>{let next=index;if(event.key==='ArrowRight')next=(index+1)%tabs.length;else if(event.key==='ArrowLeft')next=(index+tabs.length-1)%tabs.length;else if(event.key==='Home')next=0;else if(event.key==='End')next=tabs.length-1;else return;event.preventDefault();selectScreen(next,true)})});

document.querySelectorAll('[data-jump]').forEach(link=>link.addEventListener('click',()=>{const index=tabs.findIndex(tab=>tab.dataset.screen===link.dataset.jump);if(index>=0)selectScreen(index)}));


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
// END MARC screenshot enlargement


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
// END MARC keep selected mobile tab visible





// MARC signature entrance
(() => {
  const panel = document.getElementById('download');
  if (!panel ||
      window.matchMedia('(prefers-reduced-motion: reduce)').matches ||
      !('IntersectionObserver' in window)) return;

  const observer = new IntersectionObserver(entries => {
    if (!entries.some(entry => entry.isIntersecting)) return;
    panel.classList.add('signature-enter');
    observer.disconnect();
  }, { threshold: 0.15 });

  observer.observe(panel);
})();
// END MARC signature entrance


// MARC subtle scroll motion
(() => {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches ||
      !('IntersectionObserver' in window)) return;

  const targets = document.querySelectorAll(
    '.hero > div:first-child, ' +
    'section[aria-label="App screen explorer"] .sectionhead, ' +
    '.story-heading, .story-copy, .story-phone, .story-features article'
  );

  const observer = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      entry.target.classList.add('marc-reveal');
      observer.unobserve(entry.target);
    }
  }, { threshold: 0.12 });

  targets.forEach(target => observer.observe(target));
})();
// END MARC subtle scroll motion


// MARC responsive navigation
(() => {
  const header = document.querySelector('.marc-header');
  const toggle = header?.querySelector('.marc-menu-toggle');
  const links = document.getElementById('marc-nav-links');
  if (!header || !toggle || !links) return;

  const mobile = window.matchMedia('(max-width: 1000px)');

  function setOpen(open) {
    open = mobile.matches && open;
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute(
      'aria-label', open ? 'Close navigation menu' : 'Open navigation menu'
    );
    links.hidden = mobile.matches && !open;
  }

  function syncLayout() {
    const restoreFocus = mobile.matches && links.contains(document.activeElement);
    toggle.hidden = !mobile.matches;
    setOpen(false);
    if (restoreFocus) toggle.focus();
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
// END MARC responsive navigation

// MARC navbar scroll appearance
(() => {
  const header = document.querySelector('.marc-header');
  if (!header) return;

  let scheduled = false;
  let previous = null;

  function update() {
    const scrolled = window.scrollY > 8;
    if (scrolled !== previous) {
      header.classList.toggle('is-scrolled', scrolled);
      previous = scrolled;
    }
    scheduled = false;
  }

  window.addEventListener('scroll', () => {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(update);
  }, { passive: true });

  window.addEventListener('pageshow', update);
  update();
})();
// END MARC navbar scroll appearance

// MARC section navigation START
(() => {
  const header = document.querySelector('.marc-header');
  if (!header) return;

  const links = [...header.querySelectorAll('a[href]')];
  // MARC Pages URL normalization
  const pagePath = path => path
    .replace(/\/index(?:\.html)?$/, '/')
    .replace(/\.html$/, '')
    .replace(/\/$/, '') || '/';

  const sections = ['preview', 'features', 'download']
    .map(id => document.getElementById(id))
    .filter(Boolean);

  function update() {
    const line = header.getBoundingClientRect().bottom + 40;
    let active = null;
    for (const section of sections) {
      const box = section.getBoundingClientRect();
      if (box.top <= line && box.bottom > line) {
        active = section.id;
      }
    }

    for (const link of links) {
      const url = new URL(link.href, location.href);
      link.removeAttribute('aria-current');
      if (url.origin !== location.origin) continue;

      if (url.hash) {
        if (active && pagePath(url.pathname) === pagePath(location.pathname) &&
            url.hash === '#' + active) {
          link.setAttribute('aria-current', 'location');
        }
      } else if (url.pathname !== '/' &&
                 pagePath(url.pathname) === pagePath(location.pathname)) {
        link.setAttribute('aria-current', 'page');
      }
    }
  }

  let pending = false;
  function schedule() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(() => {
      pending = false;
      update();
    });
  }

  window.addEventListener('scroll', schedule, {passive:true});
  window.addEventListener('resize', schedule);
  window.addEventListener('hashchange', schedule);
  window.addEventListener('pageshow', schedule);

  // Correct an existing Explore hash after moving its anchor.
  if (location.hash === '#preview') {
    requestAnimationFrame(() => {
      document.getElementById('preview')?.scrollIntoView({behavior:'instant'});
      update();
    });
  }
  update();
})();
// MARC section navigation END

// MARC FAQ motion START
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

    const to = opening
      ? item.getBoundingClientRect().height
      : summary.getBoundingClientRect().height
        + parseFloat(getComputedStyle(item).borderTopWidth)
        + parseFloat(getComputedStyle(item).borderBottomWidth);

    const state = { opening, height: null, fade: null };
    states.set(item, state);

    if (reduced.matches) {
      item.open = opening;
      return;
    }

    item.style.overflow = "hidden";

    state.height = item.animate(
      [{ height: `${from}px` }, { height: `${to}px` }],
      {
        duration: 220,
        easing: "cubic-bezier(.2,.7,.2,1)"
      }
    );

    if (opening && answer) {
      state.fade = answer.animate(
        [{ opacity: 0 }, { opacity: 1 }],
        { duration: 180, easing: "ease-out" }
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
// MARC FAQ motion END
