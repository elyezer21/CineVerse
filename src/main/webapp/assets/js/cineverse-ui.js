/* =====================================================================
   CineVerse — comportamiento compartido por todas las páginas
   - Menú hamburguesa en pantallas pequeñas
   - Fondo de la barra al hacer scroll
   - Muestra u oculta las opciones de cuenta según haya sesión
   - Cerrar sesión desde el pie de página en cualquier página
   ===================================================================== */
(function () {
  var nav = document.getElementById('navbar');
  var user = null;
  try { user = JSON.parse(localStorage.getItem('user') || 'null'); } catch (e) { user = null; }
  var logueado = !!(localStorage.getItem('token') && user);

  // Clase en <body> para mostrar "Regístrate / Inicia sesión" o "Mi perfil / Cerrar sesión"
  document.body.classList.add(logueado ? 'cv-user' : 'cv-guest');

  if (nav) {
    // Menú hamburguesa
    var toggle = nav.querySelector('.nav-toggle');
    if (toggle) {
      toggle.addEventListener('click', function () {
        var abierto = nav.classList.toggle('nav-open');
        toggle.setAttribute('aria-expanded', abierto ? 'true' : 'false');
        toggle.setAttribute('aria-label', abierto ? 'Cerrar menú' : 'Abrir menú');
      });
      // Cierra el menú al elegir una opción o al pasar a pantalla grande
      nav.querySelectorAll('.nav-links a').forEach(function (a) {
        a.addEventListener('click', function () { nav.classList.remove('nav-open'); toggle.setAttribute('aria-expanded', 'false'); });
      });
      window.addEventListener('resize', function () {
        if (window.innerWidth > 900) { nav.classList.remove('nav-open'); toggle.setAttribute('aria-expanded', 'false'); }
      });
    }
    // Fondo de la barra al hacer scroll
    var alHacerScroll = function () { nav.classList.toggle('scrolled', window.scrollY > 40); };
    window.addEventListener('scroll', alHacerScroll, { passive: true });
    alHacerScroll();
  }

  // Cerrar sesión desde el pie de página (perfil.html tiene su propio botón con confirmación)
  document.querySelectorAll('.logout-btn').forEach(function (btn) {
    if (btn.id === 'logoutBtnFooter') return;
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = 'login.html';
    });
  });
})();

/* =====================================================================
   CV: tarjetas de película compartidas (estilo "Minimal")
   Uso: CV.cardHTML(pelicula) · CV.skeleton(n) · CV.bindCards(contenedor)
   ===================================================================== */
