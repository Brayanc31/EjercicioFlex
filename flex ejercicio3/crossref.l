/*** fb2-5 C cross-ref con tabla dinamica (rehashing) ***/

%option noyywrap nodefault yylineno

%x COMMENT
%x IFILE

/* patrones nombrados complejos */
UCN    (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})
EXP    ([Ee][-+]?[0-9]+)
ILEN   ([Uu](L|LL|l|ll)?|(L|LL|l|ll)[Uu]?)

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------- Tabla de simbolos dinamica ---------- */
struct ref {
    struct ref *next;
    char *filename;
    int flags;      /* 01 = definicion */
    int lineno;
};

struct symbol {
    char *name;
    struct ref *reflist;
};

struct symbol *symtab;       /* tabla dinamica */
int symtab_size;             /* tamano actual */
int symtab_used;             /* numero de entradas ocupadas */
#define LOAD_FACTOR 0.7      /* factor de carga para rehash */

unsigned int symhash(char *sym);
struct symbol *lookup(char *sym);
void rehash(void);
void addref(int lineno, char *filename, char *word, int flags);
void printrefs(void);

/* ---------- Pila de archivos incluidos ---------- */
struct bufstack {
    struct bufstack *prev;
    YY_BUFFER_STATE bs;
    int lineno;
    char *filename;
    FILE *f;
} *curbs = NULL;

char *curfilename;
int defining;                /* 1 si estamos en una definicion */

int newfile(char *fn);
int popfile(void);

/* ---------- Comparacion para qsort (punteros) ---------- */
int symcompare(const void *xa, const void *xb) {
    const struct symbol *a = *(const struct symbol **)xa;
    const struct symbol *b = *(const struct symbol **)xb;
    return strcmp(a->name, b->name);
}

%}

%%

 /* comentarios */
"/*"			{ BEGIN(COMMENT); }
<COMMENT>"*/"		{ BEGIN(INITIAL); }
<COMMENT>([^*\n]+|\n)+	{ /* skip */ }
<COMMENT><<EOF>>	{
    printf("%s:%d: Comentario sin terminar\n", curfilename, yylineno);
    yyterminate();
}

 /* C++ comment (extension) */
"//".*			{ /* ignore */ }

 /* palabras clave de declaracion */
"Bool"|"Complex"|"Imaginary"|"auto"|"char"|"const"|"double"|"enum"|"extern"|"float"|"inline"|"int"|"long"|"register"|"restrict"|"short"|"signed"|"static"|"struct"|"typedef"|"union"|"unsigned"|"void"|"volatile"	{ defining = 1; }

 /* otras palabras clave */
"break"|"case"|"continue"|"default"|"do"|"else"|"for"|"goto"|"if"|"return"|"sizeof"|"switch"|"while"	{ /* ignore */ }

 /* constantes */
0[0-7]*{ILEN}?			{ /* ignore */ }
[1-9][0-9]*{ILEN}?		{ /* ignore */ }
0[xX][0-9a-fA-F]+{ILEN}?	{ /* ignore */ }
([0-9]*\.[0-9]+|[0-9]+\.){EXP}?[fFlL]?	{ /* ignore */ }
[0-9]+{EXP}[fFlL]?		{ /* ignore */ }
0[xX]([0-9a-fA-F]*\.[0-9a-fA-F]+|[0-9a-fA-F]+\.?)[pP][-+]?[0-9]+[fFlL]?	{ /* ignore */ }
\'([^'\\]|\\.|\\[0-7]{1,3}|\\x[0-9a-fA-F]+|{UCN})+\'	{ /* ignore */ }
L?\"([^"\\]|\\.|\\[0-7]{1,3}|\\x[0-9a-fA-F]+|{UCN})*\"	{ /* ignore */ }

 /* punctuadores que marcan fin de declaracion */
"{"|"<%"|";"		{ defining = 0; }

 /* otros punctuadores */
"["|"]"|"("|")"|"}"|"."|"->"|"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"|"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"..."|"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"|"##"|"<:"|":>"|"%>"|"%:"|"%:%:"	{ /* ignore */ }

 /* identificador */
([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})*	{
    addref(yylineno, curfilename, yytext, defining);
}

 /* espacios */
[ \t\n]+		{ /* ignore */ }
\\$			{ /* ignore */ }   /* barra invertida al final de linea */

 /* preprocesador (excepto include) */
^"#"[ \t]*if.*\n	{ /* ignore */ }
^"#"[ \t]*else.*\n	{ /* ignore */ }
^"#"[ \t]*endif.*\n	{ /* ignore */ }
^"#"[ \t]*define.*\n	{ /* ignore */ }
^"#"[ \t]*line.*\n	{ /* ignore */ }

 /* #include */
