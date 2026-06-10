# Manual de Usuario

Este manual explica lo basico para entrar y usar el menu de usuario.

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
5. Cuando aparezca la terminal SSH, usar el usuario y contrasena del servidor.

Contrasena inicial de usuarios nuevos:

```text
password123
```

Ejemplo de usuarios:

```text
ana -> ventas
maria -> rh
pedro -> ti
elena -> finanzas
diego -> direccion
```

## Menu

Al entrar se abre automaticamente el menu de usuario:

```text
1) Ver mis rutas y archivos
2) Cambiar mi contrasena
3) Entrar a terminal
4) Cerrar sesion
```

## Opciones

`1) Ver mis rutas y archivos`

Muestra las carpetas a las que tienes acceso segun tu grupo.

Ejemplo: si eres de ventas, puedes ver `/empresa/ventas`.

`2) Cambiar mi contrasena`

Permite cambiar tu propia contrasena. El sistema pide escribirla dos veces. Mientras escribes no se ven caracteres en pantalla.

`3) Entrar a terminal`

Sale del menu y abre una terminal normal.

Comandos utiles:

```bash
ls
pwd
id
```

Para volver al menu:

```bash
source ~/.bash_profile
```

Tambien puedes cerrar sesion y volver a entrar desde el navegador.

`4) Cerrar sesion`

Cierra la sesion.

## Carpetas

Las carpetas principales estan en:

```text
/empresa
```

Departamentos base:

```text
/empresa/ventas
/empresa/rh
/empresa/ti
/empresa/finanzas
/empresa/direccion
/empresa/publico
```

Cada usuario solo puede entrar a las carpetas permitidas por su grupo.

Ejemplo:

- `ana` puede entrar a `/empresa/ventas`.
- `maria` puede entrar a `/empresa/rh`.
- `maria` no puede entrar a `/empresa/ventas`.

Si intentas entrar a una carpeta no permitida, aparecera:

```text
Permission denied
```

Eso significa que los permisos estan funcionando correctamente.

## Notas Rapidas

- Tu contrasena nueva se guarda como hash, no como texto visible.
- Si olvidas tu contrasena, pide ayuda al administrador.
- Si no ves una carpeta, probablemente no perteneces a ese grupo.
- Puedes revisar tus grupos con `id` desde la terminal.
