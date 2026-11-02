# Guía de contribución

Gracias por contribuir. Convenciones del repositorio:

## Flujo

1. Haz fork y crea una rama: `git switch -c feat/pNN-descripcion`.
2. Trabaja solo dentro de la carpeta de tu proyecto (`proyectos/NN-nombre/`); no mezcles proyectos.
3. Antes de abrir el PR, dentro de tu proyecto:
   ```bash
   rebar3 compile && rebar3 eunit
   ```
4. Abre un Pull Request describiendo qué cambia y por qué.

## Convenciones

- Behaviours OTP completos (`gen_server`, `gen_statem`, `supervisor`); todo proceso cuelga de un supervisor.
- Maps en lugar de records para estructuras que evolucionan.
- Logs con `logger:info/2` y metadata como map.
- Comentarios que expliquen el *por qué*.
- Tests: eunit (unitarios), common_test (integración).
- No agregues dependencias fuera del stack sin aprobación.
- **Nunca** subas cookies, contraseñas o certificados reales; usa valores de ejemplo en `sys.config`.
- UI: se diseña en Google Stitch y vive en `design/`.

## Commits

Mensajes en español, en imperativo y concisos (p. ej. `Agrega supervisor por parcela`).

## Licencia

Al contribuir aceptas que tu aporte se publique bajo la licencia [MIT](LICENSE).
