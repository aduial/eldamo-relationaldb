use strict;
use warnings;
use Encode;
use XML::Twig;
use Array::Utils qw(:all);
use Acme::Comment type => 'C++';
use feature 'say';
use File::Path qw(make_path);

$|=1; # this is required to not have the progress dots printed all at the same time

# 's': create SQL files; 'h': print debug hash contents to stdout
my $mode = $ARGV[0] // 'X';

# change if needed. If you enter a schema name, postfix with a period
my $schema = "";
#my $file = "test.xml";
my $file = "eldamo-data.0.5.6.xml";
#my $file = "eldamo-data.xml";


my $twig = XML::Twig->new();
my $key;
my $value;

my $entry_uid = 9999;
my $lang_uid = 100;
my $parentcat_uid = 1;
my $cat_uid = 100;
my $source_uid = 1;
my $ref_uid = 1;
my $doc_uid = 0;
my $type_uid = 1;
my $form_uid = 1;
my $gloss_uid = 1;
my $linked_uid = 1;
my $example_uid = 1;
my $rule_uid = 1;
my $grammar_uid = 1;

my @lang_rows = ();
my @cat_rows = ();
my @source_rows = ();
my @doc_rows = ();
my @form_rows = ();
my @gloss_rows = ();
my @type_rows = ();
my @srcdoc_rows = ();
my @entrydoc_rows = ();
my @langdoc_rows = ();
my @entry_rows = ();
my @linked_rows = ();
my @ref_rows = ();
my @rule_rows = ();
my @grammar_rows = ();
my @linkedgrammar_rows = ();
my @linkedform_rows = ();
my @rulesequence_rows = ();
my @example_rows = ();

my @raw_forms = ();
my @raw_glosses = ();
my @raw_sourcetypes = ();
my @raw_speechforms = ();
my @raw_inflectforms = ();
my @raw_inflectvariants = ();
my @raw_classforms = ();
my @raw_classvariants = ();


my %entrieshashbykey;
my @otherlangs;
my %langshashbykey;
my %catshashbykey;
my %sourceshashbykey;
my %typeshashbykey;
my %grammarshashbykey;
my %formshashbykey;
my %glosseshashbykey;

my %entrieshashbyvalue;
my %langshashbyvalue;
my %catshashbyvalue;
my %sourceshashbyvalue;
my %typeshashbyvalue;
my %grammarshashbyvalue;
my %formshashbyvalue;
my %glosseshashbyvalue;

my $counter = 0;

# create files and dir if needed
my $outputdir = 'output/';
my $SQLFILE;
eval { make_path($outputdir) };
if ($@) {
  print "Couldn't create $outputdir: $@";
}

# NOTE the progress indicator moduli aren't representing anything but a visual clue

# some hardcoded values, contained in the schema xml, not the data xml
my @parenttypes = ('sourcetype', 'doctype', 'linkedtype', 'exampletype', 'grammarroletype', 'entrytype');
my @doctypes = ('notes', 'cite', 'grammar', 'names', 'phonetics', 'phrases', 'words');
my @linkedtypes = ('before', 'class', 'cognate', 'deriv', 'element', 'inflect', 'related', 'see', 'see-notes', 'see-further', 'change', 'correction');
my @exampletypes = ('derivexample', 'inflectexample', 'orderexample', 'refexample');
my @grammarroletypes = ('speechform', 'inflectform', 'inflectvariant', 'classform', 'classvariant');
my @entrytypes = ('lexical', 'grammatical', 'phonetical', 'root', 'unknown');
my @langdocs = ('notes', 'grammar', 'names', 'phonetics', 'phrases', 'words');

say "=== start processing ===";
print "   Reading XML file $file";
$twig->parsefile($file);
my $root = $twig->root;
say " done.";

harvest(); # create ID references
mainloop(); # the rest

# === HARVESTING =============================================

sub harvest{
   say "   Start harvesting for lookup elements and writing them to SQL files ...";
# !! REQUIRES <language-cat ... in XML to be changed into <language ... & </language>
	hashtypes();         # % = TYPES
	hashgrammar();       # % = GRAMMAR (speech, inflect, class ...)
	hashlangs();         # % = mnemonic => UID  / does also language_doc & doc (partly)
	hashcats();          # % = id => UID
	hashsources();       # % = prefix => UID / does also source_doc & doc (partly)
	hashforms();         # % = form-txt => UID
	hashglosses();       # % = txt => UID
	say "   Harvesting stage done.";
}

sub mainloop{
   print "   Start parsing Entry (Ref, Rule, ...) elements ";
	foreach my $entry ($root->children('word')){
		parseword($entry);
		print '.' if ($entry_uid % 800 == 0);
	}
	say " done.";
	print "   Writing remaining SQL files ...";
	writemainsql() if $mode eq "-s";
	say " done.";
	say "=== end of processing ===";
}

# === TYPE =============================================

