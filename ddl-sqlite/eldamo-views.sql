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


-- entry_created source

CREATE VIEW entry_created AS
SELECT e.ID entry_id
     , Group_concat(c.TXT, ', ') AS created_by
     , e.ENTRY_CLASS_ID entry_class_id
     , e.ENTRY_TYPE_ID entry_type_id
FROM RELATION r
JOIN ENTRY e ON e.ID = r.FROM_ID 
JOIN CREATED c ON r.TO_ID = c.ID 
WHERE r.FROM_TYPE_ID = 500
AND r.TO_TYPE_ID = 501
GROUP BY e.ID;


-- entry_doc source

CREATE VIEW entry_doc AS
SELECT r.FROM_ID entry_id, d.ID doc_id, d.TXT doc, t.TXT doctype
FROM RELATION r
JOIN DOC d ON r.TO_ID = d.ID 
JOIN TYPE t ON t.ID = d.DOCTYPE_ID 
WHERE r.FROM_TYPE_ID = 500
AND r.TO_TYPE_ID = 503;


-- entry_inflection source

CREATE VIEW entry_inflection AS
SELECT entry_id
, group_concat(inflection, ', ') inflection
FROM (
SELECT DISTINCT e.ID entry_id
, t.TXT inflection
FROM ENTRY e
JOIN RELATION r ON e.ID = r.FROM_ID 
JOIN TYPE t ON r.TO_ID = t.ID AND t.PARENT_ID = 9
UNION
SELECT DISTINCT e.ID entry_id
, t.TXT inflection
FROM ENTRY e
JOIN RELATION r ON e.ID = r.FROM_ID 
JOIN TYPE t ON r.TO_ID = t.ID AND t.PARENT_ID = 10)
GROUP BY entry_id;


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


-- entry_type source

CREATE VIEW entry_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'entry-type';


-- gloss_exclude source

CREATE VIEW gloss_exclude AS
SELECT e1.ID entry_id
, e2.ID ref_id
, g2.TXT gloss
, e2.REF_SOURCES refsources
FROM ENTRY e1                           -- word 
JOIN ENTRY e2 ON e2.PARENT_ID  = e1.ID  -- ref
JOIN lgloss g2 ON e2.GLOSS_ID = g2.ID   -- gloss
JOIN ENTRY e3 ON (e3.PARENT_ID  = e2.ID 
AND ((e3.ENTRY_TYPE_ID = 111 AND e1.ENTRY_CLASS_ID = 600) -- lexical inflections
OR e3.ENTRY_TYPE_ID = 124))             -- corrections
WHERE e2.ENTRY_TYPE_ID = 121            -- ref
AND e1.ENTRY_CLASS_ID IN (600, 603)     -- lexical or root
AND e1.ENTRY_TYPE_ID IN (100, 120)      -- word / sub-word
ORDER BY 1, 2;


-- gloss_include source

CREATE VIEW gloss_include AS
SELECT e1.ID entry_id
, e2.ID ref_id
, g2.TXT gloss
, e2.REF_SOURCES refsources
FROM ENTRY e1                           -- word 
JOIN ENTRY e2 ON e2.PARENT_ID  = e1.ID  -- ref
JOIN lgloss g2 ON e2.GLOSS_ID = g2.ID   -- gloss
WHERE e2.ENTRY_TYPE_ID = 121            -- ref
AND e1.ENTRY_CLASS_ID IN (600, 603)     -- lexical or root
AND e1.ENTRY_TYPE_ID IN (100, 120)      -- word / sub-word
ORDER BY 1, 2;


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


-- lexicon_changes source

CREATE VIEW lexicon_changes AS
SELECT e1.ID entry_id
    , e2.MARK mark_from
    , f2.TXT || CASE WHEN f31.TXT IS NULL THEN '' ELSE ' >> ' || f31.TXT END form_from
    , e4.MARK mark_to
    , f3.TXT form_to
    , group_concat(e3.REF_SOURCES, '; ') sources   
    , e5.ID id_to
