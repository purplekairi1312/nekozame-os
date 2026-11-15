// nekozame music's card in steam's quick access menu (the ··· button): what's playing,
// with previous, play/pause and next. nekozame-steam-theme puts it there; it talks to
// nekozame-tunes-player on this machine. it hides when nothing's playing.
(function () {
  if (window.__nekozameMusic) return;
  window.__nekozameMusic = true;
  const API = "http://127.0.0.1:47820";
  const card = document.createElement("div");
  card.id = "nekozame-music";
  card.innerHTML = `
    <div class="nzm-text"><div class="nzm-title"></div><div class="nzm-artist"></div></div>
    <div class="nzm-buttons">
      <button data-do="prev" aria-label="previous"><svg viewBox="0 0 24 24"><path d="M6 5h2v14H6zM20 5v14L9 12z"/></svg></button>
      <button data-do="toggle" aria-label="play or pause"><svg viewBox="0 0 24 24" class="nzm-pp"></svg></button>
      <button data-do="next" aria-label="next"><svg viewBox="0 0 24 24"><path d="M16 5h2v14h-2zM4 5v14l11-7z"/></svg></button>
    </div>`;
  const style = document.createElement("style");
  style.textContent = `
    #nekozame-music { position: fixed; left: 12px; right: 12px; bottom: 12px; z-index: 99999; display: none;
      align-items: center; gap: 10px; padding: 10px 12px; border-radius: 16px; background: #433a55;
      border: 1px solid #ffc0e5; box-shadow: 0 6px 18px rgba(0,0,0,.35); font-family: "Motiva Sans", sans-serif; }
    #nekozame-music .nzm-text { flex: 1; min-width: 0; }
    #nekozame-music .nzm-title { color: #ffc0e5; font-weight: 700; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    #nekozame-music .nzm-artist { color: #e8def5; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    #nekozame-music .nzm-buttons { display: flex; gap: 6px; }
    #nekozame-music button { width: 40px; height: 40px; border-radius: 20px; border: 0; background: #685c7f; padding: 9px; }
    #nekozame-music button:active, #nekozame-music button:focus { background: #ffc0e5; }
    #nekozame-music svg { width: 22px; height: 22px; fill: #ffffff; display: block; }
    #nekozame-music button:active svg, #nekozame-music button:focus svg { fill: #433a55; }`;
  document.head.appendChild(style);
  document.body.appendChild(card);
  const $ = (q) => card.querySelector(q);
  const show = (st) => {
    if (!st || st.idle) { card.style.display = "none"; return; }
    card.style.display = "flex";
    $(".nzm-title").textContent = st.title || "";
    $(".nzm-artist").textContent = st.artist || "";
    $(".nzm-pp").innerHTML = st.paused ? '<path d="M7 4v16l13-8z"/>' : '<path d="M6 4h4v16H6zM14 4h4v16h-4z"/>';
  };
  const call = (path) => fetch(API + path).then((r) => r.json()).then(show).catch(() => show(null));
  card.addEventListener("click", (e) => { const b = e.target.closest("button"); if (b) call("/" + b.dataset.do); });
  call("/state");
  setInterval(() => call("/state"), 1500);
})();
