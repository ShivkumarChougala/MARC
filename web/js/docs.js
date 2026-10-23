(() => {
  // Spotlight search: one owner for filtering, keyboard shortcuts and dialog focus.
  function initSearch() {
    const search = document.querySelector('.docs-header .search');
    const input = document.getElementById('docs-search');
    const results = document.getElementById('search-results');
    const links = document.getElementById('search-links');
    const status = document.getElementById('search-status');
    const data = document.getElementById('docs-index');
    if (!search || !input || !results || !links || !status || !data) return;
    const index = JSON.parse(data.textContent);
    const shortcut = /Mac|iPhone|iPad/.test(navigator.platform) ? '⌘ K' : 'Ctrl K';

    const launcher = document.createElement('button');
    launcher.type = 'button';
    launcher.className = 'search spotlight-launcher';
    launcher.setAttribute('aria-haspopup', 'dialog');
    launcher.setAttribute('aria-controls', 'marc-docs-search-dialog');
    launcher.innerHTML = '<span>Search documentation…</span><kbd></kbd>';
    launcher.querySelector('kbd').textContent = shortcut;
    search.replaceWith(launcher);

    const dialog = document.createElement('dialog');
    dialog.id = 'marc-docs-search-dialog';
    dialog.className = 'marc-docs-spotlight';
    dialog.setAttribute('aria-label', 'Search MARC documentation');

    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'spotlight-close';
    close.textContent = 'Esc';
    close.setAttribute('aria-label', 'Close search');

    const hint = document.createElement('p');
    hint.className = 'spotlight-hint';
    hint.textContent = 'Search guides, features, and setup. Use ↑ ↓ to choose, Enter to open.';
    dialog.append(search, hint, close);
    document.body.append(dialog);
    search.hidden = false;
    input.placeholder = 'Search MARC Docs…';
    let previousOverflow = '';
    let scrollLocked = false;

    function find() {
      const terms = input.value.toLowerCase().trim().split(/\s+/).filter(Boolean);
      links.replaceChildren();
      hint.hidden = terms.length > 0;
      results.hidden = terms.length === 0;
      input.setAttribute('aria-expanded', String(terms.length > 0));
      if (!terms.length) return;

      const found = index.filter(page => {
        const text = (page.title + ' ' + page.text).toLowerCase();
        return terms.every(term => text.includes(term));
      });
      status.textContent = found.length ?
        `${found.length} matching guide${found.length === 1 ? '' : 's'}` :
        'No matching guides. Try SSH, Python, files, or AI.';
      found.forEach(page => {
        const link = document.createElement('a');
        link.href = page.url;
        link.textContent = page.title;
        links.append(link);
      });
    }

    function open() {
      if (!dialog.open) {
        previousOverflow = document.documentElement.style.overflow;
        dialog.showModal();
        document.documentElement.style.overflow = 'hidden';
        scrollLocked = true;
      }
      input.focus();
      input.select();
      find();
    }

    function restorePage() {
      if (!scrollLocked) return;
      document.documentElement.style.overflow = previousOverflow;
      scrollLocked = false;
      launcher.focus({
        preventScroll: true
      });
    }

    function closeSearch() {
      if (!dialog.open) return;
      dialog.close();
      // Restore immediately: a rapid reopen must not save the locked overflow.
      restorePage();
    }

    launcher.addEventListener('click', open);
    close.addEventListener('click', closeSearch);
    input.addEventListener('input', find);
    dialog.addEventListener('keydown', event => {
      if (event.key === 'Escape') {
        // Native search fields may consume Escape before a dialog can cancel.
        event.preventDefault();
        closeSearch();
      } else if (event.key === 'ArrowDown') {
        const next = event.target === input ? links.firstElementChild :
          event.target.parentElement === links ? event.target.nextElementSibling : null;
        if (next) {
          event.preventDefault();
          next.focus();
        }
      } else if (event.key === 'ArrowUp' && event.target.parentElement === links) {
        event.preventDefault();
        (event.target.previousElementSibling || input).focus();
      } else if (event.key === 'Enter' && event.target === input && !results.hidden) {
        if (links.firstElementChild) {
          event.preventDefault();
          links.firstElementChild.click();
        }
      }
    }, true);
    dialog.addEventListener('click', event => {
      if (event.target !== dialog) return;
      const box = dialog.getBoundingClientRect();
      if (event.clientX < box.left || event.clientX > box.right ||
        event.clientY < box.top || event.clientY > box.bottom) closeSearch();
    });
    dialog.addEventListener('close', () => {
      if (!dialog.open) restorePage();
    });
    dialog.addEventListener('cancel', event => {
      event.preventDefault();
      closeSearch();
    });
    document.addEventListener('keydown', event => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        open();
      }
    });
  }

  initSearch();

  document.querySelectorAll('.copy').forEach(button => {
    button.hidden = false;
    let timer;

    button.addEventListener('click', async () => {
      const code = button.closest('.code').querySelector('code');

      try {
        await navigator.clipboard.writeText(code.textContent);
        button.textContent = 'Copied';
      } catch {
        const range = document.createRange();
        range.selectNodeContents(code);

        const selection = getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        button.textContent = 'Select & copy';
      }

      clearTimeout(timer);
      timer = setTimeout(() => {
        button.textContent = 'Copy';
      }, 2200);
    });
  });

  const menu = document.querySelector('#docs-menu');
  const mobile = matchMedia('(max-width: 900px)');

  const setMenu = () => {
    menu.open = !mobile.matches;
  };

  setMenu();
  mobile.addEventListener('change', setMenu);

  const headings = [
    ...document.querySelectorAll('.article-body h2')
  ];
  const toc = [...document.querySelectorAll('.toc nav > a')];
  let pending = false;

  function track() {
    pending = false;

    const line = document.querySelector('.docs-header')
      .getBoundingClientRect().bottom + 36;

    let current = headings[0];

    headings.forEach(h => {
      if (h.getBoundingClientRect().top <= line) current = h;
    });

    toc.forEach(a => {
      if (a.hash === '#' + current?.id) {
        a.setAttribute('aria-current', 'location');
      } else {
        a.removeAttribute('aria-current');
      }
    });
  }

  addEventListener('scroll', () => {
    if (!pending) {
      pending = true;
      requestAnimationFrame(track);
    }
  }, {
    passive: true
  });

  addEventListener('resize', track);
  track();

  const legacy = {
    '#troubleshoot': '/docs/troubleshooting.html',
    '#controls': '/docs/controls.html',
    '#ai': '/docs/ai.html',
    '#contact': '/docs/troubleshooting.html#contact'
  };

  if (['/help', '/help.html', '/docs', '/docs.html'].includes(location.pathname) && legacy[location.hash]) {
    location.replace(legacy[location.hash]);
  }
})();