sub hashtypes{    
   print "   => types ...";
   no warnings 'syntax';
   # first do the hardcoded rows type_uid for parents starts with 1; for hardcoded
   # types it is set to with 1000
   harvesthardcodedtypes();
   # type_uid is now set to 2000 for harvested types
	foreach my $source ($root->children('source')){ push @raw_sourcetypes, $source->att('type') if defined $source->att('type');}
	crunchtypes([sort (unique(@raw_sourcetypes))], 'sourcetype');
	undef @raw_sourcetypes;
   #undef typeshashbyvalue; it was used to look up parent id's. Then re-create / say it ...
	undef %typeshashbyvalue;
   sayhashkeytovalue(\%typeshashbykey, \%typeshashbyvalue);
	writesql(\@type_rows, 'type.sql') if $mode eq "-s";  # table TYPE
	undef %typeshashbykey;
	undef @type_rows;
	say " done.";
}

sub harvesthardcodedtypes{
   crunchtypes(\@parenttypes, undef);
   $type_uid = 1000;
   hashkeytovalue(\%typeshashbykey, \%typeshashbyvalue);
   crunchtypes(\@doctypes, 'doctype');
   crunchtypes(\@linkedtypes, 'linkedtype');
   crunchtypes(\@exampletypes, 'exampletype');
   crunchtypes(\@grammarroletypes, 'grammarroletype');
   crunchtypes(\@entrytypes, 'entrytype');
   $type_uid = 2000;
}

sub crunchtypes{
	my ($typearray, $parentname) = @_;
	my $parent_uid = defined $parentname ? $typeshashbyvalue{$parentname} : "NULL";
   foreach my $typestring (@$typearray){
      $typeshashbykey {$type_uid} = $typestring;
	   push @type_rows, "INSERT INTO ".$schema."TYPE(ID, TXT, PARENT_ID) VALUES ($type_uid, '$typestring', $parent_uid);";
      $type_uid++;
   }
}

# === GRAMMAR ==============================================

# Paul's schema is somewhat ambivalent here, so I discern only two 'grammar'-types: 
# "classformtype" for class->form; and "inflecttype" for class->variant &
# [inflect|element]->[form|variant]
sub hashgrammar{  
   print "   => grammar ";  
   foreach my $word ($root->children('word')) { harvestgrammar($word);}
   # - this has to change, use grammar, not linked
	crunchgrammar([sort (unique(@raw_speechforms))], 'speechform');  # speech = entry type
	crunchgrammar([sort (unique(@raw_inflectforms))], 'inflectform'); 
	crunchgrammar([sort (unique(@raw_inflectvariants))], 'inflectvariant'); 
	crunchgrammar([sort (unique(@raw_classforms))], 'classform');     
	crunchgrammar([sort (unique(@raw_classvariants))], 'classvariant');     
	undef @raw_speechforms;
	undef @raw_inflectforms;
	undef @raw_inflectvariants;
	undef @raw_classforms;
	undef @raw_classvariants;
   sayhashkeytovalue(\%grammarshashbykey, \%grammarshashbyvalue);
	writesql(\@grammar_rows, 'grammar.sql') if $mode eq "-s";  # table GRAMMAR
	undef %grammarshashbykey;
	undef @grammar_rows;
	say " done.";
}

sub crunchgrammar{
	my ($grammararray, $grammartype) = @_;
	my $grammartype_id = defined $grammartype ? $typeshashbyvalue{$grammartype} : "NULL";
   foreach my $grammarstring (@$grammararray){
      $grammarshashbykey {$grammar_uid} = $grammarstring;
	   push @grammar_rows, "INSERT INTO ".$schema."GRAMMAR(ID, TXT, GRAMMARTYPE_ID) VALUES ($grammar_uid, '$grammarstring', $grammartype_id);";
      $grammar_uid++;
   }
}

sub harvestgrammar{
	my ($entry) = @_;
	print '.' if ($counter % 1500 == 0);
	$counter++;
   blobl(\@raw_speechforms, $entry->att('speech')) if defined $entry->att('speech');
   commoninflects($entry);
   foreach my $ref ($entry->children('ref')){ commoninflects($ref); }
   foreach my $class ($entry->children('class')){
      blobl(\@raw_classforms, $class->att('form')) if defined $class->att('form');
      blobl(\@raw_classvariants, $class->att('variant')) if defined $class->att('variant');
   }
   foreach my $child ($entry->children('word')){ harvestgrammar($child); }
}

sub commoninflects{
	my ($element) = @_;
   foreach my $inflect ($element->children('inflect')){ subinflects($inflect); }
   foreach my $element ($element->children('element')){ subinflects($element); }
}

sub subinflects{
	my ($subelement) = @_;
   blobl(\@raw_inflectforms, $subelement->att('form')) if defined $subelement->att('form');
   blobl(\@raw_inflectvariants, $subelement->att('variant')) if defined $subelement->att('variant');
}

sub blobl{
   my($bogloe, $kabloobl) = @_;
	foreach my $globl (split(' ', $kabloobl)){ push @$bogloe, $globl;}
}

# === LANGUAGE =================================================

