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

const STYLE_ID = "purrbreak-companion-style";
const STATE_PREFIX = "data-purrbreak-";
let settings = { ...DEFAULT_SETTINGS };
let lastURL = location.href;
let observer = null;
let autoplayTimer = null;

init();

function init() {
  installStyles();
  loadSettings().then((loadedSettings) => {
    settings = loadedSettings;
    applySettings();
    observePage();
  });

  chrome.storage.onChanged.addListener((changes, areaName) => {
    if (areaName !== "sync") {
      return;
    }

    for (const [key, change] of Object.entries(changes)) {
      if (key in DEFAULT_SETTINGS) {
        settings[key] = change.newValue;
      }
    }

    applySettings();
  });
}

function loadSettings() {
  return new Promise((resolve) => {
    chrome.storage.sync.get(DEFAULT_SETTINGS, (storedSettings) => {
      resolve({ ...DEFAULT_SETTINGS, ...storedSettings });
    });
  });
}

function installStyles() {
  if (document.getElementById(STYLE_ID)) {
    return;
  }

  const style = document.createElement("style");
  style.id = STYLE_ID;
  style.textContent = `
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-rich-section-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-reel-shelf-renderer,
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-video-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-grid-video-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-rich-item-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-guide-entry-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytd-mini-guide-entry-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-hide-shorts="true"] ytm-reel-shelf-renderer,
    html[data-purrbreak-youtube-hide-shorts="true"] ytm-rich-section-renderer:has(a[href*="/shorts"]) {
      display: none !important;
    }

    html[data-purrbreak-youtube-home="true"][data-purrbreak-youtube-hide-homepage="true"] ytd-browse[page-subtype="home"],
    html[data-purrbreak-youtube-home="true"][data-purrbreak-youtube-hide-homepage="true"] ytm-browse {
      display: none !important;
    }

    html[data-purrbreak-youtube-hide-sidebar="true"] #secondary,
    html[data-purrbreak-youtube-hide-sidebar="true"] ytd-watch-next-secondary-results-renderer,
    html[data-purrbreak-youtube-hide-sidebar="true"] ytd-compact-video-renderer,
    html[data-purrbreak-youtube-hide-sidebar="true"] ytd-compact-radio-renderer,
    html[data-purrbreak-youtube-hide-sidebar="true"] ytd-compact-playlist-renderer,
    html[data-purrbreak-youtube-hide-sidebar="true"] ytm-item-section-renderer:has(ytm-compact-video-renderer) {
      display: none !important;
    }

    html[data-purrbreak-youtube-hide-comments="true"] #comments,
    html[data-purrbreak-youtube-hide-comments="true"] ytd-comments,
    html[data-purrbreak-youtube-hide-comments="true"] ytm-comment-section-renderer {
      display: none !important;
    }

    html[data-purrbreak-youtube-hide-end-wall="true"] .ytp-endscreen-content,
    html[data-purrbreak-youtube-hide-end-wall="true"] .html5-endscreen,
    html[data-purrbreak-youtube-hide-end-wall="true"] .ytp-ce-element,
    html[data-purrbreak-youtube-hide-end-wall="true"] .ytp-suggestion-set {
      display: none !important;
    }

    html[data-purrbreak-youtube-focus-mode="true"] ytd-browse[page-subtype="home"],
    html[data-purrbreak-youtube-focus-mode="true"] #secondary,
    html[data-purrbreak-youtube-focus-mode="true"] #comments,
    html[data-purrbreak-youtube-focus-mode="true"] ytd-comments,
    html[data-purrbreak-youtube-focus-mode="true"] ytd-guide-renderer,
    html[data-purrbreak-youtube-focus-mode="true"] ytd-mini-guide-renderer,
    html[data-purrbreak-youtube-focus-mode="true"] ytd-reel-shelf-renderer,
    html[data-purrbreak-youtube-focus-mode="true"] ytd-rich-section-renderer:has(a[href*="/shorts"]),
    html[data-purrbreak-youtube-focus-mode="true"] ytd-masthead #end {
      display: none !important;
    }

    html[data-purrbreak-instagram-hide-reels="true"] a[href^="/reels/"],
    html[data-purrbreak-instagram-hide-reels="true"] a[href="/reels/"],
    html[data-purrbreak-instagram-hide-reels="true"] a[href*="/reel/"],
    html[data-purrbreak-instagram-hide-reels="true"] div:has(> a[href^="/reels/"]) {
      display: none !important;
    }

    html[data-purrbreak-instagram-hide-explore="true"] a[href="/explore/"],
    html[data-purrbreak-instagram-hide-explore="true"] div:has(> a[href="/explore/"]) {
      display: none !important;
    }

    html[data-purrbreak-instagram-hide-suggested="true"] aside,
    html[data-purrbreak-instagram-hide-suggested="true"] main section:has(a[href*="/explore/people/"]) {
      display: none !important;
    }
  `;

  (document.head || document.documentElement).appendChild(style);
}

function observePage() {
  observer?.disconnect();
  observer = new MutationObserver(() => {
    if (location.href !== lastURL) {
      lastURL = location.href;
      updateRouteState();
    }

    if (isYouTube() && settings.youtubeDisableAutoplay) {
      disableYouTubeAutoplaySoon();
    }
  });

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true
  });
}

function applySettings() {
  updateBooleanAttribute("youtube-hide-shorts", settings.youtubeHideShorts || settings.youtubeFocusMode);
  updateBooleanAttribute("youtube-hide-homepage", settings.youtubeHideHomepage || settings.youtubeFocusMode);
  updateBooleanAttribute("youtube-hide-sidebar", settings.youtubeHideSidebar || settings.youtubeFocusMode);
  updateBooleanAttribute("youtube-hide-comments", settings.youtubeHideComments || settings.youtubeFocusMode);
  updateBooleanAttribute("youtube-hide-end-wall", settings.youtubeHideEndWall || settings.youtubeFocusMode);
  updateBooleanAttribute("youtube-focus-mode", settings.youtubeFocusMode);
  updateBooleanAttribute("instagram-hide-reels", settings.instagramHideReels);
  updateBooleanAttribute("instagram-hide-explore", settings.instagramHideExplore);
  updateBooleanAttribute("instagram-hide-suggested", settings.instagramHideSuggested);
  updateRouteState();

  if (isYouTube() && settings.youtubeDisableAutoplay) {
    disableYouTubeAutoplaySoon();
  }
}

function updateBooleanAttribute(name, value) {
  document.documentElement.setAttribute(`${STATE_PREFIX}${name}`, value ? "true" : "false");
}

function updateRouteState() {
  const path = location.pathname.replace(/\/+$/, "");
  updateBooleanAttribute("youtube-home", isYouTube() && (path === "" || path === "/"));
}

function isYouTube() {
  return /(^|\.)youtube\.com$/i.test(location.hostname);
}

function disableYouTubeAutoplaySoon() {
  clearTimeout(autoplayTimer);
  autoplayTimer = setTimeout(disableYouTubeAutoplay, 250);
}

function disableYouTubeAutoplay() {
  const toggle = document.querySelector(".ytp-autonav-toggle-button[aria-checked='true']");
  if (toggle instanceof HTMLElement) {
    toggle.click();
  }
}
