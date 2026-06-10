# Documentacion de Sentry Log

Esta carpeta contiene la documentacion del proyecto Sentry Log.

## Archivos

- `manual/administrador.md`: guia para operar el servidor como administrador.
- `manual/usuario.md`: guia para usar el sistema como usuario normal.
- `capturas/`: carpeta destinada a capturas de pantalla para el reporte final.

## Resumen Del Proyecto

Sentry Log automatiza un entorno Unix/Linux empresarial usando Docker, Ubuntu, SSH, scripts Bash, permisos Linux, procesos en segundo plano, auditoria de bitacoras y un modulo C compilado con Makefile.

## Acceso Rapido

Levantar el servidor:

```bash
docker compose up -d --build
```

Entrar desde el navegador:

```text
https://sentry.hyuver.xyz
```

La pagina pide un correo, envia un codigo y despues solicita las credenciales SSH del servidor.

Entrar como administrador por SSH local:

```bash
ssh profesor@localhost -p 2222
```

Credenciales de demo:

```text
Usuario: profesor
Contrasena: password123
```

Validar el proyecto:

```bash
make check
```
