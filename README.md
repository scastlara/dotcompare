# NAME

dotcompare - A program to compare DOT files

# VERSION

v0.1.4

# SYNOPSIS

    dotcompare  --files file1.dot,file2.dot \\  
                --colors HARD               \\   
                --dot output.dot            \\   
                --table table.tbl           \\ 
                --venn venn.svg             \\ 
                --web graph.html               

# DESCRIPTION

This script compares two or more DOT (graphviz) files and 
prints the resulting merged DOT file with different 
colors for each group. 

By default, dotcompare will print the resulting graph to
STDOUT, but you can change it with the option -d (see options below).

Dotcompare has some optional outputs, each one specified by one 
option.

- - Venn diagram. 

    If given the option -v, dotcompare will create an
    svg file containing a venn diagram. In this image, you will be able to see
    a comparison of the counts of nodes and relationships in each input DOT file,
    and those nodes/relationships common to more than one file. The colors will be
    chosen using one of the profiles in data/colors.txt. By default, the color palette
    is set to be "SOFT". To change it, use the option -c (see options below).

- - Table. 

    Complementary to the venn diagram, one can choose to create a 
    table containing all the counts (so it can be used to create other plots or tables). The 
    table is already formated to be used by R. Load it to a dataframe using:

            df <-read.table(file="yourtable.tbl", header=FALSE)

- - Webpage with the graph. 

    With the option -w, one can create a webpage
    with a representation of the merged graph (with different colors for nodes and 
    relationships depending on their presence in each DOT file). To make this representation,
    dotcompare uses the Open Source library cytoscape.js. All the cytoscape.js code is
    embedded in the html file to allow maximum portability: the webpage and the graph work
    without any external file/script dependencies. This allows for an easy upload of the graph
    to any website.

# OPTIONS

- **-h**, **--help**               

    Shows this help. 

- **-f**, **--files** &lt;file1,file2,...>

    REQUIRED. Input DOT files, separated by commas.    

- **-d**, **--dot** &lt;filename.dot>

    Creates a merged dot file. Default to STDOUT.

- **-c**, **--colors** &lt;profile>

    Color profile to use: SOFT (default), HARD, LARGE or CBLIND.

- **-v**, **--venn** &lt;filename.svg>

    Creates a venn diagram with the results. 

- **-w**, **--web** &lt;filename.html>

    Writes html file with the graph using cytoscape.js

# INSTALLATION
To install dotcompare you have two options: either you move the files manually to wherever you want or you use the script `install.sh`. 

If you use `install.sh`, it will ask you in which directory you want to store the program and all the files it needs. You will need **ROOT** privileges to use install.sh, as it creates a symlink to dotcompare.pl in `/usr/local/bin` and a man page in `/usr/share/man/man1/`.

# AUTHOR

Sergio Castillo Lara - s.cast.lara@gmail.com

# BUGS AND PROBLEMS

## Current Limitations

- _Undirected\_graphs_ 

    Only works with directed graphs. If undirected, 
    dotcompare considers it to be directed.

- _Clusters_ 

    Still no clusters support eg: {A B C} -> D

- _Multiline IDs_ 

    No support for multiline IDs (yet).

## Reporting Bugs

Report Bugs at _https://github.com/scastlara/dotcompare/issues_ (still private)

# COPYRIGHT 

    (C) 2015 - Sergio CASTILLO LARA

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
