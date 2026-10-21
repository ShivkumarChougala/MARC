async function loadComponents() {
  const placeholders = [...document.querySelectorAll('[data-component]')];
  try {
    const sections = await Promise.all(placeholders.map(async node => {
      const response = await fetch(`/components/${node.dataset.component}.html?v=nav-20261021`);
      if (!response.ok) throw new Error(`Section unavailable: ${node.dataset.component}`);
      return response.text();
    }));
    placeholders.forEach((node, index) => { node.outerHTML = sections[index]; });
    const script = document.createElement('script');
    script.src = '/js/main.js?v=20261022014615792243';
    document.body.append(script);
    if (location.hash) document.getElementById(location.hash.slice(1))?.scrollIntoView();
  } catch (error) {
    console.error(error);
    const message = document.createElement('p');
    message.textContent = 'MARC could not load. Please refresh the page.';
    message.setAttribute('role', 'alert');
    document.body.prepend(message);
  }
}
loadComponents();