FROM ENTRY e1 -- entry
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID  
JOIN FORM f2 ON f2.ID = e2.FORM_ID
JOIN ENTRY e3 ON e3.PARENT_ID = e2.ID  
JOIN FORM f3 ON f3.ID = e3.FORM_ID 
JOIN ENTRY e4 ON e4.SOURCE = e3.SOURCE
JOIN ENTRY e5 ON e4.PARENT_ID = e5.ID  
LEFT OUTER JOIN FORM f31 ON f31.ID = e3.RULE_FORM_ID 
WHERE e3.ENTRY_TYPE_ID = 122 -- CHANGE
AND e2.ENTRY_TYPE_ID = 121 -- REF
AND e1.ENTRY_TYPE_ID IN (100, 120)
AND e4.ENTRY_TYPE_ID = 121 -- REF
GROUP BY e2.FORM_ID, e3.FORM_ID, e3.RULE_FORM_ID 
ORDER BY e3.ID;


-- lexicon_cognates source

CREATE VIEW lexicon_cognates AS
SELECT entry_id 
, language
, form 
, gloss
, group_concat(sources) sources
, cognate_id
FROM (
SELECT DISTINCT e1.ID entry_id
     , l5.LANG language
     , f5.TXT form
     , CASE WHEN g5.TXT IS NULL THEN '' ELSE g5.TXT END gloss
     , group_concat(e3.REF_SOURCES || CASE WHEN f4.LTXT == f5.LTXT THEN '' ELSE ' (' || f4.TXT || ')' END, ', ') sources
     , CASE WHEN e5.ENTRY_TYPE_ID IN (100, 120) THEN e5.ID ELSE NULL END cognate_id
FROM ENTRY e1                                                       -- entry
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID                               -- REF
JOIN ENTRY e3 ON e3.FORM_ID = e2.FORM_ID AND e3.SOURCE = e2.SOURCE  -- related cognate
JOIN ENTRY e4 ON e4.ID = e3.PARENT_ID 
JOIN lform f4 ON e4.FORM_ID = f4.ID 
JOIN ENTRY e5 ON e5.ID = e4.PARENT_ID
JOIN LANGUAGE l5 ON e5.LANGUAGE_ID = l5.ID 
JOIN lform f5 ON e5.FORM_ID = f5.ID 
LEFT OUTER JOIN GLOSS g5 ON e5.GLOSS_ID = g5.ID 
WHERE e2.ENTRY_TYPE_ID = 121 --ref
AND e3.ENTRY_TYPE_ID = 106 -- cognate
GROUP BY e5.ID
UNION
SELECT DISTINCT e1.ID entry_id
     , l5.LANG LANGUAGE
     , f5.TXT form
     , CASE WHEN g5.TXT IS NULL THEN '' ELSE g5.TXT END gloss
     , group_concat(e4.REF_SOURCES || CASE WHEN f4.LTXT == f5.LTXT THEN '' ELSE ' (' || f4.TXT || ')' END, ', ') sources
     , CASE WHEN e5.ENTRY_TYPE_ID IN (100, 120) THEN e5.ID ELSE NULL END cognate_id
FROM ENTRY e1                                                       -- entry
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID                               -- REF
JOIN ENTRY e3 ON e3.PARENT_ID = e2.ID                               -- cognate
JOIN ENTRY e4 ON e4.FORM_ID = e3.FORM_ID AND e4.SOURCE = e3.SOURCE  -- related ref
JOIN lform f4 ON e4.FORM_ID = f4.ID 
JOIN ENTRY e5 ON e5.ID = e4.PARENT_ID 
JOIN LANGUAGE l5 ON e5.LANGUAGE_ID = l5.ID 
JOIN lform f5 ON e5.FORM_ID = f5.ID 
LEFT OUTER JOIN GLOSS g5 ON e5.GLOSS_ID = g5.ID 
WHERE e2.ENTRY_TYPE_ID = 121 --ref
AND e3.ENTRY_TYPE_ID = 106 -- cognate
GROUP BY e5.ID)
GROUP BY form;


-- lexicon_combine source

CREATE VIEW lexicon_combine AS
SELECT e1.ID entry_id
, f1.TXT form_from
, l1.LANG lang_from
, e3.ID id_to
, f3.TXT form_to
, l3.LANG lang_to
FROM ENTRY e1 
JOIN FORM f1 ON e1.FORM_ID = f1.ID 
JOIN LANGUAGE l1 ON e1.LANGUAGE_ID  = l1.ID 
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN ENTRY e3 ON e3.LANGUAGE_ID = e2.LANGUAGE_ID AND e3.FORM_ID = e2.FORM_ID 
JOIN FORM f3 ON e3.FORM_ID = f3.ID 
JOIN LANGUAGE l3 ON e3.LANGUAGE_ID = l3.ID 
WHERE e2.ENTRY_TYPE_ID = 107 -- COMBINE
AND e3.ENTRY_TYPE_ID IN (100, 120) -- WORD OR ENTRY;


