use strict;
use warnings;
use Encode;
use XML::Twig;
use Array::Utils qw(:all);
use Acme::Comment type => 'C++';
use feature 'say';
use Data::Dump qw(dump);
#use encoding 'utf8';

#my $file = "test.xml";
my $file = "eldamo-data.xml";


my $twig = XML::Twig->new();
my $key;
my $value;

my $entry_uid = 9999;
my $lang_uid = 100;
my $cat_uid = 100;
my $parentcat_uid = 1;
my $source_uid = 1;
my $ref_uid = 1;
my $doc_uid = 0;
my $grammartype_uid = 1;
my $form_uid = 1;
my $gloss_uid = 1;
my $linked_uid = 1;
my $example_uid = 1;
my $rule_uid = 1;


my @everylang;
my @uniquelangs;

my @glosses;

my @lang_rows = ();
my @cat_rows = ();
my @source_rows = ();
my @doc_rows = ();
my @form_rows = ();
my @grammartype_rows = ();
my @srcdoc_rows = ();

my @raw_forms = ();
my @raw_grammartypes = ();

my %entrieshashbykey;
my %langshashbykey;
my %catshashbykey;
my %sourceshashbykey;
my %grammartypehashbykey;
my %formshashbykey;

my %entrieshashbyvalue;
my %langshashbyvalue;
my %catshashbyvalue;
my %sourceshashbyvalue;
my %grammartypehashbyvalue;
my %formshashbyvalue;
my %glosseshashbyvalue;

my %srctypehash = (
        'adunaic' => 1,
        'appendix' => 2,
        'index' => 3,
        'minor' => 4,
        'quenya' => 5,
        'secondary' => 6,
        'sindarin' => 7,
        'telerin' => 8,
        'work' => 9,
);

my %doctypehash = (
        'note' => 1,
        'cite' => 2,
);

$twig->parsefile($file);
my $root = $twig->root;

harvest(); # create ID references
mainloop(); # the rest
#writesql();

sub mainloop{
   foreach my $entry ($root->children('word')){
   	parseword($entry);
   }
}

