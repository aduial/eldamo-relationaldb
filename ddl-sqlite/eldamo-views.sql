-- lexicon_changes source

CREATE VIEW lexicon_changes AS
SELECT
    e1.ID entry_id
    , f4.TXT ||
    CASE
        WHEN g4.TXT IS NULL THEN ''
        ELSE ' "' || g4.TXT || '"'
    END || ' ' || f2.TXT ||
    CASE
        WHEN g2.TXT IS NULL THEN ''
        ELSE ' "' || g2.TXT || '"'
    END || ' ' || (
        s4.PREFIX || '/' || REPLACE(
            Group_concat(
                DISTINCT ltrim(
                    substr(
                        e4.SOURCE
                        , (
                            instr(
                                e4.SOURCE
                                , '/'
                            ) + 1
                        )
                        , (
                            instr(
                                e4.SOURCE
                                , '.'
                            ) - (
                                (
                                    instr(
                                        e4.SOURCE
                                        , '/'
                                    ) + 1
                                )
                            )
                        )
                    )
                    , 0
                )
            )
            , ','
            , ', '
        )
    ) related
    , f4.TXT form1
    , g4.TXT gloss1
    , f2.TXT form2
    , g2.TXT gloss2
    , (
        s4.PREFIX || '/' || REPLACE(
            Group_concat(
                DISTINCT ltrim(
                    substr(
                        e4.SOURCE
                        , (
                            instr(
                                e4.SOURCE
                                , '/'
                            ) + 1
                        )
                        , (
                            instr(
                                e4.SOURCE
                                , '.'
                            ) - (
                                (
                                    instr(
                                        e4.SOURCE
                                        , '/'
                                    ) + 1
                                )
                            )
                        )
                    )
                    , 0
                )
            )
            , ','
            , ', '
        )
    ) AS sources
FROM
    ENTRY e1
JOIN ENTRY e2 ON
    e2.PARENT_ID = e1.ID
JOIN FORM f2 ON
    f2.ID = e2.FORM_ID
LEFT OUTER JOIN GLOSS g2 ON
    g2.id = e2.GLOSS_ID
JOIN ENTRY e3 ON
    e3.FORM_ID = e2.FORM_ID
    AND e3.SOURCE = e2.SOURCE
JOIN ENTRY e4 ON
    e4.ID = e3.PARENT_ID
JOIN FORM f4 ON
    f4.id = e4.FORM_ID
JOIN SOURCE s4 ON
    s4.ID = e4.SOURCE_ID
LEFT OUTER JOIN GLOSS g4 ON
    g4.id = e4.GLOSS_ID
WHERE
    e1.PARENT_ID IS NULL
    AND e3.ENTRY_TYPE_ID = 122
GROUP BY
    f4.ID
    , g4.ID;


-- lexicon_cognates source

CREATE VIEW lexicon_cognates AS
SELECT DISTINCT e1.ID entry_id
     , l5.LANG language
     , f5.TXT form
     , g5.TXT gloss
     , REPLACE(group_concat(substr( e4.source ,  0, instr(e4.source , '.') ) ), ',', ', ') sources
FROM ENTRY e1 
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN ENTRY e3 ON e3.FORM_ID = e2.FORM_ID AND e3.SOURCE = e2.SOURCE
JOIN ENTRY e4 ON e3.PARENT_ID = e4.ID 
JOIN ENTRY e5 ON e4.PARENT_ID = e5.ID 
JOIN LANGUAGE l5 ON e5.LANGUAGE_ID = l5.ID 
JOIN FORM f5 ON e5.FORM_ID = f5.ID 
LEFT OUTER JOIN GLOSS g5 ON e5.GLOSS_ID = g5.ID 
WHERE (e1.ENTRY_TYPE_ID = 100 OR e1.ENTRY_TYPE_ID = 120) -- entry OR word
AND e2.ENTRY_TYPE_ID = 121 --ref
AND e3.ENTRY_TYPE_ID = 106 -- cognate
GROUP BY e5.ID
UNION
SELECT e1.ID entry_id
     , l3.LANG language
     , f3.TXT form
     , g3.TXT gloss
     , '[word cognate]' sources
