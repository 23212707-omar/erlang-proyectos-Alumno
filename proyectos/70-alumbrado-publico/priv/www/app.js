'use strict';
/* Interfaz del sistema de alumbrado publico (diseno de Google Stitch).
   Una sola pagina con cuatro vistas (#/, #/falla/ID, #/reportar, #/bitacora) que
   consume la API JSON del backend en Erlang. Todo texto que viene del servidor se
   escapa antes de ponerlo en el HTML. */

const INTERVALO_MS = 5000;
const CUADRILLAS = ['cuadrilla_1', 'cuadrilla_2', 'cuadrilla_3', 'cuadrilla_4'];
const ORDEN_ESTADO = { reportada: 0, asignada: 1, reparada: 2 };
const ORDEN_PRIORIDAD = { alta: 0, media: 1, baja: 2 };

const ESTADOS = {
  reportada: { texto: 'Reportada', icono: 'report', clases: 'bg-error-container text-on-error-container' },
  asignada: { texto: 'Asignada', icono: 'engineering', clases: 'bg-tertiary-fixed text-on-tertiary-fixed' },
  reparada: { texto: 'Reparada', icono: 'task_alt', clases: 'bg-secondary-fixed text-on-secondary-fixed-variant' }
};
const PRIORIDADES = {
  alta: { texto: 'Prioridad alta', icono: 'keyboard_double_arrow_up', clases: 'bg-error-container/60 text-error' },
  media: { texto: 'Prioridad media', icono: 'drag_handle', clases: 'bg-surface-container-highest text-on-surface' },
  baja: { texto: 'Prioridad baja', icono: 'keyboard_arrow_down', clases: 'bg-surface-container-high text-on-surface-variant' }
};

let desfaseReloj = 0;        // diferencia entre el reloj del servidor y el de este navegador
let temporizador = null;
let filtroEstado = 'todas';
let filtroPrioridad = 'todas';
let filtroBitacora = 'todos';
let fallas = [];
let eventos = [];
let puntos = null;           // [[id, lat, lon], ...] del catalogo; se descarga una sola vez
let proyeccion = null;       // convierte lat/lon a coordenadas del SVG
let capaBase = '';           // trazo de las 5,000 luminarias, calculado una sola vez
let seleccion = '';          // luminaria con falla elegida en el mapa
let sim = null;              // estado del simulador (GET /api/simulador)
let sectorEscenario = 0;     // cada clic en "falla de circuito" usa el siguiente sector
const CODIGOS_SECTOR = ['CEN', 'RIO', 'OTA', 'MES', 'SAN', 'EST', 'PLA'];
const RUTAS_SIM = { iniciar: 'iniciar', detener: 'detener', poste: 'escenarios/poste', circuito: 'escenarios/circuito' };

const LUGARES = { avenida: 'Avenida', calle: 'Calle', cruce_escolar: 'Cruce escolar', hospital: 'Hospital', andador: 'Andador' };
/* Contorno APROXIMADO (frontera con EE. UU. y costa del Pacifico) y nombres de sector.
   Son los mismos valores con los que se simula el catalogo; no es cartografia oficial. */
const BORDE = (lon) => 32.534 + (lon + 117.125) * 0.0923;
const COSTA = (lat) => -117.125 + (32.534 - lat) * 0.22;
const SECTORES_MAPA = [   // [nombre, lat, lon, dx, dy, anclaje]
  ['Playas', 32.5170, -117.1050, 8, 52, 'start'],
  ['Centro', 32.5320, -117.0380, -30, 44, 'end'],
  ['Zona Río', 32.5260, -117.0220, 30, -22, 'start'],
  ['La Mesa', 32.5120, -117.0000, 40, 28, 'start'],
  ['Sánchez Taboada', 32.4680, -117.0000, 0, 62, 'middle'],
  ['Otay', 32.5310, -116.9550, 0, 62, 'middle'],
  ['Zona Este', 32.5000, -116.8850, 0, 84, 'middle']
];
const COLOR_ESTADO = { reportada: '#ba1a1a', asignada: '#d97706', reparada: '#4059aa' };

/* ---------- utilidades ---------- */

const $ = (selector) => document.querySelector(selector);

