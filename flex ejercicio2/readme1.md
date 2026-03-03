
# Ejercicio 2 - Generador de concordancias 

Este programa implementa un generador de concordancias que lee archivos de texto y muestra cada palabra junto con las líneas donde aparece. No distingue entre mayúsculas y minúsculas, por lo que "HOLA" y "hola" se tratan como la misma palabra.

## Requisitos previos

- Sistema operativo: Linux (probado en Ubuntu)
- Flex
- GCC

Para instalar Flex en Ubuntu:
```bash
sudo apt update
sudo apt install flex
```

## Archivos incluidos

- `concordancia.l` - Código fuente del escáner Flex
- `texto.txt` - Archivo de ejemplo para probar el programa
- `README.md` - Este archivo con las instrucciones

## Compilación

Desde la terminal, en el directorio donde se encuentra `concordancia.l`, ejecuta:

```bash
flex concordancia.l
gcc -o concordance lex.yy.c -lfl
```

Esto generará el ejecutable `concordance`.

## Uso

Ejecuta el programa pasando como argumento el archivo a analizar:

```bash
./concordance texto.txt
```

También puedes procesar varios archivos a la vez:

```bash
./concordance archivo1.txt archivo2.txt archivo3.txt
```

## Ejemplo de uso

Con el archivo `texto.txt` incluido, que contiene:

```
Este es un texto de prueba.
Incluye palabras como hola y HOLA.
Tambien palabras repetidas: prueba prueba.
```

Al ejecutar:

```bash
./concordance texto.txt
```

Obtendrás una salida similar a:

```
=== CONCORDANCIA ===
como            texto.txt:2
de              texto.txt:1
es              texto.txt:1
este            texto.txt:1
hola            texto.txt:2
incluye         texto.txt:2
palabras        texto.txt:2 texto.txt:3
prueba          texto.txt:1 texto.txt:3
repetidas       texto.txt:3
texto           texto.txt:1
un              texto.txt:1
y               texto.txt:2
```

Observa que "hola" y "HOLA" aparecen juntas como una sola entrada "hola".