-- lexicon_elements source

CREATE VIEW lexicon_elements AS
SELECT entry_id 
, form_from
, gloss_from
, group_concat(inflection, '; ') inflection
, id_to
, form_to
, gloss_to
FROM (
SELECT DISTINCT e1.ID entry_id
, f1.TXT form_from
, g1.TXT gloss_from
, CASE WHEN ei.inflection IS NULL THEN '' ELSE 
 group_concat(DISTINCT ei.inflection) END inflection
, e3.ID id_to
, f3.TXT form_to
, g3.TXT gloss_to
FROM ENTRY e1 
JOIN FORM f1 ON e1.FORM_ID = f1.ID 
LEFT OUTER JOIN GLOSS g1 ON e1.GLOSS_ID = g1.ID
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
LEFT OUTER JOIN entry_inflection ei ON e2.ID = ei.entry_id 
JOIN ENTRY e3 ON e3.LANGUAGE_ID = e2.LANGUAGE_ID AND e3.FORM_ID  = e2.FORM_ID
JOIN FORM f3 ON e3.FORM_ID = f3.ID 
LEFT OUTER JOIN GLOSS g3 ON e3.GLOSS_ID = g3.ID
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e1.ENTRY_CLASS_ID IN (600, 603)
AND e2.ENTRY_TYPE_ID = 101 -- ELEMENT
AND e3.ENTRY_TYPE_ID IN (100, 120)
GROUP BY e2.ID
UNION
SELECT e1.ID entry_id
, f1.TXT form_from
, g1.TXT gloss_from
, group_concat(DISTINCT 
 (CASE WHEN (ei3.inflection IS NULL OR ei3.inflection = ei41.inflection) THEN '' ELSE ei3.inflection END ||
  CASE WHEN (ei3.inflection IS NOT NULL AND ei3.inflection != ei41.inflection) THEN ', ' ELSE '' END ||
  CASE WHEN ei41.inflection IS NULL THEN '' ELSE ei41.inflection END)) inflection
, e5.ID id_to
, f5.TXT form_to
, g5.TXT gloss_to
FROM ENTRY e1 
JOIN FORM f1 ON e1.FORM_ID = f1.ID 
LEFT OUTER JOIN GLOSS g1 ON e1.GLOSS_ID = g1.ID
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN ENTRY e3 ON e3.PARENT_ID = e2.ID 
LEFT OUTER JOIN entry_inflection ei3 ON e3.ID = ei3.entry_id 
JOIN ENTRY e4 ON e4.SOURCE = e3.SOURCE
LEFT OUTER JOIN ENTRY e41 ON e41.PARENT_ID = e4.ID
LEFT OUTER JOIN entry_inflection ei41 ON e41.ID = ei41.entry_id 
JOIN ENTRY e5 ON e4.PARENT_ID = e5.ID
JOIN FORM f5 ON e5.FORM_ID = f5.ID 
LEFT OUTER JOIN GLOSS g5 ON e5.GLOSS_ID = g5.ID
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e2.ENTRY_TYPE_ID = 121 -- REF
AND e3.ENTRY_TYPE_ID = 101 -- ELEMENT
AND e4.ENTRY_TYPE_ID = 121 -- REF
AND e41.ENTRY_TYPE_ID = 111 -- INFLECT
AND e5.ENTRY_TYPE_ID IN (100, 120)
GROUP BY e3.ID
)
GROUP BY form_from, id_to
ORDER BY entry_id, id_to;


-- lexicon_examples source

CREATE VIEW lexicon_examples AS
SELECT e1.ID entry_id
, f3.TXT form
, e3.source source
FROM ENTRY e1 
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID
JOIN ENTRY e3 ON e3.PARENT_ID = e2.ID
JOIN FORM f3 ON f3.ID = e3.FORM_ID 
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e3.ENTRY_TYPE_ID = 129;


-- lexicon_glosses source

CREATE VIEW lexicon_glosses AS
SELECT entry_id
, ref_id
, gloss
, REPLACE(group_concat(DISTINCT refsources), ',', '; ') sources
FROM (
SELECT * FROM gloss_include 
EXCEPT -- exclude rows that have specific child elements
SELECT * FROM gloss_exclude 
)
GROUP BY entry_id, gloss;


