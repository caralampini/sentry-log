# Manual de Administrador

Este manual explica lo basico para entrar y usar el menu de administrador.

## Acceso

Entrar desde el navegador:

```text
https://sentry.hyuver.xyz
```

Flujo:

1. Abrir el link en el navegador.
2. Escribir el correo solicitado.
3. Revisar el correo y copiar el codigo recibido.
4. Ingresar el codigo en la pagina.
5. Cuando aparezca la terminal SSH, usar las credenciales del servidor.

Credenciales de administrador:

```text
Usuario: profesor
Contrasena: password123
```

Al entrar se abre automaticamente el menu de administrador.

## Menu

```text
1) Agregar usuario
2) Eliminar usuario
3) Agregar grupo
4) Eliminar grupo
5) Listar Usuarios
6) Listar Grupos
7) Ver intentos fallidos de acceso SSH
8) Ver checksums de archivos vigilados
9) Iniciar monitor en segundo plano
10) Detener monitor
11) Ver estado del monitor
12) Ver bitacora del monitor
13) Acceder a terminal
14) Cerrar sesion
```

## Opciones

`1) Agregar usuario`

Crea un usuario nuevo. Pide nombre de usuario y grupo. Si el grupo no existe, pregunta si se desea crearlo.

`2) Eliminar usuario`

Muestra usuarios y pide el nombre del usuario a eliminar.

`3) Agregar grupo`

Crea un grupo/departamento nuevo. Pide nombre del grupo y ruta. Ejemplo recomendado:

```text
/empresa/web
```

`4) Eliminar grupo`

Muestra grupos y pide el grupo a eliminar.

`5) Listar Usuarios`

Muestra usuarios configurados y si existen en Linux.

`6) Listar Grupos`

Muestra grupos, rutas y permisos configurados.

`7) Ver intentos fallidos de acceso SSH`

Muestra intentos fallidos. Si el contenedor no tiene `/var/log/auth.log`, usa una bitacora simulada para demostrar el analisis.

`8) Ver checksums de archivos vigilados`

Genera y muestra checksums de archivos importantes como `/etc/passwd`, `/etc/group`, configuraciones y `/empresa`.

`9) Iniciar monitor en segundo plano`

Inicia el monitor que revisa cambios en archivos vigilados.

`10) Detener monitor`

Detiene el monitor.

`11) Ver estado del monitor`

Indica si el monitor esta activo o detenido.

`12) Ver bitacora del monitor`

Muestra alertas recientes, por ejemplo archivos nuevos, modificados o eliminados.

`13) Acceder a terminal`

Sale del menu y abre una terminal normal.

Para volver al menu:

```bash
cd /app
./scripts/admin.sh
```

`14) Cerrar sesion`

Cierra la sesion.

## Notas Rapidas

- Los usuarios y grupos se guardan aunque se haga `docker compose down`.
- Las contrasenas cambiadas tambien persisten como hashes.
- Las carpetas de la empresa estan en `/empresa`.
- Los logs estan en `data/logs`.
- Si una carpeta muestra `Permission denied`, los permisos estan funcionando correctamente.
