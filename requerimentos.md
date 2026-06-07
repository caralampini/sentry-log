# Proyecto Final: Configuración y Automatización de un Entorno Unix/Linux

## Datos Generales

| Campo | Información |
| --- | --- |
| Centro | Centro de Ciencias Básicas |
| Departamento | Departamento de Sistemas Electrónicos |
| Academia | Academia de Programación y Software de Base |
| Materia | Unix |
| Carrera | Ing. en Sistemas Computacionales |
| Profesor | Gerardo Salazar Salazar |
| Semestre | 4º |
| Nombre del proyecto | Configuración y automatización de un entorno Unix/Linux |
| Fecha de entrega | Miércoles 10 de junio a las 10:00 am |
| Observaciones | Se explica a detalle en el documento. La entrega será a través del aula virtual. |

## Instrucciones Generales

Se requiere que el estudiante trabaje en equipos de 3 o 4 personas, genere una propuesta de proyecto y sea validada por el administrador.

Deberá entregar el código fuente, incluyendo scripts, Makefiles y código C/Java, además de un reporte con todos los archivos necesarios para su ejecución.

De igual forma, se deben subir los archivos al aula virtual ([aulavirtual.uaa.mx](https://aulavirtual.uaa.mx)) en una carpeta comprimida antes de la fecha límite especificada.

## Documentación a Entregar

La documentación debe incluir lo siguiente:

- Portada e índices.
- Abstract/Introducción.
- Desarrollo: requerimientos de hardware y software, incluyendo la distribución Linux elegida.
- Desarrollo: implementación de servidor, con detalles del servidor creado para la ejecución del proyecto.
- Desarrollo: solución a requerimientos, incluyendo arquitectura y scripts implementados.
- Desarrollo: análisis de impacto en la seguridad y rendimiento del sistema.
- Conclusiones y bibliografía.
- Anexos: manual de usuario/administrador que muestre su funcionamiento paso a paso, con capturas de pantalla.

Un proyecto copiado de Internet o de alguna otra fuente causará la anulación de la calificación final del curso. También se anularán proyectos con errores de compilación o que no realicen lo solicitado.

## Temas a Evaluar

Se evaluará que el proyecto cumpla de forma integral con los conceptos teóricos y prácticos adquiridos en el curso, abarcando los siguientes rubros:

- Instalación y configuración del sistema operativo y conexión a redes.
- Gestión de usuarios, grupos y permisos de seguridad.
- Manejo de procesos concurrentes, estados y señales.
- Programación en Shell empleando variables, ciclos, condicionales y pase de parámetros.
- Manejo de expresiones regulares y utilerías de procesamiento de datos como `sed`, `awk` y `grep`.
- Administración de proyectos con sistema Makefile e integración de lenguajes compilados.

Se evaluará que el proyecto no tenga errores de compilación, sintaxis o ejecución. Además, debe cumplir con todos los temas que marca el programa de la materia.

## Proyecto: Automatización de un Entorno GNU/Linux

El equipo deberá automatizar y gestionar un entorno de servidor virtual simulando los requerimientos de una empresa, utilizando programación Shell y las utilerías del sistema UNIX.

## 1. Diseño del Sistema

Valor: 5 puntos.

### Creación de Servidor

Como requerimiento fundamental, los alumnos deben instalar, configurar y levantar un servidor propio, ya sea con una máquina virtual, contenedor o equipo físico, en el cual se ejecutará y validará toda la programación y automatización del proyecto.

### Documentación del Diseño

Se deben incluir detalles de:

- Configuración de la máquina virtual.
- Esquema de usuarios.
- Estructura de directorios.
- Planeación de los algoritmos para los scripts.

El envío al aula virtual será uno por equipo. Se tendrá una revisión de avance de proyecto antes de la entrega final, donde los equipos deberán entregar el avance del proyecto.

## 2. Aplicación y Componentes de Programación

Valor: 20 puntos.

El proyecto debe incluir e implementar obligatoriamente los siguientes componentes:

- Shell Scripting avanzado: programación de al menos dos scripts robustos que incluyan estructuras de control como `for`, `while`, `if` y `case`, además de funciones propias.
- Procesamiento de archivos de datos: implementación de filtros y redireccionamientos utilizando utilerías como `grep`, `sed` o `awk` para procesar y extraer información de bitácoras del sistema.
- Gestión de permisos: asignación estricta de permisos para usuarios y grupos, incluyendo la implementación de bits de acceso especial donde se justifique su uso.
- Gestión de procesos: evidencia del control y ejecución de procesos en segundo plano, además de interacción con señales.
- Herramientas de compilación: integración de la compilación de un módulo secundario en lenguaje C utilizando la herramienta Makefile.

## Fechas y Consideraciones Finales

1. Se deberá subir la descripción inicial del proyecto al aula virtual para confirmar la viabilidad del tema.
2. Para tener derecho a la revisión final, el equipo deberá asistir a una revisión de avance que será notificada en aula virtual.
3. Los alumnos deberán entregar un avance del proyecto para poder tener derecho a la entrega final. La entrega del avance del proyecto será el viernes 29 de mayo de 2026 a las 11:59 pm.
4. El proyecto final se deberá subir individualmente al aula virtual a más tardar el martes 9 de junio de 2026 a las 11:59 pm.
5. La revisión del proyecto se realizará presencialmente en el aula 58-E y todo el equipo debe estar presente con el servidor funcionando.
6. Deberán presentarse con puntualidad en el día y la hora señalada para defender técnicamente el código generado.