FROM ENTRY e1
JOIN ENTRY e2 ON e2.FORM_ID = e1.FORM_ID AND e2.LANGUAGE_ID  = e1.LANGUAGE_ID 
JOIN ENTRY e3 ON e3.ID = e2.PARENT_ID 
JOIN LANGUAGE l3 ON e3.LANGUAGE_ID = l3.ID 
JOIN FORM f3 ON e3.FORM_ID = f3.ID 
LEFT OUTER JOIN GLOSS g3 ON e3.GLOSS_ID = g3.ID
WHERE (e1.ENTRY_TYPE_ID = 100 OR e1.ENTRY_TYPE_ID = 120)  
AND e2.ENTRY_TYPE_ID = 106;

-- lexicon_glosses source

CREATE VIEW lexicon_glosses AS
SELECT ewd.ID entry_id
, g.TXT gloss
, (s.PREFIX || '/' || Replace(Group_concat(DISTINCT ltrim(substr(erf.SOURCE, (instr(erf.SOURCE, '/') + 1), (instr(erf.SOURCE, '.') - ((instr(erf.SOURCE, '/') + 1)))), 0)
), ',', ', ')) AS reference
FROM ENTRY ewd
JOIN ENTRY erf ON erf.PARENT_ID  = ewd.ID 
JOIN SOURCE s ON s.ID = erf.SOURCE_ID 
JOIN GLOSS g ON erf.GLOSS_ID = g.ID 
WHERE erf.ENTRY_TYPE_ID = 121
GROUP BY g.ID
ORDER BY erf.ID;

-- lexicon_header source

CREATE VIEW lexicon_header AS
SELECT e.ID entry_id, f.TXT, l.LANG, es.speechtypes, c.LABEL 
FROM ENTRY e 
JOIN FORM f ON e.FORM_ID = f.ID 
JOIN entry_speech es ON es.entry = e.id
JOIN LANGUAGE l ON e.LANGUAGE_ID = l.ID 
LEFT OUTER JOIN GLOSS g ON e.GLOSS_ID = g.ID 
LEFT OUTER JOIN CAT c ON e.CAT_ID = c.ID 
WHERE e.ENTRY_CLASS_ID = 600;


-- lexicon_references source

CREATE VIEW lexicon_references AS
SELECT entry_id,
group_concat(sourcerefs, '; ') AS 'references'
FROM (
SELECT ewd.ID entry_id
, erf.ID eref_id
, (s.PREFIX || '/' || Replace(Group_concat(DISTINCT ltrim(substr(erf.SOURCE, (instr(erf.SOURCE, '/') + 1), (instr(erf.SOURCE, '.') - ((instr(erf.SOURCE, '/') + 1)))), 0)
), ',', ', ')) AS sourcerefs
FROM ENTRY ewd
JOIN ENTRY erf ON erf.PARENT_ID = ewd.ID 
JOIN SOURCE s ON s.ID = erf.SOURCE_ID 
WHERE erf.ENTRY_TYPE_ID = 121
GROUP BY ewd.ID, erf.SOURCE_ID ) entry_refs
GROUP BY entry_refs.entry_id;

-- lexicon_related source

CREATE VIEW lexicon_related AS
SELECT e1.ID entry_id
     , f4.TXT || CASE WHEN g4.TXT IS NULL THEN '' ELSE ' "' || g4.TXT || '"' END || ' ' || ed3.doc || ' ' || f2.TXT || CASE WHEN g2.TXT IS NULL THEN '' ELSE ' "' || g2.TXT || '"' END
     , f4.TXT form1
     , g4.TXT gloss1
     , ed3.doc doc
     , f2.TXT form2
     , g2.TXT gloss2