-- lexicon_header source

CREATE VIEW lexicon_header AS
SELECT e.ID entry_id, l.LANG language, f.TXT form, es.speechtypes type, g.TXT gloss, c.LABEL cat
FROM ENTRY e 
JOIN FORM f ON e.FORM_ID = f.ID 
LEFT OUTER JOIN entry_speech es ON es.entry = e.id
JOIN LANGUAGE l ON e.LANGUAGE_ID = l.ID 
LEFT OUTER JOIN GLOSS g ON e.GLOSS_ID = g.ID 
LEFT OUTER JOIN CAT c ON e.CAT_ID = c.ID 
WHERE e.ENTRY_CLASS_ID = 600
OR e.ENTRY_CLASS_ID = 603;


-- lexicon_inflections source

CREATE VIEW lexicon_inflections AS
SELECT DISTINCT e.ID entry_id
     , re.MARK mark
     , rf.TXT form
     , riv.inflections inflections
     , rg.TXT gloss
     , REPLACE(group_concat(DISTINCT re.REF_SOURCES || CASE WHEN d.TXT IS NULL THEN '' ELSE ': ' || d.TXT END), ',', '; ') AS 'references'
FROM entry e
JOIN entry re ON re.PARENT_ID = e.ID 
JOIN form rf ON re.FORM_ID = rf.ID
LEFT OUTER JOIN gloss rg ON re.GLOSS_ID = rg.ID
JOIN ref_inflect_var riv ON riv.parent_id = re.ID 
LEFT OUTER JOIN relation r ON r.FROM_ID = re.ID 
LEFT OUTER JOIN DOC d ON d.ID = r.TO_ID 
WHERE inflections != ''
GROUP BY form, gloss, re.MARK
ORDER BY inflections;


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
     , CASE WHEN e5.LANGUAGE_ID = e1.LANGUAGE_ID THEN '' ELSE l5.LANG END language_from
     , CASE WHEN f4.TXT IS NULL THEN '' ELSE '@' || f4.TXT END form_from
     , CASE WHEN g4.TXT IS NULL THEN '' ELSE g4.TXT END gloss_from
     , CASE WHEN ed3.doc IS NULL THEN (CASE WHEN ed4.doc IS NULL THEN '' ELSE ed4.doc END) ELSE ed3.doc END relation
     , '' language_to
     , CASE WHEN f2.TXT IS NULL THEN '' ELSE f2.TXT END form_to
     , CASE WHEN g2.TXT IS NULL THEN '' ELSE g2.TXT END gloss_to
     , e3.REF_SOURCES ref_sources
     , CASE WHEN e5.ENTRY_CLASS_ID IN (600, 603) THEN e5.ID ELSE NULL END related_id
FROM ENTRY e1
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN FORM f2 ON f2.ID = e2.FORM_ID 
LEFT OUTER JOIN GLOSS g2 ON g2.id = e2.GLOSS_ID
JOIN ENTRY e3 ON e3.SOURCE = e2.SOURCE AND e3.FORM_ID = e2.FORM_ID  
LEFT OUTER JOIN entry_doc ed3 ON e3.ID = ed3.entry_id 
JOIN ENTRY e4 ON e4.ID = e3.PARENT_ID 
LEFT OUTER JOIN entry_doc ed4 ON e4.ID = ed4.entry_id 
JOIN FORM f4 ON f4.id = e4.FORM_ID
LEFT OUTER JOIN GLOSS g4 ON g4.id = e4.GLOSS_ID
JOIN ENTRY e5 ON e5.ID = e4.PARENT_ID 
LEFT OUTER JOIN LANGUAGE l5 ON e5.LANGUAGE_ID = l5.ID 
WHERE e2.ENTRY_TYPE_ID = 121 -- REF (e1 is implicitly 100[entry] OR 120[word])
AND e3.ENTRY_TYPE_ID = 113 -- RELATED
UNION
SELECT e1.ID entry_id
     , '' language_from
     , CASE WHEN f1.TXT IS NULL THEN '' ELSE f1.TXT END form_from
     , CASE WHEN g1.TXT IS NULL THEN '' ELSE g1.TXT END gloss_from
     , CASE WHEN ed2.doc IS NULL THEN '' ELSE ed2.doc END relation
     , CASE WHEN e3.LANGUAGE_ID = e1.LANGUAGE_ID THEN '' ELSE l3.LANG END language_to
     , CASE WHEN f2.TXT IS NULL THEN '' ELSE '@' || f2.TXT END form_to
     , CASE WHEN g2.TXT IS NULL THEN '' ELSE g2.TXT END gloss_to
     , '' ref_sources
     , CASE WHEN e3.ENTRY_CLASS_ID IN (600, 603) THEN e3.ID ELSE NULL END related_id
