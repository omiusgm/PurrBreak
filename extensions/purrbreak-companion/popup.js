const DEFAULT_SETTINGS = {
  youtubeHideShorts: true,
  youtubeHideHomepage: false,
  youtubeHideSidebar: true,
  youtubeHideComments: false,
  youtubeHideEndWall: true,
  youtubeDisableAutoplay: true,
  youtubeFocusMode: false,
  instagramHideReels: true,
  instagramHideExplore: false,
  instagramHideSuggested: true
};

const controls = Array.from(document.querySelectorAll("[data-setting]"));

chrome.storage.sync.get(DEFAULT_SETTINGS, (settings) => {
  for (const control of controls) {
    const key = control.dataset.setting;
    control.checked = Boolean(settings[key]);
  }
});

for (const control of controls) {
  control.addEventListener("change", () => {
    chrome.storage.sync.set({
      [control.dataset.setting]: control.checked
    });
  });
}
