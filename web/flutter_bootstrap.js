{{flutter_js}}
{{flutter_build_config}}

(function () {
  const loading = document.getElementById('loading');
  const status = document.getElementById('loading-status');

  function setStatus(text) {
    if (status) status.textContent = text;
  }

  _flutter.loader.load({
    config: {
      // Keep bundled CanvasKit for school networks that block external CDNs.
      useLocalCanvasKit: true,
    },
    onEntrypointLoaded: async function (engineInitializer) {
      setStatus('アプリを準備しています…');
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      if (loading) {
        loading.classList.add('loading-hidden');
        window.setTimeout(function () {
          loading.remove();
        }, 400);
      }
    },
  });
})();