FROM ENTRY e1
JOIN FORM f1 ON f1.ID = e1.FORM_ID 
LEFT OUTER JOIN GLOSS g1 ON g1.id = e1.GLOSS_ID
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN FORM f2 ON f2.ID = e2.FORM_ID 
LEFT OUTER JOIN GLOSS g2 ON g2.id = e2.GLOSS_ID
JOIN ENTRY e3 ON e3.LANGUAGE_ID = e2.LANGUAGE_ID AND e3.FORM_ID = e2.FORM_ID
LEFT OUTER JOIN entry_doc ed2 ON e2.ID = ed2.entry_id 
LEFT OUTER JOIN LANGUAGE l3 ON e3.LANGUAGE_ID = l3.ID 
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e2.ENTRY_TYPE_ID = 113 -- RELATED
AND e3.ENTRY_TYPE_ID IN (100, 120)
UNION
SELECT e1.ID entry_id
     , CASE WHEN e3.LANGUAGE_ID = e1.LANGUAGE_ID THEN '' ELSE l3.LANG END language_from
     , CASE WHEN f3.TXT IS NULL THEN '' ELSE '@' || f3.TXT END form_from
     , CASE WHEN g3.TXT IS NULL THEN '' ELSE g3.TXT END gloss_from
     , CASE WHEN ed2.doc IS NULL THEN '' ELSE ed2.doc END relation
     , '' language_to
     , CASE WHEN f1.TXT IS NULL THEN '' ELSE f1.TXT END form_to
     , CASE WHEN g1.TXT IS NULL THEN '' ELSE g1.TXT END gloss_to
     , '' ref_sources
     , CASE WHEN e3.ENTRY_CLASS_ID IN (600, 603) THEN e3.ID ELSE NULL END related_id
FROM ENTRY e1
JOIN FORM f1 ON f1.ID = e1.FORM_ID 
LEFT OUTER JOIN GLOSS g1 ON g1.id = e1.GLOSS_ID
JOIN ENTRY e2 ON e2.LANGUAGE_ID = e1.LANGUAGE_ID AND e2.FORM_ID = e1.FORM_ID
JOIN ENTRY e3 ON e2.PARENT_ID = e3.ID 
JOIN FORM f3 ON f3.ID = e3.FORM_ID 
LEFT OUTER JOIN GLOSS g3 ON g3.id = e3.GLOSS_ID
LEFT OUTER JOIN entry_doc ed2 ON e2.ID = ed2.entry_id 
LEFT OUTER JOIN LANGUAGE l3 ON e3.LANGUAGE_ID = l3.ID 
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e2.ENTRY_TYPE_ID = 113 -- RELATED
AND e3.ENTRY_TYPE_ID IN (100, 120)
ORDER BY entry_id;


-- lexicon_see source

CREATE VIEW lexicon_see AS
SELECT e1.ID entry_id
, l1.LANG language
, f1.TXT form
, t2.TXT see
, e3.ID see_id
FROM entry e1
JOIN FORM f1 ON e1.FORM_ID = f1.ID 
JOIN LANGUAGE l1 ON e1.LANGUAGE_ID = l1.ID 
JOIN entry e2 ON e2.PARENT_ID = e1.ID
JOIN TYPE t2 ON t2.ID = e2.ENTRY_TYPE_ID
JOIN entry e3 ON e3.LANGUAGE_ID = e2.LANGUAGE_ID AND e3.FORM_ID = e2.FORM_ID 
WHERE e2.ENTRY_TYPE_ID IN (116, 117, 118, 119)
AND e1.ENTRY_TYPE_ID IN (100, 120)
AND e3.ENTRY_TYPE_ID IN (100, 120);


-- lexicon_variations source

CREATE VIEW lexicon_variations AS
SELECT entry_id
, ref_id
, mark
, form
, REPLACE(group_concat(DISTINCT refsources), ',', '; ') sources
FROM (
SELECT * FROM var_include 
EXCEPT -- exclude rows that have specific child elements
SELECT * FROM var_exclude 
)
GROUP BY entry_id, nform;