FROM ENTRY e1
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN FORM f2 ON f2.ID = e2.FORM_ID 
LEFT OUTER JOIN GLOSS g2 ON g2.id = e2.GLOSS_ID
JOIN ENTRY e3 ON e3.FORM_ID = e2.FORM_ID AND e3.SOURCE = e2.SOURCE 
LEFT OUTER JOIN entry_doc ed3 ON e3.ID = ed3.entry_id 
JOIN ENTRY e4 ON e4.ID = e3.PARENT_ID 
JOIN FORM f4 ON f4.id = e4.FORM_ID
LEFT OUTER JOIN GLOSS g4 ON g4.id = e4.GLOSS_ID
WHERE e3.ENTRY_TYPE_ID = 113
AND e1.PARENT_ID IS NULL 
UNION ALL
SELECT e1.ID entry_id
     , f2.TXT || CASE WHEN g2.TXT IS NULL THEN '' ELSE ' "' || g2.TXT || '"' END || ' ' || ed3.doc || ' ' || f3.TXT || CASE WHEN g3.TXT IS NULL THEN '' ELSE ' "' || g3.TXT || '"' END
     , f2.TXT form1 
     , g2.TXT gloss1
     , ed3.doc doc
     , f3.TXT form2
     , g3.TXT gloss2
FROM ENTRY e1
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN FORM f2 ON f2.ID = e2.FORM_ID 
LEFT OUTER JOIN GLOSS g2 ON g2.id = e2.GLOSS_ID
JOIN ENTRY e3 ON e3.PARENT_ID = e2.ID 
JOIN FORM f3 ON f3.ID = e3.FORM_ID 
LEFT OUTER JOIN GLOSS g3 ON g3.ID = e3.GLOSS_ID 
LEFT OUTER JOIN entry_doc ed3 ON e3.ID = ed3.entry_id 
WHERE e3.ENTRY_TYPE_ID = 113
AND e1.PARENT_ID IS NULL;


-- simplexicon source

CREATE VIEW simplexicon AS
SELECT e.ID id
  , e.MARK mark
  , f.TXT form
  , e.language_id language_id
  , l.name languagename
  , g.TXT gloss
  , c.LABEL cat
  , sf.TXT stem
  , t2.TXT entry_class
  , t1.TXT entry_type
FROM entry e
JOIN form f ON e.FORM_ID = f.ID
JOIN language l ON e.language_id = l.id
JOIN gloss g ON e.GLOSS_ID = g.ID
LEFT OUTER JOIN CAT c ON e.CAT_ID = c.ID
LEFT OUTER JOIN form sf ON e.STEM_FORM_ID = sf.id
JOIN TYPE t1 ON e.ENTRY_TYPE_ID = t1.ID 
JOIN TYPE t2 ON e.ENTRY_CLASS_ID = t2.ID;

-- entry_doc source

CREATE VIEW entry_doc AS
SELECT r.FROM_ID entry_id, d.ID doc_id, d.TXT doc, t.TXT doctype
FROM RELATION r
JOIN DOC d ON r.TO_ID = d.ID 
JOIN TYPE t ON t.ID = d.DOCTYPE_ID 
WHERE r.FROM_TYPE_ID = 500
AND r.TO_TYPE_ID = 503;

-- entry_speech source

CREATE VIEW entry_speech AS
SELECT e.ID entry
     , Group_concat(st.TXT) AS speechtypes
     , e.ENTRY_CLASS_ID
     , e.ENTRY_TYPE_ID
FROM RELATION r
JOIN ENTRY e ON e.ID = r.FROM_ID 
JOIN speech_type st ON r.TO_ID = st.ID 
WHERE r.FROM_TYPE_ID = 500
AND r.TO_TYPE_ID = 502
GROUP BY e.ID;

-- related_to_root source

CREATE VIEW related_to_root AS
SELECT e1.ID entry1_id
     , t1.TXT type1
     , e1.ENTRY_TYPE_ID type1_id
     , e2.ID entry2_id
     , t2.TXT type2
     , e2.ENTRY_TYPE_ID type2_id
     , g2.TXT root
     , root.ID root_id