sub hashlangs{
   print "   => languages ";  
	my %hashbykey;
	foreach my $lang ($root->children('language')){ harvestlangs($lang, undef); }
	print '.';
	foreach my $entry ($root->children('word')){ harvestotherlangs($entry); }
	print '.';
	hashkeytovalue(\%langshashbykey, \%langshashbyvalue);
	foreach my $otherlang (unique @otherlangs){
	   if (!exists($langshashbyvalue{$otherlang})) {
				$langshashbyvalue{$otherlang} = $lang_uid;
					push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES ($lang_uid, '$otherlang', '$otherlang', NULL);" ;
				$lang_uid++;  
		}
	}
	print '.';
	push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1000, 'Modern languages', 'ML', NULL);" ;
	push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1010, 'English', 'ENG', 1000);" ;
	push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1011, 'Čeština (Czech)', 'CZE', 1000);";
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1012, 'Dansk (Danish)', 'DAN', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1013, 'Deutsch (German)', 'GER', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1014, 'Nederlands (Dutch)', 'DUT', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1015, 'Français (French)', 'FRA', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1016, 'Italiano (Italian)', 'ITA', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1017, 'Norsk (Norwegian)', 'NOR', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1018, 'Nynorsk (Nynorsk Norwegian)', 'NNO', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1019, 'Bokmal (Bokmal Norwegian)', 'NOB', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1020, 'Polskie (Polish)', 'POL', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1021, 'Português (Portuguese)', 'POR', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1022, 'Română (Romanian)', 'RUM', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1023, 'Русский (Russian)', 'RUS', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1024, 'Slovenský (Slovak)', 'SLO', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1025, 'Slovenščina (Slovenian)', 'SLV', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1026, 'Español (Spanish)', 'SPA', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1027, 'Српски (Serbian)', 'SRP', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1028, 'Swedish (Svenska)', 'SWE', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1029, 'Türk (Turkish)', 'TUR', 1000);" ;
   push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES (1030, 'Cymraeg (Welsh)', 'WEL', 1000);" ;
	sayhash(\%langshashbykey) if $mode eq "-h";
	writesql_no_encode(\@lang_rows, 'lang.sql') if $mode eq "-s";  # table LANGUAGE
	writesql(\@langdoc_rows, 'lang_doc.sql') if $mode eq "-s";  # table LANGUAGE_DOC & DOC
	undef %langshashbykey;
   undef @lang_rows;
	say " done.";
}


sub harvestlangs{
	my ($lang, $parent_uid) = @_;
	foreach my $langdoctype (@langdocs){crunchlangdocs($lang, $langdoctype);} # see above
	$langshashbykey {$lang_uid} = $lang->att('id') if (defined $lang->att('id'));
	push @lang_rows, "INSERT INTO ".$schema."LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES ($lang_uid, '".(defined $lang->att('name') ? $lang->att('name') : "NULL")."', ".(defined $lang->att('id') ? "'".$lang->att('id')."'" : "NULL").", ".(defined $parent_uid ? $parent_uid : "NULL").");" ;
	
	$parent_uid = $lang_uid;
	$lang_uid++;
	foreach my $sublang ($lang->children('language')){harvestlangs($sublang, $parent_uid);}
}

sub crunchlangdocs{
   my ($lang, $langdoctype) = @_;
	my $ordering = 1;
   foreach my $langdoc ($lang->children($langdoctype)){
		parselangdoc($langdoc, $langdoctype, $ordering);
		$ordering++;
	}
}

#lang_uid, doc_uid in context
sub parselangdoc{
	my ($doc, $langdoctype, $ordering) = @_;
	parsedoc($doc, $langdoctype); # <- doc_uid gets set here
	push @langdoc_rows, "INSERT INTO ".$schema."LANGUAGE_DOC (LANGUAGE_ID, DOC_ID, ORDERING) VALUES ($lang_uid, $doc_uid, $ordering);";
}

sub harvestotherlangs{
	my ($element) = @_;
   push @otherlangs, $element->att('l') if (defined $element->att('l'));
   foreach my $subelement ($element->children){harvestotherlangs($subelement);}
}

# === CATEGORY ===============================================

sub hashcats{
   print "   => categories ";  
	foreach my $cats ($root->children('cats')){ harvestcats($cats); }
	sayhashkeytovalue(\%catshashbykey, \%catshashbyvalue);
	writesql(\@cat_rows, 'cat.sql') if $mode eq "-s";  # table CAT
	undef %catshashbykey;
	undef @cat_rows;
	say " done.";
}

sub harvestcats{
	my ($cats) = @_;
	my $label = '';
	foreach my $parentcat ($cats->children('cat-group')){
		$catshashbykey {$parentcat_uid} = $parentcat->att('id');
		$label = $parentcat->att('label');
		$label =~ s/\'/''/g;
		push @cat_rows, "INSERT INTO ".$schema."CAT (ID, LABEL, PARENT_ID) VALUES ($parentcat_uid, '$label', NULL);" ;
		foreach my $cat ($parentcat->children('cat')){
			$catshashbykey {$cat_uid} = $cat->att('id');
		   $label = $cat->att('label');
		   $label =~ s/\'/''/g;
		   push @cat_rows, "INSERT INTO ".$schema."CAT (ID, LABEL, PARENT_ID) VALUES ($cat_uid, '$label', $parentcat_uid);" ;
	      print '.' if ($cat_uid % 200 == 0);
			$cat_uid++;
		}
		$parentcat_uid++;
	}
}