-- lexicon_word_cognates source

CREATE VIEW lexicon_word_cognates AS
SELECT e1.ID entry_id
     , l3.LANG language
     , f3.TXT form
     , CASE WHEN g3.TXT IS NULL THEN '' ELSE g3.TXT END gloss
     , '[word cognate]' sources
FROM ENTRY e1
JOIN ENTRY e2 ON e2.FORM_ID = e1.FORM_ID AND e2.LANGUAGE_ID  = e1.LANGUAGE_ID 
JOIN ENTRY e3 ON e3.ID = e2.PARENT_ID 
JOIN LANGUAGE l3 ON e3.LANGUAGE_ID = l3.ID 
JOIN FORM f3 ON e3.FORM_ID = f3.ID 
LEFT OUTER JOIN GLOSS g3 ON e3.GLOSS_ID = g3.ID
WHERE (e1.ENTRY_TYPE_ID = 100 OR e1.ENTRY_TYPE_ID = 120)  
AND e2.ENTRY_TYPE_ID = 106;


-- lform source

CREATE VIEW lform AS 
SELECT 
f.ID as ID,
f.TXT AS TXT,
lower(f.TXT) AS LTXT,
f.NORMALTXT AS NORMALTXT 
FROM FORM f;


-- lgloss source

CREATE VIEW lgloss AS 
SELECT 
g.ID as ID,
g.LANGUAGE_ID as LANGUAGE_ID,
g.TXT AS TXT,
lower(g.TXT) AS LTXT
FROM GLOSS g;


-- ref_ernediad source

CREATE VIEW ref_ernediad AS
SELECT rf.ID, group_concat(t.TXT) inflect, tt.TXT 
FROM entry rf
JOIN RELATION r ON rf.ID = r.FROM_ID 
JOIN "TYPE" t ON r.TO_ID = t.ID 
JOIN "TYPE" tt ON r.RELATION_TYPE_ID = tt.ID 
--WHERE r.RELATION_TYPE_ID = 419
GROUP BY rf.ID;


-- ref_inflect_var source

CREATE VIEW ref_inflect_var AS
SELECT ref_id
     , parent_id
     , CASE WHEN inflection IS NULL THEN '' ELSE inflection END || CASE WHEN variant IS NULL THEN '' ELSE '; ' || variant END inflections
FROM(SELECT er.ID ref_id,
            er.PARENT_ID parent_id,
(SELECT group_concat(t.TXT, ' ')
FROM relation r 
JOIN TYPE t ON r.TO_ID = t.ID 
WHERE r.RELATION_TYPE_ID = 417
AND r.FROM_ID = er.ID
GROUP BY r.from_id) inflection,
(SELECT group_concat(t.TXT)
FROM relation r 
JOIN TYPE t ON r.TO_ID = t.ID 
WHERE r.RELATION_TYPE_ID = 418
AND r.FROM_ID = er.ID
GROUP BY r.from_id) variant
FROM ENTRY er
WHERE PARENT_ID IS NOT NULL);


-- ref_sources source

CREATE VIEW ref_sources AS
SELECT ref_id,
group_concat(sourcerefs, '; ') AS 'references'
FROM (
SELECT re.ID ref_id
, (rs.PREFIX || '/' || Replace(Group_concat(DISTINCT ltrim(substr(re.SOURCE, (instr(re.SOURCE, '/') + 1), (instr(re.SOURCE, '.') - ((instr(re.SOURCE, '/') + 1)))), 0)
), ',', ', ')) AS sourcerefs
FROM ENTRY re
JOIN SOURCE rs ON rs.ID = re.SOURCE_ID 
GROUP BY ref_id, rs.PREFIX ) 
GROUP BY ref_id;


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


-- relation_type source

CREATE VIEW relation_type AS
SELECT t_child.ID, t_child.TXT FROM TYPE t_child
JOIN TYPE t_parent ON t_child.PARENT_ID = t_parent.ID 
WHERE t_parent.TXT = 'relation-type';


-- simplexicon source