FROM ENTRY e1 
JOIN ENTRY e2 
ON e1.SOURCE = e2.SOURCE
AND e1.FORM_ID = e2.FORM_ID 
JOIN TYPE t1 ON t1.ID = e1.ENTRY_TYPE_ID
JOIN TYPE t2 ON t2.ID = e2.ENTRY_TYPE_ID
JOIN ENTRY root ON e2.PARENT_ID = root.ID 
JOIN GLOSS g2 ON g2.ID = e2.GLOSS_ID 
WHERE e1.ID != e2.ID
AND e1.SOURCE != ''
AND e2.SOURCE != ''
AND root.ENTRY_CLASS_ID = 603;

-- related_form_source source

CREATE VIEW related_form_source AS
SELECT e1.ID entry1_id
     , e1.ENTRY_TYPE_ID type1_id
     , t1.TXT type1
     , e2.ID entry2_id
     , e2.ENTRY_TYPE_ID type2_id
     , t2.TXT type2
FROM ENTRY e1 
JOIN ENTRY e2 
ON e1.SOURCE = e2.SOURCE
AND e1.FORM_ID = e2.FORM_ID 
JOIN TYPE t1 ON t1.ID = e1.ENTRY_TYPE_ID
JOIN TYPE t2 ON t2.ID = e2.ENTRY_TYPE_ID
WHERE e1.ID != e2.ID
AND e1.SOURCE != ''
AND e2.SOURCE != '';

-- v_entry source

CREATE VIEW v_entry AS
SELECT e.ID
     , e.PARENT_ID
     , e.ENTRY_TYPE_ID
     , e.LANGUAGE_ID
     , e.FORM_ID
     , e.GLOSS_ID
     , e.SOURCE
     , CASE WHEN l.LANG IS NULL THEN '' ELSE l.LANG || ' || ' END || f.TXT || CASE WHEN e.GLOSS_ID IS NULL THEN '' ELSE ' || ' || g.TXT END short
     , CASE WHEN l.LANG IS NULL THEN '' ELSE l.LANG || ' || ' END || f.TXT || CASE WHEN e.GLOSS_ID IS NULL THEN '' ELSE ' || ' || g.TXT END || CASE WHEN e.SOURCE IS '' THEN '' ELSE ' || ' || e.SOURCE END medium
     , CASE WHEN l.LANG IS NULL THEN '' ELSE l.LANG || ' || ' END || f.TXT || CASE WHEN e.GLOSS_ID IS NULL THEN '' ELSE ' || ' || g.TXT END || ' || ' || t1.TXT || CASE WHEN t2.TXT IS NULL THEN '' ELSE ' || ' || t2.TXT END types
     , l.LANG language
     , f.TXT form
     , g.TXT gloss
     , t1.TXT entrytype
     , t2.TXT entryclass
FROM ENTRY e
JOIN TYPE t1 ON t1.ID = e.ENTRY_TYPE_ID 
LEFT OUTER JOIN TYPE t2 ON t2.ID = e.ENTRY_CLASS_ID 
LEFT OUTER JOIN LANGUAGE l ON l.ID = e.LANGUAGE_ID 
JOIN FORM f ON f.id = e.FORM_ID
LEFT OUTER JOIN GLOSS g ON g.id = e.GLOSS_ID;


-- class_form_type source

CREATE VIEW class_form_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'class-form-type';

-- class_form_variant_type source

CREATE VIEW class_form_variant_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'class-form-variant-type';

-- doc_type source

CREATE VIEW doc_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'doc-type';

-- entity_type source

CREATE VIEW entity_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'entity-type';

-- entry_class source

CREATE VIEW entry_class AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'entry-class';

-- entry_type source

CREATE VIEW entry_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'entry-type';

-- inflect_type source

CREATE VIEW inflect_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'inflect-type';

-- inflect_variant_type source

CREATE VIEW inflect_variant_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'inflect-variant-type';

-- source_type source

CREATE VIEW source_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'source-type';

-- speech_type source

CREATE VIEW speech_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'speech-type';

-- relation_type source

CREATE VIEW relation_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'relation-type';