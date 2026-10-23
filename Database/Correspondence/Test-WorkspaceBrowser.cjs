/* Browser regression checks for the workspace assets using a mocked Web Forms lifecycle.
   No application data, credentials, network service or package installation is needed.
   node Test-WorkspaceBrowser.cjs [playwright module directory] [Chromium executable]
   Real ASP.NET/SQL integration is covered separately by Test-Workspace.ps1. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.argv[2] || 'playwright');
const project = path.resolve(__dirname, '../..');
const readAsset = file => fs.readFileSync(path.join(project, 'Portal/assets', file), 'utf8');

async function run() {
  const browser = await chromium.launch({ headless: true, ...(process.argv[3] ? { executablePath: process.argv[3] } : {}) });
  try {
    const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
    await page.route('https://correspondence.test/**', route => route.fulfill({ contentType: 'text/html', body: '<html></html>' }));
    await page.goto('https://correspondence.test/Modules/Correspondence/ManageCorrespondence.aspx?ID=1');
    await page.setContent(`<html dir="rtl"><body><form><div id="correspondence-workspace" data-thread="1" data-scope="personal" data-draft="synthetic-draft" data-select-target="select">
      ${['hfThread', 'hfVisible', 'hfNavigation', 'hfDraftText', 'hfSendSucceeded'].map(id => `<input type="hidden" id="${id}" value="${id === 'hfDraftText' ? '{}' : '0'}">`).join('')}
      <div class="correspondence-layout"><aside class="correspondence-sidebar"><details class="correspondence-filters"><summary>فلاتر البحث</summary><div>خيارات</div></details><div id="correspondence-thread-list"><a class="correspondence-thread" data-thread-id="1">الأولى</a><a class="correspondence-thread" data-thread-id="2">الثانية</a></div></aside>
      <main class="correspondence-main"><div id="upConversation"><div id="correspondence-sync" data-thread="1" data-reply="1" data-close="1" data-queued="0"></div>
      <div class="correspondence-conversation"><header class="correspondence-header">عنوان المحادثة</header><div class="correspondence-message-area"><div id="correspondence-messages">
      ${Array.from({ length: 18 }, (_, index) => `<div class="correspondence-message is-other" data-message-id="${index + 1}"><div class="correspondence-message-content"><div class="correspondence-bubble">رسالة ${index + 1}<br>نص الرسالة</div></div></div>`).join('')}
      </div><button type="button" id="correspondence-new-messages" hidden>رسائل جديدة</button></div></div><div id="correspondence-empty" hidden>اختر محادثة</div></div>
      <div id="correspondence-compose"><div id="correspondence-live-note" hidden></div><div id="pnlCompose"><textarea id="txtReply"></textarea><button type="button" id="btnSend">إرسال</button><button type="button" id="btnCloseStart">إغلاق</button><span id="AttachmentUpload"><div class="ajax__fileupload"></div></span></div></div></main></div></div></form></body></html>`);
    await page.addStyleTag({ content: ':root{--erp-surface:#fff;--erp-border:#ddd;--erp-bg:#f4f5f9;--erp-text:#111;--erp-primary:#3056b9;--erp-primary-soft:#edf2ff}' + readAsset('css/correspondence-chat.css') });
    await page.addScriptTag({ content: `
      window.fake = { init: [], end: [], running: false, calls: 0, upload: { _filesInQueue: [], _isUploading: false } };
      fake.get_isInAsyncPostBack = () => fake.running;
      fake.add_initializeRequest = handler => fake.init.push(handler);
      fake.add_endRequest = handler => fake.end.push(handler);
      window.Sys = { WebForms: { PageRequestManager: { getInstance: () => fake } }, Application: { add_load: () => {} } };
      window.$find = id => id === 'AttachmentUpload' ? fake.upload : null;
      window.__doPostBack = source => {
        let cancelled = false;
        fake.init.forEach(handler => handler(null, { get_postBackElement: () => ({ id: source }), set_cancel: value => cancelled = value }));
        if (!cancelled) { fake.running = true; fake.calls++; }
      };
      window.finish = (id, options = {}) => {
        fake.running = false;
        document.getElementById('correspondence-sync').dataset.thread = String(id);
        if (options.replace) {
          const old = document.getElementById('txtReply'), replacement = old.cloneNode();
          replacement.value = ''; old.replaceWith(replacement);
        }
        document.getElementById('hfSendSucceeded').value = options.sent ? '1' : '0';
        fake.end.forEach(handler => handler(null, { get_error: () => options.error ? new Error('Synthetic failure') : null, set_errorHandled: () => {} }));
      };
    ` });
    await page.addScriptTag({ content: readAsset('js/correspondence-chat.js') });

    await page.fill('#txtReply', 'مسودة الأولى');
    await page.evaluate(() => CorrespondenceChat.select('2'));
    assert.equal(await page.$eval('#txtReply', node => node.readOnly), true);
    await page.evaluate(() => finish(2, { replace: true }));
    await page.fill('#txtReply', 'مسودة الثانية');
    await page.evaluate(() => CorrespondenceChat.select('1'));
    await page.evaluate(() => finish(1, { replace: true }));
    assert.equal(await page.inputValue('#txtReply'), 'مسودة الأولى');
    console.log('PASS: Switching restores independent per-thread drafts.');

    await page.evaluate(() => fake.upload._filesInQueue = [{ _isUploaded: false }]);
    const calls = await page.evaluate(() => fake.calls);
    await page.evaluate(() => CorrespondenceChat.select('2'));
    assert.equal(await page.evaluate(() => fake.calls), calls);
    assert.equal(await page.inputValue('#hfThread'), '1');
    await page.evaluate(() => __doPostBack('tmCorrespondenceCount'));
    assert.equal(await page.evaluate(() => fake.calls), calls);
    await page.evaluate(() => fake.upload._filesInQueue = []);
    console.log('PASS: Pending uploads block switching and background refresh.');

    await page.evaluate(() => __doPostBack('btnSend'));
    assert.equal(await page.$eval('#txtReply', node => node.disabled), false);
    await page.evaluate(() => finish(1, { replace: true, error: true }));
    assert.equal(await page.inputValue('#txtReply'), 'مسودة الأولى');
    await page.evaluate(() => __doPostBack('btnSend'));
    await page.evaluate(() => finish(1, { replace: true, sent: true }));
    assert.equal(await page.inputValue('#txtReply'), '');
    assert.equal(JSON.parse(await page.inputValue('#hfDraftText'))['2'], 'مسودة الثانية');
    console.log('PASS: Send errors preserve drafts; confirmed sends clear only their own draft.');

    await page.fill('#txtReply', 'قبل التحديث');
    await page.evaluate(() => __doPostBack('tmCorrespondenceCount'));
    await page.fill('#txtReply', 'أثناء التحديث');
    await page.evaluate(() => finish(1));
    assert.equal(await page.inputValue('#txtReply'), 'أثناء التحديث');
    await page.evaluate(() => __doPostBack('btnClearUploads'));
    await page.fill('#txtReply', 'كتابة خلال مسح المرفقات');
    await page.evaluate(() => finish(1, { replace: true }));
    assert.equal(await page.inputValue('#txtReply'), 'كتابة خلال مسح المرفقات');
    console.log('PASS: Typing survives both timer refresh and a delayed composer replacement.');

    await page.$eval('#correspondence-messages', node => { node.scrollTop = 0; node.dispatchEvent(new Event('scroll')); });
    await page.evaluate(() => __doPostBack('tmCorrespondenceCount'));
    await page.$eval('#correspondence-messages', node => {
      const message = document.createElement('div');
      message.className = 'correspondence-message is-other'; message.dataset.messageId = '100'; message.textContent = 'رسالة جديدة'; node.appendChild(message);
    });
    await page.evaluate(() => finish(1));
    assert.equal(await page.$eval('#correspondence-new-messages', node => node.hidden), false);
    await page.evaluate(() => __doPostBack('tmCorrespondenceCount'));
    await page.$eval('#correspondence-new-messages', node => node.replaceWith(node.cloneNode()));
    await page.evaluate(() => finish(1));
    assert.equal(await page.$eval('#correspondence-new-messages', node => node.hidden), false);
    await page.click('#correspondence-new-messages');
    assert.equal(await page.$eval('#correspondence-new-messages', node => node.hidden), true);
    console.log('PASS: Incoming-message indicator survives later refreshes until acknowledged.');

    const pausedAt = await page.evaluate(() => fake.calls);
    await page.$eval('.correspondence-filters', node => node.open = true);
    await page.evaluate(() => __doPostBack('tmCorrespondenceCount'));
    assert.equal(await page.evaluate(() => fake.calls), pausedAt);
    await page.$eval('.correspondence-filters', node => node.open = false);
    const geometry = await page.evaluate(() => {
      const area = document.getElementById('correspondence-messages'), compose = document.getElementById('correspondence-compose'), layout = document.querySelector('.correspondence-layout');
      return { scrolls: area.scrollHeight > area.clientHeight, composeBottom: compose.getBoundingClientRect().bottom, layoutBottom: layout.getBoundingClientRect().bottom };
    });
    assert.equal(geometry.scrolls, true);
    assert.ok(geometry.composeBottom <= geometry.layoutBottom + 1);
    await page.setViewportSize({ width: 390, height: 844 });
    assert.equal(await page.$eval('.correspondence-sidebar', node => getComputedStyle(node).display), 'none');
    await page.evaluate(() => { CorrespondenceChat.select('0'); finish(0, { replace: true }); });
    assert.notEqual(await page.$eval('.correspondence-sidebar', node => getComputedStyle(node).display), 'none');
    assert.equal(await page.$eval('.correspondence-main', node => getComputedStyle(node).display), 'none');
    console.log('PASS: Filters pause refresh; messages scroll independently; mobile list/thread layout is preserved.');

    await page.evaluate(() => {
      const root = document.getElementById('correspondence-workspace'); root.dataset.scope = 'all'; root.classList.add('is-supervisory');
      CorrespondenceChat.select('1'); finish(1, { replace: true });
      CorrespondenceChat.select('0', 'https://correspondence.test/Modules/Correspondence/ManageCorrespondence.aspx'); finish(0, { replace: true });
    });
    assert.equal(new URL(page.url()).searchParams.get('scope'), 'all');
    assert.notEqual(await page.$eval('.correspondence-sidebar', node => getComputedStyle(node).display), 'none');
    console.log('PASS: Supervisory Back retains scope in both layout and URL.');
  } finally {
    await browser.close();
  }
}
run().catch(error => { console.error(error); process.exitCode = 1; });
