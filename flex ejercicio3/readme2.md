
# Ejercicio 3 - Cross-referencer de C con tabla dinámica

Este programa analiza archivos fuente en C y genera un cross-reference: lista todos los identificadores mostrando dónde se definen (marcados con *) y dónde se usan, con manejo de archivos incluidos.


## Requisitos

- Flex
- GCC

```bash
sudo apt install flex gcc
```

## Compilación

```bash
flex crossref.l
gcc -o crossref lex.yy.c -lfl
```

## Uso

```bash
./crossref archivo.c [otro_archivo.c ...]
```

## Ejemplo con prueba.c

```bash
./crossref prueba.c
```

## Archivos incluidos

- `crossref.l` - Código fuente del escáner Flex
- `prueba.c` - Archivo de prueba en C
- `README.md` - Este archivo



## Prueba rápida

Si tu archivo `prueba.c` contiene algo como:

```c
int variable = 10;
void funcion() {
    int local = variable;
}
```

La salida debería ser similar a:

```
=== CROSS-REFERENCE ===
(Los símbolos marcados con * son definiciones)

funcion           prueba.c:2*
local             prueba.c:3*
variable          prueba.c:1* prueba.c:3
```

