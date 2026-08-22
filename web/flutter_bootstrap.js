{{flutter_js}}
{{flutter_build_config}}

(function () {
  const loading = document.getElementById('loading');
  const status = document.getElementById('loading-status');

  function setStatus(text) {
    if (status) status.textContent = text;
  }

  setStatus('アプリ本体を読み込んでいます…');

  _flutter.loader.load({
    config: {
      // Google's CDN is often faster on first visit than self-hosted CanvasKit.
      useLocalCanvasKit: false,
    },
    onEntrypointLoaded: async function (engineInitializer) {
      setStatus('画面を準備しています…');
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
