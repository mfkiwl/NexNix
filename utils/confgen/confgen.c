/*
    confgen.c - generates a configuration script from configuration file
    SPDX-License-Identifier: ISC
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <libgen.h>
#include <ctype.h>
#include <errno.h>

#define LINESZ 256
#define VARMAX 4

char* progname = NULL;

void parsefile(FILE* src, FILE* dest, FILE* hdr);

// Makes the program exit
void panic(char* str, ...)
{
    // Print out prefix message
    printf("%s: ", progname);
    va_list list;
    va_start(list, str);
    vprintf(str, list);
    va_end(list);
    // Print newline
    printf("\r\n");
}

int runsubprojects(char* title, FILE* dest, FILE* hdr)
{
    if(!title)
        return 0;
    // Get the title of this project variable
    char* projvar = malloc(strlen(title) + 10);
    if(!projvar)
    {
        panic("out of memory");
        return 2;
    }
    strcpy(projvar, title);
    strcat(projvar, "_PROJECTS");
    // Get the variable value
    char* val = getenv(projvar);
    if(!val)
    {
        free(projvar);
        return 0;
    }
    free(projvar);
    // Parse the string
    char* proj = strtok(val, " ");
    do
    {
        // Open up this file, first preparing the path of this file
        char* filepath = malloc((strlen(proj) * 2) + 5);
        strcpy(filepath, proj);
        strcat(filepath, "/");
        strcat(filepath, proj);
        strcat(filepath, ".cfg");
        FILE* file = fopen(filepath, "r");
        if(!file)
        {
            panic("%s: %s\n", filepath, strerror(errno));
            free(filepath);
            return 1;
        }
        // Parse it
        parsefile(file, dest, hdr);
    } while((proj = strtok(NULL, " ")) != NULL);
    return 0;
}

// Parses a configuration file
void parsefile(FILE* src, FILE* dest, FILE* hdr)
{
    // Begin parsing the file,
    char* line = (char*)malloc(LINESZ);
    if(!line)
    {
        panic("out of memory");
        fclose(src);
        fclose(dest);
        fclose(hdr);
        exit(1);
    }
    char* orgline = line;
    char* title = NULL;
    int exiting = 0;
    while(fgets(line, LINESZ, src))
    {
        // Start by shaving off all whitespace
        while(isspace(*line))
            ++line;
        // Check if this line is whitespace
        if(*line == '\0')
            continue;
        // Is this is a comment?
        if(*line == '#')
            continue;
        // Remove all whitespace from the end of the string
        int len = strlen(line) - 1;
        while(isspace(line[len]))
            --len;
        line[len + 1] = '\0';
        // Now check if this marks the title
        if(line[0] == ':')
        {
            // If there was a previous title, run all of its sub-configuration files
            if(title)
            {
                int res = runsubprojects(title, dest, hdr);
                if(res == 1)
                {
                    free(title);
                    free(orgline);
                    fclose(dest);
                    fclose(src);
                    fclose(hdr);
                    exit(1);
                }
                else if(res == 2)
                {
                    free(orgline);
                    fclose(dest);
                    fclose(src);
                    fclose(hdr);
                    exit(1);
                }
                free(title);
            }
            // Copy it over
            ++line;
            title = malloc(len - 1);
            if(!title)
            {
                panic("out of memory");
                free(orgline);
                fclose(dest);
                fclose(src);
                fclose(hdr);
                exit(1);
            }
            strcpy(title, line);
            line = orgline;
            continue;
        }
        // This is a variable assignment. Get everything up until the first whitespace
        // character or an equals sign
        char* name = line;
        // Terminate it
        int i = 0;
        len = strlen(line);
        while(!isspace(name[i]) && name[i] != '=')
        {
            ++i;
            if(i == len)
            {
                panic("unterminated variable");
                free(orgline);
                fclose(dest);
                fclose(src);
                fclose(hdr);
                exit(1);
            }
        }
        name[i] = '\0';
        // Move to after variable name
        line += (i + 1);
        // Go to the value now
        while(isspace(*line) || *line == '=')
            ++line;
        char* val = line;
        // Remove quotation marks from line
        if(*val == '"')
        {
            len = strlen(val) - 1;
            ++val;
        }
        else
            len = strlen(val);
        int foundquote = 0;
        if(val[len - 1] == '"')
        {
            foundquote = 1;
            val[len - 1] = '\0';
        }
        // Now we must evaluate variables inside of this expression
        int foundvar = 0;
        char* varstart = NULL;
        char* evaledline = calloc(1, LINESZ * 2);
        if(!evaledline)
        {
            free(title);
            free(orgline);
            fclose(src);
            fclose(dest);
            fclose(hdr);
            exit(1);
        }
        int elpos = 0;
        for(int i = 0; i < len; ++i)
        {
            if(val[i] == '$')
            {
                if(!foundvar)
                {
                    // Save data about this
                    varstart = &val[i] + 1;
                    foundvar = 1;
                }
                else
                {
                    // Evaluate the variable
                    foundvar = 0;
                    int sz = (val + i) - varstart;
                    char* name = malloc(sz);
                    memcpy(name, varstart, sz);
                    // Get the variable
                    char* val = getenv(name);
                    if(!val)
                    {
                        panic("unable to find variable %s", name);
                        free(name);
                        exiting = 1;
                        goto free;
                    }
                    // Copy it to evaledline
                    strcpy(evaledline + elpos, val);
                    elpos += strlen(val);
                    free(name);
                }
            }
            if(!foundvar)
            {
                if(val[i] != '$')
                {
                    evaledline[elpos] = val[i];
                    ++elpos;
                }
            }
        }
        // Check for an unterminated variable
        if(foundvar)
        {
            panic("unterminated variable reference");
            exiting = 1;
            goto free;
        }
        // Prepend the title now
        int titlelen = strlen(title);
        int namelen = strlen(name);
        char* fullname = malloc(namelen + titlelen + 2);
        if(!fullname)
        {
            panic("out of memory");
            goto free;
        }
        strcpy(fullname, title);
        fullname[titlelen] = '_';
        fullname[titlelen + 1] = '\0';
        strcat(fullname, name);
        // Now, we must set this enivronment variable
        setenv(fullname, evaledline, 1);
        // We have it parsed now. All that is left is to write this out
        // Write out the shell exporting part
        fwrite((void*)"export ", 7, 1, dest);
        fwrite(fullname, titlelen + namelen + 1, 1, dest);
        fwrite("=", 1, 1, dest);
        if(foundquote)
            --elpos;
        fwrite("\"", 1, 1, dest);
        fwrite(evaledline, elpos, 1, dest);
        fwrite("\"\n", 2, 1, dest);
        // Now write out the CMake variable part
        fwrite("export GLOBAL_CMAKEVARS=\"${GLOBAL_CMAKEVARS} ", 45, 1, dest);
        fwrite("-D", 2, 1, dest);
        fwrite(fullname, titlelen + namelen + 1, 1, dest);
        fwrite("=\\\"${", 5, 1, dest);
        fwrite(fullname, titlelen + namelen + 1, 1, dest);
        fwrite("}\\\"\" \n", 6, 1, dest);
        // Write out the header #define line
        fwrite("#define ", 8, 1, hdr);
        fwrite(fullname, titlelen + namelen + 1, 1, hdr);
        fwrite(" ", 1, 1, hdr);
        if(foundquote)
            fwrite("\"", 1, 1, hdr);
        fwrite(evaledline, elpos, 1, hdr);
        if(foundquote)
            fwrite("\"", 1, 1, hdr);
        fwrite("\n", 1, 1, hdr);
        free:
        free(evaledline);
        if(exiting)
        {
            free(title);
            free(orgline);
            fclose(src);
            fclose(dest);
            fclose(hdr);
            exit(1);
        }
        line = orgline;
    }
    line = orgline;
    // Run all subprojects
    runsubprojects(title, dest, hdr);
    free(line);
    if(title)
        free(title);
}

// Program entry point
int main(int argc, char** argv)
{
    progname = basename(argv[0]);
    // Grab the file we want to read and the output too
    if(argc < 4)
    {
        panic("configuration file and output file must be passed");
        exit(1);
    }
    // Open up input file
    FILE* conf = fopen(argv[1], "r");
    if(!conf)
    {
        panic("%s: %s\n", argv[1], strerror(errno));
        exit(1);
    }
    // Open up output file
    FILE* output = fopen(argv[2], "w");
    if(!output)
    {
        panic("%s: %s\n", argv[2], strerror(errno));
        exit(1);
    }
    // Open up header file
    FILE* hdr = fopen(argv[3], "w");
    if(!hdr)
    {
        panic("%s: %s\n", argv[3], strerror(errno));
        exit(1);
    }
    // Parse all the files
    parsefile(conf, output, hdr);
    // Cleanup files and memory
    fclose(conf);
    fclose(output);
    fclose(hdr);
    return 0;
}
