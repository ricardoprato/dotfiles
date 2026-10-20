chrome.commands.onCommand.addListener((command) => {
  if (command !== 'copy-url') return;

  chrome.tabs.query({ active: true, currentWindow: true }, ([tab]) => {
    if (!tab) return;

    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      args: [tab.url],
      func: (url) => {
        // execCommand fallback for when the async Clipboard API is blocked
        // (http page, no document focus, or no transient activation).
        const viaExecCommand = () => {
          const ta = document.createElement('textarea');
          ta.value = url;
          ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0';
          document.body.appendChild(ta);
          ta.focus();
          ta.select();
          let ok = false;
          try { ok = document.execCommand('copy'); } catch (e) {}
          ta.remove();
          return ok;
        };

        // Return the promise so executeScript awaits the real result.
        if (navigator.clipboard && navigator.clipboard.writeText) {
          return navigator.clipboard.writeText(url).then(() => true, () => viaExecCommand());
        }
        return viaExecCommand();
      }
    }).then((results) => {
      const ok = results && results[0] && results[0].result;
      chrome.notifications.create({
        type: 'basic',
        iconUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
        title: ok ? '   URL copied to clipboard' : '   Could not copy URL',
        message: ok ? '' : 'Clipboard blocked — try clicking the page first'
      });
    });
  });
});
