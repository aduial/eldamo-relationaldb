# eldamo-relationaldb

# update for version 0.2.2
This release is compatible with eldamo v. 0.5.6

Description of the files:

- *eldamo-0.5.6.sqlite:* SQLite database containing Eldamo v0.5.6 
- *ddl-sqlite/eldamo-struct-sqlite.sql:* DDL file to generate the database structure with (SQLite dialect)
- *eldamo-mysql-erd.png:* (deprecated) ERD diagram of version 0.2.1 of the MYSQL database (Eldamo v0.5.5)
- *eldamo-sqlite-erd.png:* updated ERD diagram of the SQLite version of the database
- *table-data-sqlite_eldamo-0.5.6.zip:* zipped output of the eldamo.pl script for Eldamo v.0.5.6
- *eldamo.pl:* the Perl script used to parse the eldamo.xml data with. It will parse the XML file and can write all SQL table data scripts in one pass.
The XML filename is still hard-coded in the script but can be easily changed (`my $file`). By default it does not prefix the table names with the schema name, but that can also be set in the script (`my $schema`)
The script uses, and if necessary, creates a directory called 'output' in the current directory and will write the SQL files in there. If the directory and files already exist they will be overwritten. 
### - NOTE If you want to run this script on the eldamo data xml downloaded from eldamo.org, you will have to manually carry out one small edit: `<language-cat ... > ... </language-cat>` in the XML needs to be changed into `<language ...> ... </language>`
- usage: `eldamo.pl [ -s | -h ]`
- - the -s switch will create SQL output 
- - the -h switch will generate some debug info in SDOUT

- I used Perl v5.24.1 with some additional modules that you might need to install (e.g. using CPAN):

>     XML::Twig
>     Utils qw(:all)
>     Acme::Comment type => 'C++'
>     feature 'say'
>     File::Path qw(make_path)

#background

The intention of this project is to create a dictionary of the languages described by JRR Tolkien. 
Of course there are already a number of Elvish dictionaries out there, but anything that contains a fixed vocabulary soon becomes deprecated with the ongoing changes and updates of the corpus of linguistic data, as published in Parma Eldalamberon (http://www.eldalamberon.com/) and Vinyar Tengwar (http://www.elvish.org/VT/).

Therefore we want to create a dictionary that uses a well-designed database that will be updated as new content becomes available. 
We're still discussing about how to fill that in, but the central idea is to have a global database that is reachable online, and next to that, every client application will have a local database that is initially copied from the global database. If changes are submitted to the global database, we could then notify the clients that an update is available, so that they can download the update and apply that on their own copy. 
We could also have the clients check for updates periodically, eliminating the need for a notification. 

The advantage of this set-up is that the client would also function if they are offline. It will also be significantly faster if the data needn't be fetched over the internet. Note that even the very large Eldamo data set with all its notes, grammatical and phonological information still adds only ~15 Mb of data at the very most, which is not that much, compared to the size of the average application. 

Local clients can add their own (reconstructed) vocabulary if they want, but those changes will not be pushed to the central database. Maybe it would be useful for the client application to have an additional export / import feature for local changes, so that, say, a group of users could share reconstructed entries. 

We wanted this dictionary to be as thorough and complete as possible while also offering the flexibility for the user to add their own (reconstructed) entries on their local copy of the data set (*note that this not the same as adding new content to the database!*)

In a next stage we will focus on building a client application (possibly using Python and Kivy (1)) that uses this database, although anyone is of course free to build their own web-based, desktop or mobile application as a front-end. 
Of course, there will also be the possibility to enter or edit the central database. Supposedly we could use the same functionality for *editing the global database* as for *local edits*, where the first would require some kind of authorisation step to prevent vandalism :) But all this is still being discussed anyhow. 

As starting point we decided to 'fork' Paul Strack's phenomenal effort, the Eldamo project @ https://github.com/pfstrack/eldamo by translating his XML-based data model to a relational model. The model of this first commit allows all the data also found in Eldamo.xml, with the exception of the inflection table elements. 
In this initial commit are included:




- - - - - - - - - -
(1) Kivy is a cross-platform GUI library for Python applications https://kivy.org/#home so: build once & deploy on Linux, Windows, Mac OS, Android and iOS (2)

(2) OTOH: it turns out that it's much easier to create and deploy cross-platform Java GUI applications than it used to be when I last looked into it, for instance with *Codename One* (https://en.wikipedia.org/wiki/Codename_One). If that works well it could be a huge timesaver if you happen to be familiar with Java (like myself).

