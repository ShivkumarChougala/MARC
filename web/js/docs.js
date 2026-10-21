
(() => {
  const search = document.querySelector('.search');
  const input = document.querySelector('#docs-search');
  const results = document.querySelector('#search-results');
  const links = document.querySelector('#search-links');
  const status = document.querySelector('#search-status');
  const index = JSON.parse(
    document.querySelector('#docs-index').textContent
  );

  search.hidden = false;

  function hide() {
    results.hidden = true;
    input.setAttribute('aria-expanded', 'false');
  }

  function find() {
    const terms = input.value.toLowerCase().trim()
      .split(/\s+/).filter(Boolean);

    links.replaceChildren();

    if (!terms.length) {
      hide();
      return;
    }

    const found = index.filter(p =>
      terms.every(t =>
        (p.title + ' ' + p.text).toLowerCase().includes(t)
      )
    );

    status.textContent = found.length
      ? `${found.length} matching guide${found.length === 1 ? '' : 's'}`
      : 'No matching guides. Try SSH, Python, files, or AI.';

    found.forEach(p => {
      const a = document.createElement('a');
      a.href = p.url;
      a.textContent = p.title;
      links.append(a);
    });

    results.hidden = false;
    input.setAttribute('aria-expanded', 'true');
  }

  input.addEventListener('input', find);
  input.addEventListener('focus', find);

  search.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
      hide();
      input.focus();
    }

    if (e.key === 'ArrowDown') {
      const next = e.target === input
        ? links.firstElementChild
        : e.target.nextElementSibling;

      if (next) {
        e.preventDefault();
        next.focus();
      }
    }

    if (e.key === 'ArrowUp' && e.target !== input) {
      e.preventDefault();
      (e.target.previousElementSibling || input).focus();
    }

    if (
      e.key === 'Enter' &&
      e.target === input &&
      !results.hidden &&
      links.firstElementChild
    ) {
      e.preventDefault();
      links.firstElementChild.click();
    }
  });

  search.addEventListener('focusout', e => {
    if (!search.contains(e.relatedTarget)) hide();
  });

  document.addEventListener('click', e => {
    if (!search.contains(e.target)) hide();
  });

  document.addEventListener('keydown', e => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      input.focus();
      input.select();
    }
  });

  if (!/Mac|iPhone|iPad/.test(navigator.platform)) {
    document.querySelector('.search kbd').textContent = 'Ctrl K';
  }

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
  }, {passive: true});

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