# === SOURCE ===============================================

sub hashsources{
   print "   => sources ";  
	foreach my $source ($root->children('source')){ harvestsources($source); }
	sayhashkeytovalue(\%sourceshashbykey, \%sourceshashbyvalue);
	undef %sourceshashbykey;
	writesql(\@source_rows, 'source.sql') if $mode eq "-s";  # table SOURCE
	writesql(\@srcdoc_rows, 'source_doc.sql') if $mode eq "-s";  # table SOURCE_DOC
	undef @source_rows;
	undef @srcdoc_rows;
	say " done.";
}

sub harvestsources{
	my ($source) = @_;
	my $ordering = 1;
	$sourceshashbykey {$source_uid} = $source->att('prefix');
	push @source_rows, "INSERT INTO ".$schema."SOURCE (ID, NAME, PREFIX, SOURCETYPE_ID) VALUES ($source_uid, '".$source->att('name')."', '".$source->att('prefix')."', ".(defined $source->att('type') ? $typeshashbyvalue{$source->att('type')} : "NULL").");" ;
	foreach my $note ($source->children('notes')){
		parsesourcedoc($note, 'notes', $ordering);
		$ordering++;
	}
	$ordering = 1;
	foreach my $cite ($source->children('cite')){
		parsesourcedoc($cite, 'cite', $ordering);
		$ordering++;
	}
	$ordering = 1;
	print '.' if ($source_uid % 30 == 0);
	$source_uid++;
}

#source_uid, doc_uid in global context
sub parsesourcedoc{
	no warnings 'uninitialized';
	my ($doc, $sourcedoctype, $ordering) = @_; # sourcedoctype = notes or cite
	parsedoc($doc, $sourcedoctype); # always call parsedoc first to set uid 
	push  @srcdoc_rows, "INSERT INTO ".$schema."SOURCE_DOC(SOURCE_ID, DOC_ID, ORDERING) VALUES ($source_uid, $doc_uid, $ordering);";
}

# === FORM =============================================

sub hashforms{
   print "   => forms ";  
	foreach my $word ($root->children('word')){ harvestforms($word); }
	foreach my $form (sort (unique(@raw_forms))){
		if ($form ne '') {
         push @form_rows, "INSERT INTO ".$schema."FORM (ID, TXT) VALUES ('$form_uid', '$form');";
         $formshashbykey {$form_uid} = $form;
         print '.' if ($form_uid % 10000 == 0);
         $form_uid++;
      }
	}
	undef @raw_forms; 
	sayhashkeytovalue(\%formshashbykey, \%formshashbyvalue);
	undef %formshashbykey;
	writesql(\@form_rows, 'form.sql') if $mode eq "-s";  # table FORM
	undef @form_rows;
	say " done.";
}

sub harvestforms{
	my ($entry) = @_;
	print '.' if ($counter % 1400 == 0);
	$counter++;
	pushform($entry->att('v'));
	pushform($entry->att('rule'));
	pushform($entry->att('from'));
	pushform($entry->att('stem'));
	pushform($entry->att('orthography'));
	foreach my $before ($entry->children('before')){
		pushform($before->att('v'));
		foreach my $order ($before->children('order-example')){pushform($order->att('v'));}
	}
	procdinges($entry);
	procrule($entry);
	foreach my $see ($entry->children('see')){ pushform($see->att('v'));}
	foreach my $seefurther ($entry->children('see-further')){pushform($seefurther->att('v'));}
	foreach my $seenotes ($entry->children('see-notes')){pushform($seenotes->att('v'));}
	foreach my $ref ($entry->children('ref')){
		pushform($ref->att('v'));
		pushform($ref->att('from'));
		pushform($ref->att('rl'));
		pushform($ref->att('rule'));
		foreach my $change ($ref->children('change')){
			pushform($change->att('v'));
			pushform($change->att('i1'));
		}
		procdinges($ref);
		foreach my $correction ($ref->children('correction')){pushform($correction->att('v'));}
	}
	foreach my $wordchild ($entry->children('word')){harvestforms($wordchild);}
}

sub procrule{
	my ($ruleparent) = @_;
	foreach my $rule ($ruleparent->children('rule')){
		pushform($rule->att('from'));
		pushform($rule->att('rule'));
		#pushform($rule->att('to'));
	}
}

sub procdinges{
	my ($dingesparent) = @_;
	foreach my $cognate ($dingesparent->children('cognate')){pushform($cognate->att('v'));}
	foreach my $deriv ($dingesparent->children('deriv')){
		pushform($deriv->att('v'));
		pushform($deriv->att('i1'));
		pushform($deriv->att('i2'));
		pushform($deriv->att('i3'));
		foreach my $ruleexample ($deriv->children('rule-example')){
			pushform($ruleexample->att('from'));
			pushform($ruleexample->att('rule'));
			pushform($ruleexample->att('stage'));
		}
		foreach my $rulestart ($deriv->children('rule-start')){pushform($rulestart->att('stage'));}
	}
	foreach my $example ($dingesparent->children('example')){pushform($example->att('v'));}
	foreach my $element ($dingesparent->children('element')){pushform($element->att('v'));}
	foreach my $inflect ($dingesparent->children('inflect')){pushform($inflect->att('v'));}
	foreach my $related ($dingesparent->children('related')){pushform($related->att('v'));}
}