^"#"[ \t]*include[ \t]*[\"<]	{ BEGIN IFILE; }
<IFILE>[^>\"]+ {
    int c;
    while ((c = input()) && c != '\n') ;
    newfile(strdup(yytext));
    BEGIN INITIAL;
}
<IFILE>.|\n {
    fprintf(stderr, "%s:%d: linea include mal formada\n", curfilename, yylineno);
    BEGIN INITIAL;
}

<<EOF>>		{ if (!popfile()) yyterminate(); }

 /* caracter extrano */
.		{ printf("%s:%d: Caracter extrano '%s'\n", curfilename, yylineno, yytext); }

%%

/* ---------- Funciones de la tabla de simbolos ---------- */

unsigned int symhash(char *sym) {
    unsigned int hash = 0;
    unsigned char c;
    while ((c = *sym++)) hash = hash * 9 ^ c;
    return hash;
}

struct symbol *lookup(char *sym) {
    unsigned int h = symhash(sym);
    int index = h % symtab_size;
    int count = symtab_size;

    /* Rehash si el factor de carga se excede */
    if (symtab_used >= symtab_size * LOAD_FACTOR) {
        rehash();
        index = symhash(sym) % symtab_size;
        count = symtab_size;
    }

    while (count--) {
        if (symtab[index].name && strcmp(symtab[index].name, sym) == 0)
            return &symtab[index];
        if (!symtab[index].name) {
            symtab[index].name = strdup(sym);
            symtab[index].reflist = NULL;
            symtab_used++;
            return &symtab[index];
        }
        if (++index >= symtab_size) index = 0;
    }
    /* No deberia pasar */
    fprintf(stderr, "Error: tabla llena\n");
    exit(1);
}

void rehash(void) {
    int old_size = symtab_size;
    struct symbol *old_tab = symtab;
    int new_size = old_size * 2;
    struct symbol *new_tab = calloc(new_size, sizeof(struct symbol));
    if (!new_tab) {
        perror("rehash");
        exit(1);
    }

    for (int i = 0; i < old_size; i++) {
        if (old_tab[i].name) {
            unsigned int h = symhash(old_tab[i].name);
            int index = h % new_size;
            while (new_tab[index].name) {
                if (++index >= new_size) index = 0;
            }
            new_tab[index] = old_tab[i];
        }
    }
    symtab = new_tab;
    symtab_size = new_size;
    free(old_tab);
}

void addref(int lineno, char *filename, char *word, int flags) {
    struct ref *r;
    struct symbol *sp = lookup(word);

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

void printrefs(void) {
    /* Crear array de punteros a las entradas ocupadas */
    struct symbol **sorted = malloc(symtab_used * sizeof(struct symbol *));
    if (!sorted) {
        perror("malloc");
        return;
    }
    int j = 0;
    for (int i = 0; i < symtab_size; i++) {
        if (symtab[i].name)
            sorted[j++] = &symtab[i];
    }

    qsort(sorted, symtab_used, sizeof(struct symbol *), symcompare);

    for (int k = 0; k < symtab_used; k++) {
        struct symbol *sp = sorted[k];
        char *prevfn = NULL;

        /* invertir lista de referencias */
        struct ref *rp = sp->reflist;
        struct ref *rpp = NULL;
        struct ref *rpn;
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
            if (rp->flags & 01) printf("*");
        }
        printf("\n");
    }
    free(sorted);
}

/* ---------- Manejo de archivos incluidos ---------- */

int newfile(char *fn) {
    FILE *f = fopen(fn, "r");
    struct bufstack *bs = malloc(sizeof(struct bufstack));
    if (!f) {
        perror(fn);
        return 0;
    }
    if (!bs) {
        perror("malloc");
        exit(1);
    }
    if (curbs) curbs->lineno = yylineno;
    bs->prev = curbs;
    bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
    bs->f = f;
    bs->filename = fn;
    yy_switch_to_buffer(bs->bs);
    curbs = bs;
    yylineno = 1;
    curfilename = fn;
    return 1;
}

int popfile(void) {
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;
    if (!bs) return 0;
    fclose(bs->f);
    yy_delete_buffer(bs->bs);
    prevbs = bs->prev;
    free(bs);
    if (!prevbs) return 0;
    yy_switch_to_buffer(prevbs->bs);
    curbs = prevbs;
    yylineno = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}

/* ---------- Programa principal ---------- */

int main(int argc, char **argv) {
    int i;
    if (argc < 2) {
        fprintf(stderr, "Uso: %s archivo1 [archivo2 ...]\n", argv[0]);
        return 1;
    }

    /* Inicializar tabla dinamica */
    symtab_size = 1024;
    symtab = calloc(symtab_size, sizeof(struct symbol));
    if (!symtab) {
        perror("calloc");
        return 1;
    }
    symtab_used = 0;

    for (i = 1; i < argc; i++) {
        if (newfile(argv[i]))
            yylex();
    }

    printrefs();

    /* Liberar memoria */
    for (i = 0; i < symtab_size; i++) {
        if (symtab[i].name)
            free(symtab[i].name);
    }
    free(symtab);
    return 0;
}