CREATE VIEW simplexicon AS
SELECT e.ID id
  , e.MARK mark
  , f.TXT form
  , f.NORMALTXT nform
  , e.language_id form_lang_id
  , l.LANG form_lang_abbr
  , CASE WHEN g.TXT IS NULL THEN '' ELSE g.TXT END gloss
  , g.language_id gloss_lang_id
  , c.LABEL cat
  , sf.TXT stem
  , ec.created_by created_by
  , e.ENTRY_CLASS_ID entry_class_id
  , t1.TXT entry_class
  , e.ENTRY_TYPE_ID entry_type_id
  , t2.TXT entry_type
FROM entry e
JOIN form f ON e.FORM_ID = f.ID
JOIN LANGUAGE l ON e.LANGUAGE_ID = l.ID 
LEFT OUTER JOIN gloss g ON e.GLOSS_ID = g.ID
LEFT OUTER JOIN CAT c ON e.CAT_ID = c.ID
LEFT OUTER JOIN form sf ON e.STEM_FORM_ID = sf.id
LEFT OUTER JOIN TYPE t1 ON e.ENTRY_CLASS_ID = t1.ID
LEFT OUTER JOIN TYPE t2 ON e.ENTRY_TYPE_ID = t2.ID
LEFT OUTER JOIN entry_created ec ON e.ID = ec.entry_id
WHERE (e.ENTRY_CLASS_ID = 600 OR e.ENTRY_CLASS_ID = 603)
ORDER BY nform ASC;


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


-- temp_lex_word_deriv source

CREATE VIEW temp_lex_word_deriv AS
SELECT e1.ID
, f1.TXT form_from
, g1.TXT gloss_from
, e3.ID
, f3.TXT form_to
, g3.TXT gloss_to
FROM ENTRY e1 
JOIN FORM f1 ON e1.FORM_ID = f1.ID 
LEFT OUTER JOIN GLOSS g1 ON e1.GLOSS_ID = g1.ID
JOIN ENTRY e2 ON e2.PARENT_ID = e1.ID 
JOIN ENTRY e3 ON e3.LANGUAGE_ID = e2.LANGUAGE_ID AND e3.FORM_ID  = e2.FORM_ID
JOIN FORM f3 ON e3.FORM_ID = f3.ID 
LEFT OUTER JOIN GLOSS g3 ON e3.GLOSS_ID = g3.ID
WHERE e1.ENTRY_TYPE_ID IN (100, 120)
AND e2.ENTRY_TYPE_ID = 114 -- DERIV
AND e3.ENTRY_TYPE_ID IN (100, 120);


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


-- var_exclude source

CREATE VIEW var_exclude AS
SELECT e1.ID entry_id
, e2.ID ref_id
, e2.mark mark
, f2.NORMALTXT nform
, f2.TXT form
, e2.REF_SOURCES refsources
FROM ENTRY e1                                                           -- word element 
JOIN lform f1 ON e1.FORM_ID = f1.ID  
JOIN lform f2 ON e2.FORM_ID = f2.ID 
JOIN ENTRY e2 ON e2.PARENT_ID  = e1.ID --AND f1.NORMALTXT = f2.NORMALTXT -- ON non-matching normalised forms
JOIN ENTRY e3 ON (e3.PARENT_ID  = e2.ID 
AND ((e3.ENTRY_TYPE_ID = 111 AND e1.ENTRY_CLASS_ID = 600) -- lexical inflections
OR e3.ENTRY_TYPE_ID = 124)) -- or corrections
WHERE e2.ENTRY_TYPE_ID = 121 -- REF
AND e1.ENTRY_CLASS_ID IN (600, 603) -- lexical OR root
AND e1.ENTRY_TYPE_ID IN (100, 120) -- word
ORDER BY 1, 2;


-- var_include source

CREATE VIEW var_include AS
SELECT e1.ID entry_id
, e2.ID ref_id
, e2.mark mark
, f2.NORMALTXT nform
, f2.TXT form
, e2.REF_SOURCES refsources
FROM ENTRY e1                                                           -- word element 
JOIN lform f1 ON e1.FORM_ID = f1.ID  
JOIN ENTRY e2 ON e2.PARENT_ID  = e1.ID --AND f1.NORMALTXT = f2.NORMALTXT -- ON non-matching normalised forms
JOIN lform f2 ON e2.FORM_ID = f2.ID 
WHERE e2.ENTRY_TYPE_ID = 121 -- REF
AND e1.ENTRY_CLASS_ID IN (600, 603) -- lexical OR root
AND e1.ENTRY_TYPE_ID IN (100, 120) -- WORD
ORDER BY 1, 2;