sub pushform{
	my ($formval) = @_;
   push @raw_forms, $formval if (defined $formval);
}

# === GLOSS ============================================

sub hashglosses{
   print "   => glosses ...";  
	foreach my $word ($root->children('word')){harvestglosses($word);}
	foreach my $gloss (sort(unique(@raw_glosses))){
		if ($gloss ne '') {
         $glosseshashbykey {$gloss_uid} = $gloss; 
         push @gloss_rows, "INSERT INTO ".$schema."GLOSS (ID, LANGUAGE_ID, TXT) VALUES ($gloss_uid, 1010, '$gloss');";
         print '.' if ($gloss_uid % 2000 == 0);
         $gloss_uid++;
		}
	}
	undef @raw_glosses;
	sayhashkeytovalue(\%glosseshashbykey, \%glosseshashbyvalue);
	undef %glosseshashbykey;
	writesql(\@gloss_rows, 'gloss.sql') if $mode eq "-s";  # table GLOSS
	undef @gloss_rows;
	say " done.";
}

sub harvestglosses{
	my ($entry) = @_;
	push @raw_glosses, $entry->att('gloss') if (defined $entry->att('gloss'));
	foreach my $ref ($entry->children('ref')){
		push @raw_glosses, $ref->att('gloss') if (defined $ref->att('gloss'));
	}
	foreach my $subentry ($entry->children('word')){ harvestglosses($subentry); }
}

# === END HARVESTING =============================================

# === PARSING =============================================

# === ENTRY =================================================

