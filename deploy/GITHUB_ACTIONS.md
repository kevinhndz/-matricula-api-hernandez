# Flujo de cambios y despliegue de CampusFlow

`main` es la rama que se presenta y la unica que se despliega al VPS. `refactor` es la rama de trabajo.

## Flujo normal

1. Actualiza `refactor` y trabaja ahi. Guarda cada avance con un commit y subelo:

   ```bash
   git switch refactor
   git pull origin refactor
   git add <archivos>
   git commit -m "Describir el cambio"
   git push origin refactor
   ```

2. Abre un Pull Request de `refactor` hacia `main`.
3. GitHub Actions compila el frontend y construye las imagenes Docker de API y frontend para validar el PR. Ese trabajo no accede al VPS ni despliega.
4. Revisa los cambios y combina el PR. El push resultante a `main` inicia el despliegue al VPS.
5. El workflow envia las dos imagenes por SSH/SCP y recrea solo `campusflow-backend` y `campusflow-frontend`, conectados a la red externa `red-saas`. No recrea el contenedor compartido `nginx-recepcionista`. Luego verifica el sitio y `/api/docs`; si falla, vuelve a las imagenes anteriores.
6. Despues de integrar, sincroniza `refactor` con `main` para iniciar el siguiente trabajo desde el estado presentado:

   ```bash
   git fetch origin
   git switch refactor
   git pull origin refactor
   git merge origin/main
   git push origin refactor
   ```

No uses `git push --force` para sincronizar las ramas; primero resuelve cualquier conflicto y conserva los commits de trabajo.

## Acceso de despliegue

GitHub Actions usa una llave SSH dedicada para el usuario `campusflow-deploy` del VPS. No usa la llave personal del usuario `root`.

Configura estos valores en los ajustes del repositorio:

### Secret

- `CAMPUSFLOW_DEPLOY_KEY`: llave privada SSH de la cuenta de despliegue.

### Variables

- `CAMPUSFLOW_VPS_HOST`: IP o nombre del VPS.
- `CAMPUSFLOW_VPS_USER`: usuario remoto de despliegue.
- `CAMPUSFLOW_VPS_KNOWN_HOSTS`: llave publica del host SSH para verificar el servidor.

No guardes la llave privada en el repositorio, en archivos `.env` ni en los logs de Actions.

## Ejecucion manual

En GitHub abre **Actions**, selecciona **CI CD CampusFlow** y usa **Run workflow** en la rama `main`. La ejecucion manual sobre otra rama no despliega.

## Proteccion recomendada de `main`

En la configuracion de ramas de GitHub, exige Pull Request para integrar a `main` y exige que el workflow termine correctamente. La validacion actual comprueba la compilacion del frontend y construye las dos imagenes; no ejecuta pruebas automatizadas ni aplica migraciones de base de datos. El Nginx compartido debe estar conectado a `red-saas` y configurado para enviar `/` a `campusflow-frontend:80`, y `/api/` y `/uploads/` a `campusflow-backend:8000`.