sub parseword{
	no warnings 'uninitialized';
   my ($entry, $parent_uid, $childorder) = @_;
	$entry_uid++;
	my $ordering = 1;
	#say encode_utf8($entry->att('v'))." ".$entry->att('page-id');
	my $entry_form_uid = ($formshashbyvalue{$entry->att('v')} // 'X');
	my $entry_lang_uid = ($langshashbyvalue{$entry->att('l')} // 'X');
	my $entry_gloss_uid = defined $entry->att('gloss') ? ($glosseshashbyvalue{$entry->att('gloss')} // 'X') : 0;
	my $entry_type_uid = entrytype($entry->att('speech')) // 'X';
	my $entry_cat_uid = defined $entry->att('cat') ? ($catshashbyvalue{$entry->att('cat')} // 'X') : 0;
	my $entry_ruleform_uid = defined $entry->att('rule') ? ($formshashbyvalue{$entry->att('rule')} // 'X') : 0;
	my $entry_stemform_uid = defined $entry->att('stem') ? ($formshashbyvalue{$entry->att('stem')} // 'X') : 0;
	my $entry_fromform_uid = defined $entry->att('from') ? ($formshashbyvalue{$entry->att('from')} // 'X') : 0;
	my $entry_orthoform_uid = defined $entry->att('orthography') ? ($formshashbyvalue{$entry->att('orthography')} // 'X') : 0;
	my $entry_tengwar = $entry->att('tengwar') // "";
	my $entry_mark = $entry->att('mark') // "";
	my $entry_orderfield = $entry->att('order') // "";
	my $entry_eldamopageid = $entry->att('page-id') // "";
	$parent_uid = $parent_uid // 'NULL';
	#say encode_utf8("INSERT INTO eldamo.ENTRY (ID, FORM_ID, LANGUAGE_ID, GLOSS_ID, CAT_ID, RULE_FORM_ID, FROM_FORM_ID, STEM_FORM_ID, TENGWAR, MARK, ELDAMO_PAGEID, ORDERFIELD, ORTHO_FORM_ID, PARENT_ID, ORDERING, TYPE_ID) VALUES ($entry_uid, $entry_form_uid, $entry_lang_uid, $entry_gloss_uid, $entry_cat_uid, $entry_ruleform_uid, $entry_fromform_uid, $entry_stemform_uid, '$entry_tengwar', '$entry_mark', '$entry_eldamopageid', '$entry_orderfield', $entry_orthoform_uid, $parent_uid, $ordering, $entry_type_uid);");
	
	if (defined $entry->att('speech')){
		foreach my $speech (split(' ', $entry->att('speech'))){	
			parselinkedgram($speech, $ordering, 0);
			$ordering++;
		}
	}
	$ordering = 1;
	foreach my $before ($entry->children('before')){
		parselinked($before, $ordering, 0, 501); # entry_uid + to_v + to_l (= after_entry_id) 
		$ordering++;
	}
	$ordering = 1;
	foreach my $class ($entry->children('class')){
		parselinked($class, $ordering, 0, 502); # entry_uid + Grammatical form (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $cognate ($entry->children('cognate')){
		parselinked($cognate, $ordering, 0, 503); # entry_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $deriv ($entry->children('deriv')){
		parselinked($deriv, $ordering, 0, 504); # this entry_uid + deriv_v + deriv_l (= deriv_entry_id) + mark
		$ordering++;  								  # + additional multiple FORM_ID + ordering
	} 
	$ordering = 1;
	foreach my $element ($entry->children('element')){
		parselinked($element, $ordering, 0, 505); # entry_uid + element_v + parent_l + Grammatical form (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $inflect ($entry->children('inflect')){
		parselinked($inflect, $ordering, 0, 506); # entry_uid + v + form + Grammatical form (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $related ($entry->children('related')){
		parselinked($related, $ordering, 0, 507); # entry_uid + entry_uid + related_v + related_l (= related_entry_id) + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $rule ($entry->children('rule')){
		parserule($rule, $ordering); 
		$ordering++;
	}
	$ordering = 1;
	foreach my $see ($entry->children('see')){
		parselinked($see, $ordering, 0, 508); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $seefurther ($entry->children('see-further')){
		parselinked($seefurther, $ordering, 0, 510); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $seenotes ($entry->children('see-notes')){
		parselinked($seenotes, $ordering, 0, 509); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $ref ($entry->children('ref')){
		parseref($ref, $entry_lang_uid, $entry_type_uid, $ordering); 
		$ordering++;
	}
	$ordering = 1;
	foreach my $note ($entry->children('notes')){
		parseentrydoc($note, $ordering); 
		$ordering++;
	}
	$ordering = 1;
	foreach my $child ($entry->children('word')){
		parseword($child, $entry_uid, $ordering); 
		$ordering++;
	}
	$ordering = 1;
}

# context entry_uid
sub parserule{
   my ($rule, $ruleorder) = @_;
	my $rule_from_form_uid = defined $rule->att('from') ? ($formshashbyvalue{$rule->att('from')} // 'X') : 0;
	my $rule_rule_form_uid = defined $rule->att('rule') ? ($formshashbyvalue{$rule->att('rule')} // 'X') : 0;
	my $rule_lang_uid = defined $rule->att('l') ? ($langshashbyvalue{$rule->att('l')} // 'X') : 0;
   #say encode_utf8("INSERT INTO eldamo.RULE (ID, ENTRY_ID, FROM_FORM_ID, RULE_FORM_ID, LANGUAGE_ID, ORDERING) VALUES ($rule_uid, $entry_uid, $rule_from_form_uid, $rule_rule_form_uid, $rule_lang_uid, $ruleorder);") ;
	$rule_uid++;
}

# context entry_uid
sub parseref{
   my ($ref, $entrylang_uid, $entry_type_uid, $refordering) = @_;
	no warnings 'uninitialized';
   # $refordering is in entry context
   my $ordering = 1;
	my $ref_form_uid = defined $ref->att('v') ? ($formshashbyvalue{$ref->att('v')} // 'X') : 0;
	my $ref_lang_uid = defined $ref->att('l') ? ($langshashbyvalue{$ref->att('l')} // 'X-'.$ref->att('l')) : $entrylang_uid;
	my $ref_gloss_uid = defined $ref->att('gloss') ? ($glosseshashbyvalue{$ref->att('gloss')} // $ref->att('gloss')) : 0;
	my $ref_rulefrom_form_uid = defined $ref->att('from') ? ($formshashbyvalue{$ref->att('from')} // 'X') : 0;
	my $ref_rulerule_form_uid = defined $ref->att('rule') ? ($formshashbyvalue{$ref->att('rule')} // 'X') : 0;
	my $ref_rlrule_form_uid = defined $ref->att('rl') ? ($formshashbyvalue{$ref->att('rl')} // 'X') : 0;
	my $ref_mark = $ref->att('mark') // "";
	my $ref_source_uid = defined $ref->att('source') ? ($sourceshashbyvalue{substr($ref->att('source'), 0, index($ref->att('source'), '/'))} // 'X') : 0;
	#say encode_utf8("ref: $ref_uid v=$ref_form_uid l=$ref_lang_uid gloss=$ref_gloss_uid from=$ref_rulefrom_form_uid rule=$ref_rulerule_form_uid rl=$ref_rlrule_form_uid mark=$ref_mark source=$ref_source_uid");
	
	#say encode_utf8("INSERT INTO eldamo.REF (ID, ENTRY_ID, FORM_ID, GLOSS_ID, LANGUAGE_ID, SOURCE_ID, MARK, RULE_FROMFORM_ID, RULE_RLFORM_ID, RULE_RULEFORM_ID, ORDERING, ENTRY_TYPE_ID) VALUES ($ref_uid, $entry_uid, $ref_form_uid, $ref_gloss_uid, $ref_lang_uid, $ref_source_uid, '$ref_mark', $ref_rulefrom_form_uid, $ref_rlrule_form_uid, $ref_rulerule_form_uid, $ordering, $entry_type_uid);");
	
	foreach my $change ($ref->children('change')){
		parselinked($change, $ordering, 1, 511); # ref_uid + i1 + source + change_v
		$ordering++;
	}
	$ordering = 1;
	foreach my $cognate ($ref->children('cognate')){
		parselinked($cognate, $ordering, 1, 503); # ref_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $correction ($ref->children('correction')){
		parselinked($correction, $ordering, 1, 512); # ref_uid + source + correction_v
		$ordering++;
	}
	$ordering = 1;
	foreach my $deriv ($ref->children('deriv')){
		parselinked($deriv, $ordering, 1, 504); # ref_uid + v + uses l= of containing WORD (?) + mark + source
		$ordering++;
	} # additional multiple FORM_ID + ordering
	$ordering = 1;
	foreach my $element ($ref->children('element')){
		parselinked($element, $ordering, 1, 505); # this ref_uid + v + parent_l + parent_l + Grammatical form (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $example ($ref->children('example')){
		parseexample($example, $ordering, $example->att('t') eq 'deriv' ? 601 : 602);
		$ordering++;
	}
	$ordering = 1;
	foreach my $inflect ($ref->children('inflect')){
		parselinked($inflect, $ordering, 1, 506); # ref_uid + source + form + Grammatical form (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $related ($ref->children('related')){
		parselinked($related, $ordering, 0, 507); # ref_uid + v + source + mark
		$ordering++;
	}
	$ref_uid++;
}

#entry_uid in context
sub parseentrydoc{
	no warnings 'uninitialized';
   my ($note, $ordering) = @_;
	# type note, parent 10004 entrynote
	parsedoc($note, 301);
	#say encode_utf8("INSERT INTO eldamo.ENTRY_DOC(ENTRY_ID, DOC_ID, ORDERING) VALUES ($entry_uid, $doc_uid, $ordering);");
}

sub parsedoc{
	$doc_uid++;
   my ($doc, $type_uid) = @_;
   my $text = $doc->text;
   $text =~ s/\R//g;
   #say encode_utf8("INSERT INTO DOC (ID, TXT, TYPE_ID) VALUES ($doc_uid, '$text', $type_uid);") ;
}

# context entry_uid & ref_uid; linkedtype -> TYPE
sub parselinked{
	no warnings 'uninitialized';
   my ($linked, $linkedordering, $isref, $linkedtype) = @_;
	#take ref_uid ONLY if $isref = 1; 
	my $ordering = 1;
	if (defined $linked->att('form')){
		foreach my $form (split(' ', $linked->att('form'))){	
			parselinkedgram($form, $ordering, 1);
			$ordering++;
		}
	}
	$ordering = 1;
	if (defined $linked->att('variant')){
		foreach my $variant (split(' ', $linked->att('variant'))){	
			parselinkedgram($variant, $ordering, 1);
			$ordering++;
		}
	}
	$ordering = 1;
	my $linked_to_lang_uid = defined $linked->att('l') ? ($langshashbyvalue{$linked->att('l')} // 'X') : 0;
	my $linked_mark = $linked->att('mark') // "";
	my $linked_source_uid = defined $linked->att('source') ? ($sourceshashbyvalue{substr($linked->att('source'), 0, index($linked->att('source'), '/'))} // 'X') : 0;
	foreach my $orderexample ($linked->children('order-example')){
   	parseexample($orderexample, $ordering, 603);
		$ordering++;
   }
	$ordering = 1;
	
   parselinkedform($linked->att('v'), 1) if (defined $linked->att('v'));
   parselinkedform($linked->att('i1'), 2) if (defined $linked->att('i1'));
   parselinkedform($linked->att('i2'), 3) if (defined $linked->att('i2'));
   parselinkedform($linked->att('i3'), 4) if (defined $linked->att('i3'));
   foreach my $ruleseq ($linked->children('rule-start')){ # rule-example see parseruleseq()
   	parseruleseq($linked);
   }
   if ($isref == 1){
   	#say encode_utf8("INSERT INTO eldamo.LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, REF_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK) VALUES ($linked_uid, $linkedtype, $entry_uid, $ref_uid, $linked_to_lang_uid, $ordering, $linked_source_uid, '$linked_mark');") ; 
   } else {
   	#say encode_utf8("INSERT INTO eldamo.LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK) VALUES ($linked_uid, $linkedtype, $entry_uid, $linked_to_lang_uid, $ordering, $linked_source_uid, '$linked_mark');") ;
   }
	$linked_uid++;
}

#context linked_uid 601:deriv  602:inflect  603:order
sub parseexample{
   my ($example, $ordering, $type) = @_;
   #if $type = 2 links to linked, else to ref
	no warnings 'uninitialized';
	my $example_form_uid = defined $example->att('v') ? ($formshashbyvalue{$example->att('v')} // $example->att('v')) : 0;
	my $example_source_uid = defined $example->att('source') ? ($sourceshashbyvalue{substr($example->att('source'), 0, index($example->att('source'), '/'))} // 'X') : 0;
	
	if ($type == 603){
		#say encode_utf8("INSERT INTO eldamo.EXAMPLE (LINKED_ID, SOURCE_ID, FORM_ID, ORDERING, TYPE_ID) VALUES ($linked_uid, $example_source_uid, $example_form_uid, $ordering, $type);");
	} else {
		#say encode_utf8("INSERT INTO eldamo.EXAMPLE (REF_ID, SOURCE_ID, FORM_ID, ORDERING, TYPE_ID) VALUES ($ref_uid, $example_source_uid, $example_form_uid, $ordering, $type);");
	}
	$example_uid++;
}

#context linked_uid;
sub parselinkedform{
   my ($linkedform, $ordering) = @_;
	my $linkedform_form_uid = $formshashbyvalue{$linkedform} // 'X';
	#say encode_utf8("linkedform ($linked_uid:$linkedform_form_uid)");
	#say encode_utf8("INSERT INTO LINKED_FORM(LINKED_ID, FORM_ID, ORDERING) VALUES ($linked_uid, $linkedform_form_uid, $ordering);");
}

#context linked_uid, entry_uid
sub parselinkedgram{
   my ($linkedgram, $ordering, $type) = @_;
   #$type 0 links to entry, 1 to linked
	my $linkedgram_gram_uid = $grammartypehashbyvalue{$linkedgram} // 'X'.$linkedgram;
	#say encode_utf8("linkedgram ".($type == 0 ? "entry($entry_uid" : "linked($linked_uid").":$linkedgram_gram_uid)");
	if ($type == 0){
		say encode_utf8("INSERT INTO eldamo.LINKED_GRAMMAR(ENTRY_ID, GRAMMAR_ID, ORDERING) VALUES ($entry_uid, $linkedgram_gram_uid, $ordering);");
	} elsif ($type == 1){
		say encode_utf8("INSERT INTO eldamo.LINKED_GRAMMAR(LINKED_ID, GRAMMAR_ID, ORDERING) VALUES ($linked_uid, $linkedgram_gram_uid, $ordering);");
	}
}

sub parseruleseq{
   my ($linked) = @_;
   my $rsordering = 1;
	foreach my $startrow ($linked->children('rule-start')){
   	parseruleseqrow($startrow, $rsordering);
   	$rsordering++;
   }
	foreach my $rulerow ($linked->children('rule-example')){
   	parseruleseqrow($rulerow, $rsordering);
   	$rsordering++;
   }
}

#context linked_uid; ordering
sub parseruleseqrow{
   my ($rulerow, $ordering) = @_;
	my $ruleseq_fromform_uid = defined $rulerow->att('from') ? ($formshashbyvalue{$rulerow->att('from')} // 'X') : 0;
	my $ruleseq_ruleform_uid = defined $rulerow->att('rule') ? ($formshashbyvalue{$rulerow->att('rule')} // 'X') : 0;
	my $ruleseq_toform_uid = defined $rulerow->att('to') ? ($formshashbyvalue{$rulerow->att('to')} // 'X') : 0;
	my $ruleseq_lang_uid = defined $rulerow->att('l') ? ($langshashbyvalue{$rulerow->att('l')} // 'X') : 0;
	#say encode_utf8("linked:$linked_uid #$ordering from: $ruleseq_fromform_uid rule: $ruleseq_ruleform_uid to:$ruleseq_toform_uid lang:$ruleseq_lang_uid");
   #say encode_utf8("INSERT INTO RULESEQUENCE (DERIV_ID, FROM_FORM_ID, LANGUAGE_ID, RULE_FORM_ID, TO_FORM_ID, ORDERING) VALUES ($linked_uid, $ruleseq_fromform_uid, $ruleseq_lang_uid, $ruleseq_ruleform_uid, $ruleseq_toform_uid, $ordering);");
}

sub entrytype{
   my ($speech) = @_;
	if ($speech =~ /phone/) {
		return 203;
	} elsif ($speech =~ /grammar/) {
		return 202;
	} elsif ($speech =~ /root/) {
		return 204;
	} else {
		return 201;
	}
}

sub harvest{
# !! REQUIRES <language-cat ... in XML to be changed into <language ...
   hashlangs(); 			# % = mnemonic => UID
   hashcats();     		# % = id => UID
   hashsources();  		# % = prefix => UID
   hashgrammartypes();	# % = grammartype-txt => UID
   hashforms();    		# % = form-txt => UID
   hashglosses();    	# % = txt => UID
}

sub hashlangs{
	my %hashbykey;
	foreach my $lang ($root->children('language')){
		harvestlangs($lang, undef);
	}
	while (($key, $value) = each %langshashbykey) {
    	$langshashbyvalue{$value} = $key;
      #print encode_utf8("key: ".$key." --> value: ".$value."\n");
	}
	$langshashbyvalue{'bel'} = 149;
	$langshashbyvalue{'dor'} = 150;
	$langshashbyvalue{'dor ilk'} = 151;
	$langshashbyvalue{'edan'} = 152;
	$langshashbyvalue{'eon'} = 153;
	$langshashbyvalue{'fal'} = 154;
	$langshashbyvalue{'ln'} = 155;
	$langshashbyvalue{'lon'} = 156;
	$langshashbyvalue{'oss'} = 157;
	$langshashbyvalue{'sol'} = 158;
	undef %langshashbykey;
}

sub hashcats{
   foreach my $cats ($root->children('cats')){
      harvestcats($cats);
   }
   while (($key, $value) = each %catshashbykey) {
      $catshashbyvalue{$value} = $key;
      #print encode_utf8("key: ".$key." --> value: ".$value."\n");
   }
   undef %catshashbykey;
}

sub hashsources{
   foreach my $source ($root->children('source')){
      harvestsources($source);
   }
   while (($key, $value) = each %sourceshashbykey) {
      $sourceshashbyvalue{$value} = $key;
      #print encode_utf8("key: ".$key." --> value: ".$value."\n");
   }
   undef %sourceshashbykey;
}

sub hashgrammartypes{
   foreach my $word ($root->children('word')){
      harvestgrammartypes($word);
   }
   foreach my $grammartype (sort (unique(@raw_grammartypes))){
      #grammartyperow($grammartype, $grammartype_uid);
      #say encode_utf8("INSERT INTO eldamo.GRAMMAR (ID, TXT) VALUES ($grammartype_uid, '$grammartype');") ;
      $grammartypehashbykey {$grammartype_uid} = $grammartype;
      $grammartype_uid++;
   }
   undef @raw_grammartypes; 
   while (($key, $value) = each %grammartypehashbykey) {
      $grammartypehashbyvalue{$value} = $key;
      #print encode_utf8("key: ".$key." --> value: ".$value."\n");
   }
   undef %grammartypehashbykey;
   #foreach my $grammartype_row (@grammartype_rows){
      #print encode_utf8($grammartype_row)."\n";
   #}
   $grammartypehashbyvalue{'?strong-past'} = 292;
	$grammartypehashbyvalue{'1st-plural-inclusive'} = 293;
	$grammartypehashbyvalue{'1st-plural-inclusive-poss'} = 294;
	$grammartypehashbyvalue{'2nd-sg-polity-prep'} = 295;
	$grammartypehashbyvalue{'2nd-sg-poss'} = 296;
	$grammartypehashbyvalue{'adj-agreement'} = 297;
	$grammartypehashbyvalue{'agental'} = 298;
	$grammartypehashbyvalue{'augmentation'} = 299;
	$grammartypehashbyvalue{'consuetudinal-past'} = 300;
	$grammartypehashbyvalue{'declension-B'} = 301;
	$grammartypehashbyvalue{'diminutive-superlative'} = 302;
	$grammartypehashbyvalue{'dynamic-lengthening'} = 303;
	$grammartypehashbyvalue{'eq-genitive'} = 304;
	$grammartypehashbyvalue{'f.'} = 305;
	$grammartypehashbyvalue{'fortified'} = 306;
	$grammartypehashbyvalue{'future-imperfect'} = 307;
	$grammartypehashbyvalue{'future-passive'} = 308;
	$grammartypehashbyvalue{'future-passive-participle'} = 309;
	$grammartypehashbyvalue{'future-perfect'} = 310;
	$grammartypehashbyvalue{'future-reflexive'} = 311;
	$grammartypehashbyvalue{'imperfect-passive-participle'} = 312;
	$grammartypehashbyvalue{'impersonal'} = 313;
	$grammartypehashbyvalue{'incomplete'} = 314;
	$grammartypehashbyvalue{'inversion'} = 315;
	$grammartypehashbyvalue{'long-imperfect'} = 316;
	$grammartypehashbyvalue{'long-perfect'} = 317;
	$grammartypehashbyvalue{'masc'} = 318;
	$grammartypehashbyvalue{'mutation'} = 319;
	$grammartypehashbyvalue{'neut'} = 320;
	$grammartypehashbyvalue{'o-genitive'} = 321;
	$grammartypehashbyvalue{'past-future'} = 322;
	$grammartypehashbyvalue{'past-future-perfect'} = 323;
	$grammartypehashbyvalue{'past-imperfect'} = 324;
	$grammartypehashbyvalue{'past-passive'} = 325;
	$grammartypehashbyvalue{'past-reflexive'} = 326;
	$grammartypehashbyvalue{'pluperfect'} = 327;
	$grammartypehashbyvalue{'Powers'} = 328;
	$grammartypehashbyvalue{'present-passive'} = 329;
	$grammartypehashbyvalue{'present-reflexive'} = 330;
	$grammartypehashbyvalue{'pronoun-prefix'} = 331;
	$grammartypehashbyvalue{'reflexive-participle'} = 332;
	$grammartypehashbyvalue{'rh-mutation'} = 333;
	$grammartypehashbyvalue{'stressed'} = 334;
	$grammartypehashbyvalue{'suppression'} = 335;
	$grammartypehashbyvalue{'unaccented'} = 336;
	$grammartypehashbyvalue{'verb-inflection'} = 337;
	$grammartypehashbyvalue{'w-mutation'} = 338;
	$grammartypehashbyvalue{'with-1st-pl-object'} = 339;
	$grammartypehashbyvalue{'with-1st-sg-dative'} = 340;
	$grammartypehashbyvalue{'with-2nd-pl-object'} = 341;
	$grammartypehashbyvalue{'with-plural-object'} = 342;
	$grammartypehashbyvalue{'with-remote-pl-object'} = 343;
	$grammartypehashbyvalue{'with-remote-sg-object'} = 344;
   
}

sub hashforms{
   foreach my $word ($root->children('word')){
      harvestforms($word);
   }
   foreach my $form (sort (unique(@raw_forms))){
      #formrow($form, $form_uid);
      #say encode_utf8("INSERT INTO eldamo.FORM (ID, TXT) VALUES ('$form_uid', '$form');"); 
      $formshashbykey {$form_uid} = $form;
      #print encode_utf8($form_uid." - ".$form)."\n";
      $form_uid++;
   }
   undef @raw_forms; 
   while (($key, $value) = each %formshashbykey) {
      $formshashbyvalue{$value} = $key;
      #print encode_utf8("key: ".$key." --> value: ".$value."\n");
   }
   undef %formshashbykey;
   #print "Total nr of forms: ".(scalar @raw_forms)."\n\n";
   #foreach my $form (unique(@raw_forms)){
      #print encode_utf8($form_uid." - ".$form."\n");
      #print encode_utf8($form."\n");
      #$form_uid++
   #}
}

sub hashglosses{
	my $uid = 1;
	my %hashbykey;
	foreach my $word ($root->children('word')){
		harvestglosses($word);
	}
	foreach my $gloss (sort(unique(@glosses))){
		$hashbykey {$uid} = $gloss; 
      #say encode_utf8("INSERT INTO eldamo.GLOSS (ID, LANGUAGE_ID, TXT) VALUES ($uid, 1010, '$gloss');");
		$uid++;
	}
	while (($key, $value) = each %hashbykey) {
    	$glosseshashbyvalue{$value} = $key;
      #say encode_utf8("key: ".$key." --> value: ".$value);
	}
	undef %hashbykey;
	undef @glosses;
}

sub harvestlangs{
	my ($lang, $parent_uid) = @_;
	#langrow($lang, $lang_uid, $parent_uid);
	my $ordering = 1;
	foreach my $grammar ($lang->children('grammar')){
		parselangdoc($grammar, 401, $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $name ($lang->children('names')){
		parselangdoc($name, 402, $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $note ($lang->children('notes')){
		parselangdoc($note, 403, $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $phonetic ($lang->children('phonetics')){
		parselangdoc($phonetic, 404, $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $phrase ($lang->children('phrases')){
		parselangdoc($phrase, 405, $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $word ($lang->children('words')){
		parselangdoc($word, 406, $ordering);
		$ordering++;
	}
	$ordering = 1;
	$parent_uid = $lang_uid;
	$langshashbykey {$lang_uid} = $lang->att('id') if (defined $lang->att('id'));
	$lang_uid++;
	foreach my $sublang ($lang->children('language')){
		harvestlangs($sublang, $parent_uid)
	}
}

#lang_uid in context
sub parselangdoc{
	no warnings 'uninitialized';
   my ($doc, $type_uid, $ordering) = @_;
	# type id = 401-406
	parsedoc($doc, $type_uid);
	#say encode_utf8("INSERT INTO eldamo.LANGUAGE_DOC(LANGUAGE_ID, DOC_ID, ORDERING) VALUES ($lang_uid, $doc_uid, $ordering);");
}

sub harvestcats{
   my ($cats) = @_;
   foreach my $catgroup ($cats->children('cat-group')){
      #print encode_utf8("catgroup: ".$catgroup->att('label')."\n");
      $catshashbykey {$parentcat_uid} = $catgroup->att('id');
      #catrow($catgroup, $parentcat_uid, undef);
      foreach my $cat ($catgroup->children('cat')){
         #print encode_utf8("($cat_uid) catgroup: ".$catgroup->att('label')." - cat: ".$cat->att('label')."\n");
         $catshashbykey {$cat_uid} = $cat->att('id');
         #catrow($cat, $cat_uid, $parentcat_uid);
         $cat_uid++;
      }
      $parentcat_uid++;
   }
}

sub harvestsources{
   my ($source) = @_;
   my $ordering = 1;
   $sourceshashbykey {$source_uid} = $source->att('prefix');
   #sourcerow($source, $source_uid);
   foreach my $note ($source->children('notes')){
      parsesourcedoc($note, 101, $ordering);
      $ordering++;
   }
   $ordering = 1;
   foreach my $cite ($source->children('cite')){
      parsesourcedoc($cite, 102, $ordering);
      $ordering++;
   }
   $ordering = 1;
   $source_uid++;
}

#source_uid in context
sub parsesourcedoc{
	no warnings 'uninitialized';
   my ($doc, $type_uid, $ordering) = @_;
	# type id = 101 (note) 102 (cite)
	parsedoc($doc, $type_uid);
	#say encode_utf8("INSERT INTO eldamo.SOURCE_DOC(SOURCE_ID, DOC_ID, ORDERING) VALUES ($source_uid, $doc_uid, $ordering);");
}

sub harvestgrammartypes{
   my ($entry) = @_;
   # grammartype harvesting
   blobl($entry->att('speech') // "");
   foreach my $class ($entry->children('class')){
      blobl($class->att('form') // "");
      blobl($class->att('variant') // "");
   }
   foreach my $deriv ($entry->children('deriv')){
		push @raw_grammartypes, $deriv->att('form') if (defined $deriv->att('form'));
   }
   foreach my $element ($entry->children('element')){
   	blobl($element->att('form') // "");
   	blobl($element->att('variant') // "");
   }
   foreach my $inflect ($entry->children('inflect')){
   	blobl($inflect->att('form') // "");
      blobl($inflect->att('variant') // "");
   } 
   foreach my $ref ($entry->children('ref')){
      foreach my $deriv ($ref->children('deriv')){
         push @raw_grammartypes, $deriv->att('form') if (defined $deriv->att('form'));
      }
      foreach my $element ($ref->children('element')){
      	blobl($element->att('form') // "");
         blobl($element->att('variant') // "");
      }
      foreach my $inflect ($ref->children('inflect')){
      	blobl($inflect->att('form') // "");
         blobl($inflect->att('variant') // "");
      }
   }
}
sub bogloe{
   my ($kabloobl) = @_;
	print $kabloobl;
}

sub blobl{
   my ($kabloobl) = @_;
	foreach my $globl (split(' ', $kabloobl)){
		push @raw_grammartypes, $globl;
	}
}

# nb formtype is now 1 = word, 2 = grammar, 3 = phonetic, 4 = root   
#   my $lang_id = $langshashbyvalue{$entry->att('l')};
#  

sub harvestforms{
   my ($entry) = @_;
   # now get the forms .. first the main 'v' ones
   
	push @raw_forms, $entry->att('v') if (defined $entry->att('v'));
	push @raw_forms, $entry->att('rule') if (defined $entry->att('rule'));
	push @raw_forms, $entry->att('from') if (defined $entry->att('from'));
	push @raw_forms, $entry->att('stem') if (defined $entry->att('stem'));
	push @raw_forms, $entry->att('orthography') if (defined $entry->att('orthography'));
   foreach my $before ($entry->children('before')){
      push @raw_forms, $before->att('v');
      foreach my $order ($before->children('order-example')){
         push @raw_forms, $order->att('v');
      }
   }
   procdinges($entry);
   procrule($entry);
   foreach my $see ($entry->children('see')){
      push @raw_forms, $see->att('v') if (defined $see->att('v'));
   }
   foreach my $seefurther ($entry->children('see-further')){
      push @raw_forms, $seefurther->att('v') if (defined $seefurther->att('v'));
   }
   foreach my $seenotes ($entry->children('see-notes')){
      push @raw_forms, $seenotes->att('v') if (defined $seenotes->att('v'));
   }
   foreach my $ref ($entry->children('ref')){
      push @raw_forms, $ref->att('v') if (defined $ref->att('v'));
      push @raw_forms, $ref->att('from') if (defined $ref->att('from'));
      push @raw_forms, $ref->att('rl') if (defined $ref->att('rl'));
      push @raw_forms, $ref->att('rule') if (defined $ref->att('rule'));
      foreach my $change ($ref->children('change')){
         push @raw_forms, $change->att('v') if (defined $change->att('v'));
         push @raw_forms, $change->att('i1') if (defined $change->att('i1'));
      }
      procdinges($ref);
      foreach my $correction ($ref->children('correction')){
         push @raw_forms, $correction->att('v') if (defined $correction->att('v'));
      }
   }
   foreach my $wordchild ($entry->children('word')){
      harvestforms($wordchild);
   }
}

sub procrule{
   my ($ruleparent) = @_;
   foreach my $rule ($ruleparent->children('rule')){
		push @raw_forms, $rule->att('from') if (defined $rule->att('from'));
		push @raw_forms, $rule->att('rule') if (defined $rule->att('rule'));
		push @raw_forms, $rule->att('to') if (defined $rule->att('to'));
   }
}

sub procdinges{
   my ($dingesparent) = @_;
   foreach my $cognate ($dingesparent->children('cognate')){
      push @raw_forms, $cognate->att('v');
   }
   foreach my $deriv ($dingesparent->children('deriv')){
      push @raw_forms, $deriv->att('v');
      push @raw_forms, $deriv->att('i1') if (defined $deriv->att('i1'));
      push @raw_forms, $deriv->att('i2') if (defined $deriv->att('i2'));
      push @raw_forms, $deriv->att('i3') if (defined $deriv->att('i3'));
      foreach my $ruleexample ($deriv->children('rule-example')){
         push @raw_forms, $ruleexample->att('from') if (defined $ruleexample->att('from'));
         push @raw_forms, $ruleexample->att('rule') if (defined $ruleexample->att('rule'));
         push @raw_forms, $ruleexample->att('to') if (defined $ruleexample->att('to'));
      }
      foreach my $rulestart ($deriv->children('rule-start')){
         push @raw_forms, $rulestart->att('to');
      }
   }
   foreach my $example ($dingesparent->children('example')){
      push @raw_forms, $example->att('v') if (defined $example->att('v'));
   }
   foreach my $element ($dingesparent->children('element')){
      push @raw_forms, $element->att('v') if (defined $element->att('v'));
   }
   foreach my $inflect ($dingesparent->children('inflect')){
      push @raw_forms, $inflect->att('v') if (defined $inflect->att('v'));
   }
   foreach my $related ($dingesparent->children('related')){
      push @raw_forms, $related->att('v') if (defined $related->att('v'));
   }
}

/*
   # 1200 is the ID of English
   if (defined $entry->att('gloss')){
      my $gloss_id = $gloss_uid;
      #glossrow($entry->att('gloss'), $gloss_id, 1200);
      $gloss_uid++;
   }
   if (defined $entry->att('cat')){
      my $cat_id = $catshashbyvalue{$entry->att('cat')};
   }
   if (defined $entry->att('tengwar')){
      my $tengwar = $entry->att('tengwar');
   }
   if (defined $entry->att('mark')){
      my $mark = $entry->att('mark');
   }
   if (defined $entry->att('order')){
      my $order = $entry->att('order');
   }
   print "\n";
}
*/

/*
foreach my $entry ($root->children('word')){
   if ($entry->att('v') ne ''){
       $entrieshashbykey {$entry_uid} = $entry->att('v');
       $entry_uid++;
   }
}
*/

sub harvestglosses{
	my ($entry) = @_;
	push @glosses, $entry->att('gloss') if (defined $entry->att('gloss'));
	foreach my $ref ($entry->children('ref')){
		push @glosses, $ref->att('gloss') if (defined $ref->att('gloss'));
	}
	foreach my $subentry ($entry->children('word')){
		harvestglosses($subentry);
	}
}

sub formrow{
   my ($frm, $frmid) = @_;
   #print encode_utf8("<".$frmid." - ".$frm."> ");
   push @form_rows, "INSERT INTO eldamo.FORM (ID, TXT) VALUES ($frmid, '$frm');" ;
}

sub grammartyperow{
   my ($grammartype, $grammartype_uid) = @_;
   push @grammartype_rows, "INSERT INTO eldamo.GRAMMARTYPE (ID, TXT) VALUES ($grammartype_uid, '$grammartype');" ;
   #push @grammartype_rows, "UPDATE eldamo.GRAMMARTYPE SET TXT = '$grammartype' WHERE ID = $grammartype_uid;" ;
}

sub srcdocrow{
   my ($doc, $doc_uid, $doctype_uid, $source_uid, $ordering) = @_;
   push @doc_rows, "INSERT INTO DOC (ID, TXT, DOCTYPE_ID) VALUES ($doc_uid, '".$doc->text."', $doctype_uid);" ;
   push @srcdoc_rows, "INSERT INTO SOURCE_DOC (SOURCE_ID, DOC_ID, ORDERING, DOCTYPE_ID) VALUES ($source_uid, $doc_uid, $ordering, $doctype_uid);" ;
}

sub sourcerow{
   my ($source, $uid) = @_;
   say encode_utf8("INSERT INTO SOURCE (ID, NAME, PREFIX, SOURCETYPE_ID) VALUES ($uid, '".$source->att('name')."', '".$source->att('prefix')."', ".(defined $source->att('type') ? $srctypehash{$source->att('type')} : "NULL").");") ;
}

sub catrow{
   my ($cat, $uid, $parentuid) = @_;
   push @cat_rows, "INSERT INTO CAT (ID, LABEL, PARENT_ID) VALUES ($uid, '".$cat->att('label')."', ".(defined $parentuid ? "'".$parentuid."'" : "NULL").");" ;
}

sub langrow{
   my ($lang, $uid, $parentuid) = @_;
   push @lang_rows,  "INSERT INTO LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES ($uid, '".$lang->att('name')."', ".(defined $lang->att('id') ? "'".$lang->att('id')."'" : "NULL").", ".(defined $parentuid ? $parentuid : "NULL").");" ;
}

sub writesql{

      /*
   foreach my $lang_row (@lang_rows){
      print encode_utf8($lang_row)."\n";
   }
   foreach my $cat_row (@cat_rows){
      print encode_utf8($cat_row)."\n";
   }
   foreach my $source_row (@source_rows){
      print encode_utf8($source_row)."\n";
   }
   
   foreach my $doc_row (@doc_rows){
      print encode_utf8($doc_row)."\n";
   }
   
   foreach my $srcdoc_row (@srcdoc_rows){
      print encode_utf8($srcdoc_row)."\n";
   }
   
   foreach my $grammartype_row (@grammartype_rows){
      print encode_utf8($grammartype_row)."\n";
   }
   foreach my $form_row (@form_rows){
      #print encode_utf8($form_row)."\n";
   }
   */
}