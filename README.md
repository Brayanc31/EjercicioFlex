
# Tarea Capítulo 2 - Flex

Soluciones a los 3 ejercicios del Capítulo 2 del libro "Flex & Bison".


## Requisitos

```bash
sudo apt install flex gcc
```

## Cómo compilar y ejecutar

### Ejercicio 1
```bash
cd ejercicio1
flex fb2-3-solution.l
gcc lex.yy.c -o include_program
./include_program principal.c
```

### Ejercicio 2
```bash
cd ejercicio2
flex concordancia.l
gcc lex.yy.c -o concordance
./concordance texto.txt
```

### Ejercicio 3
```bash
cd ejercicio3
flex crossref.l
gcc lex.yy.c -o crossref
./crossref prueba.c
```

## Archivos incluidos

Cada carpeta contiene su código fuente (.l), archivos de prueba y un README específico.
```

