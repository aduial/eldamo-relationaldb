-- beforeview source

CREATE VIEW beforeview AS
SELECT 	l.id 			linked_id, 
		 	l.entry_id 	from_entry_id, 
		 	e2.id 		to_entry_id FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
JOIN entry e1 ON e1.id = l.entry_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
WHERE t.txt = 'before'
ORDER BY from_entry_id, to_entry_id ASC;


-- changeview source

CREATE VIEW changeview AS 
SELECT  l.ref_id          refidfrom,
        lf.ordering       lgorder, 
        f.txt             formtxt,
        s.name            sourcename, 
        s.prefix          sourceprefix, 
        l.source          sourcestring,
        t2.txt            sourcetypetxt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
WHERE t.txt = 'change'
ORDER BY l.ref_id, lf.ordering ASC;


-- classview source

CREATE VIEW classview AS
SELECT 	l.entry_id 		entryid, 
			l.mark 			mark,  
			lg.ordering 	lgorder, 
			g.txt 			grammartxt, 
			t2.txt 			grammartypetxt, 
			g.id 				grammarid FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_grammar lg ON l.id = lg.linked_id
JOIN grammar g ON g.id = lg.grammar_id
JOIN type t2 ON lg.grammartype_id = t2.id
WHERE t.txt = 'class'
ORDER BY l.entry_id, lg.ordering, t2.id ASC;


-- cognateview source

CREATE VIEW cognateview AS
SELECT  l.entry_id        entryidfrom, 
        e2.id             entryidto, 
        l.ref_id          refidfrom, 
        r.id              refidto, 
        ln.name           languageto, 
        f.txt             formtxt, 
        s.name            sourcename, 
        s.prefix          sourceprefix, 
        l.source          sourcestring,
        t2.txt            sourcetypetxt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
WHERE t.txt = 'cognate'
ORDER BY l.entry_id, l.ref_id, e2.id, r.id ASC;


-- correctionview source

CREATE VIEW correctionview AS
SELECT  l.ref_id          refidfrom,
        r.id              refidto,
        f.txt             formtxt,
        s.name            sourcename,
        s.prefix          sourceprefix,
        l.source          sourcestring,
        t2.txt            sourcetypetxt FROM linked l
                                                 JOIN type t ON l.linkedtype_id = t.id
                                                 JOIN linked_form lf ON l.id = lf.linked_id
                                                 JOIN form f ON f.id = lf.form_id
                                                 JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
                                                 LEFT OUTER JOIN source s ON l.source_id = s.id
                                                 LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
WHERE t.txt = 'correction'
ORDER BY l.ref_id, f.id, r.id ASC;


-- derivview source

CREATE VIEW derivview AS
SELECT  l.entry_id        entryidfrom,
        e2.id             entryidto,
        l.ref_id          refidfrom,
        r.id              refidto,
        ln.name           languageto,
        f.txt             formtxt,
        s.name            sourcename,
        s.prefix          sourceprefix,
        l.source          sourcestring,
        t2.txt            sourcetypetxt,
        g1.TXT            entrygloss,
        g2.TXT            refgloss,
        lf.ordering       lforder FROM linked l
                                           JOIN type t ON l.linkedtype_id = t.id
                                           JOIN linked_form lf ON l.id = lf.linked_id
                                           LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
                                           LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
                                           JOIN form f ON f.id = lf.form_id
                                           LEFT OUTER JOIN source s ON l.source_id = s.id
                                           LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
                                           LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
                                           LEFT OUTER JOIN GLOSS g1 ON e2.GLOSS_ID = g1.ID
                                           LEFT OUTER JOIN GLOSS g2 ON r.GLOSS_ID = g2.ID
WHERE t.txt = 'deriv'
GROUP BY formtxt
ORDER BY l.entry_id, l.ref_id, lf.ordering, e2.id, r.id ASC;


-- elementview source

CREATE VIEW elementview AS
SELECT  l.entry_id        entryidfrom,
        e2.id             entryidto,
        l.ref_id          refidfrom,
        r.id              refidto,
        ln.name           languageto,
        f.txt             formtxt,
        g.txt             grammartxt,
        s.name            sourcename,
        s.prefix          sourceprefix,
        l.source          sourcestring,
        t2.txt            sourcetypetxt FROM linked l
                                                 JOIN type t ON l.linkedtype_id = t.id
                                                 JOIN linked_form lf ON l.id = lf.linked_id
                                                 LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
                                                 LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
                                                 JOIN form f ON f.id = lf.form_id
                                                 LEFT OUTER JOIN source s ON l.source_id = s.id
                                                 LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
                                                 LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
                                                 LEFT OUTER JOIN linked_grammar lg ON lg.linked_id = l.id
                                                 LEFT OUTER JOIN grammar g ON g.id = lg.grammar_id
WHERE t.txt = 'element'
ORDER BY l.entry_id, l.ref_id, e2.id, r.id ASC;


-- entrynoteview source

