"""Gráficas y análisis de grafos para logicDemo2.

Este módulo no decide nada: recibe listas ya deducidas por Prolog y las dibuja.
Se usa la API de objetos de matplotlib (Figure), sin pyplot, para que funcione
en un servidor sin pantalla y desde varios hilos.
"""

from matplotlib.figure import Figure

AMBAR = "#f5b942"
FONDO = "#111317"
TEXTO = "#e2e2e8"


def _figura(titulo, ancho=9, alto=5):
    fig = Figure(figsize=(ancho, alto), facecolor=FONDO, layout="constrained")
    ax = fig.subplots()
    ax.set_facecolor(FONDO)
    ax.set_title(titulo, color=TEXTO, fontsize=14, loc="left")
    ax.tick_params(colors=TEXTO)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    for lado in ("bottom", "left"):
        ax.spines[lado].set_color("#504535")
    return fig, ax


def barras(titulo, etiquetas, valores, archivo, horizontal=False):
    """Dibuja barras y guarda el PNG. Devuelve la ruta del archivo."""
    fig, ax = _figura(titulo)
    etiquetas = [str(e) for e in etiquetas]
    if horizontal:
        ax.barh(etiquetas[::-1], valores[::-1], color=AMBAR)
    else:
        ax.bar(etiquetas, valores, color=AMBAR)
    fig.savefig(archivo, dpi=120)
    return archivo


def red(centro, aristas, archivo):
    """Dibuja la red de colaboraciones. aristas = [[actor_a, actor_b, peliculas], ...]"""
    import networkx as nx

    g = nx.Graph()
    g.add_weighted_edges_from(aristas)
    fig, ax = _figura(f"Con quién trabaja {centro}", 9, 7)
    ax.axis("off")
    pos = nx.spring_layout(g, seed=7, weight="weight")
    anchos = [g[a][b]["weight"] for a, b in g.edges]
    colores = [AMBAR if n == centro else "#333539" for n in g.nodes]
    nx.draw_networkx_edges(g, pos, ax=ax, width=anchos, edge_color="#9c8f7b", alpha=0.6)
    nx.draw_networkx_nodes(g, pos, ax=ax, node_color=colores, node_size=900)
    nx.draw_networkx_labels(g, pos, ax=ax, font_size=8, font_color=TEXTO)
    fig.savefig(archivo, dpi=120)
    return archivo


def centrales(aristas, n):
    """Los n actores con mayor intermediación en la red: [[actor, puntaje], ...]"""
    import networkx as nx

    g = nx.Graph()
    g.add_weighted_edges_from(aristas)
    puntajes = nx.betweenness_centrality(g)
    orden = sorted(puntajes.items(), key=lambda par: par[1], reverse=True)
    return [[actor, round(p, 3)] for actor, p in orden[:n]]
