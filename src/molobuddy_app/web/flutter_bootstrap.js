{{flutter_js}}
{{flutter_build_config}}

const moloBootstrap = document.getElementById('molo-bootstrap');

function removeMoloBootstrap() {
  if (!moloBootstrap) return;

  moloBootstrap.classList.add('is-leaving');
  window.setTimeout(() => moloBootstrap.remove(), 220);
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(removeMoloBootstrap);
    });
  },
});