window.CV = (function () {
  var IMG = 'https://image.tmdb.org/t/p/';
  var ICON_PLAY = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M8 5v14l11-7z"/></svg>';
  var ICON_HEART = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1.1L12 21l7.8-7.5 1-1.1a5.5 5.5 0 0 0 0-7.8z"/></svg>';
  var favIds = new Set();

  function esc(t) {
    return String(t == null ? '' : t).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function usuario() {
    try { return localStorage.getItem('token') ? JSON.parse(localStorage.getItem('user') || 'null') : null; } catch (e) { return null; }
  }

  // Normaliza una película de TMDB o de la tabla favoritos
  function norm(m) {
    return {
      id: m.id != null ? m.id : m.tmdb_id,
      title: m.title || m.titulo || 'Sin título',
      poster: m.poster_path || '',
      year: (m.release_date || '').slice(0, 4),
      rating: typeof m.vote_average === 'number' && m.vote_average > 0 ? m.vote_average.toFixed(1) : ''
    };
  }

  function cardHTML(m, opts) {
    opts = opts || {};
    var p = norm(m);
    var href = 'reproductor.html?id=' + encodeURIComponent(p.id);
    var img = p.poster
      ? '<img src="' + IMG + 'w342' + esc(p.poster) + '" srcset="' + IMG + 'w342' + esc(p.poster) + ' 342w, ' + IMG + 'w500' + esc(p.poster) + ' 500w, ' + IMG + 'w780' + esc(p.poster) + ' 780w" sizes="(max-width: 600px) 46vw, 220px" alt="Póster de ' + esc(p.title) + '" loading="lazy" decoding="async">'
      : '<img src="assets/sin-poster.svg" alt="Sin póster disponible">';
    var esFav = opts.fav || favIds.has(Number(p.id));
    var meta = '';
    if (p.year || p.rating) {
      meta = '<div class="cv-card-meta"><span>' + esc(p.year) + '</span>' + (p.rating ? '<span class="cv-card-rate">★ ' + p.rating + '</span>' : '') + '</div>';
    }
    return '<article class="cv-card" data-id="' + esc(p.id) + '" data-title="' + esc(p.title) + '" data-poster="' + esc(p.poster) + '">' +
      '<div class="cv-card-media">' +
        '<a class="cv-card-link" href="' + href + '" tabindex="-1" aria-hidden="true">' + img + '</a>' +
        '<div class="cv-card-glass">' +
          '<a class="cv-play" href="' + href + '" aria-label="Ver ' + esc(p.title) + '">' + ICON_PLAY + '</a>' +
          '<button type="button" class="cv-fav' + (esFav ? ' is-fav' : '') + '" aria-pressed="' + esFav + '" aria-label="' + (esFav ? 'Quitar de favoritos' : 'Añadir a favoritos') + '">' + ICON_HEART + '</button>' +
        '</div>' +
      '</div>' +
      '<div class="cv-card-body"><a class="cv-card-title" href="' + href + '">' + esc(p.title) + '</a>' + meta + '</div>' +
    '</article>';
  }

  function skeleton(n) {
    var h = '';
    for (var i = 0; i < n; i++) {
      h += '<div class="cv-card is-skeleton" aria-hidden="true"><div class="cv-card-media"></div><div class="cv-skel-line"></div><div class="cv-skel-line short"></div></div>';
    }
    return h;
  }

  var toastBox;
  function toast(msg, isError) {
    if (!toastBox) { toastBox = document.createElement('div'); toastBox.className = 'cv-toast-box'; toastBox.setAttribute('role', 'status'); document.body.appendChild(toastBox); }
    var t = document.createElement('div');
    t.className = 'cv-toast' + (isError ? ' is-error' : '');
    t.textContent = msg;
    toastBox.appendChild(t);
    setTimeout(function () { t.remove(); }, 2600);
  }

  // Carga los ids de las películas favoritas del usuario (para pintar el corazón)
  function loadFavIds() {
    var u = usuario();
    if (!u) return Promise.resolve(favIds);
    return fetch('api/favoritos.jsp?usuarioId=' + u.id)
      .then(function (r) { return r.ok ? r.json() : []; })
      .then(function (lista) { favIds = new Set((lista || []).map(function (f) { return Number(f.tmdb_id); })); return favIds; })
      .catch(function () { return favIds; });
  }

  function setFav(btn, on) {
    btn.classList.toggle('is-fav', on);
    btn.setAttribute('aria-pressed', on);
    btn.setAttribute('aria-label', on ? 'Quitar de favoritos' : 'Añadir a favoritos');
  }

  // Agrega o quita la película de favoritos usando api/favoritos.jsp
  function toggleFav(card, btn, onRemoved) {
    var u = usuario();
    if (!u) {
      toast('Inicia sesión para guardar tus favoritos');
      setTimeout(function () { window.location.href = 'login.html'; }, 900);
      return;
    }
    var id = Number(card.dataset.id), title = card.dataset.title, quitar = btn.classList.contains('is-fav');
    var body = quitar
      ? { usuarioId: u.id, movieId: id, action: 'remove' }
      : { usuarioId: u.id, movieId: id, movieTitle: title, posterPath: card.dataset.poster };
    btn.disabled = true;
    fetch('api/favoritos.jsp', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) })
      .then(function (r) { return r.json().catch(function () { return {}; }).then(function (d) { return { ok: r.ok, d: d }; }); })
      .then(function (res) {
        if (!res.ok) throw new Error(res.d.message || 'Error del servidor');
        if (quitar) { favIds.delete(id); setFav(btn, false); toast('«' + title + '» se quitó de tus favoritos'); if (onRemoved) onRemoved(card); }
        else { favIds.add(id); setFav(btn, true); toast(res.d.action === 'exists' ? '«' + title + '» ya estaba en tus favoritos' : '«' + title + '» se añadió a tus favoritos'); }
      })
      .catch(function (e) { toast('No se pudo actualizar favoritos: ' + e.message, true); })
      .then(function () { btn.disabled = false; });
  }

  // Activa las imágenes (aparición suave) y los corazones de un contenedor
  function bindCards(container, opts) {
    opts = opts || {};
    container.querySelectorAll('.cv-card-media img').forEach(function (img) {
      var listo = function () { img.classList.add('is-loaded'); };
      if (img.complete && img.naturalWidth) listo(); else img.addEventListener('load', listo);
      img.addEventListener('error', function () { img.removeAttribute('srcset'); img.src = 'assets/sin-poster.svg'; listo(); }, { once: true });
    });
    if (container.dataset.cvBound) return;
    container.dataset.cvBound = '1';
    container.addEventListener('click', function (e) {
      var btn = e.target.closest('.cv-fav');
      if (!btn || !container.contains(btn)) return;
      e.preventDefault();
      toggleFav(btn.closest('.cv-card'), btn, opts.onRemoved);
    });
  }

  return { cardHTML: cardHTML, skeleton: skeleton, bindCards: bindCards, loadFavIds: loadFavIds, toast: toast };
})();