function esc(texto) {
  return String(texto).replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

async function api(metodo, ruta, cuerpo) {
  const opciones = { method: metodo, headers: {} };
  if (cuerpo !== undefined) {
    opciones.headers['content-type'] = 'application/json';
    opciones.body = JSON.stringify(cuerpo);
  }
  try {
    const res = await fetch(ruta, opciones);
    const fecha = res.headers.get('date');
    if (fecha) { desfaseReloj = new Date(fecha).getTime() - Date.now(); }
    let datos = {};
    try { datos = await res.json(); } catch (e) { /* respuesta sin cuerpo JSON */ }
    marcarConexion(true);
    return { ok: res.ok, estado: res.status, datos };
  } catch (e) {
    marcarConexion(false);
    return { ok: false, estado: 0, datos: {} };
  }
}

function marcarConexion(enLinea) {
  $('#texto-conexion').textContent = enLinea ? 'En línea' : 'Sin conexión';
  $('#punto-conexion').className = 'w-1.5 h-1.5 rounded-full ' + (enLinea ? 'bg-secondary-fixed' : 'bg-error');
}

function ahoraSeg() { return (Date.now() + desfaseReloj) / 1000; }

function hace(segundos) {
  const d = Math.max(0, Math.floor(ahoraSeg() - segundos));
  if (d < 60) { return 'hace ' + d + ' s'; }
  if (d < 3600) { return 'hace ' + Math.floor(d / 60) + ' min'; }
  if (d < 86400) { return 'hace ' + Math.floor(d / 3600) + ' h'; }
  return 'hace ' + Math.floor(d / 86400) + ' d';
}

function hora(segundos) {
  return new Date(segundos * 1000).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' });
}

function aviso(texto, error) {
  const caja = $('#aviso');
  const color = error ? 'bg-error text-on-error' : 'bg-inverse-surface text-inverse-on-surface';
  caja.innerHTML = '<div class="rounded-xl px-4 py-3 shadow-lg font-label-lg text-label-lg ' + color + '">' + esc(texto) + '</div>';
  setTimeout(() => { caja.innerHTML = ''; }, 4000);
}

function insignia(clases, icono, texto) {
  return '<span class="inline-flex items-center gap-1 px-2 py-1 rounded-full font-label-sm text-label-sm font-bold ' + clases + '">' +
    '<span class="material-symbols-outlined text-[14px]" aria-hidden="true">' + icono + '</span>' + esc(texto) + '</span>';
}

function insigniaEstado(estado) {
  const e = ESTADOS[estado] || ESTADOS.reportada;
  return insignia(e.clases, e.icono, e.texto);
}

function insigniaPrioridad(prioridad) {
  const p = PRIORIDADES[prioridad] || PRIORIDADES.media;
  return insignia(p.clases, p.icono, p.texto);
}

function textoFuentes(fuentes) {
  const partes = Object.entries(fuentes || {}).map(([nombre, n]) => n + ' ' + nombre);
  return partes.length ? partes.join(' · ') : 'sin fuentes';
}

function ficha(clases, etiqueta, valor, icono) {
  return '<div class="' + clases + ' p-space-sm rounded-xl flex flex-col justify-between shadow-sm">' +
    '<div class="flex items-center justify-between"><span class="font-label-sm text-label-sm font-bold tracking-tight uppercase">' + etiqueta + '</span>' +
    '<span class="material-symbols-outlined text-[18px]" aria-hidden="true">' + icono + '</span></div>' +
    '<span class="font-headline-lg-mobile text-headline-lg-mobile font-bold leading-none my-1">' + valor + '</span></div>';
}

function chip(activo, accion, valor, texto) {
  const clases = activo ? 'bg-primary-container text-on-primary' : 'bg-surface-container-high text-on-surface-variant';
  return '<button type="button" data-accion="' + accion + '" data-valor="' + valor + '" class="px-3 py-1.5 rounded-full font-label-md text-label-md whitespace-nowrap ' + clases + '">' + texto + '</button>';
}

/* ---------- mapa SVG del catalogo ---------- */

function crearProyeccion(lista) {
  let latMin = Infinity, latMax = -Infinity, lonMin = Infinity, lonMax = -Infinity;
  lista.forEach((p) => {
    if (p[1] < latMin) { latMin = p[1]; }
    if (p[1] > latMax) { latMax = p[1]; }
    if (p[2] < lonMin) { lonMin = p[2]; }
    if (p[2] > lonMax) { lonMax = p[2]; }
  });
  lonMin -= 0.045; latMax += 0.04; latMin -= 0.008;                // espacio para el mar y el rotulo de EE. UU.
  const k = Math.cos(((latMin + latMax) / 2) * Math.PI / 180);   // la longitud mide menos que la latitud
  const ancho = 1000, margen = 20;
  const escala = (ancho - 2 * margen) / Math.max((lonMax - lonMin) * k, 1e-9);
  const alto = Math.round((latMax - latMin) * escala + 2 * margen);
  const r1 = (v) => Math.round(v * 10) / 10;
  return { ancho, alto, latMin, latMax, lonMin, lonMax, xy: (lat, lon) => ({ x: r1(margen + (lon - lonMin) * k * escala), y: r1(margen + (latMax - lat) * escala) }) };
}

async function asegurarPuntos() {
  if (puntos) { return true; }
  const r = await api('GET', '/api/catalogo/puntos');
  if (!r.ok || !Array.isArray(r.datos.puntos) || !r.datos.puntos.length) { return false; }
  puntos = r.datos.puntos;
  proyeccion = crearProyeccion(puntos);
  capaBase = puntos.map((p) => { const q = proyeccion.xy(p[1], p[2]); return 'M' + q.x + ' ' + q.y + 'h0'; }).join('');
  return true;
}

/* Fondo del mapa: mar, territorio de EE. UU., territorio mexicano, frontera y nombres. */
function fondoMapa() {
  const p = proyeccion;
  const lonE = p.lonMax + 0.02, latS = p.latMin - 0.02, latN = p.latMax + 0.03;
  const pt = (lat, lon) => { const q = p.xy(lat, lon); return q.x + ',' + q.y; };
  const mexico = [pt(32.534, -117.125), pt(BORDE(lonE), lonE), pt(latS, lonE), pt(latS, COSTA(latS))];
  const eeuu = [pt(latN, -117.14), pt(latN, lonE), pt(BORDE(lonE), lonE), pt(32.534, -117.125)];
  const rotulo = (texto, lat, lon, color) => {
    const q = p.xy(lat, lon);
    return '<text x="' + q.x + '" y="' + q.y + '" fill="' + color + '" font-size="22" font-weight="700" letter-spacing="2" text-anchor="middle">' + texto + '</text>';
  };
  const nombres = SECTORES_MAPA.map((s) => {
    const q = p.xy(s[1], s[2]);
    return '<text x="' + (q.x + s[3]) + '" y="' + (q.y + s[4]) + '" text-anchor="' + s[5] + '" font-size="24" font-weight="700" fill="#264191" ' +
      'stroke="#ffffff" stroke-width="5" paint-order="stroke" stroke-linejoin="round">' + esc(s[0]) + '</text>';
  }).join('');
  return '<rect width="100%" height="100%" fill="#d9e6ff"/><polygon points="' + eeuu.join(' ') + '" fill="#e9eaf2"/>' +
    '<polygon points="' + mexico.join(' ') + '" fill="#ffffff"/>' +
    '<polyline points="' + pt(32.534, -117.125) + ' ' + pt(BORDE(lonE), lonE) + '" fill="none" stroke="#ba1a1a" stroke-width="3" stroke-dasharray="14 8"/>' +
    '<polyline points="' + pt(32.534, -117.125) + ' ' + pt(latS, COSTA(latS)) + '" fill="none" stroke="#7d9be8" stroke-width="4"/>' +
    rotulo('OCÉANO', 32.505, -117.145, '#5f7fcf') + rotulo('PACÍFICO', 32.497, -117.145, '#5f7fcf') + rotulo('ESTADOS UNIDOS', 32.572, -116.99, '#8a8da0') + nombres;
}

/* marcas: [{lat, lon, color, r, titulo, id?, sel?}]. Con id, el punto se puede tocar. */
function mapaSvg(marcas) {
  const dibujadas = marcas.map((m) => {
    const q = proyeccion.xy(m.lat, m.lon);
    const borde = m.sel ? ' stroke="#000d21" stroke-width="4"' : ' stroke="#ffffff" stroke-width="2"';
    const toque = m.id ? ' data-accion="sel-falla" data-id="' + esc(m.id) + '" style="cursor:pointer"' : '';
    return '<circle cx="' + q.x + '" cy="' + q.y + '" r="' + (m.sel ? m.r + 4 : m.r) + '" fill="' + m.color + '"' + borde + toque + '><title>' + esc(m.titulo) + '</title></circle>';
  }).join('');
  return '<svg viewBox="0 0 ' + proyeccion.ancho + ' ' + proyeccion.alto + '" class="w-full h-auto rounded-xl overflow-hidden" style="background:#d9e6ff" role="img" ' +
    'aria-label="Mapa de luminarias de Tijuana (catálogo simulado)">' + fondoMapa() +
    '<path d="' + capaBase + '" fill="none" stroke="#b6c4ff" stroke-width="3" stroke-linecap="round"/>' + dibujadas + '</svg>';
}

function leyendaMapa() {
  const punto = (color, texto) => '<span class="inline-flex items-center gap-1"><span class="inline-block w-2.5 h-2.5 rounded-full" style="background:' + color + '"></span>' + texto + '</span>';
  return '<div class="flex flex-wrap gap-x-space-md gap-y-space-xs font-label-md text-label-md text-on-surface-variant">' +
    punto(COLOR_ESTADO.reportada, 'Reportada') + punto(COLOR_ESTADO.asignada, 'Asignada') + punto(COLOR_ESTADO.reparada, 'Reparada') + punto('#b6c4ff', 'Sin falla') + '</div>' +
    '<div class="font-label-sm text-label-sm text-on-surface-variant">' + puntos.length.toLocaleString('es-MX') + ' luminarias · catálogo simulado, no son datos reales del municipio</div>';
}

function ubicacionTexto(f) {
  return f.direccion ? esc(f.direccion) : '';   // la direccion del catalogo ya termina con el sector
}

/* ---------- rutas ---------- */

function ruta() {
  const partes = (location.hash || '#/').replace(/^#\/?/, '').split('/');
  return { nombre: partes[0] || 'mapa', id: partes[1] ? decodeURIComponent(partes[1]) : '' };
}

function navegar() {
  clearInterval(temporizador);
  temporizador = null;
  const r = ruta();
  const activa = r.nombre === 'falla' ? 'detalle' : r.nombre;
  document.querySelectorAll('[data-nav]').forEach((a) => {
    const esActiva = a.dataset.nav === activa;
    a.classList.toggle('text-primary-container', esActiva);
    a.classList.toggle('font-bold', esActiva);
    a.classList.toggle('text-on-surface-variant', !esActiva);
  });
  const titulos = { mapa: 'Mapa y fallas', falla: 'Detalle de falla', detalle: 'Detalle de falla', reportar: 'Reportar falla', bitacora: 'Bitácora de eventos' };
  $('#titulo-vista').textContent = titulos[r.nombre] || titulos.mapa;
  window.scrollTo(0, 0);

  if (r.nombre === 'falla' && r.id) { vistaDetalle(r.id); sondear(() => cargarDetalle(r.id)); }
  else if (r.nombre === 'detalle' || r.nombre === 'falla') { vistaBuscar(); }
  else if (r.nombre === 'reportar') { vistaReportar(); }
  else if (r.nombre === 'bitacora') { vistaBitacora(); sondear(cargarBitacora); }
  else { vistaMapa(); sondear(cargarMapa); }
}

function sondear(funcion) { temporizador = setInterval(funcion, INTERVALO_MS); }

/* ---------- vista: mapa y fallas ---------- */

function vistaMapa() {
  $('#vista').innerHTML =
    '<section class="px-margin-mobile pt-space-md pb-space-sm flex flex-col gap-space-xs">' +
      '<h1 class="font-headline-lg-mobile text-headline-lg-mobile text-primary font-bold tracking-tight">Panel de incidencias</h1>' +
      '<p class="font-body-sm text-body-sm text-on-surface-variant">Fallas vigentes, de mayor a menor urgencia.</p></section>' +
    '<section class="px-margin-mobile py-space-xs"><div id="fichas" class="grid grid-cols-3 gap-space-xs"></div></section>' +
    '<section class="px-margin-mobile py-space-sm flex items-center gap-space-xs">' +
      '<a href="#/reportar" class="flex-1 h-12 bg-primary-container text-on-primary rounded-xl font-label-lg text-label-lg flex items-center justify-center gap-2 shadow-md">' +
        '<span class="material-symbols-outlined text-[20px]" aria-hidden="true">add_circle</span>Reportar falla</a>' +
      '<button type="button" data-accion="actualizar" class="h-12 px-space-md bg-surface-container-high text-on-surface rounded-xl font-label-lg text-label-lg flex items-center gap-1.5">' +
        '<span class="material-symbols-outlined text-[20px] text-secondary" aria-hidden="true">sync</span>Actualizar</button></section>' +
    '<section id="caja-sim" class="px-margin-mobile py-space-xs"></section>' +
    '<section class="px-margin-mobile py-space-xs flex flex-col gap-space-sm">' +
      '<div id="caja-mapa" class="flex flex-col gap-space-xs"><div class="rounded-xl bg-surface-container-low p-space-md font-body-sm text-body-sm text-on-surface-variant">Cargando mapa…</div></div>' +
      '<div id="tarjeta-sel"></div></section>' +
    '<section class="px-margin-mobile py-space-xs flex flex-col gap-space-xs">' +
      '<div id="filtros-estado" class="flex gap-space-xs overflow-x-auto"></div>' +
      '<div id="filtros-prioridad" class="flex gap-space-xs overflow-x-auto"></div></section>' +
    '<section id="lista-fallas" class="px-margin-mobile py-space-sm flex flex-col gap-space-sm"></section>';
  cargarMapa();
}

async function cargarMapa() {
  const [r, rs] = await Promise.all([api('GET', '/api/mapa/fallas'), api('GET', '/api/simulador'), asegurarPuntos()]);
  if (rs.ok) { sim = rs.datos; }
  if (!r.ok) { aviso('No se pudo actualizar el mapa de fallas.', true); return; }
  fallas = r.datos.fallas || [];
  pintarMapa();
}

function pintarMapa() {
  if (!$('#fichas')) { return; }
  const cuenta = (e) => fallas.filter((f) => f.estado === e).length;
  $('#fichas').innerHTML =
    ficha('bg-error-container/40 text-error', 'Reportadas', cuenta('reportada'), 'warning') +
    ficha('bg-tertiary-fixed/60 text-on-tertiary-fixed', 'Asignadas', cuenta('asignada'), 'engineering') +
    ficha('bg-secondary-fixed/50 text-on-secondary-fixed-variant', 'Reparadas', cuenta('reparada'), 'task_alt');
  $('#filtros-estado').innerHTML =
    chip(filtroEstado === 'todas', 'filtro-estado', 'todas', 'Todas (' + fallas.length + ')') +
    chip(filtroEstado === 'reportada', 'filtro-estado', 'reportada', 'Reportadas') +
    chip(filtroEstado === 'asignada', 'filtro-estado', 'asignada', 'Asignadas') +
    chip(filtroEstado === 'reparada', 'filtro-estado', 'reparada', 'Reparadas');
  $('#filtros-prioridad').innerHTML =
    chip(filtroPrioridad === 'todas', 'filtro-prioridad', 'todas', 'Toda prioridad') +
    chip(filtroPrioridad === 'alta', 'filtro-prioridad', 'alta', 'Alta') +
    chip(filtroPrioridad === 'media', 'filtro-prioridad', 'media', 'Media') +
    chip(filtroPrioridad === 'baja', 'filtro-prioridad', 'baja', 'Baja');

  const visibles = fallas
    .filter((f) => (filtroEstado === 'todas' || f.estado === filtroEstado) &&
                   (filtroPrioridad === 'todas' || f.prioridad === filtroPrioridad))
    .sort((a, b) => (ORDEN_ESTADO[a.estado] - ORDEN_ESTADO[b.estado]) ||
                    (ORDEN_PRIORIDAD[a.prioridad] - ORDEN_PRIORIDAD[b.prioridad]) ||
                    (b.reportes - a.reportes) || (a.reportada_en - b.reportada_en));

  pintarMapaSvg(visibles);
  pintarSim();
  $('#lista-fallas').innerHTML = visibles.length ? visibles.map(tarjetaFalla).join('') :
    '<div class="rounded-xl bg-surface-container-low p-space-lg text-center font-body-md text-on-surface-variant">No hay fallas con estos filtros.</div>';
}

function pintarSim() {
  const caja = $('#caja-sim');
  if (!caja || !sim) { return; }
  const marcha = !!sim.activo;
  const dato = (etiqueta, valor) => '<div class="flex flex-col"><span class="font-title-md text-title-md text-primary font-bold">' + esc(valor) +
    '</span><span class="font-label-sm text-label-sm text-on-surface-variant">' + etiqueta + '</span></div>';
  const estado = marcha ? insignia('bg-secondary-fixed text-on-secondary-fixed-variant', 'play_circle', 'En marcha') :
    insignia('bg-surface-container-high text-on-surface-variant', 'pause_circle', 'Detenida');
  const principal = marcha ?
    '<button type="button" data-accion="sim-detener" class="h-11 rounded-xl bg-error text-on-error font-label-lg text-label-lg">Detener simulación</button>' :
    '<button type="button" data-accion="sim-iniciar" class="h-11 rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg">Iniciar simulación</button>';
  caja.innerHTML = '<div class="rounded-xl bg-surface-container-lowest shadow-sm p-space-md flex flex-col gap-space-sm">' +
    '<div class="flex items-center justify-between gap-space-sm"><h2 class="font-title-lg text-title-lg text-primary font-bold">Simulador de reportes</h2>' + estado + '</div>' +
    '<div class="grid grid-cols-4 gap-space-xs">' + dato('Día', sim.dia) + dato('Reportes', sim.reportes) + dato('Asignadas', sim.asignadas) + dato('Reparadas', sim.reparadas) + '</div>' +
    '<div class="font-label-md text-label-md text-on-surface-variant">' + esc(sim.nuevas) + ' nuevas · ' + esc(sim.agrupadas) + ' agrupadas · ' + esc(sim.reincidencias) + ' reincidencias</div>' +
    principal +
    '<div class="grid grid-cols-2 gap-space-xs">' +
      '<button type="button" data-accion="sim-poste" class="h-11 rounded-xl bg-surface-container-high text-on-surface font-label-md text-label-md">15 reportes · mismo poste</button>' +
      '<button type="button" data-accion="sim-circuito" class="h-11 rounded-xl bg-surface-container-high text-on-surface font-label-md text-label-md">Falla de circuito (40)</button></div>' +
    '<p class="font-body-sm text-body-sm text-on-surface-variant">Datos simulados: ' + esc(sim.reportes_por_dia) + ' reportes por día; un día dura ' +
      Math.round(Number(sim.dia_ms) / 1000) + ' s. 4 cuadrillas atienden hasta 3 fallas cada una, las más urgentes primero.</p></div>';
}

async function simular(accion) {
  let cuerpo = {};
  if (accion === 'poste') {
    cuerpo = { luminaria: 'L-' + String(1 + Math.floor(Math.random() * 5000)).padStart(4, '0') };
  } else if (accion === 'circuito') {
    cuerpo = { circuito: 'C-' + CODIGOS_SECTOR[sectorEscenario % CODIGOS_SECTOR.length] + '-01' };
    sectorEscenario += 1;
  }
  const r = await api('POST', '/api/simulador/' + RUTAS_SIM[accion], cuerpo);
  if (!r.ok) { aviso('No se pudo ejecutar: ' + (r.datos.error || 'error de conexión'), true); return; }
  const d = r.datos;
  if (accion === 'poste') {
    aviso(d.enviados + ' reportes a ' + d.luminaria + ': ' + d.nuevas + ' falla nueva, ' + d.agrupadas + ' agrupados.', false);
  } else if (accion === 'circuito') {
    aviso('Circuito ' + d.circuito + ': ' + d.luminarias + ' luminarias, ' + d.nuevas + ' fallas nuevas.', false);
  } else {
    aviso(accion === 'iniciar' ? 'Simulación iniciada.' : 'Simulación detenida.', false);
  }
  cargarMapa();
}

function pintarMapaSvg(visibles) {
  const caja = $('#caja-mapa');
  if (!caja) { return; }
  if (!puntos) {
    caja.innerHTML = '<div class="rounded-xl bg-surface-container-low p-space-md font-body-sm text-body-sm text-on-surface-variant">No se pudo cargar el catálogo de luminarias; la lista sigue mostrando las fallas.</div>';
    return;
  }
  const marcas = visibles
    .filter((f) => typeof f.lat === 'number' && typeof f.lon === 'number')
    .sort((a, b) => ORDEN_ESTADO[b.estado] - ORDEN_ESTADO[a.estado])      // las reportadas quedan encima
    .map((f) => ({ lat: f.lat, lon: f.lon, color: COLOR_ESTADO[f.estado] || '#ba1a1a', r: 9, id: f.luminaria,
                   sel: f.luminaria === seleccion, titulo: f.luminaria + ' · ' + (f.direccion || '') }));
  caja.innerHTML = mapaSvg(marcas) + leyendaMapa();
  const f = fallas.find((x) => x.luminaria === seleccion);
  $('#tarjeta-sel').innerHTML = f ?
    '<div class="rounded-xl bg-surface-container-lowest shadow-sm p-space-md flex items-center justify-between gap-space-sm"><div class="min-w-0">' +
      '<div class="font-title-md text-title-md text-primary font-bold"># ' + esc(f.luminaria) + '</div>' +
      '<div class="font-body-sm text-body-sm text-on-surface-variant truncate">' + (ubicacionTexto(f) || 'Sin ubicación en el catálogo') + '</div></div>' +
      '<a href="#/falla/' + encodeURIComponent(f.luminaria) + '" class="h-10 px-space-md rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg flex items-center">Ver detalle</a></div>' :
    '<p class="font-body-sm text-body-sm text-on-surface-variant">Toca un punto de falla en el mapa para ver su ubicación.</p>';
}

function tarjetaFalla(f) {
  const cuadrilla = f.asignada_a ? '<div class="flex items-center gap-1 text-on-tertiary-fixed-variant font-label-md text-label-md">' +
    '<span class="material-symbols-outlined text-[16px]" aria-hidden="true">groups</span>' + esc(f.asignada_a) + '</div>' : '';
  return '<article class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
    '<div class="flex items-start justify-between gap-space-sm"><div>' +
      '<h2 class="font-title-lg text-title-lg text-primary font-bold"># ' + esc(f.luminaria) + '</h2>' +
      '<span class="font-label-sm text-label-sm text-on-surface-variant">Reportada ' + hace(f.reportada_en) + '</span>' +
      (f.direccion ? '<div class="font-body-sm text-body-sm text-on-surface mt-1">' + ubicacionTexto(f) + '</div>' : '') + '</div>' +
      '<div class="flex flex-col items-end gap-1">' + insigniaEstado(f.estado) + insigniaPrioridad(f.prioridad) + '</div></div>' +
    '<div class="rounded-xl bg-secondary-fixed/40 p-space-sm flex items-center gap-space-sm">' +
      '<span class="material-symbols-outlined text-secondary" aria-hidden="true">campaign</span><div>' +
      '<div class="font-label-lg text-label-lg text-on-surface">' + f.reportes + (f.reportes === 1 ? ' reporte acumulado' : ' reportes acumulados') + '</div>' +
      '<div class="font-label-sm text-label-sm text-on-surface-variant">' + esc(textoFuentes(f.fuentes)) + '</div></div></div>' +
    cuadrilla +
    '<a href="#/falla/' + encodeURIComponent(f.luminaria) + '" class="h-11 rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg flex items-center justify-center gap-2">' +
      '<span class="material-symbols-outlined text-[18px]" aria-hidden="true">content_paste_search</span>Ver detalle</a></article>';
}

/* ---------- vista: detalle de una falla ---------- */

function vistaBuscar() {
  $('#vista').innerHTML =
    '<section class="px-margin-mobile pt-space-md flex flex-col gap-space-md">' +
      '<h1 class="font-headline-lg-mobile text-headline-lg-mobile text-primary font-bold">Detalle de falla</h1>' +
      '<form id="form-buscar" class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
        '<label for="buscar-id" class="font-label-lg text-label-lg text-on-surface">ID de luminaria</label>' +
        '<input id="buscar-id" maxlength="40" placeholder="L-0001" class="h-12 rounded-xl bg-surface-container-low px-4 font-body-lg text-body-lg" />' +
        '<button type="submit" class="h-12 rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg">Buscar</button></form>' +
      '<p class="font-body-sm text-body-sm text-on-surface-variant">También puedes abrir el detalle desde la lista de fallas.</p></section>';
}

function vistaDetalle(id) {
  $('#vista').innerHTML = '<section class="px-margin-mobile pt-space-md font-body-md text-on-surface-variant">Cargando ' + esc(id) + '…</section>';
  cargarDetalle(id);
}

async function cargarDetalle(id) {
  const r = await api('GET', '/api/fallas/' + encodeURIComponent(id));
  if (r.estado === 404) {
    $('#vista').innerHTML = '<section class="px-margin-mobile pt-space-md flex flex-col gap-space-sm">' +
      '<a href="#/" class="text-secondary font-label-lg text-label-lg">← Volver a la lista</a>' +
      '<div class="rounded-xl bg-error-container p-space-md text-on-error-container font-body-md">No hay una falla registrada para la luminaria <b>' + esc(id) + '</b>.</div></section>';
    return;
  }
  if (!r.ok) { aviso('No se pudo cargar el detalle.', true); return; }
  await asegurarPuntos();
  pintarDetalle(r.datos);
}

function bloqueUbicacion(f) {
  if (!f.direccion) { return ''; }
  const fila = (k, v) => '<div class="flex justify-between gap-space-sm font-body-md text-body-md"><span class="text-on-surface-variant">' + k +
    '</span><span class="text-on-surface text-right">' + esc(v) + '</span></div>';
  const mini = (puntos && typeof f.lat === 'number' && typeof f.lon === 'number') ?
    mapaSvg([{ lat: f.lat, lon: f.lon, color: COLOR_ESTADO[f.estado] || '#ba1a1a', r: 12, sel: true, titulo: f.luminaria }]) : '';
  return '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
    '<h2 class="font-title-lg text-title-lg text-primary font-bold">Ubicación</h2>' + mini +
    fila('Dirección', f.direccion) + fila('Sector', f.sector) + fila('Circuito', f.circuito) +
    fila('Tipo de lugar', LUGARES[f.lugar] || f.lugar || '') +
    fila('Coordenadas', Number(f.lat).toFixed(5) + ', ' + Number(f.lon).toFixed(5)) + '</div>';
}

function pintarDetalle(f) {
  const previo = $('#sel-cuadrilla') ? $('#sel-cuadrilla').value : '';
  const total = f.reportes || 0;
  const barras = Object.entries(f.fuentes || {}).map(([nombre, n]) => {
    const pct = total ? Math.round((n * 100) / total) : 0;
    return '<div class="flex flex-col gap-1"><div class="flex justify-between font-label-md text-label-md text-on-surface">' +
      '<span>' + esc(nombre) + '</span><span>' + n + ' (' + pct + '%)</span></div>' +
      '<div class="h-2 rounded-full bg-surface-container-high"><div class="h-2 rounded-full bg-secondary" style="width:' + pct + '%"></div></div></div>';
  }).join('');

  const hecho = (ok) => ok ? 'text-secondary' : 'text-outline';
  const asignada = f.estado === 'asignada' || f.estado === 'reparada';
  const reparada = f.estado === 'reparada';
  const paso = (icono, titulo, detalle, ok) =>
    '<li class="flex gap-space-sm"><span class="material-symbols-outlined ' + hecho(ok) + '" aria-hidden="true">' + icono + '</span>' +
    '<div><div class="font-title-md text-title-md ' + (ok ? 'text-on-surface' : 'text-outline') + '">' + titulo + '</div>' +
    '<div class="font-body-sm text-body-sm text-on-surface-variant">' + detalle + '</div></div></li>';

  const opciones = CUADRILLAS.map((c) => '<option value="' + c + '"' + (c === previo ? ' selected' : '') + '>' + c.replace('_', ' ') + '</option>').join('');
  const puedeAsignar = f.estado === 'reportada';
  const puedeReparar = f.estado === 'asignada';

  $('#vista').innerHTML =
    '<section class="px-margin-mobile pt-space-md flex flex-col gap-space-md">' +
      '<a href="#/" class="text-secondary font-label-lg text-label-lg">← Volver a la lista</a>' +
      '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
        '<span class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wide">Ficha de incidencia</span>' +
        '<h1 class="font-headline-lg-mobile text-headline-lg-mobile text-primary font-bold">Luminaria ' + esc(f.luminaria) + '</h1>' +
        '<div class="flex flex-wrap gap-space-xs">' + insigniaEstado(f.estado) + insigniaPrioridad(f.prioridad) + '</div>' +
        (f.reincidencias ? '<div class="rounded-xl bg-error-container p-space-sm text-on-error-container font-label-lg text-label-lg flex items-center gap-2">' +
          '<span class="material-symbols-outlined" aria-hidden="true">replay</span>Reincidencias de esta luminaria: ' + f.reincidencias + '</div>' : '') +
      '</div>' + bloqueUbicacion(f) +
      '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
        '<div class="flex items-center justify-between"><h2 class="font-title-lg text-title-lg text-primary font-bold">Reportes agrupados</h2>' +
        '<span class="px-2 py-1 rounded-full bg-primary-container text-on-primary font-label-sm text-label-sm">' + total + ' en total</span></div>' + barras + '</div>' +
      '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-md">' +
        '<h2 class="font-title-lg text-title-lg text-primary font-bold">Ciclo de vida</h2><ol class="flex flex-col gap-space-md">' +
          paso('report', '1. Reportada', 'Detectada ' + hace(f.reportada_en) + ' (' + hora(f.reportada_en) + ')', true) +
          paso('engineering', '2. Asignada', asignada ? 'Cuadrilla: ' + esc(f.asignada_a || '') : 'Pendiente de asignar', asignada) +
          paso('task_alt', '3. Reparada', reparada ? 'Cerrada ' + hace(f.reparada_en) + ' (' + hora(f.reparada_en) + ')' : 'Pendiente', reparada) +
        '</ol></div>' +
      '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
        '<h2 class="font-title-lg text-title-lg text-primary font-bold">Acciones</h2>' +
        '<label for="sel-cuadrilla" class="font-label-lg text-label-lg text-on-surface">Cuadrilla</label>' +
        '<select id="sel-cuadrilla" class="h-12 rounded-xl bg-surface-container-low px-3 font-body-lg text-body-lg"' + (puedeAsignar ? '' : ' disabled') + '>' + opciones + '</select>' +
        '<button type="button" data-accion="asignar" data-id="' + esc(f.luminaria) + '"' + (puedeAsignar ? '' : ' disabled') +
          ' class="h-12 rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg disabled:opacity-40 disabled:cursor-not-allowed">Asignar a cuadrilla</button>' +
        '<button type="button" data-accion="reparar" data-id="' + esc(f.luminaria) + '"' + (puedeReparar ? '' : ' disabled') +
          ' class="h-12 rounded-xl bg-secondary text-on-secondary font-label-lg text-label-lg disabled:opacity-40 disabled:cursor-not-allowed">Marcar como reparada</button>' +
        '<p class="font-body-sm text-body-sm text-on-surface-variant">Solo se puede reparar una falla que ya está asignada. Una falla reparada no se reabre: un nuevo reporte crea una falla nueva y cuenta como reincidencia.</p>' +
      '</div></section>';
}

async function accionFalla(id, cuerpo) {
  const r = await api('PATCH', '/api/fallas/' + encodeURIComponent(id), cuerpo);
  if (r.ok) { aviso('Listo.', false); } else { aviso('No se pudo aplicar: ' + (r.datos.error || 'error de conexión'), true); }
  cargarDetalle(id);
}

/* ---------- vista: reportar falla ---------- */

function vistaReportar() {
  const radio = (nombre, valor, texto, marcado) =>
    '<label class="flex items-center gap-3 rounded-xl bg-surface-container-low p-space-sm cursor-pointer">' +
    '<input type="radio" name="' + nombre + '" value="' + valor + '"' + (marcado ? ' checked' : '') + ' class="w-5 h-5" />' +
    '<span class="font-body-md text-body-md text-on-surface">' + texto + '</span></label>';
  $('#vista').innerHTML =
    '<section class="px-margin-mobile pt-space-md flex flex-col gap-space-md">' +
      '<h1 class="font-headline-lg-mobile text-headline-lg-mobile text-primary font-bold">Nuevo reporte de luminaria</h1>' +
      '<p class="font-body-sm text-body-sm text-on-surface-variant">Si la luminaria ya tiene una falla abierta, el reporte se agrupa en ella en lugar de crear otra.</p>' +
      '<form id="form-reporte" class="flex flex-col gap-space-md">' +
        '<div class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-sm">' +
          '<label for="rep-id" class="font-label-lg text-label-lg text-on-surface">ID de luminaria <span class="text-error">*</span></label>' +
          '<input id="rep-id" required maxlength="40" pattern="[A-Za-z0-9_\\-]+" placeholder="L-0001" class="h-12 rounded-xl bg-surface-container-low px-4 font-body-lg text-body-lg" />' +
          '<span class="font-body-sm text-body-sm text-on-surface-variant">Catálogo simulado: de L-0001 a L-5000.</span></div>' +
        '<fieldset class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-xs">' +
          '<legend class="font-label-lg text-label-lg text-on-surface">Prioridad <span class="text-error">*</span></legend>' +
          radio('prioridad', 'alta', 'Alta · avenidas, cruces escolares, hospitales', false) +
          radio('prioridad', 'media', 'Media · calles secundarias y colonias', true) +
          radio('prioridad', 'baja', 'Baja · andadores, plazas y parques', false) + '</fieldset>' +
        '<fieldset class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-xs">' +
          '<legend class="font-label-lg text-label-lg text-on-surface">Fuente del reporte <span class="text-error">*</span></legend>' +
          radio('fuente', 'ciudadano', 'Ciudadano · llamada, ventanilla o app', true) +
          radio('fuente', 'telemetria', 'Telemetría · sensor de la luminaria', false) + '</fieldset>' +
        '<button type="submit" class="h-12 rounded-xl bg-primary-container text-on-primary font-label-lg text-label-lg flex items-center justify-center gap-2">' +
          '<span class="material-symbols-outlined text-[20px]" aria-hidden="true">send</span>Enviar reporte</button>' +
      '</form><div id="resultado-reporte"></div></section>';
}

async function enviarReporte(evento) {
  evento.preventDefault();
  const id = $('#rep-id').value.trim();
  const prioridad = document.querySelector('input[name="prioridad"]:checked').value;
  const fuente = document.querySelector('input[name="fuente"]:checked').value;
  const r = await api('POST', '/api/lamparas/' + encodeURIComponent(id) + '/falla', { prioridad, fuente });
  const caja = $('#resultado-reporte');
  if (!r.ok) {
    caja.innerHTML = '<div class="rounded-xl bg-error-container p-space-md text-on-error-container font-body-md">No se pudo enviar el reporte: ' +
      esc(r.datos.error || 'error de conexión') + '.</div>';
    return;
  }
  const mensajes = {
    nueva: 'Se creó una falla nueva para ',
    agrupada: 'El reporte se agrupó con la falla ya abierta de ',
    reincidencia: 'La luminaria reincidió: se abrió una falla nueva para '
  };
  caja.innerHTML = '<div class="rounded-xl bg-secondary-fixed p-space-md text-on-secondary-fixed font-body-md flex flex-col gap-space-sm">' +
    '<div>' + (mensajes[r.datos.resultado] || 'Reporte recibido para ') + '<b>' + esc(id) + '</b>.</div>' +
    '<a class="font-label-lg text-label-lg text-secondary underline" href="#/falla/' + encodeURIComponent(id) + '">Ver detalle de la falla</a></div>';
}

/* ---------- vista: bitacora ---------- */

function vistaBitacora() {
  $('#vista').innerHTML =
    '<section class="px-margin-mobile pt-space-md flex flex-col gap-space-sm">' +
      '<h1 class="font-headline-lg-mobile text-headline-lg-mobile text-primary font-bold">Bitácora de eventos</h1>' +
      '<p class="font-body-sm text-body-sm text-on-surface-variant">Últimos eventos del sistema, del más reciente al más antiguo. Se guardan en memoria: se pierden si el servicio se reinicia.</p>' +
      '<input id="bit-buscar" placeholder="Buscar por ID, por ejemplo L-0001" class="h-12 rounded-xl bg-surface-container-lowest shadow-sm px-4 font-body-md text-body-md" />' +
      '<div id="filtros-bitacora" class="flex gap-space-xs overflow-x-auto"></div></section>' +
    '<section id="lista-eventos" class="px-margin-mobile py-space-md flex flex-col gap-space-sm"></section>';
  cargarBitacora();
}

async function cargarBitacora() {
  const r = await api('GET', '/api/bitacora?limite=100');
  if (!r.ok) { aviso('No se pudo actualizar la bitácora.', true); return; }
  eventos = r.datos.eventos || [];
  pintarBitacora();
}

function textoEvento(e) {
  const d = e.detalle || {};
  switch (e.tipo) {
    case 'nueva': return { titulo: 'Reporte nuevo', texto: 'Se abrió una falla (fuente: ' + (d.fuente || '?') + ', prioridad ' + (d.prioridad || '?') + ').', icono: 'report', clases: 'bg-error-container text-on-error-container' };
    case 'agrupada': return { titulo: 'Reporte agrupado', texto: 'Otro reporte se sumó a la falla abierta (fuente: ' + (d.fuente || '?') + ').', icono: 'campaign', clases: 'bg-secondary-fixed text-on-secondary-fixed-variant' };
    case 'reincidencia': return { titulo: 'Reincidencia', texto: 'La luminaria falló de nuevo tras una reparación; se abrió una falla nueva.', icono: 'replay', clases: 'bg-error text-on-error' };
    case 'asignada': return { titulo: 'Asignada', texto: 'Asignada a ' + (d.cuadrilla || '?') + '.', icono: 'engineering', clases: 'bg-tertiary-fixed text-on-tertiary-fixed' };
    case 'reparada': return { titulo: 'Reparada', texto: 'Falla cerrada con ' + (d.reportes || '?') + ' reportes acumulados.', icono: 'task_alt', clases: 'bg-secondary-fixed text-on-secondary-fixed-variant' };
    default: return { titulo: e.tipo, texto: '', icono: 'info', clases: 'bg-surface-container-high text-on-surface' };
  }
}

function pintarBitacora() {
  if (!$('#lista-eventos')) { return; }
  const texto = ($('#bit-buscar').value || '').trim().toLowerCase();
  $('#filtros-bitacora').innerHTML =
    chip(filtroBitacora === 'todos', 'filtro-bitacora', 'todos', 'Todos los eventos') +
    chip(filtroBitacora === 'asignada', 'filtro-bitacora', 'asignada', 'Asignaciones') +
    chip(filtroBitacora === 'reparada', 'filtro-bitacora', 'reparada', 'Reparaciones') +
    chip(filtroBitacora === 'reincidencia', 'filtro-bitacora', 'reincidencia', 'Reincidencias');
  const visibles = eventos.filter((e) =>
    (filtroBitacora === 'todos' || e.tipo === filtroBitacora) &&
    (!texto || String(e.luminaria).toLowerCase().includes(texto)));
  $('#lista-eventos').innerHTML = visibles.length ? visibles.map((e) => {
    const t = textoEvento(e);
    return '<article class="bg-surface-container-lowest rounded-xl shadow-sm p-space-md flex flex-col gap-space-xs">' +
      '<div class="flex items-center justify-between gap-space-sm">' +
        '<a href="#/falla/' + encodeURIComponent(e.luminaria) + '" class="font-title-md text-title-md text-primary font-bold">Luminaria ' + esc(e.luminaria) + '</a>' +
        insignia(t.clases, t.icono, t.titulo) + '</div>' +
      '<p class="font-body-md text-body-md text-on-surface">' + esc(t.texto) + '</p>' +
      '<span class="font-label-sm text-label-sm text-on-surface-variant">' + hace(e.hora) + ' · ' + hora(e.hora) + '</span></article>';
  }).join('') : '<div class="rounded-xl bg-surface-container-low p-space-lg text-center font-body-md text-on-surface-variant">No hay eventos para mostrar.</div>';
}

/* ---------- eventos de la pagina ---------- */

document.addEventListener('click', (ev) => {
  const boton = ev.target.closest('[data-accion]');
  if (!boton) { return; }
  const { accion, valor, id } = boton.dataset;
  if (accion === 'filtro-estado') { filtroEstado = valor; pintarMapa(); }
  else if (accion === 'filtro-prioridad') { filtroPrioridad = valor; pintarMapa(); }
  else if (accion === 'filtro-bitacora') { filtroBitacora = valor; pintarBitacora(); }
  else if (accion === 'actualizar') { cargarMapa(); }
  else if (accion === 'sel-falla') { seleccion = id; pintarMapa(); }
  else if (accion.startsWith('sim-')) { simular(accion.slice(4)); }
  else if (accion === 'asignar') { accionFalla(id, { accion: 'asignar', cuadrilla: $('#sel-cuadrilla').value }); }
  else if (accion === 'reparar') { accionFalla(id, { accion: 'reparar' }); }
});

document.addEventListener('submit', (ev) => {
  if (ev.target.id === 'form-reporte') { enviarReporte(ev); }
  else if (ev.target.id === 'form-buscar') {
    ev.preventDefault();
    const id = $('#buscar-id').value.trim();
    if (id) { location.hash = '#/falla/' + encodeURIComponent(id); }
  }
});

document.addEventListener('input', (ev) => {
  if (ev.target.id === 'bit-buscar') { pintarBitacora(); }
});

window.addEventListener('hashchange', navegar);
navegar(); 