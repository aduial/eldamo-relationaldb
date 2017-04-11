# eldamo-relationaldb

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

It is likely that the model will evolve somewhat in the future.

In this initial commit are included:

- eldamo_db.sql: a MySQL dump file containing both db creation DDL and data insert scripts
- eldamo-diagram.png: a diagram of the database table structure 
- eldamo1.pl: the Perl script that I wrote to parse the eldamo.xml data with. Mind that this is a very 'rough' script, needing commenting and uncommenting parts in a certain order to create the table scripts. Use at your own risk.

- - - - - - - - - -
(1) Kivy is a cross-platform GUI library for Python applications https://kivy.org/#home so: build once & deploy on Linux, Windows, Mac OS, Android and iOS (2)

(2) OTOH: it turns out that it's much easier to create and deploy cross-platform Java GUI applications than it used to be when I last looked into it, for instance with *Codename One* (https://en.wikipedia.org/wiki/Codename_One). If that works well it could be a huge timesaver if you happen to be familiar with Java (like myself).

