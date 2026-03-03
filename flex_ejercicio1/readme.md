
# Ejercicio 1 - Manejador de archivos include con Flex

Este programa procesa archivos C, reconoce directivas `#include`, maneja la inclusión anidada y muestra cada línea con su número de línea.

## Compilación

```bash
flex fb2-3-solution.l
gcc -o include_program lex.yy.c -lfl
```

## Uso

```bash
./include_program archivo_principal.c
```

Ejemplo con los archivos proporcionados:

```bash
./include_program principal.c
```

## Archivos de prueba

- `principal.c`: archivo principal que incluye `otro.h`
- `otro.h`: archivo de cabecera (vacío o con contenido)
```
