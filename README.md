# eldamo-relationaldb

The intention of this project is to create a dictionary of the languages described by JRR Tolkien. 
Of course there are already a number of Elvish dictionaries out there, but anything that contains a fixed vocabulaire soon becomes deprecated with the ongoing changes and updates of the corpus of linguistic data published in Parma Eldalamberon and Vinya Tengwar.

Therefore we want to create a dictionary that uses a well-designed database that is centrally managed, so that periodical updates can be pushed to (or pulled from) any client application that uses it (we're still discussing about how to fill in that management part).

We wanted this dictionary to be as thorough and complete as possible while also offering the flexibility for the user to add their own reconstructed vocabulary.

In a next stage we will focus on building a client application (possibly using Python and Kivy) that uses this database, although anyone is of course free to build their own web-based, desktop or mobile application as a front-end. 
Of course, there will also be the possibility to enter or edit the central database. This, too, is still being discussed. 

As starting point we decided to 'fork' Paul Strack's Eldamo project @ https://github.com/pfstrack/eldamo 
In this initial commit are included:

- a MySQL dump file containing both db creation DDL and data insert scripts
- a diagram of the database table structure 
