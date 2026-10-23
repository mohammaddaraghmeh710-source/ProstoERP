// Browser regression contract. Run with the CUA tab already authenticated and on a detail page.
// The caller repeats this at desktop/mobile sizes for news, customer pages and employee pages.
export async function checkDetailLanguage(tab) {
  const read = () => tab.playwright.evaluate(() => {
    const root = document.querySelector('[data-detail-language]');
    if (!root) throw new Error('Authorized bilingual detail root missing');
    const language = root.getAttribute('data-detail-language');
    const header = root.querySelector('[data-detail-header]');
    const metadata = root.querySelector('[data-detail-metadata]');
    const button = root.querySelector('[data-detail-language-toggle]');
    const visible = element => !!element && getComputedStyle(element).display !== 'none' && element.getClientRects().length > 0;
    const parts = Array.from(root.querySelectorAll('[data-detail-lang]')).map(element => ({
      language: element.getAttribute('data-detail-lang'), visible: visible(element),
      title: element.hasAttribute('data-detail-title'), text: element.textContent.trim(), dir: element.getAttribute('dir')
    }));
    return {language, parts, headerDir: header?.getAttribute('dir'), headerAlign: header ? getComputedStyle(header).textAlign : null, metadataDir: metadata ? getComputedStyle(metadata).direction : null, title: document.title, buttonType: button?.getAttribute('type'),
      href: button?.getAttribute('href'), onclick: button?.getAttribute('onclick')};
  });
  await tab.playwright.locator('[data-detail-language-toggle][aria-label]').waitFor({state: 'visible'});
  const initialUrl = await tab.url();
  const initial = await read();
  function verify(state, language) {
    if (state.language !== language) throw new Error('Language state did not change');
    const direction = language === 'en' ? 'ltr' : 'rtl';
    if (state.headerDir !== direction || state.metadataDir !== direction || state.headerAlign !== (language === 'en' ? 'left' : 'right')) throw new Error('Header/title/date direction did not switch');
    if (state.buttonType !== 'button' || state.href || state.onclick) throw new Error('Toggle must remain a local non-submit button');
    const title = state.parts.find(part => part.title && part.language === language);
    if (!title?.visible || !title.text || state.title !== title.text) throw new Error('Visible/document title did not switch');
    if (!state.parts.some(part => !part.title && part.language === language && part.visible && part.text)) throw new Error('Visible translated content missing');
    if (state.parts.some(part => part.language !== language && part.visible)) throw new Error('Opposite-language content is still visible');
    if (state.parts.some(part => part.language === language && part.dir && part.dir !== (language === 'en' ? 'ltr' : 'rtl'))) throw new Error('Content direction mismatch');
  }
  verify(initial, initial.language);
  for (const language of [initial.language === 'ar' ? 'en' : 'ar', initial.language]) {
    await tab.playwright.locator('[data-detail-language-toggle]').click();
    await tab.playwright.locator('[data-detail-language="' + language + '"]').waitFor({state: 'visible'});
    verify(await read(), language);
    if (await tab.url() !== initialUrl) throw new Error('Language toggle changed the URL');
  }
  return {url: initialUrl, directions: 'ar↔en', passed: true};
}
