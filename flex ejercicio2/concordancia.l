/* concordancia.l - versión sin distinción de mayúsculas/minúsculas */
%option noyywrap nodefault yylineno

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <strings.h>   /* para strcasecmp */

struct symbol {
    char *name;
    struct ref *reflist;
};

struct ref {
    struct ref *next;
    char *filename;
    int flags;
    int lineno;
};

#define NHASH 9997
struct symbol symtab[NHASH];
struct symbol *lookup(char*);
void addref(int, char*, char*, int);
char *curfilename;

/* Función hash modificada: convierte cada carácter a minúscula */
static unsigned symhash(char *sym) {
    unsigned int hash = 0;
    unsigned c;
    while ((c = *sym++)) {
        c = tolower(c);
        hash = hash * 9 ^ c;
    }
    return hash;
}

struct symbol *lookup(char *sym) {
    struct symbol *sp = &symtab[symhash(sym) % NHASH];
    int count = NHASH;
    while (--count >= 0) {
        if (sp->name) {
            /* Comparación sin distinción de mayúsculas */
            if (strcasecmp(sp->name, sym) == 0)
                return sp;
        } else {
            sp->name = strdup(sym);
            sp->reflist = NULL;
            return sp;
        }
        if (++sp >= symtab + NHASH)
            sp = symtab;
    }
    fprintf(stderr, "Tabla de símbolos llena\n");
    abort();
}

void addref(int lineno, char *filename, char *word, int flags) {
    struct ref *r;
    struct symbol *sp = lookup(word);
    /* Evita duplicados en la misma línea y archivo */
    if (sp->reflist && sp->reflist->lineno == lineno &&
        sp->reflist->filename == filename)
        return;
    r = malloc(sizeof(struct ref));
    if (!r) {
        fputs("Sin memoria\n", stderr);
        abort();
    }
    r->next = sp->reflist;
    r->filename = filename;
    r->lineno = lineno;
    r->flags = flags;
    sp->reflist = r;
}

/* Función de comparación para qsort (insensible a mayúsculas) */
static int symcompare(const void *xa, const void *xb) {
    const struct symbol *a = xa;
    const struct symbol *b = xb;
    if (!a->name) {
        if (!b->name) return 0;
        return 1;
    }
    if (!b->name) return -1;
    return strcasecmp(a->name, b->name);
}

void printrefs() {
    struct symbol *sp;
    qsort(symtab, NHASH, sizeof(struct symbol), symcompare);
    for (sp = symtab; sp->name && sp < symtab + NHASH; sp++) {
        char *prevfn = NULL;
        struct ref *rp = sp->reflist;
        struct ref *rpp = NULL;
        struct ref *rpn;
        /* Invertir la lista para orden cronológico */
        do {
            rpn = rp->next;
            rp->next = rpp;
            rpp = rp;
            rp = rpn;
        } while (rp);
        printf("%10s", sp->name);
        for (rp = rpp; rp; rp = rp->next) {
            if (rp->filename == prevfn)
                printf(" %d", rp->lineno);
            else {
                printf(" %s:%d", rp->filename, rp->lineno);
                prevfn = rp->filename;
            }
        }
        printf("\n");
    }
}
%}

%%
 /* Palabras comunes que se ignoran (con variaciones de mayúsculas) */
[Gg]et |
[Ii]s |
[Oo]f |
[Oo]n |
[Tt]he |
[Tt]o  { ; }

 /* Palabras normales: ahora incluyen mayúsculas y minúsculas */
[A-Za-z]+('[st])?  { addref(yylineno, curfilename, yytext, 0); }

 /* Salto de línea: necesario para evitar "scanner jammed" */
\n  ;

 /* Cualquier otro carácter se ignora */
.  ;
%%

int main(int argc, char *argv[]) {
    int i;
    if (argc < 2) {
        curfilename = "(stdin)";
        yylineno = 1;
        yylex();
    } else {
        for (i = 1; i < argc; i++) {
            FILE *f = fopen(argv[i], "r");
            if (!f) {
                perror(argv[i]);
                return 1;
            }
            curfilename = argv[i];
            yyrestart(f);
            yylineno = 1;
            yylex();
            fclose(f);
        }
    }
    printrefs();
    return 0;
}