CREATE VIEW entrynoteview as
select e.id entry_id, ed.ORDERING ordering, d.TXT txt from entry e
                                                               join entry_doc ed on e.ID = ed.ENTRY_ID
                                                               join doc d on ed.DOC_ID = d.ID
                                                               join type t on d.DOCTYPE_ID = t.ID
where t.TXT = 'notes'
order by ed.ORDERING;


-- inflectview source

CREATE VIEW inflectview AS
SELECT  l.entry_id        entryidfrom,
        l.ref_id          refidfrom,
        f.txt             formtxt,
        lg.ordering       lgorder,
        g.txt             inflection,
        tgram.txt         inflecttypetxt FROM linked l
                                                  JOIN type t ON l.linkedtype_id = t.id
                                                  LEFT OUTER JOIN linked_form lf ON lf.linked_id = l.id
                                                  LEFT OUTER JOIN form f ON f.id = lf.form_id
                                                  LEFT OUTER JOIN linked_grammar lg ON lg.linked_id = l.id
                                                  LEFT OUTER JOIN grammar g ON g.id = lg.grammar_id
                                                  LEFT OUTER JOIN type tgram ON lg.grammartype_id = tgram.id
WHERE t.txt = 'inflect'
ORDER BY l.entry_id, l.ref_id, tgram.id, lg.ordering ASC;


-- lexicon source

CREATE VIEW lexicon AS SELECT  e.id entry_id,
                               f.txt form,
                               l.mnemonic lang_mnemonic,
                               l.name lang_name,
                               g.txt gloss,
                               c.label cat,
                               e.tengwar tengwar,
                               e.mark mark,
                               e.eldamo_pageid eldamo_pageid,
                               e.orderfield orderfield,
                               e.parent_id parent_id,
                               e.ordering ordering,
                               e.entrytype_id entrytype_id,
                               t.txt entry_type
                       FROM ENTRY e
                                LEFT OUTER JOIN FORM f
                                                ON e.form_id = f.id
                                LEFT OUTER JOIN LANGUAGE l
                                                ON e.language_id = l.id
                                LEFT OUTER JOIN GLOSS g
                                                ON e.gloss_id = g.id
                                LEFT OUTER JOIN CAT c
                                                ON e.cat_id = c.id
                                LEFT OUTER JOIN TYPE t
                                                ON e.entrytype_id = t.id;


-- refcognateview source

CREATE VIEW refcognateview AS SELECT DISTINCT l.entry_id 		        entry_id,
                                              Upper(lang.mnemonic)
                                                  || '.'                                           lang,
                                              r1.mark
                                                  || f.txt                                         form,
                                              COALESCE(g1.txt, g2.txt)                         gloss,
                                              Group_concat(DISTINCT COALESCE (r1.source
                                                                                  || ' ('
                                                                                  || f11.txt
                                                                                  || ')', r2.source
                                                                                  || ' ('
                                                                                  || f22.txt
                                                                                  || ')')) sources
                              FROM   linked l
                                         LEFT OUTER JOIN linked_form lf
                                                         ON lf.linked_id = l.id
                                         JOIN form f
                                              ON f.id = lf.form_id
                                         JOIN ref r1
                                              ON r1.source = l.source
                                         JOIN entry e
                                              ON e.id = r1.entry_id
                                         LEFT OUTER JOIN gloss g1
                                                         ON e.gloss_id = g1.id
                                         JOIN language lang
                                              ON lang.id = e.language_id
                                         JOIN type t
                                              ON l.linkedtype_id = t.id
                                         JOIN ref r2
                                              ON r2.entry_id = e.id
                                         LEFT OUTER JOIN gloss g2
                                                         ON r2.gloss_id = g2.id
                                         JOIN form f11
                                              ON r1.form_id = f11.id
                                         JOIN form f22
                                              ON r2.form_id = f22.id
                              WHERE  t.txt = 'cognate'
                                AND r2.gloss_id IS NOT NULL
                                AND NOT EXISTS (SELECT *
                                                FROM   linked l2
                                                WHERE  l2.ref_id = r2.id)
                                AND r2.id != r1.id
                              GROUP  BY l.entry_id,
                                        form;


-- refderivview source

CREATE VIEW refderivview AS SELECT l.entry_id AS entry_id,
                                   f.txt      AS form,
                                   Replace(Replace(Group_concat(DISTINCT g.txt), ',', '; '), ';  ', '; ') AS glosses,
                                   Replace(Group_concat(DISTINCT l.source), ',', '; ')                    AS sources
                            FROM   linked l
                                       JOIN   linked_form lf
                                              ON     lf.linked_id = l.id
                                       JOIN   form f
                                              ON     f.id = lf.form_id
                                       LEFT JOIN ref r
                                                 ON     r.source = l.source AND r.form_id = f.id
                                       JOIN gloss g
                                            ON     r.gloss_id = g.id
                                       JOIN type t
                                            ON     l.linkedtype_id = t.id
                            WHERE  t.txt = 'deriv'
                              AND    r.entry_id != l.entry_id
                            GROUP  BY l.entry_id, form;


