CREATE VIEW before AS
SELECT 	l.id 			linked_id, 
		 	l.entry_id 	from_entry_id, 
		 	e2.id 		to_entry_id FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
JOIN entry e1 ON e1.id = l.entry_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
WHERE t.txt = 'before'
ORDER BY from_entry_id, to_entry_id ASC;


CREATE VIEW class AS
SELECT 	l.entry_id 		entry_id, 
			l.ref_id 		ref_id, 
			ln.name 			language_name, 
			l.mark 			mark, 
			l.ordering 		l_order, 
			lg.ordering 	lg_order, 
			g.txt 			grammar_txt, 
			t2.txt 			grammartype_txt, 
			g.id 				grammar_id FROM linked l
JOIN type t ON l.linkedtype_id = t.id
LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
JOIN linked_grammar lg ON l.id = lg.linked_id
JOIN grammar g ON g.id = lg.grammar_id
JOIN type t2 ON lg.grammartype_id = t2.id
WHERE t.txt = 'class'
ORDER BY entry_id, ref_id, lg_order, t2.id ASC;


CREATE VIEW cognate AS
SELECT  l.entry_id        from_entry_id, 
        e2.id             to_entry_id, 
        l.ref_id          from_ref_id, 
        r.id              to_ref_id, 
        ln.name           to_language_name, 
        f.txt             form_txt, 
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
WHERE t.txt = 'cognate'
ORDER BY from_entry_id, from_ref_id, to_entry_id, to_ref_id ASC;


CREATE VIEW deriv AS
SELECT  l.entry_id        from_entry_id, 
        e2.id             to_entry_id, 
        l.ref_id          from_ref_id, 
        r.id              to_ref_id, 
        ln.name           to_language_name, 
        f.txt             form_txt, 
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt,
        lf.ordering       lf_order FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
WHERE t.txt = 'deriv'
ORDER BY from_entry_id, from_ref_id, lf_order, to_entry_id, to_ref_id ASC;


CREATE VIEW element AS
SELECT  l.entry_id        from_entry_id, 
        e2.id             to_entry_id, 
        l.ref_id          from_ref_id, 
        r.id              to_ref_id, 
        ln.name           to_language_name, 
        f.txt             form_txt, 
        g.txt             grammar_txt,
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt FROM linked l
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
ORDER BY from_entry_id, from_ref_id, to_entry_id, to_ref_id ASC;


CREATE VIEW inflect AS
SELECT  l.entry_id        from_entry_id, 
        l.ref_id          from_ref_id,
        f.txt             baseform, 
        lg.ordering       ord, 
        g.txt             inflection, 
        tgram.txt         inflecttype FROM linked l
JOIN type t ON l.linkedtype_id = t.id
LEFT OUTER JOIN linked_form lf ON lf.linked_id = l.id
LEFT OUTER JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN linked_grammar lg ON lg.linked_id = l.id
LEFT OUTER JOIN grammar g ON g.id = lg.grammar_id
LEFT OUTER JOIN type tgram ON lg.grammartype_id = tgram.id
WHERE t.txt = 'inflect'
ORDER BY l.entry_id, l.ref_id, tgram.id, lg.ordering ASC;


CREATE VIEW related AS 
SELECT  l.entry_id        from_entry_id, 
        e2.id             to_entry_id, 
        l.ref_id          from_ref_id, 
        r.id              to_ref_id, 
        ln.name           to_language_name, 
        l.ordering        l_order,
        f.txt             form_txt, 
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
LEFT OUTER JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
LEFT OUTER JOIN entry e2 ON e2.form_id = lf.form_id AND e2.language_id = l.to_language_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
LEFT OUTER JOIN language ln ON l.to_language_id = ln.id
WHERE t.txt = 'related'
ORDER BY from_entry_id, from_ref_id, l.ordering, to_entry_id, to_ref_id ASC;


CREATE VIEW correction AS
SELECT  l.ref_id          from_ref_id,
        r.id              to_ref_id,
        f.txt             form_txt, 
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
JOIN form f ON f.id = lf.form_id
JOIN ref r ON lf.form_id = r.form_id AND l.source_id = r.source_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
WHERE t.txt = 'correction'
ORDER BY l.ref_id, f.id, r.id ASC;


CREATE VIEW change AS 
SELECT  l.ref_id          from_ref_id,
        lf.ordering       lg_order, 
        f.txt             form_txt,
        s.name            source_name, 
        s.prefix          source_prefix, 
        t2.txt            sourcetype_txt FROM linked l
JOIN type t ON l.linkedtype_id = t.id
JOIN linked_form lf ON l.id = lf.linked_id
JOIN form f ON f.id = lf.form_id
LEFT OUTER JOIN source s ON l.source_id = s.id
LEFT OUTER JOIN type t2 ON s.sourcetype_id = t2.id
WHERE t.txt = 'change'
ORDER BY l.ref_id, lf.ordering ASC;