sub parseword{
	no warnings 'uninitialized';
	my ($entry, $parent_uid, $childorder) = @_;
	$entry_uid++;
	my $ordering = 1;
	my $entry_form_uid = ($formshashbyvalue{$entry->att('v')} // 'X');
	my $entry_lang_uid = ($langshashbyvalue{$entry->att('l')} // 'X');
	my $entry_gloss_uid = ($glosseshashbyvalue{$entry->att('gloss')} // 'NULL');
	my $entry_cat_uid = ($catshashbyvalue{$entry->att('cat')} // 'NULL');
	my $entry_ruleform_uid = ($formshashbyvalue{$entry->att('rule')} // 'NULL');
	my $entry_stemform_uid = ($formshashbyvalue{$entry->att('stem')} // 'NULL');
	my $entry_fromform_uid = ($formshashbyvalue{$entry->att('from')} // 'NULL');
	my $entry_orthoform_uid = ($formshashbyvalue{$entry->att('orthography')} // 'NULL');
	my $entry_tengwar = $entry->att('tengwar') // "";
	my $entry_mark = $entry->att('mark') // "";
	my $entry_orderfield = $entry->att('order') // "";
	my $entry_eldamopageid = $entry->att('page-id') // "";
	my $entrytype_uid = entrytype($entry->att('speech') // 'unknown');
	$parent_uid = $parent_uid // 'NULL';
	push @entry_rows, "INSERT INTO ".$schema."ENTRY (ID, FORM_ID, LANGUAGE_ID, GLOSS_ID, CAT_ID, RULE_FORM_ID, FROM_FORM_ID, STEM_FORM_ID, TENGWAR, MARK, ELDAMO_PAGEID, ORDERFIELD, ORTHO_FORM_ID, PARENT_ID, ORDERING, ENTRYTYPE_ID) VALUES ($entry_uid, $entry_form_uid, $entry_lang_uid, $entry_gloss_uid, $entry_cat_uid, $entry_ruleform_uid, $entry_fromform_uid, $entry_stemform_uid, '$entry_tengwar', '$entry_mark', '$entry_eldamopageid', '$entry_orderfield', $entry_orthoform_uid, $parent_uid, $ordering, $entrytype_uid);";
	
	$ordering = 1;
	foreach my $speeches ($entry->children('speech')){
	   foreach my $speech (split(' ', $speeches)){ 
         push @linkedgrammar_rows, "INSERT INTO ".$schema."LINKED_GRAMMAR (ENTRY_ID, GRAMMAR_ID, ORDENING) VALUES ($entry_uid, ".($grammarshashbyvalue{$speech} // 'X').", $ordering);"; 
         $ordering++;
		}
	}
	$ordering = 1;
	foreach my $before ($entry->children('before')){
		parselinked($before, $ordering, 0, 'before'); # entry_uid + to_v + to_l (= after_entry_id) 
		$ordering++;
	}
	$ordering = 1;
	foreach my $class ($entry->children('class')){
		parselinked($class, $ordering, 0, 'class'); # entry_uid + Grammatical type (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $cognate ($entry->children('cognate')){
		parselinked($cognate, $ordering, 0, 'cognate'); # entry_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $deriv ($entry->children('deriv')){
		parselinked($deriv, $ordering, 0, 'deriv'); # this entry_uid + deriv_v + deriv_l (= deriv_entry_id) + mark
		$ordering++;								  # + additional multiple FORM_ID + ordering
	} 
	$ordering = 1;
	foreach my $element ($entry->children('element')){
		parselinked($element, $ordering, 0, 'element'); # entry_uid + element_v + parent_l + Grammatical type (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $inflect ($entry->children('inflect')){
		parselinked($inflect, $ordering, 0, 'inflect'); # entry_uid + v + form + Grammatical type (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $related ($entry->children('related')){
		parselinked($related, $ordering, 0, 'related'); # entry_uid + entry_uid + related_v + related_l (= related_entry_id) + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $rule ($entry->children('rule')){
		parserule($rule, $ordering); 
		$ordering++;
	}
	$ordering = 1;
	foreach my $see ($entry->children('see')){
		parselinked($see, $ordering, 0, 'see'); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $seefurther ($entry->children('see-further')){
		parselinked($seefurther, $ordering, 0, 'see-further'); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $seenotes ($entry->children('see-notes')){
		parselinked($seenotes, $ordering, 0, 'see-notes'); # entry_uid + see_v + see_l + TYPE
		$ordering++;
	}
	$ordering = 1;
	foreach my $ref ($entry->children('ref')){
		parseref($ref, $entry_lang_uid, $entrytype_uid, $ordering); 
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

# === RULE =================================================

# context entry_uid
sub parserule{
	my ($rule, $ruleorder) = @_;
	my $rule_from_form_uid = ($formshashbyvalue{$rule->att('from')} // 'NULL');
	my $rule_rule_form_uid = ($formshashbyvalue{$rule->att('rule')} // 'NULL');
	my $rule_lang_uid = ($langshashbyvalue{$rule->att('l')} // 'NULL');
	push @rule_rows, "INSERT INTO ".$schema."RULE (ID, ENTRY_ID, FROM_FORM_ID, RULE_FORM_ID, LANGUAGE_ID, ORDERING) VALUES ($rule_uid, $entry_uid, $rule_from_form_uid, $rule_rule_form_uid, $rule_lang_uid, $ruleorder);" ;
	$rule_uid++;
}


# === REF =================================================
# context entry_uid
sub parseref{
	my ($ref, $entrylang_uid, $entrytype_uid, $refordering) = @_;
	no warnings 'uninitialized';
	# $refordering is in entry context
	my $ordering = 1;  
	my $ref_form_uid = ($formshashbyvalue{$ref->att('v')} // 'X');
	my $ref_lang_uid = ($langshashbyvalue{$ref->att('l')} // 'NULL');
	my $ref_gloss_uid = ($glosseshashbyvalue{$ref->att('gloss')} // 'NULL');
	my $ref_rulefrom_form_uid = ($formshashbyvalue{$ref->att('from')} // 'NULL');
	my $ref_rlrule_form_uid = ($formshashbyvalue{$ref->att('rule')} // 'NULL');
	my $ref_rulerule_form_uid = ($formshashbyvalue{$ref->att('rl')} // 'NULL');
	my $ref_mark = $ref->att('mark') // "";
	my $ref_source_uid = ($sourceshashbyvalue{substr($ref->att('source'), 0, index($ref->att('source'), '/'))} // 'NULL');
	#say encode_utf8("ref: $ref_uid v=$ref_form_uid l=$ref_lang_uid gloss=$ref_gloss_uid from=$ref_rulefrom_form_uid rule=$ref_rulerule_form_uid rl=$ref_rlrule_form_uid mark=$ref_mark source=$ref_source_uid");
	
	push @ref_rows, "INSERT INTO ".$schema."REF (ID, ENTRY_ID, FORM_ID, GLOSS_ID, LANGUAGE_ID, SOURCE_ID, MARK, RULE_FROMFORM_ID, RULE_RLFORM_ID, RULE_RULEFORM_ID, ORDERING, ENTRYTYPE_ID) VALUES ($ref_uid, $entry_uid, $ref_form_uid, $ref_gloss_uid, $ref_lang_uid, $ref_source_uid, '$ref_mark', $ref_rulefrom_form_uid, $ref_rlrule_form_uid, $ref_rulerule_form_uid, $ordering, $entrytype_uid);";
	
	foreach my $change ($ref->children('change')){
		parselinked($change, $ordering, 1, 'change'); # ref_uid + i1 + source + change_v
		$ordering++;
	}
	$ordering = 1;
	foreach my $cognate ($ref->children('cognate')){
		parselinked($cognate, $ordering, 1, 'cognate'); # ref_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
		$ordering++;
	}
	$ordering = 1;
	foreach my $correction ($ref->children('correction')){
		parselinked($correction, $ordering, 1, 'correction'); # ref_uid + source + correction_v
		$ordering++;
	}
	$ordering = 1;
	foreach my $deriv ($ref->children('deriv')){
		parselinked($deriv, $ordering, 1, 'deriv'); # ref_uid + v + uses l= of containing WORD (?) + mark + source
		$ordering++;
	} # additional multiple FORM_ID + ordering
	$ordering = 1;
	foreach my $element ($ref->children('element')){
		parselinked($element, $ordering, 1, 'element'); # this ref_uid + v + parent_l + parent_l + Grammatical type (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $example ($ref->children('example')){
		parseexample($example, $ordering, 1);
		$ordering++;
	}
	$ordering = 1;
	foreach my $inflect ($ref->children('inflect')){
		parselinked($inflect, $ordering, 1, 'inflect'); # ref_uid + source + form + Grammatical type (2x) + ordering
		$ordering++;
	}
	$ordering = 1;
	foreach my $related ($ref->children('related')){
		parselinked($related, $ordering, 0, 'related'); # ref_uid + v + source + mark
		$ordering++;
	}
	$ref_uid++;
}

# === ENTRY_DOC =================================================

#entry_uid, doc_uid in global context
sub parseentrydoc{
	no warnings 'uninitialized';
	my ($note, $ordering) = @_;
	# type note, 
	parsedoc($note, 'notes'); #first call this to set doc_uid
	push @entrydoc_rows, "INSERT INTO ".$schema."ENTRY_DOC(ENTRY_ID, DOC_ID, ORDERING) VALUES ($entry_uid, $doc_uid, $ordering);";
}

# === DOC =================================================

sub parsedoc{
	$doc_uid++;
	my ($doc, $doctype) = @_;
	my $text = $doc->text;
	$text =~ s/\R//g;
	$text =~ s/\'/''/g;
	push @doc_rows, "INSERT INTO ".$schema."DOC (ID, TXT, DOCTYPE_ID) VALUES ($doc_uid, '$text', ".($typeshashbyvalue{$doctype} // 'X').");";
}

# === LINKED =================================================

# entry_uid & ref_uid in global context; linkedtype -> TYPE
sub parselinked{
	no warnings 'uninitialized';
	my ($linked, $linkedordering, $isref, $linkedtype) = @_;
	#take ref_uid ONLY if $isref = 1; 
	my $ordering = 1; 
	if (defined $linked->att('form')){
		foreach my $form (split(' ', $linked->att('form'))){	
			push @linkedgrammar_rows, "INSERT INTO ".$schema."LINKED_GRAMMAR(LINKED_ID, GRAMMAR_ID, ORDERING) VALUES ($linked_uid, ".($grammarshashbyvalue{$form} // 'X').", $ordering);";
			$ordering++;
		}
	}
	$ordering = 1;
	if (defined $linked->att('variant')){
		foreach my $variant (split(' ', $linked->att('variant'))){	
			push @linkedgrammar_rows, "INSERT INTO ".$schema."LINKED_GRAMMAR(LINKED_ID, GRAMMAR_ID, ORDERING) VALUES ($linked_uid, ".($grammarshashbyvalue{$variant} // 'X').", $ordering);";
			$ordering++;
		}
	}
	$ordering = 1;
	my $linked_to_lang_uid = defined $linked->att('l') ? ($langshashbyvalue{$linked->att('l')} // 'X') : 'NULL';
	my $linked_mark = $linked->att('mark') // "";
	my $linked_source_uid = defined $linked->att('source') ? ($sourceshashbyvalue{substr($linked->att('source'), 0, index($linked->att('source'), '/'))} // 'X') : 'NULL';
	foreach my $orderexample ($linked->children('order')){
		parseexample($orderexample, $ordering, 2);
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
		push @linked_rows, "INSERT INTO ".$schema."LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, REF_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK) VALUES ($linked_uid, ".($typeshashbyvalue{$linkedtype} // 'X').", $entry_uid, $ref_uid, $linked_to_lang_uid, $ordering, $linked_source_uid, '$linked_mark');"; 
	} else {
		push @linked_rows, "INSERT INTO ".$schema."LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK) VALUES ($linked_uid, ".($typeshashbyvalue{$linkedtype} // 'X').", $entry_uid, $linked_to_lang_uid, $ordering, $linked_source_uid, '$linked_mark');";
	}
	$linked_uid++;
}

# === EXAMPLE =================================================

#context linked_uid 
sub parseexample{
	my ($example, $ordering, $type) = @_;
	#type = 1 links to ref, 2 to linked
	no warnings 'uninitialized';
	my $example_form_uid = defined $example->att('v') ? ($formshashbyvalue{$example->att('v')} // $example->att('v')) : 0;
	my $example_source_uid = defined $example->att('source') ? ($sourceshashbyvalue{substr($example->att('source'), 0, index($example->att('source'), '/'))} // 'X') : 0;
	
	if ($type == 2){
	   push @example_rows, "INSERT INTO ".$schema."EXAMPLE (LINKED_ID, SOURCE_ID, FORM_ID, ORDERING, EXAMPLETYPE_ID) VALUES ($linked_uid, $example_source_uid, $example_form_uid, $ordering, ".($typeshashbyvalue{'orderexample'} // 'X').");";
	} else {
		push @example_rows, "INSERT INTO ".$schema."EXAMPLE (REF_ID, SOURCE_ID, FORM_ID, ORDERING, EXAMPLETYPE_ID) VALUES ($ref_uid, $example_source_uid, $example_form_uid, $ordering, ".(($typeshashbyvalue{$example->att('t').'example'} // $typeshashbyvalue{'refexample'}) // 'X').");";
	}
	$example_uid++;
}

# === LINKED_FORM =================================================

#linked_uid in global context
sub parselinkedform{
	my ($linkedform, $ordering) = @_;
	push @linkedform_rows, "INSERT INTO ".$schema."LINKED_FORM(LINKED_ID, FORM_ID, ORDERING) VALUES ($linked_uid, ".($formshashbyvalue{$linkedform} // 'X').", $ordering);";
}

# === RULE_SEQUENCE =================================================

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

#linked_uid; ordering in global context
sub parseruleseqrow{
	my ($rulerow, $ordering) = @_;
	my $ruleseq_fromform_uid = defined $rulerow->att('from') ? ($formshashbyvalue{$rulerow->att('from')} // 'X') : 'NULL';
	my $ruleseq_ruleform_uid = defined $rulerow->att('rule') ? ($formshashbyvalue{$rulerow->att('rule')} // 'X') : 'NULL';
	my $ruleseq_stageform_uid = defined $rulerow->att('stage') ? ($formshashbyvalue{$rulerow->att('stage')} // 'X') : 'NULL';
	my $ruleseq_lang_uid = defined $rulerow->att('l') ? ($langshashbyvalue{$rulerow->att('l')} // 'X') : 'NULL';
	push @rulesequence_rows, "INSERT INTO ".$schema."RULESEQUENCE (DERIV_ID, FROM_FORM_ID, LANGUAGE_ID, RULE_FORM_ID, STAGE_FORM_ID, ORDERING) VALUES ($linked_uid, $ruleseq_fromform_uid, $ruleseq_lang_uid, $ruleseq_ruleform_uid, $ruleseq_stageform_uid, $ordering);";
}

# === UTILS =================================================

sub sayhashkeytovalue{
   my $hashedbykey = $_[0];
   my $hashedbyvalue = $_[1];
   while (($key, $value) = each %$hashedbykey) { 
      $$hashedbyvalue{$value} = $key; 
      say encode_utf8("key: ".$key." --> value: ".$value) if $mode eq "-h";
   }
}

sub hashkeytovalue{
   my $hashedbykey = $_[0];
   my $hashedbyvalue = $_[1];
   while (($key, $value) = each %$hashedbykey) { $$hashedbyvalue{$value} = $key; }
}

sub sayhash{
   my $hashed = $_[0];
   while (($key, $value) = each %$hashed) { say encode_utf8("key: ".$key." --> value: ".$value); }
}

sub sayarray{
	my $arrayed = @_;
   foreach my $arrayrow (@$arrayed){ say encode_utf8($arrayrow); }
}
	
sub writesql{	
	my $arrayed = $_[0];
	my $filename = $_[1];
   open (SQLFILE, ">", $outputdir.$filename) or die "$! error trying to create or overwrite $SQLFILE";
   foreach my $arrayrow (@$arrayed){ say SQLFILE encode_utf8($arrayrow); }
	close SQLFILE;
}

sub writesql_no_encode{	
	my $arrayed = $_[0];
	my $filename = $_[1];
   open (SQLFILE, ">", $outputdir.$filename) or die "$! error trying to create or overwrite $SQLFILE";
   foreach my $arrayrow (@$arrayed){ say SQLFILE $arrayrow; }
	close SQLFILE;
}


# === FINALLY =================================================

sub writemainsql{
	writesql(\@entry_rows, 'entry.sql'); # table ENTRY 
	writesql(\@linkedgrammar_rows, 'linked_grammar.sql'); # table LINKED_GRAMMAR
	writesql(\@rule_rows, 'rule.sql'); # table RULE
	writesql(\@ref_rows, 'ref.sql'); # table REF
	writesql(\@entrydoc_rows, 'entry_doc.sql'); # table ENTRY_DOC
	writesql(\@doc_rows, 'doc.sql'); # table DOC
	writesql(\@linked_rows, 'linked.sql'); # table LINKED
	writesql(\@example_rows, 'example.sql'); # table EXAMPLE
	writesql(\@linkedform_rows, 'linked_form.sql'); # table LINKED_FORM
	writesql(\@rulesequence_rows, 'rulesequence.sql'); # table RULESEQUENCE
}

sub entrytype{
	my ($speech) = @_;
	if ($speech =~ /phone/) { return $typeshashbyvalue{'phonetical'}; } 
	elsif ($speech =~ /grammar/) { return $typeshashbyvalue{'grammatical'}; } 
	elsif ($speech =~ /root/) { return $typeshashbyvalue{'root'}; } 
	else { return $typeshashbyvalue{'lexical'}; }
}

# === RECYCLE BIN =================================================


# nb formtype is now 1 = word, 2 = grammar, 3 = phonetic, 4 = root	
#	 my $lang_id = $langshashbyvalue{$entry->att('l')};
#	

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


