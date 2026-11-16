"""El sentido contrario: Python pregunta a Prolog (pip install janus-swi).

En el curso el programa es Prolog; esto solo muestra que el puente es de dos vías.
Uso: python3 desde_python.py
"""

import janus_swi as janus

janus.consult("../logicDemo/consultas.pl")

# Cada solución del backtracking llega como un diccionario.
for r in janus.query("titulo_contiene(matrix, Id, Titulo, Anio)"):
    print(r["Anio"], r["Titulo"])

# Una sola respuesta, con un dato de entrada.
r = janus.query_once("carrera(Actor, Primer, Ultimo, Cuantas)", {"Actor": "Tom Hanks"})
print(r)