-- refelementview source

CREATE VIEW refelementview AS
SELECT e1.id entry_id
     , upper(lg.mnemonic) lang
     , e2f.TXT form
     , group_concat(DISTINCT COALESCE(e2g.txt, rg.txt)) gloss
     , ' ✧ ' || REPLACE(group_concat(DISTINCT r.source || CASE WHEN LOWER(rf.txt) = LOWER(e2f.TXT)
                                                                   THEN '' ELSE ' (' || rf.txt || ')' END),',', '; ') sources
FROM entry e1
         JOIN form f1 on e1.form_id = f1.id
         JOIN form f2 on f2.normaltxt = f1.normaltxt
         JOIN linked_form lf ON f2.id = lf.FORM_ID
         JOIN linked l ON l.id = lf.LINKED_ID
         LEFT OUTER JOIN ref r ON l.REF_ID = r.ID
         LEFT OUTER JOIN form rf ON rf.ID = r.FORM_ID
         LEFT OUTER JOIN gloss rg ON rg.ID = r.GLOSS_ID
         JOIN entry e2 ON l.ENTRY_ID = e2.ID
         LEFT OUTER JOIN form e2f ON e2f.ID = e2.FORM_ID
         LEFT OUTER JOIN gloss e2g ON e2g.ID = e2.GLOSS_ID
         JOIN language lg ON lg.ID = e2.LANGUAGE_ID
         JOIN type t ON l.LINKEDTYPE_ID = t.ID
WHERE t.txt = 'element'
GROUP BY e1.id, form;


-- refglossview source

CREATE VIEW refglossview AS
SELECT r.entry_id entry_id, 
       '"' || g.txt || '" ✧ ' || Group_Concat(r.source, '; ') refgloss 
FROM ref r  
JOIN gloss g ON g.id = r.gloss_id  
AND NOT EXISTS (select * FROM linked l WHERE l.ref_id = r.id) 
GROUP BY LOWER(g.txt);


-- refinflectview source

CREATE VIEW refinflectview AS
SELECT r.entry_id entry_id, f.txt form, gr.txt grammar, gl.txt gloss, ' ✧ ' || Group_Concat(r.source, '; ') sources FROM ref r
LEFT OUTER JOIN gloss gl ON gl.id = r.gloss_id
JOIN form f ON f.id = r.form_id
JOIN linked l ON l.REF_ID = r.ID
LEFT OUTER JOIN linked_grammar lg ON lg.LINKED_ID = l.ID
JOIN grammar gr ON gr.ID = lg.GRAMMAR_ID
JOIN type t2 ON lg.GRAMMARTYPE_ID = t2.id
JOIN type t ON l.LINKEDTYPE_ID = t.ID
WHERE t.txt = 'inflect'
GROUP BY LOWER(f.txt);


-- relatedview source

CREATE VIEW relatedview AS
SELECT  l.entry_id        entryidfrom,
        e2.id             entryidto,
        l.ref_id          refidfrom,
        r.id              refidto,
        ln.name           languageto,
        l.ordering        lorder,
        f.txt             formtxt,
        s.name            sourcename,
        s.prefix          sourceprefix,
        l.source          sourcestring,
        t2.txt            sourcetypetxt FROM linked l
                                                 JOIN type t ON l.linkedtype_id = t.id
                                                 JOIN linked_form lf ON l.id = lf.linked_id
                                                 LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
                                                 LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
                                                 JOIN form f ON f.id = lf.form_id
                                                 LEFT OUTER JOIN source s ON l.source_id = s.id
                                                 LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
                                                 LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
WHERE t.txt = 'related'
ORDER BY l.entry_id, l.ref_id, l.ordering, e2.id, r.id ASC;


-- simplexicon source

CREATE VIEW simplexicon AS SELECT
      e.id                        entry_id,
      e.mark                      mark,
      f.txt                       form,
      e.language_id               form_lang_id,
      l.MNEMONIC 				  form_lang_abbr,
      ifnull(g.txt, '--')      as gloss,
      ifnull(g.language_id, 0) as gloss_lang_id,
      ifnull(c.label, '--')    as cat,
      ifnull(sf.txt, '--')     as stem,
      e.entrytype_id              entrytype_id
FROM  entry e
JOIN  form f
ON    e.form_id = f.id
JOIN  language l 
ON    e.LANGUAGE_ID = l.ID 
LEFT OUTER JOIN gloss g
ON    e.gloss_id = g.id
LEFT OUTER JOIN cat c
ON    e.cat_id = c.id
LEFT OUTER JOIN form sf
ON    e.stem_form_id = sf.id
WHERE e.entrytype_id = 1033;


-- speechformview source

CREATE VIEW speechformview AS SELECT DISTINCT lg.entry_id, g.txt FROM
    GRAMMAR g
        JOIN LINKED_GRAMMAR lg
             ON g.ID = lg.GRAMMAR_ID
        JOIN TYPE t
             ON lg.GRAMMARTYPE_ID = t.ID
                              WHERE t.TXT = 'speechform';