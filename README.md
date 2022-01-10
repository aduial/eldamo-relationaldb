# Update for Eldamo v0.8

Description of the files:

- *eldamo.sqlite:* SQLite database containing Eldamo v0.8 
- *eldamo.pl:* script used to parse the Eldamo data XML with (for usage see below) 
- *ddl-sqlite/* table & view create scripts (views are in development)
- *ERD/* contains some ERD diagrams (outdated)
- *table-data/* data insert scripts

# eldamo.pl 

This script parses the Eldamo data file and writes the SQL insert scripts in one pass.

Usage: `eldamo.pl [ -s | -h ]`

- the -s switch will create SQL output 
- the -h switch will generate some debug info in SDOUT


Hardcoded parameters are:

- `$file` input filename (e.g. eldamo.xml)
- `$schema` database schema prefix (to be added to INSERT statements)
- `$outputdir` name of output directory; will be created if it not exists.

The script will overwrite existing `*.sql` files with the same name without warning.

Before it can be run, the script requires one manual edit in the [Eldamo.xml file](https://github.com/pfstrack/eldamo/blob/master/src/data/eldamo-data.xml): 

`<language-cat ... > ... </language-cat>` in the XML needs to be changed into `<language ...> ... </language>`

Perl version used: v5.34.0 (for this version) with the following required modules that can be installed using CPAN:

>     XML::Twig
>     Utils qw(:all)
>     Acme::Comment type => 'C++'
>     feature 'say'
>     File::Path qw(make_path)

# Purpose

The primary intention of this project is to create a relational database version of the Eldamo data set so that it can be used in the (mobile) [**Ithildin** app](https://github.com/aduial/ithildin).

# Licensing and attribution

[Eldamo-relationaldb](https://github.com/aduial/eldamo-relationaldb) by [Luthien Dulk, animatrice.nl](https://animatrice.nl) is based on Eldamo - An Elvish Lexicon by Paul Strack ([website](https://eldamo.org) & [Github repository](https://github.com/pfstrack/eldamo))

This repository is licensed under [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/) 
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-pink.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/80x15.png)](https://creativecommons.org/licenses/by-sa/4.0/)


