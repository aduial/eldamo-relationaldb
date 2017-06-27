--PRAGMA foreign_keys = OFF;
CREATE TABLE CAT (
	ID integer NOT NULL,
	LABEL varchar(255),
	PARENT_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (PARENT_ID) REFERENCES CAT (ID)
);
CREATE TABLE DOC (
	ID integer NOT NULL,
	TXT varchar(4000) NOT NULL,
	DOCTYPE_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (DOCTYPE_ID) REFERENCES TYPE (ID)
);
CREATE TABLE ENTRY (
	ID integer NOT NULL,
	FORM_ID integer NOT NULL,
	LANGUAGE_ID integer NOT NULL,
	GLOSS_ID integer,
	CAT_ID integer,
	RULE_FORM_ID integer,
	FROM_FORM_ID integer,
	STEM_FORM_ID integer,
	TENGWAR varchar(100),
	MARK varchar(10),
	ELDAMO_PAGEID varchar(50),
	ORDERFIELD varchar(50),
	ORTHO_FORM_ID integer,
	PARENT_ID integer,
	ORDERING integer,
	ENTRYTYPE_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID),
	FOREIGN KEY (GLOSS_ID) REFERENCES GLOSS (ID),
	FOREIGN KEY (FROM_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (STEM_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (RULE_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (ENTRYTYPE_ID) REFERENCES TYPE (ID),
	FOREIGN KEY (CAT_ID) REFERENCES CAT (ID)
);
CREATE TABLE ENTRY_DOC (
	ENTRY_ID integer NOT NULL,
	DOC_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	FOREIGN KEY (DOC_ID) REFERENCES DOC (ID),
	FOREIGN KEY (ENTRY_ID) REFERENCES ENTRY (ID)
);
CREATE TABLE EXAMPLE (
	LINKED_ID integer,
	REF_ID integer,
	SOURCE_ID integer NOT NULL,
	FORM_ID integer NOT NULL,
	ORDERING integer,
	EXAMPLETYPE_ID integer,
	FOREIGN KEY (FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (EXAMPLETYPE_ID) REFERENCES TYPE (ID),
	FOREIGN KEY (SOURCE_ID) REFERENCES SOURCE (ID),
	FOREIGN KEY (REF_ID) REFERENCES REF (ID),
	FOREIGN KEY (LINKED_ID) REFERENCES LINKED (ID)
);
CREATE TABLE FORM (
	ID integer NOT NULL,
	TXT varchar(255) NOT NULL,
	PRIMARY KEY (ID)
);
CREATE TABLE GLOSS (
	ID integer NOT NULL,
	LANGUAGE_ID integer NOT NULL,
	TXT varchar(255) NOT NULL,
	PRIMARY KEY (ID),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID)
);
CREATE TABLE GRAMMAR (
	ID integer NOT NULL,
	TXT varchar(100) NOT NULL,
	GRAMMARTYPE_ID integer NOT NULL,
	PRIMARY KEY (ID),
	FOREIGN KEY (GRAMMARTYPE_ID) REFERENCES TYPE (ID)
);
CREATE TABLE LANGUAGE (
	ID integer NOT NULL,
	NAME varchar(255) NOT NULL,
	MNEMONIC varchar(10),
	PARENT_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (PARENT_ID) REFERENCES LANGUAGE (ID)
);
CREATE TABLE LANGUAGE_DOC (
	LANGUAGE_ID integer NOT NULL,
	DOC_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	PRIMARY KEY (LANGUAGE_ID,DOC_ID,ORDERING),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID),
	FOREIGN KEY (DOC_ID) REFERENCES DOC (ID)
);
CREATE TABLE LINKED (
	ID integer NOT NULL,
	LINKEDTYPE_ID integer NOT NULL,
	ENTRY_ID integer,
	REF_ID integer,
	TO_LANGUAGE_ID integer,
	TO_ENTRY_ID integer,
	ORDERING integer,
	SOURCE_ID integer,
	MARK varchar(10),
	PRIMARY KEY (ID),
	FOREIGN KEY (TO_LANGUAGE_ID) REFERENCES LANGUAGE (ID),
	FOREIGN KEY (TO_ENTRY_ID) REFERENCES ENTRY (ID),
	FOREIGN KEY (ENTRY_ID) REFERENCES ENTRY (ID),
	FOREIGN KEY (SOURCE_ID) REFERENCES SOURCE (ID),
	FOREIGN KEY (REF_ID) REFERENCES REF (ID),
	FOREIGN KEY (LINKEDTYPE_ID) REFERENCES TYPE (ID)
);
CREATE TABLE LINKED_FORM (
	LINKED_ID integer NOT NULL,
	FORM_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	FOREIGN KEY (FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (LINKED_ID) REFERENCES LINKED (ID)
);
CREATE TABLE LINKED_GRAMMAR (
	LINKED_ID integer,
	ENTRY_ID integer,
	GRAMMAR_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	FOREIGN KEY (ENTRY_ID) REFERENCES ENTRY (ID),
	FOREIGN KEY (LINKED_ID) REFERENCES LINKED (ID),
	FOREIGN KEY (GRAMMAR_ID) REFERENCES GRAMMAR (ID)
);
CREATE TABLE REF (
	ID integer NOT NULL,
	ENTRY_ID integer,
	FORM_ID integer NOT NULL,
	GLOSS_ID integer,
	LANGUAGE_ID integer,
	SOURCE_ID integer NOT NULL,
	MARK varchar(10),
	RULE_FROMFORM_ID integer,
	RULE_RLFORM_ID integer,
	RULE_RULEFORM_ID integer,
	ORDERING integer,
	ENTRYTYPE_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID),
	FOREIGN KEY (GLOSS_ID) REFERENCES GLOSS (ID),
	FOREIGN KEY (FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (RULE_RLFORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (RULE_FROMFORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (RULE_RULEFORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (ENTRYTYPE_ID) REFERENCES TYPE (ID),
	FOREIGN KEY (ENTRY_ID) REFERENCES ENTRY (ID)
);
CREATE TABLE RULE (
	ID integer NOT NULL,
	ENTRY_ID integer NOT NULL,
	FROM_FORM_ID integer NOT NULL,
	RULE_FORM_ID integer NOT NULL,
	LANGUAGE_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	PRIMARY KEY (ID),
	FOREIGN KEY (RULE_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (FROM_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID),
	FOREIGN KEY (ENTRY_ID) REFERENCES ENTRY (ID)
);
CREATE TABLE RULESEQUENCE (
	DERIV_ID integer NOT NULL,
	FROM_FORM_ID integer,
	LANGUAGE_ID integer,
	RULE_FORM_ID integer,
	STAGE_FORM_ID integer,
	TO_ENTRY_ID integer,
	ORDERING integer,
	FOREIGN KEY (DERIV_ID) REFERENCES LINKED (ID),
	FOREIGN KEY (TO_ENTRY_ID) REFERENCES ENTRY (ID),
	FOREIGN KEY (STAGE_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (RULE_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (FROM_FORM_ID) REFERENCES FORM (ID),
	FOREIGN KEY (LANGUAGE_ID) REFERENCES LANGUAGE (ID)
);
CREATE TABLE SOURCE (
	ID integer NOT NULL,
	NAME varchar(255),
	PREFIX varchar(255),
	SOURCETYPE_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (SOURCETYPE_ID) REFERENCES TYPE (ID)
);
CREATE TABLE SOURCE_DOC (
	SOURCE_ID integer NOT NULL,
	DOC_ID integer NOT NULL,
	ORDERING integer NOT NULL,
	PRIMARY KEY (SOURCE_ID,DOC_ID,ORDERING),
	FOREIGN KEY (DOC_ID) REFERENCES DOC (ID)
);
CREATE TABLE TYPE (
	ID integer NOT NULL,
	TXT varchar(50) NOT NULL,
	PARENT_ID integer,
	PRIMARY KEY (ID),
	FOREIGN KEY (PARENT_ID) REFERENCES TYPE (ID)
);
--PRAGMA foreign_keys = ON;