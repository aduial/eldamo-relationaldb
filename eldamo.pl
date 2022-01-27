use strict;
use warnings;
use Encode;
use XML::Twig;
use Array::Utils qw(:all);
use Acme::Comment type => 'C++';
use feature 'say';
use File::Path qw(make_path);
use Data::Dumper;

$| = 1
  ; # this is required to not have the progress dots printed all at the same time

# '-s': create SQL files; '-h': print debug hash contents to stdout
my $mode = $ARGV[0] // 'X';

# change if needed. If you enter a schema name, postfix with a period
my $schema = "";

#my $file = "test.xml";
my $file = "eldamo-data08.xml";

#my $file = "eldamo-data.xml";
my $outputdir = 'output08/';

my $twig = XML::Twig->new();
my $key;
my $value;

my $cat_uid       = 100;
my $created_uid   = 1;
my $lang_uid      = 1;
my $source_uid    = 1;
my $type_uid      = 1;
my $parentcat_uid = 1;
my $form_uid      = 1;
my $gloss_uid     = 1;
my $entry_uid     = 9999; # incremented at top of parseentry, start @ 10000
my $ref_uid       = 0; # incremented at top of parseref
my $linked_uid    = 0; # incremented at top of parselinked
my $example_uid   = 0; # incremented at top of parseexample
my $eic_uid       = 0; # incremented at top of parseeic
my $doc_uid       = 0; # incremented at top of parsedoc

my $insert_cat;
my $insert_created;
my $insert_doc;
my $insert_arnediad;
my $insert_eic;
my $insert_entry;
my $insert_example;
my $insert_form;
my $insert_gloss;
my $insert_language;
my $insert_linked;
my $insert_ref;
my $insert_source;
my $insert_type;

my @cat_rows           = ();
my @source_rows        = ();
my @type_rows          = ();
my @lang_rows          = ();
my @created_rows       = ();
my @form_rows          = ();
my @gloss_rows         = ();
my @arnediad_rows      = ();
my @entry_rows         = ();
my @linked_rows        = ();
my @eic_rows           = ();
my @ref_rows           = ();
my @example_rows       = ();
my @doc_rows           = ();

my @raw_forms        = ();
my @raw_glosses      = ();
my @raw_created      = ();

my %parenttypehashkey;
my %sourcetypehashkey;
my %doctypehashkey;
my %linkedtypehashkey;
my %exampletypehashkey;
my %eictypehashkey;
my %reftypehashkey;
my %arnediadtypehashkey;
my %classformtypehashkey;
my %classformvartypehashkey;
my %inflecttypehashkey;
my %inflectvartypehashkey;
my %speechtypehashkey;

my %parenttypehashval;
my %sourcetypehashval;
my %doctypehashval;
my %linkedtypehashval;
my %exampletypehashval;
my %eictypehashval;
my %reftypehashval;
my %arnediadtypehashval;
my %classformtypehashval;
my %classformvartypehashval;
my %inflecttypehashval;
my %inflectvartypehashval;
my %speechtypehashval;

my %langhashkey;
my %entryhashkey;
my %cathashkey;
my %sourcehashkey;
my %createdhashkey;
my %formhashkey;
my %glosshashkey;

my %langhashval;
my %entryhashval;
my %cathashval;
my %sourcehashval;
my %createdhashval;
my %formhashval;
my %glosshashval;

my $counter = 0;
my $ordering = 1;

my %languages;
my @parenttype;
my @sourcetype;
my @doctype;
my @linkedtype;
my @exampletype;
my @eictype;
my @reftype;
my @arnediadtype;
my @classformtype;
my @classformvartype;
my @inflecttype;
my @inflectvartype;
my @speechtype;

my $arnediadtype_uid;

# create files and dir if needed
my $SQLFILE;
eval { make_path($outputdir) };
if ($@) {
    print "Couldn't create $outputdir: $@";
}

# NOTE the progress indicator moduli aren't representing anything but a visual clue


say "=== start processing ===";
print "    Reading XML file $file";
$twig->parsefile($file);
my $root = $twig->root;
say " done.";

loadvariables(); # load hardcoded variables (type, languages), create ID references
harvest();       # harvest forms, glosses, docs from eldamo-data, create ID references
mainloop();      # actual parsing of eldamo-data

# === LOADING & HARVESTING =============================================

sub harvest {
    say
"   Start harvesting for lookup elements and writing them to SQL files ...";

# !! REQUIRES <language-cat ... in XML to be changed into <language ... & </language>
    hashtype();   # % = type
    hashlangs();   # % = mnemonic => UID  / does also language_doc & doc (partly)
    hashcats();    # % = id => UID
    hashcreated(); # % = txt => UID
    hashsources(); # % = prefix => UID / does also source_doc & doc (partly)
    hashforms();   # % = form-txt => UID
    hashglosses(); # % = txt => UID
    say "   Harvesting stage done.";
}

sub mainloop {
    print "  Start parsing Entries ";
    # language & source docs have been parsed in sub harvest()
    
    foreach my $entry ( $root->children('word') ) {
        parseword($entry);
        print '.' if ( $entry_uid % 800 == 0 );
    }
    say " done.";
    print "   Writing remaining SQL files ...";
    writemainsql() if $mode eq "-s";
    say " done.";
    say "=== end of processing ===";
}

# === LOAD type ======================================================

sub hashtype {
    print "  => type ............";
    no warnings 'syntax';

    crunchtype( \%parenttypehashkey, \%parenttypehashval, \@parenttype, undef );

    $type_uid = 100;
    crunchtype( \%sourcetypehashkey, \%sourcetypehashval, \@sourcetype, 'source-type' );
    $type_uid = 200;
    crunchtype( \%doctypehashkey, \%doctypehashval, \@doctype, 'doc-type' );
    $type_uid = 300;
    crunchtype( \%linkedtypehashkey, \%linkedtypehashval, \@linkedtype, 'linked-type' );
    $type_uid = 400;
    crunchtype( \%eictypehashkey, \%eictypehashval, \@eictype, 'eic-type' );
    $type_uid = 500;
    crunchtype( \%exampletypehashkey, \%exampletypehashval, \@exampletype, 'example-type' );
    $type_uid = 600;
    crunchtype( \%reftypehashkey, \%reftypehashval, \@reftype, 'ref-type' );
    $type_uid = 700;
    crunchtype( \%arnediadtypehashkey, \%arnediadtypehashval,
                \@arnediadtype, 'arnediad-type' );
    $type_uid = 1000;
    crunchtype( \%classformtypehashkey, \%classformtypehashval,
                \@classformtype, 'class-form-type' );
    $type_uid = 1100;
    crunchtype( \%classformvartypehashkey, \%classformvartypehashval,
                \@classformvartype, 'class-form-variant-type' );
    $type_uid = 1200;
    crunchtype( \%inflecttypehashkey, \%inflecttypehashval,
                \@inflecttype, 'inflect-type' );
    $type_uid = 2000;
    crunchtype( \%inflectvartypehashkey, \%inflectvartypehashval,
                \@inflectvartype, 'inflect-variant-type' );
    $type_uid = 2200;
    crunchtype( \%speechtypehashkey, \%speechtypehashval, \@speechtype, 'speech-type' );
   
    undef %parenttypehashval;
    writesql( $insert_type, \@type_rows, 'type.sql', '>' )
      if $mode eq "-s";    # table TYPE
    undef %parenttypehashkey;
    undef @type_rows;
    say " done.";
}


# If parent name is given, lookup UID; iterate through typeArray; add string to
# generated UID in sub-type hash; push values to type_rows to build SQL; and 
# generate sub-type hash-by-value for later use
sub crunchtype {
    my ( $typehashkey, $typehashval, $typearray, $parentname ) = @_;
    
    my $parent_uid =
       defined $parentname
       ? ( $parenttypehashval {$parentname} // "NULL" )
    : 0;
    
    foreach my $typestring (@$typearray) {
        $$typehashkey{$type_uid} = $typestring;
        push @type_rows, "($type_uid, '$typestring', $parent_uid)";
        $type_uid++;
    }
    sayhashkeytovalue( $typehashkey, $typehashval );
}

# === LOAD LANGUAGES & HARVEST LANGUAGE DOCS ===============================


sub hashlangs {
    print "  => languages ";

    foreach my $language ( sort { $a <=> $b } keys %languages ) {
        print '.' if ( $counter % 6 == 0 );
        push @lang_rows, "($language, '$languages{$language}{name}', '$languages{$language}{lang}', $languages{$language}{parent})";

        say encode_utf8(
            "loaded $languages{$language}{lang} - $languages{$language}{name}")
          if $mode eq "-h";
          
        $langhashkey{$language} = $languages{$language}{lang};
        $counter++;
    }

    # flip hash to by value
    sayhashkeytovalue( \%langhashkey, \%langhashval );

    # set $arnediadtype_uid to 'language'
    $arnediadtype_uid = $arnediadtypehashval{'languagenote'};

    # iterate over all language elements in Eldamo to retrieve documentation
    foreach my $doclang ( $root->children('language') ) {
        harvestlangdocs($doclang);
    }

    writesql_no_encode( $insert_language, \@lang_rows, 'language.sql', '>' )
      if $mode eq "-s";    # table LANGUAGE
     # write sql only after all three type of arnediad's have been added
     # writesql( $insert_language_doc, \@langdoc_rows, 'language_doc.sql', '>' )
     #   if $mode eq "-s";    # table LANGUAGE_DOC
     #undef %langhashkey;
    undef @lang_rows;
    say " done.";
}

# find documentation of all doctype under the given language 
sub harvestlangdocs {
    my ( $doclang ) = @_;
    my $lang_uid =
       defined $doclang->att('id')
       ? $langhashval{ $doclang->att('id') } 
       : 0;
    
    # for every doctype in the hardcoded doctype list: 
    foreach my $doctype (@doctype) {
        crunchlangdocs( $lang_uid, $doclang, $doctype );
    }                     
    foreach my $subdoclang ( $doclang->children('language') ) {
        harvestlangdocs( $subdoclang );
    }
} 

sub crunchlangdocs {
    my ( $lang_uid, $doclang, $doctype ) = @_;
    $ordering = 1;
    # for every doc of type $doctype found under $doclang
    foreach my $langdoc ( $doclang->children($doctype) ) {
        parselangdoc( $lang_uid, $langdoc, $doctype, $ordering );
        $ordering++;
    }
}

# add the doc to the docs table, create row for langId, docId, ordering, arnediad_type
sub parselangdoc {
    my ( $lang_uid, $langdoc, $doctype, $ordering ) = @_;
    parsedoc( $langdoc, $doctype );    # <- doc_uid gets set here
    # lang_uid is set globally in calling harvestlangdocs
    push @arnediad_rows, "($lang_uid, $doc_uid, $ordering, $arnediadtype_uid)";
}

# === HARVEST CATEGORIES =============================================

sub hashcats {
    print "  => categories ";
    foreach my $cats ( $root->children('cats') ) { harvestcats($cats); }
    sayhashkeytovalue( \%cathashkey, \%cathashval );
    writesql( $insert_cat, \@cat_rows, 'cat.sql', '>' ) if $mode eq "-s"; # table CAT
    undef %cathashkey;
    undef @cat_rows;
    say " done.";
}

sub harvestcats {
    my ($cats) = @_;
    my $label = '';
    foreach my $parentcat ( $cats->children('cat-group') ) {
        $cathashkey{$parentcat_uid} = $parentcat->att('id');
        $label = $parentcat->att('label');
        $label =~ s/\'/''/g;
        push @cat_rows, "($parentcat_uid, '$label', NULL)";
        foreach my $cat ( $parentcat->children('cat') ) {
            $cathashkey{$cat_uid} = $cat->att('id');
            $label = $cat->att('label');
            $label =~ s/\'/''/g;
            push @cat_rows, "($cat_uid, '$label', $parentcat_uid)";
            print '.' if ( $cat_uid % 30 == 0 );
            $cat_uid++;
        }
        $parentcat_uid++;
    }
}

# === HARVEST CREATED ===============================================

sub hashcreated {
    print "  => created (by) ...";
    foreach my $word ( $root->children('word') ) { 
       harvestcreated($word); 
    }
    foreach my $created ( sort( unique(@raw_created) ) ) {
        if ( $created ne '' ) {
            $createdhashkey{$created_uid} = $created;
            push @created_rows, "($created_uid, '$created')";
            print '.' if ( $created_uid % 10 == 0 );
            $created_uid++;
        }
    }
    undef @raw_created;
    sayhashkeytovalue( \%createdhashkey, \%createdhashval );
    undef %createdhashkey;
    writesql( $insert_created, \@created_rows, 'created.sql', '>' ) if $mode eq "-s";    # table CREATED
    undef @created_rows;
    say " done.";
}

sub blobl{
   my($bogloe, $kabloobl) = @_;
   foreach my $globl (split(' ', $kabloobl)){ push @$bogloe, $globl;}
}

sub harvestcreated {
    my ($entry) = @_;
    if ( defined $entry->att('created') ){
       foreach my $globl (split(',', $entry->att('created'))){ 
          $globl=~ s/^\s+//;
          push @raw_created, $globl;
       }
    }
    foreach my $subentry ( $entry->children('word') ) {
        harvestcreated($subentry);
    }
}

# === HARVEST SOURCES ===============================================

sub hashsources {
    print "  => sources ";
    foreach my $source ( $root->children('source') ) {
        harvestsources($source);
    }
    sayhashkeytovalue( \%sourcehashkey, \%sourcehashval );
    undef %sourcehashkey;
    
    # set $arnediadtype_uid to 'source'
    $arnediadtype_uid = $arnediadtypehashval{'sourcenote'};
   
    writesql( $insert_source, \@source_rows, 'source.sql', '>') if $mode eq "-s";    # table SOURCE 
    # write sql only after all three type of arnediad's have been added
    #writesql( $insert_source_doc, \@srcdoc_rows, 'source_doc.sql', '>' ) if $mode eq "-s";    # table SOURCE_DOC
    undef @source_rows;
    say " done.";
}

sub harvestsources {
    my ($source) = @_;
    $ordering = 1;
    $sourcehashkey{$source_uid} = $source->att('prefix');
    push @source_rows,
        "($source_uid, '"
      . $source->att('name') . "', '"
      . $source->att('prefix') . "', "
      . (
        defined $source->att('type')
        ? $sourcetypehashval{ $source->att('type') }
        : "NULL"
      ) . ")";
    foreach my $note ( $source->children('notes') ) {
        parsesourcenote( $note, 'notes', $ordering );
        $ordering++;
    }
    $ordering = 1;
    foreach my $cite ( $source->children('cite') ) {
        parsesourcenote( $cite, 'cite', $ordering );
        $ordering++;
    }
    $ordering = 1;
    print '.' if ( $source_uid % 10 == 0 );
    $source_uid++;
}

#source_uid, doc_uid in global context
sub parsesourcenote {
    no warnings 'uninitialized';
    my ( $doc, $sourcenotetype, $ordering ) = @_; # sourcenotetype = notes or cite
    parsedoc( $doc, $sourcenotetype );    # always call parsedoc first to set uid
    push @arnediad_rows, "($source_uid, $doc_uid, $ordering, $arnediadtype_uid)";
}

# === HARVEST FORMS =============================================

sub hashforms {
    print "  => forms ";
    foreach my $word ( $root->children('word') ) { 
      harvestforms($word); 
    }
    foreach my $form ( sort ( unique(@raw_forms) ) ) {
        if ( $form ne '' ) {
            push @form_rows, "($form_uid, '$form')";
            $formhashkey{$form_uid} = $form;
            print '.' if ( $form_uid % 5000 == 0 );
            $form_uid++;
        }
    }
    undef @raw_forms;
    sayhashkeytovalue( \%formhashkey, \%formhashval );
    undef %formhashkey;
    writesql( $insert_form, \@form_rows, 'form.sql', '>') if $mode eq "-s";    # table FORM
    undef @form_rows;
    say " done.";
}

sub harvestforms {
    my ($entry) = @_;
    print '.' if ( $counter % 1000 == 0 );
    $counter++;
    
    pushform( $entry->att('v') );
    pushform( $entry->att('rule') );
    pushform( $entry->att('from') );
    pushform( $entry->att('stem') );
    pushform( $entry->att('orthography') );
    process_entrychild($entry);
    
    foreach my $ref ( $entry->children('ref') ) {
        pushform( $ref->att('v') );
        pushform( $ref->att('from') );
        pushform( $ref->att('rule') );
        process_refchild($ref);
    }
    foreach my $wordchild ( $entry->children('word') ) {
        harvestforms($wordchild);
    }
}

sub process_entrychild {
    my ($parent) = @_;
    
    # these shouldn't add any new forms, but just in case
    foreach my $before ( $parent->children('before') ) {
        pushform( $before->att('v') );
        foreach my $orderexample ( $before->children('order-example') ) {
            pushform( $orderexample->att('v') );
        }
    }
    foreach my $cognate ( $parent->children('cognate') ) {
        pushform( $cognate->att('v') );
    }
    foreach my $combine ( $parent->children('combine') ) {
        pushform( $combine->att('v') );
    }
    foreach my $deprecated ( $parent->children('deprecated') ) {
        pushform( $deprecated->att('v') );
    }
    foreach my $deriv ( $parent->children('deriv') ) {
        pushform( $deriv->att('v') );
    }
    foreach my $element ( $parent->children('element') ) {
        pushform( $element->att('v') );
    }
    foreach my $inflect ( $parent->children('inflect') ) {
        pushform( $inflect->att('v') );
    }
    foreach my $related ( $parent->children('related') ) {
        pushform( $related->att('v') );
    }
    foreach my $rule ( $parent->children('rule') ) {
        pushform( $rule->att('from') );
        pushform( $rule->att('rule') );
    }
    foreach my $see ( $parent->children('see') ) { 
      pushform( $see->att('v') ); 
    }
    foreach my $seefurther ( $parent->children('see-further') ) {
        pushform( $seefurther->att('v') );
    }
    foreach my $seenotes ( $parent->children('see-notes') ) {
        pushform( $seenotes->att('v') );
    }
}


sub process_refchild {
    my ($parent) = @_;
    
    foreach my $change ( $parent->children('change') ) {
        pushform( $change->att('v') );
        pushform( $change->att('i1') );
    }
    foreach my $cognate ( $parent->children('cognate') ) {
        pushform( $cognate->att('v') );
    }
    foreach my $correction ( $parent->children('correction') ) {
        pushform( $correction->att('v') );
    }
    foreach my $deriv ( $parent->children('deriv') ) {
        pushform( $deriv->att('v') );
        pushform( $deriv->att('i1') );
        pushform( $deriv->att('i2') );
        pushform( $deriv->att('i3') );
        foreach my $ruleexample ( $deriv->children('rule-example') ) {
            pushform( $ruleexample->att('from') );
            pushform( $ruleexample->att('rule') );
            pushform( $ruleexample->att('stage') );
        }
        foreach my $rulestart ( $deriv->children('rule-start') ) {
            pushform( $rulestart->att('stage') );
        }
    }
    foreach my $element ( $parent->children('element') ) {
        pushform( $element->att('v') );
    }
    foreach my $example ( $parent->children('example') ) {
        pushform( $example->att('v') );
    }
    foreach my $inflect ( $parent->children('inflect') ) {
        pushform( $inflect->att('v') );
    }
    foreach my $related ( $parent->children('related') ) {
        pushform( $related->att('v') );
    }
}

sub pushform {
    my ($formval) = @_;
    push @raw_forms, $formval if ( defined $formval );
}

# === HARVEST GLOSSES ============================================
sub hashglosses {
    print "  => glosses ...";
    foreach my $word ( $root->children('word') ) { harvestglosses($word); }
    foreach my $gloss ( sort( unique(@raw_glosses) ) ) {
        if ( $gloss ne '' ) {
            $glosshashkey{$gloss_uid} = $gloss;
            push @gloss_rows, "($gloss_uid, 1010, '$gloss')";
            print '.' if ( $gloss_uid % 2000 == 0 );
            $gloss_uid++;
        }
    }
    undef @raw_glosses;
    sayhashkeytovalue( \%glosshashkey, \%glosshashval );
    undef %glosshashkey;
    writesql( $insert_gloss, \@gloss_rows, 'gloss.sql', '>') if $mode eq "-s";    # table GLOSS
    undef @gloss_rows;
    say " done.";
}

sub harvestglosses {
    my ($entry) = @_;
    push @raw_glosses, $entry->att('gloss') if ( defined $entry->att('gloss') );
    push @raw_glosses, $entry->att('ngloss') if ( defined $entry->att('ngloss') );
    foreach my $ref ( $entry->children('ref') ) {
        push @raw_glosses, $ref->att('gloss') if ( defined $ref->att('gloss') );
    }
    foreach my $subentry ( $entry->children('word') ) {
        harvestglosses($subentry);
    }
}

# === END LOADING & HARVESTING =========================================

# === START PARSING ====================================================

# === PARSE ENTRIES ====================================================

sub parseword {
    no warnings 'uninitialized';
    my ( $entry, $parent_uid, $childorder ) = @_;
    $entry_uid++;
    
       $ordering            = 1;
    my $entry_form_uid      = ( $formhashval   { $entry->att('v') }           // 'X' );
    my $entry_lang_uid      = ( $langhashval   { $entry->att('l') }           // 'X' );
    my $entry_gloss_uid     = ( $glosshashval  { $entry->att('gloss') }       // 'NULL' );
    my $entry_ngloss_uid    = ( $glosshashval  { $entry->att('ngloss') }      // 'NULL' );
    my $entry_cat_uid       = ( $cathashval    { $entry->att('cat') }         // 'NULL' );
    
    my $entry_created_uid   = ( $createdhashval{ $entry->att('created') }     // 'NULL' );
    
    my $entry_ruleform_uid  = ( $formhashval   { $entry->att('rule') }        // 'NULL' );
    my $entry_stemform_uid  = ( $formhashval   { $entry->att('stem') }        // 'NULL' );
    my $entry_fromform_uid  = ( $formhashval   { $entry->att('from') }        // 'NULL' );
    my $entry_orthoform_uid = ( $formhashval   { $entry->att('orthography') } // 'NULL' );
    my $entry_tengwar       = $entry->att('tengwar')                          // "";
    my $entry_mark          = $entry->att('mark')                             // "";
    my $entry_neoversion    = $entry->att('neo-version')                      // "";
    my $entry_orderfield    = $entry->att('order')                            // "";
    my $entry_eldamopageid  = $entry->att('page-id')                          // "";
    my $entrytype_uid       = entrytype( $entry->att('speech')             // 'unknown' );
       $parent_uid          = $parent_uid                                       // 'NULL';
    
    push @entry_rows, "($entry_uid, $entry_form_uid, $entry_lang_uid, $entry_gloss_uid, $entry_ngloss_uid, $entry_cat_uid, $entry_created_uid, $entry_ruleform_uid, $entry_fromform_uid, $entry_stemform_uid, '$entry_tengwar', '$entry_mark', '$entry_neoversion', '$entry_eldamopageid', '$entry_orderfield', $entry_orthoform_uid, $parent_uid, $ordering, $entrytype_uid)";

    # ==== speech n-m TYPES  / ERNEDIAD ====
    $ordering = 1;
    foreach my $speeches ( $entry->att('speech') ) {
        foreach my $speech ( split( ' ', $speeches ) ) {
            push @arnediad_rows,
                "($entry_uid, "
              . ( $speechtypehashval{$speech} // 0 )
              . ", $ordering, "
              . ( $arnediadtypehashval{'entryspeechtype'} // 0 ) . ")";
            $ordering++;
        }
    }
    
    # ==== created n-m TYPES  / ERNEDIAD ====
    $ordering = 1;
    foreach my $creators ( $entry->att('created') ) {
        foreach my $creator ( split( ',', $creators ) ) {
            $creator=~ s/^\s+//;
            push @arnediad_rows,
                "($entry_uid, "
              . ( $createdhashval{ $creator } // 0 )
              . ", $ordering, "
              . ( $arnediadtypehashval{'created'} // 0 ) . ")";
            $ordering++;
        }
    }
    
    # ==== process LINKED ====
    $ordering = 1;
    foreach my $before ( $entry->children('before') ) {
        parselinked( $before, $ordering, 'before' )
          ;    # entry_uid + to_v + to_l (= after_entry_id)
        $ordering++;
    }
    $ordering = 1;
    foreach my $cognate ( $entry->children('cognate') ) {
        parselinked( $cognate, $ordering, 'cognate' )
          ; # entry_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
        $ordering++;
    }
    $ordering = 1;
    foreach my $combine ( $entry->children('combine') ) {
        parselinked( $combine, $ordering, 'combine' )
          ; 
        $ordering++;
    }
    $ordering = 1;
    foreach my $deprecated ( $entry->children('deprecated') ) {
        parselinked( $deprecated, $ordering, 'deprecated' )
          ; 
        $ordering++;
    }
    $ordering = 1;
    foreach my $deriv ( $entry->children('deriv') ) {
        parselinked( $deriv, $ordering, 'deriv' )
          ;    # this entry_uid + deriv_v + deriv_l (= deriv_entry_id) + mark
        $ordering++;    # + additional multiple FORM_ID + ordering
    }
    $ordering = 1;
    foreach my $related ( $entry->children('related') ) {
        parselinked( $related, $ordering, 'related' )
          ; # entry_uid + entry_uid + related_v + related_l (= related_entry_id) + mark
        $ordering++;
    }
    $ordering = 1;
    foreach my $see ( $entry->children('see') ) {
        parselinked( $see, $ordering, 'see' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    $ordering = 1;
    foreach my $seefurther ( $entry->children('see-further') ) {
        parselinked( $seefurther, $ordering, 'see-further' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    $ordering = 1;
    foreach my $seenotes ( $entry->children('see-notes') ) {
        parselinked( $seenotes, $ordering, 'see-notes' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    
    # ==== REF ====
    # (REF also contains RULE)
    $ordering = 1;
    foreach my $rule ( $entry->children('rule') ) {
        parserule( $rule, $ordering );
        $ordering++;
    }
    # 'undef' = parent REF, so not defined here = root ref has context entry_uid as parent
    $ordering = 1;
    foreach my $ref ( $entry->children('ref') ) {
        parseref( $ref, undef, $ordering, 'ref' );
        $ordering++;
    }
    
    # ==== EIC ====
    $ordering = 1;
    foreach my $class ( $entry->children('class') ) {
        parseeic( $class, $entry_uid, $ordering, 'class', 1 )
          ;    # entry_uid + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $element ( $entry->children('element') ) {
        parseeic( $element, $entry_uid, $ordering, 'element', 1 )
          ; # entry_uid + element_v + parent_l + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $inflect ( $entry->children('inflect') ) {
        parseeic( $inflect, $entry_uid, $ordering, 'inflect', 1 )
          ;    # entry_uid + v + form + Grammatical type (2x) + ordering
        $ordering++;
    }
    
    # ==== DOC / ERNEDIAD ====
    # set $arnediadtype_uid to 'entrynote'
    $arnediadtype_uid = $arnediadtypehashval{'entrynote'};
    $ordering = 1;
    foreach my $note ( $entry->children('notes') ) {
        parseentrynote( $note, $ordering );
        $ordering++;
    }
    
    # ==== recurse ====
    $ordering = 1;
    foreach my $child ( $entry->children('word') ) {
        parseword( $child, $entry_uid, $ordering );
        $ordering++;
    }
    $ordering = 1;
}

# === PARSE LINKED =====================================================
# entry_uid in global context
sub parselinked {
    no warnings 'uninitialized';
    $linked_uid++;
    my ( $linked, $linkedordering, $linkedtype ) = @_;

    my $linked_lang_uid =
      defined $linked->att('l')
      ? ( $langhashval{ $linked->att('l') } // 0 )
      : 'NULL';

    my $linked_form_uid =
      defined $linked->att('v')
      ? ( $formhashval{ $linked->att('v') } // 0 )
      : 'NULL';
    my $linked_mark = $linked->att('mark') // "";
    my $linked_type_uid = ( $linkedtypehashval{$linkedtype} // 0 );
    
    # there's only one doc per linked, hardcoding 1 for ordering
    if ( $linked->text ne "" ) { 
       $arnediadtype_uid = $arnediadtypehashval{$linkedtype };
       parsedoc( $linked, $linkedtype ); # call parsedoc first to set uid
       push @arnediad_rows, "($linked_uid, $doc_uid, 1, $arnediadtype_uid)";
    }
    push @linked_rows, "($linked_uid, $entry_uid, $linked_lang_uid, $linked_form_uid, '$linked_mark', $linkedordering, $linked_type_uid)";
    
    # order-example for BEFORE (the 1 = switch for LINKED/before/orderex vs REF example)
    $ordering = 1;
    foreach my $orderexample ( $linked->children('order-example') ) {
        parseexample( $orderexample, $linked_uid,  $ordering, 1 );
        $ordering++;
    }
}

# === PARSE EIC =====================================================
# entry_uid & ref_uid NOT in global context but in parent_uid
sub parseeic {
    no warnings 'uninitialized';
    $eic_uid++;
    my ( $eic, $parent_uid, $eicordering, $eictype, $islinkedeic ) = @_;
    my ( $formtype_uid, $varianttype_uid );

    my $eic_lang_uid =
      defined $eic->att('l')
      ? ( $langhashval{ $eic->att('l') } // 0 )
      : 'NULL';

    my $eic_source_uid =
      defined $eic->att('source')
      ? ( $sourcehashkey{ $eic->att('source') } // 0 )
      : 'NULL';

    my $eic_form_uid =
      defined $eic->att('v')
      ? ( $formhashval{ $eic->att('v') } // 0 )
      : 'NULL';


    my $arnediad_ordering = 1;
    if ( defined $eic->att('form') ) {
        $arnediadtype_uid = $arnediadtypehashval{$eictype eq 'class' ? 'classform' : 'inflectform'};
        foreach my $form ( split( ' ', $eic->att('form') ) ) {
            $formtype_uid = ($eictype eq 'class' ? 
                             $classformtypehashval{$form} : 
                             $inflecttypehashval{$form} // 0 );
            push @arnediad_rows,
                "($eic_uid, "
              .   $formtype_uid
              . ", $arnediad_ordering, $arnediadtype_uid)";
            #if ($formtype_uid == 0) {say "eictype: $eictype, undefined form: $form";}  
            $arnediad_ordering++;
        }
    }
    
    $arnediad_ordering = 1;
    if ( defined $eic->att('variant') ) {
        $arnediadtype_uid = $arnediadtypehashval{$eictype eq 'class' ? 'classvariant' : 'inflectvariant'};
        foreach my $variant ( split( ' ', $eic->att('variant') ) ) {
            $varianttype_uid = ($eictype eq 'class' ? 
                                $classformvartypehashval{$variant} : 
                                $inflectvartypehashval{$variant} // 0 );
            push @arnediad_rows,
                "($eic_uid, "
              .   $varianttype_uid
              . ", $arnediad_ordering, $arnediadtype_uid)";
            #if ($varianttype_uid == 0) {say "eictype: $eictype, undefined variant: $variant";}  
            $arnediad_ordering++;
        }
    }

    my $eic_mark = $eic->att('mark') // "";
    my $eic_type_uid = ( $eictypehashval{$eictype} // 0 );

    # there's only one doc per eic, hardcoding 1 for ordering
    if ( $eic->text ne "" ) {
        # set arnediad type to 'eictype' (element, inflect)
        $arnediadtype_uid = $arnediadtypehashval{$eictype};
        parsedoc( $eic, $eictype );    # call parsedoc first to set uid
        push @arnediad_rows, "($eic_uid, $doc_uid, 1, $arnediadtype_uid)";
    }
    
    if ($islinkedeic) {
        push @eic_rows, "($eic_uid, $parent_uid, NULL, $eic_lang_uid, NULL, $eic_form_uid, '$eic_mark', $eicordering, $eic_type_uid)";
    }
    else {
        push @eic_rows, "($eic_uid, NULL, $parent_uid, $eic_lang_uid, NULL, $eic_form_uid, '$eic_mark', $eicordering, $eic_type_uid)";
    }
}

# === PARSE ENTRY NOTE =================================================
#entry_uid, doc_uid, arnediadtype_uid in global context
sub parseentrynote {
    no warnings 'uninitialized';
    my ( $note, $ordering ) = @_;
    parsedoc( $note, 'notes' );    #first call this to set doc_uid
    push @arnediad_rows, "($entry_uid, $doc_uid, $ordering, $arnediadtype_uid)";
}

# === PARSE RULE (in table REF) =================================================
# context entry_uid, ref_uid
sub parserule {
    no warnings 'uninitialized';
    $ref_uid++;
    my ( $rule, $ruleordering ) = @_;
    
    my $rule_lang_uid =
      defined $rule->att('l')
      ? ( $langhashval{ $rule->att('l') } // 0 )
      : 'NULL';
      
    my $rule_rule_uid =
      defined $rule->att('rule')
      ? ( $formhashval{ $rule->att('rule') } // 0 )
      : 'NULL';
    
    my $rule_from_uid =
      defined $rule->att('from')
      ? ( $formhashval{ $rule->att('from') } // 0 )
      : 'NULL';
    
    push @ref_rows, "($ref_uid, NULL, $entry_uid, NULL, $rule_lang_uid, NULL, NULL, $rule_rule_uid, $rule_from_uid, NULL, '', $ruleordering, $reftypehashval{'rule'})";
}

# === PARSE REF ========================================================
# context entry_uid
sub parseref {
    no warnings 'uninitialized';     
    $ref_uid++;
    
    my ( $ref, $parent_ref_uid, $refordering, $reftype ) = @_;
    
    my $ref_rulefrom_uid = ( $formhashval{ $ref->att('from') } // 'NULL' );
    my $ref_gloss_uid = ( $glosshashval{ $ref->att('gloss') } // 'NULL' );
    my $ref_lang_uid  = ( $langhashval{ $ref->att('l') } // 'NULL' );
    my $ref_mark = $ref->att('mark') // "";
    my $ref_rulerl_uid = ( $langhashval{ $ref->att('rl') } // 'NULL' );
    my $ref_rulerule_uid = ( $formhashval{ $ref->att('rule') } // 'NULL' );
    my $ref_source_uid = (
        $sourcehashval{
            substr( $ref->att('source'), 0, index( $ref->att('source'), '/' ) )
        } // 'NULL'
    ); 
    my $ref_form_uid  = ( $formhashval{ $ref->att('v') } // 'X' );
    
    # there's only one doc per ref, hardcoding 1 for ordering
    if ( $ref->text ne "" ) {
        # set arnediad type to 'reftype' 
        $arnediadtype_uid = $arnediadtypehashval{$reftype};
        parsedoc( $ref, $reftype );    # call parsedoc first to set uid
        push @arnediad_rows, "($ref_uid, $doc_uid, 1, $arnediadtype_uid)";
    }
    
    if (!defined($parent_ref_uid)){
       # parent_ref_uid not defined, so this is a ROOT REF element
       push @ref_rows, "($ref_uid, NULL, $entry_uid, $ref_gloss_uid, $ref_lang_uid, $ref_form_uid, $ref_source_uid, $ref_rulerule_uid, $ref_rulefrom_uid, NULL, $ref_mark, $refordering, $reftypehashval{$reftype})";
    } else {
       # parent_ref_uid is defined, so this is a CHILD REF element
       push @ref_rows, "($ref_uid, $parent_ref_uid, NULL, $ref_gloss_uid, $ref_lang_uid, $ref_form_uid, $ref_source_uid, $ref_rulerule_uid, $ref_rulefrom_uid, NULL, $ref_mark, $refordering, $reftypehashval{$reftype})";
    }         
    
    # REF child types
    # RULESTART & RULE-EXAMPLE (children of DERIV REF)
    $ordering = 1;
    foreach my $rulestart ( $ref->children('rule-start') ) {
        parseref( $rulestart, $ref_uid, $ordering, 'rule-start' );
        $ordering++;
    }
    $ordering = 1;
    foreach my $ruleexample ( $ref->children('rule_example') ) {
        parseref( $ruleexample, $ref_uid, $ordering, 'rule_example' );
        $ordering++;
    }
    
    # other REF children
    $ordering = 1;
    foreach my $change ( $ref->children('change') ) {
        parseref( $change, $ref_uid, $ordering, 'change' );
        $ordering++;
    }
    $ordering = 1;
    foreach my $cognate ( $ref->children('cognate') ) {
        parseref( $cognate, $ref_uid, $ordering, 'cognate' ); 
        $ordering++;
    }
    $ordering = 1;
    foreach my $correction ( $ref->children('correction') ) {
        parseref( $correction, $ref_uid, $ordering, 'correction' ); 
        $ordering++;
    }
    $ordering = 1;
    foreach my $deriv ( $ref->children('deriv') ) {
        parseref( $deriv, $ref_uid, $ordering, 'deriv' );
        $ordering++;
    }
    $ordering = 1;
    foreach my $related ( $ref->children('related') ) {
        parseref( $related, $ref_uid, $ordering, 'related' );    
        $ordering++;
    }
    
    # EXAMPLE (parameter 0 means REF example of deriv or inflect type)
    $ordering = 1;
    foreach my $example ( $ref->children('example') ) {
        parseexample( $example, $ref_uid, $ordering, 0 );
        $ordering++;
    }
    
    # EIC types
    $ordering = 1;
    foreach my $element ( $ref->children('element') ) {
        parseeic( $element, $ref_uid, $ordering, 'element', 0 ); 
        $ordering++;
    }
    $ordering = 1;
    foreach my $inflect ( $ref->children('inflect') ) {
        parseeic( $inflect, $ref_uid, $ordering, 'inflect', 0 );
        $ordering++;
    }
}


# === PARSE EXAMPLES ===================================================
# $linked_uid, $ref_uid NOT in context
sub parseexample {
    no warnings 'uninitialized';  
    $example_uid++;
    my ( $example, $parent_uid, $exampleordering, $isorderexample ) = @_;

    my $example_type_uid;

    my $example_source_uid = defined $example->att('source') ? 
       ( $sourcehashval{
            substr(
                $example->att('source'), 0,
                index( $example->att('source'), '/' )
            )
        } // 'X'
      )
      : 0;
      
    my $example_source = $example->att('source') // "";
    
    my $example_form_uid = defined $example->att('v') ? 
       ( $formhashval{ $example->att('v') } // 0 ) : 'NULL';

    if ($isorderexample) {
        $example_type_uid = ( $exampletypehashval{'order'} // 0 );
    } else {
        $example_type_uid = defined $example->att('t') ? 
      ( $exampletypehashval{ $example->att('t') } // 0 ) : 'NULL';
    }
      
    if ($isorderexample) {
        push @example_rows,
            "($parent_uid, NULL, $example_source_uid, '$example_source', $example_form_uid, $exampleordering, $example_type_uid)";
    } else {
        push @example_rows,
            "(NULL, $parent_uid, $example_source_uid, '$example_source', $example_form_uid, $exampleordering, $example_type_uid)";
    }
}


# === PARSE DOCS =======================================================

sub parsedoc {
    $doc_uid++;
    my ( $doc, $doctype ) = @_;
    my $text = $doc->text;
    $text =~ s/\R//g;
    $text =~ s/\'/''/g;
    push @doc_rows,
      "($doc_uid, '$text', " . ( $doctypehashval{$doctype} // 0 ) . ")";
}


# === UTILS =================================================
# flips key<->value
sub sayhashkeytovalue {
    my $hashedbykey   = $_[0];
    my $hashedbyvalue = $_[1];
    while ( ( $key, $value ) = each %$hashedbykey ) {
        $$hashedbyvalue{$value} = $key;
        say encode_utf8( "key: " . $key . " --> value: " . $value )
          if $mode eq "-h";
    }
}

sub sayhash {
    my $hashed = $_[0];
    while ( ( $key, $value ) = each %$hashed ) {
        say encode_utf8( "key: " . $key . " --> value: " . $value );
    }
}

sub sayarray {
    my $arrayed = @_;
    foreach my $arrayrow (@$arrayed) { say encode_utf8($arrayrow); }
}

sub writesql {
    my $insertinto  = $_[0];
    my $arrayed     = $_[1];
    my $filename    = $_[2];
    my $writeappend = $_[3];
    my $rows        = 1;
    my $arraysize   = @$arrayed;
    open( SQLFILE, $writeappend, $outputdir . $filename )
      or die "$! error trying to create or overwrite $SQLFILE";
    say SQLFILE encode_utf8($insertinto);
    foreach my $arrayrow (@$arrayed) {
        if ( $rows % 1000 == 0 ) {
            say SQLFILE encode_utf8( $arrayrow . ";" );
            say SQLFILE encode_utf8($insertinto) if ( $arraysize % 1000 != 0 );
        }
        else {
          if ( $rows == $arraysize ) {
            say SQLFILE encode_utf8($arrayrow . ";");
          } else {
            say SQLFILE encode_utf8($arrayrow . ",");
          }
        }
        $rows++;
    }
    close SQLFILE;
}

sub writesql_no_encode {
    my $insertinto  = $_[0];
    my $arrayed     = $_[1];
    my $filename    = $_[2];
    my $writeappend = $_[3];
    my $rows        = 1;
    my $arraysize   = @$arrayed;
    open( SQLFILE, $writeappend, $outputdir . $filename )
      or die "$! error trying to create or overwrite $SQLFILE";
    say SQLFILE $insertinto;
    foreach my $arrayrow (@$arrayed) {
        if ( $rows % 1000 == 0 ) {
            say SQLFILE $arrayrow . ";";
            say SQLFILE $insertinto if ( $arraysize % 1000 != 0 );
        } else {
          if ( $rows == $arraysize ) {
            say SQLFILE $arrayrow . ";";
          } else {
            say SQLFILE $arrayrow . ",";
          }
        }
        $rows++;
    }
    close SQLFILE;
}

# === FINALLY =================================================
sub writemainsql {
    writesql( $insert_entry, \@entry_rows, 'entry.sql', '>' );
    print ' entries';
    writesql( $insert_linked, \@linked_rows, 'linked.sql', '>' );
    print ', linked';
    writesql( $insert_eic, \@eic_rows, 'eic.sql', '>' );
    print ', eic';
    writesql( $insert_ref, \@ref_rows, 'ref.sql', '>' );
    print ', ref\'s';
    writesql( $insert_example, \@example_rows, 'example.sql', '>' );
    print ', linked';
    writesql( $insert_doc, \@doc_rows, 'doc.sql', '>' );
    print ', docs';
    writesql( $insert_arnediad, \@arnediad_rows, 'arnediad.sql', '>' );
    print ' and the rest.';
   
}

sub entrytype {
    my ($speech) = @_;
    if    ( $speech =~ /phone/ )   { return $parenttypehashval{'phonetical'}; }
    elsif ( $speech =~ /grammar/ ) { return $parenttypehashval{'grammatical'}; }
    elsif ( $speech =~ /root/ )    { return $parenttypehashval{'root'}; }
    else                           { return $parenttypehashval{'lexical'}; }
}


sub loadvariables {


    # some hardcoded values, contained in the schema xml, not the data xml
    # === LIST type =================================================

    @parenttype = (
        'arnediad-type',           'class-form-type',
        'class-form-variant-type', 'doc-type',
        'eic-type',                'example-type',
        'inflect-type',            'inflect-variant-type',
        'linked-type',             'ref-type',
        'source-type',             'speech-type'
    );

    @sourcetype = (
        'adunaic',  'appendix',   'index',  'minor-work',
        'minor',    'neologisms', 'quenya', 'secondary',
        'sindarin', 'telerin',    'work'
    );

    @doctype = (
        'before',       'cite',    'class',     'cognate',
        'deprecations', 'deriv',   'eic',       'element',
        'grammar',      'inflect', 'linked',    'names',
        'neologisms',   'notes',   'phonetics', 'phrases',
        'ref',          'related', 'roots',     'vocabulary',
        'words'
    );

    @linkedtype = (
        'before',      'cognate',   'combine', 'deprecated',
        'deriv',       'element',   'related', 'see-also',
        'see-further', 'see-notes', 'see',     'word'
    );

    @eictype = ( 'element', 'inflect', 'class' );

    @exampletype = ( 'ref', 'deriv', 'inflect', 'order' );

    @reftype = (
        'change',  'cognate', 'correction',   'deriv',
        'example', 'ref',     'rule-example', 'rule-start',
        'rule'
    );

    @arnediadtype = (
        'before',            'cognate',
        'created',           'deriv',
        'eic',               'classform',
        'classvariant',      'inflectform',
        'inflectvariant',    'element',
        'entrynote',         'entryspeechtype',
        'inflect',           'languagenote',
        'linked',            'ref',
        'related',           'sourcenote'
    );


    @classformtype = (
        'strong-I',           'strong-II',
        'weak-I',             'weak-II',
        'neut',               'gendered',
        'biconsonantal-verb', 'triconsonantal-verb',
        'derived-verb',       'uniconsonantal-form',
        'biconsonantal-root', 'triconsonantal-root',
        'a-verb',             'basic-verb',
        'irregular-verb',     'na-formative',
        'non-verb-derived',   'ta-causative',
        'ta-formative',       'talat-stem',
        'u-verb',             'weak-verb',
        'ya-causative',       'ya-formative'
    );

    @classformvartype = ( 'common', 'fem', 'masc' );

    @inflecttype = (
        '?',                            'singular',
        'dual',                         'plural',
        'partitive-plural',             'class-plural',
        'draft-dual',                   'draft-plural',
        'infinitive',                   'aorist',
        'present',                      'past',
        'strong-past',                  'perfect',
        'strong-perfect',               'future',
        'gerund',                       'particular-infinitive',
        'consuetudinal-past',           'present-imperfect',
        'present-perfect',              'past-continuous',
        'past-imperfect',               'past-perfect',
        'past-future',                  'past-future-perfect',
        'long-perfect',                 'pluperfect',
        'future-imperfect',             'future-perfect',
        'future-future',                'continuative-present',
        'continuative-past',            'draft-perfect',
        'passive-past',                 'stative',
        'stative-past',                 'stative-future',
        'conditional',                  'imperative',
        'suffixed-imperative',          'subjunctive',
        'past-subjunctive',             'present-subjective',
        'impersonal',                   'passive',
        'reflexive',                    'active-participle',
        'passive-participle',           'imperfect-participle',
        'imperfect-passive-participle', 'perfect-participle',
        'perfect-passive-participle',   'perfective-participle',
        'future-participle',            'future-passive-participle',
        'reflexive-participle',         '1st-sg',
        '1st-dual-exclusive',           '1st-dual-inclusive',
        '1st-pl',                       '1st-pl-exclusive',
        '1st-pl-inclusive',             '2nd-sg',
        '2nd-sg-familiar',              '2nd-sg-polite',
        '2nd-sg-honorific',             '2nd-dual',
        '2nd-dual-polite',              '2nd-dual-honorific',
        '2nd-pl',                       '2nd-pl-polite',
        '2nd-pl-honorific',             '3rd-sg',
        '3rd-sg-fem',                   '3rd-sg-masc',
        '3rd-sg-neut',                  '3rd-sg-reflexive',
        '3rd-dual',                     '3rd-dual-fem',
        '3rd-dual-masc',                '3rd-dual-neut',
        '3rd-pl',                       '3rd-pl-fem',
        '3rd-pl-masc',                  '3rd-pl-neut',
        '3rd-pl-reflexive',             'with-sg-object',
        'with-dual-object',             'with-pl-object',
        'with-remote-sg-object',        'with-remote-pl-object',
        'with-1st-sg-object',           'with-1st-pl-object',
        'with-2nd-sg-object',           'with-2nd-pl-object',
        'with-1st-sg-dative',           '1st-sg-prep',
        '1st-dual-prep',                '1st-pl-exclusive-prep',
        '1st-pl-inclusive-prep',        '2nd-sg-prep',
        '2nd-sg-familiar-prep',         '2nd-sg-polite-prep',
        '2nd-pl-prep',                  '3rd-sg-prep',
        '3rd-sg-inanimate-prep',        '3rd-sg-honorific-prep',
        '3rd-pl-prep',                  '3rd-pl-honorific-prep',
        'definite-prep',                'definite-plural-prep',
        '1st-sg-poss',                  '1st-pl-exclusive-poss',
        '1st-pl-inclusive-poss',        '2nd-sg-poss',
        '2nd-sg-polite-poss',           '2nd-dual-poss',
        '2nd-pl-poss',                  '3rd-sg-poss',
        '3rd-pl-poss',                  'accusative',
        'ablative',                     'allative',
        'dative',                       'genitive',
        'instrumental',                 'locative',
        'nominative',                   'possessive',
        'possessive-adjectival',        's-case',
        'old-genitive',                 'comitative',
        'similative',                   'partitive',
        'objective',                    'subjective',
        'agental-formation',            'draft-dative',
        'draft-genitive',               'draft-instrumental',
        'draft-subjective',             'augmentative',
        'comparative',                  'diminutive',
        'intensive',                    'superlative',
        'diminutive-superlative',       'fem',
        'masc',                         'neut',
        'soft-mutation',                'nasal-mutation',
        'liquid-mutation',              'stop-mutation',
        'mixed-mutation',               'sibilant-mutation',
        'i-mutation',                   'a-fortification',
        'augmentation',                 'consonant-doubling',
        'extension',                    'full-form',
        'inversion',                    'nasal-infixion',
        'nasal-prefixion',              's-fortification',
        'strengthened',                 'subordinate-vowel-variation',
        'vocalic-extension',            'vowel-lengthening',
        'vowel-prefixion',              'vowel-suffixion',
        'vowel-suppression',            'stem',
        'assimilated',                  'elided',
        'shortened',                    'negated',
        'definite',                     'indefinite',
        'affix',                        'prefix',
        'suffix',                       'patronymic',
        'adjectival',                   'adverbial',
        'frequentative',                'radical',
        'complete',                     'glide-consonant',
        'negative-quasi-participle',    'no-agreement',
        'agental',                      'root'
    );

    @inflectvartype = (
        'b-mutation',                   'c-mutation',
        'cw-mutation',                  'd-mutation',
        'dy-mutation',                  'g-mutation',
        'gw-mutation',                  'h-mutation',
        'lh-mutation',                  'm-mutation',
        'mb-mutation',                  'nd-mutation',
        'ng-mutation',                  'p-mutation',
        'rh-mutation',                  's-mutation',
        't-mutation',                   'declension-A',
        'declension-B',                 'declension-C',
        'declension-D',                 'fem',
        'masc',                         'neut',
        'a-genitive',                   'adj-agreement',
        'adjectival',                   'adjective-in-objective',
        'archaic-objective-with-glide', 'archaic-strong-dual',
        'archaic-dual-with-glide',      'archaic-strong-objective',
        'archaic-strong-plural',        'archaic-strong-subjective',
        'assimilated',                  'augmentless',
        'bare-stem',                    'colloquial-possessive',
        'dialectical',                  'draft',
        'er-plural',                    'half-strong-past',
        'infixed-imperative',           'irregular',
        'irregular-dual',               'irregular-plural',
        'irregular-subjective',         'joining-base-vowel',
        'long-dative',                  'long-imperfect',
        'n-accusative',                 'na-dative',
        'no-agreement',                 'o-genitive',
        'normal-and-subjective',        'object-suffix-only',
        'objective-with-syncope',       'plural-with-linking-consonant',
        'possessive-second',            'pronoun-prefix',
        'prosodic-lengthening',         'r-locative',
        'root-perfect',                 'short-instrumental',
        'strong-I-without-syncope',     'strong-past',
        'strong-perfect',               'suffixed-imperative',
        'u-dual',                       'weak-past',
        'weak-perfect'
    );

    @speechtype = (
        '?',               'adj',
        'adv',             'affix',
        'article',         'cardinal',
        'conj',            'collective-name',
        'collective-noun', 'family-name',
        'fem-name',        'fraction',
        'grammar',         'infix',
        'interj',          'masc-name',
        'n',               'ordinal',
        'particle',        'phoneme',
        'phonetics',       'phonetic-group',
        'phonetic-rule',   'phrase',
        'place-name',      'pref',
        'prep',            'pron',
        'proper-name',     'radical',
        'root',            'text',
        'suf',             'vb'
    );
      
    $insert_cat =
      'INSERT INTO ' . $schema . 'CAT (ID, LABEL, PARENT_ID) VALUES ';
    $insert_created = 'INSERT INTO ' . $schema . 'CREATED (ID, TXT) VALUES ';
    $insert_doc =
      'INSERT INTO ' . $schema . 'DOC (ID, TXT, DOCTYPE_ID) VALUES ';
    $insert_arnediad =
        'INSERT INTO '
      . $schema
      . 'ARNEDIAD (FROM_ID, TO_ID, "ORDERING", ARNEDIAD_TYPE_ID) VALUES ';
    $insert_eic =
        'INSERT INTO '
      . $schema
      . 'EIC (ID, ENTRY_ID, REF_ID, LANG_ID, SOURCE_ID, SOURCE, FORM_ID, INFLECT_TYPE_ID, INFLECT_VAR_TYPE_ID, MARK, "ORDERING", EIC_TYPE_ID) VALUES ';
    $insert_entry =
        'INSERT INTO '
      . $schema
      . 'ENTRY (ID, FORM_ID, LANGUAGE_ID, GLOSS_ID, NGLOSS_ID, CAT_ID, CREATED_ID, RULE_FORM_ID, FROM_FORM_ID, STEM_FORM_ID, ORTHO_FORM_ID, TENGWAR, MARK, NEOVERSION, ELDAMO_PAGEID, ORDERFIELD, ENTRY_TYPE_ID) VALUES ';
    $insert_example =
        'INSERT INTO '
      . $schema
      . 'EXAMPLE (LINKED_ID, REF_ID, SOURCE_ID, SOURCE, FORM_ID, "ORDERING", EXAMPLE_TYPE_ID) VALUES ';
    $insert_form = 'INSERT INTO ' . $schema . 'FORM (ID, TXT) VALUES ';
    $insert_gloss =
      'INSERT INTO ' . $schema . 'GLOSS (ID, LANGUAGE_ID, TXT) VALUES ';
    $insert_language =
      'INSERT INTO ' . $schema . 'LANGUAGE (ID, NAME, LANG, PARENT_ID) VALUES ';
    $insert_linked =
        'INSERT INTO '
      . $schema
      . 'LINKED (ID, ENTRY_ID, LANG_ID, FORM_ID, MARK, "ORDERING", LINKED_TYPE_ID) VALUES ';
    $insert_ref =
        'INSERT INTO '
      . $schema
      . '(ID, REF_ID, ENTRY_ID, GLOSS_ID, LANG_ID, FORM_ID, SOURCE_ID, SOURCE, FORM1_ID, FORM2_ID, FORM3_ID, MARK, "ORDERING", REF_TYPE_ID) VALUES ';
    $insert_source =
        'INSERT INTO '
      . $schema
      . 'SOURCE (ID, NAME, PREFIX, SOURCETYPE_ID) VALUES ';
    $insert_type =
      'INSERT INTO ' . $schema . 'TYPE (ID, TXT, PARENT_ID) VALUES ';
      
      
    %languages = (
        0 => {
            parent => 0,
            lang   => "ROOT",
            name   => "ROOT",
        },
        1 => {
            parent => 0,
            lang   => "all",
            name   => "Eldarin Languages",
        },
        2 => {
            parent => 1,
            lang   => "neo",
            name   => "Combined (Neo) Languages",
        },
        3 => {
            parent => 1,
            lang   => "late",
            name   => "Late Period (1950-1973)",
        },
        4 => {
            parent => 1,
            lang   => "middle",
            name   => "Middle Period (1930-1950)",
        },
        6 => {
            parent => 1,
            lang   => "early",
            name   => "Early Period (1910-1930)",
        },
        7 => {
            parent => 1,
            lang   => "ws",
            name   => "Writing Systems",
        },
        10 => {
            parent => 0,
            lang   => "AML",
            name   => "Active modern Languages",
        },
        11 => {
            parent => 0,
            lang   => "IML",
            name   => "Inactive  modern Languages",
        },
        20 => {
            parent => 2,
            lang   => "np",
            name   => "Neo-Primitive Elvish",
        },
        21 => {
            parent => 2,
            lang   => "nq",
            name   => "Neo-Quenya",
        },
        22 => {
            parent => 2,
            lang   => "ns",
            name   => "Neo-Sindarin",
        },
        30 => {
            parent => 3,
            lang   => "p",
            name   => "Primitive Elvish",
        },
        31 => {
            parent => 3,
            lang   => "man",
            name   => "Mannish Languages",
        },
        32 => {
            parent => 3,
            lang   => "oth",
            name   => "Other Languages",
        },
        40 => {
            parent => 4,
            lang   => "mp",
            name   => "Middle Primitive Elvish",
        },
        50 => {
            parent => 5,
            lang   => "ep",
            name   => "Early Primitive Elvish",
        },
        60 => {
            parent => 6,
            lang   => "teng",
            name   => "Tengwar",
        },
        61 => {
            parent => 6,
            lang   => "cir",
            name   => "Cirth",
        },
        62 => {
            parent => 6,
            lang   => "sar",
            name   => "Sarati",
        },
        63 => {
            parent => 6,
            lang   => "un",
            name   => "Unknown",
        },
        100 => {
            parent => 10,
            lang   => "ENG",
            name   => "English",
        },
        101 => {
            parent => 10,
            lang   => "GER",
            name   => "Deutsch",
        },
        102 => {
            parent => 11,
            lang   => "NOB",
            name   => "Bokmal",
        },
        103 => {
            parent => 11,
            lang   => "FRA",
            name   => "Français",
        },
        104 => {
            parent => 11,
            lang   => "CZE",
            name   => "Čeština",
        },
        105 => {
            parent => 11,
            lang   => "WEL",
            name   => "Cymraeg",
        },
        106 => {
            parent => 11,
            lang   => "DAN",
            name   => "Dansk",
        },
        107 => {
            parent => 11,
            lang   => "SPA",
            name   => "Español",
        },
        108 => {
            parent => 11,
            lang   => "ITA",
            name   => "Italiano",
        },
        109 => {
            parent => 11,
            lang   => "DUT",
            name   => "Nederlands",
        },
        110 => {
            parent => 11,
            lang   => "NOR",
            name   => "Norsk",
        },
        111 => {
            parent => 11,
            lang   => "NNO",
            name   => "Nynorsk",
        },
        112 => {
            parent => 11,
            lang   => "POL",
            name   => "Polskie",
        },
        113 => {
            parent => 11,
            lang   => "POR",
            name   => "Português",
        },
        114 => {
            parent => 11,
            lang   => "RUM",
            name   => "Română",
        },
        115 => {
            parent => 11,
            lang   => "SLV",
            name   => "Slovenščina",
        },
        116 => {
            parent => 11,
            lang   => "SLO",
            name   => "Slovenský",
        },
        117 => {
            parent => 11,
            lang   => "SWE",
            name   => "Swedish",
        },
        118 => {
            parent => 11,
            lang   => "TUR",
            name   => "Türk",
        },
        119 => {
            parent => 11,
            lang   => "RUS",
            name   => "Русский",
        },
        120 => {
            parent => 11,
            lang   => "SRP",
            name   => "Српски",
        },
        300 => {
            parent => 30,
            lang   => "aq",
            name   => "Ancient Quenya",
        },
        301 => {
            parent => 30,
            lang   => "at",
            name   => "Ancient Telerin",
        },
        302 => {
            parent => 30,
            lang   => "av",
            name   => "Avarin",
        },
        310 => {
            parent => 31,
            lang   => "ed",
            name   => "Edain",
        },
        311 => {
            parent => 31,
            lang   => "roh",
            name   => "Rohirric",
        },
        312 => {
            parent => 31,
            lang   => "wos",
            name   => "Wose",
        },
        313 => {
            parent => 31,
            lang   => "dun",
            name   => "Dunlending",
        },
        314 => {
            parent => 31,
            lang   => "eas",
            name   => "Easterling",
        },
        320 => {
            parent => 32,
            lang   => "val",
            name   => "Valarin",
        },
        321 => {
            parent => 32,
            lang   => "ent",
            name   => "Entish",
        },
        322 => {
            parent => 32,
            lang   => "kh",
            name   => "Khuzdul",
        },
        323 => {
            parent => 32,
            lang   => "khx",
            name   => "Khuzdhul, External",
        },
        324 => {
            parent => 32,
            lang   => "bs",
            name   => "Black Speech",
        },
        400 => {
            parent => 40,
            lang   => "maq",
            name   => "Middle Ancient Quenya",
        },
        401 => {
            parent => 40,
            lang   => "on",
            name   => "Old Noldorin",
        },
        402 => {
            parent => 40,
            lang   => "mt",
            name   => "Middle Telerin",
        },
        403 => {
            parent => 40,
            lang   => "ilk",
            name   => "Ilkorin",
        },
        404 => {
            parent => 40,
            lang   => "dor",
            name   => "Doriathrin",
        },
        405 => {
            parent => 40,
            lang   => "dor ilk",
            name   => "Doriathrin/Ilkorin",
        },
        406 => {
            parent => 40,
            lang   => "fal",
            name   => "Falathrin",
        },
        407 => {
            parent => 40,
            lang   => "bel",
            name   => "Beleriand(r)ic",
        },
        408 => {
            parent => 40,
            lang   => "dan",
            name   => "Danian",
        },
        409 => {
            parent => 40,
            lang   => "oss",
            name   => "Ossriandric",
        },
        410 => {
            parent => 40,
            lang   => "edan",
            name   => "East Danian",
        },
        411 => {
            parent => 40,
            lang   => "lem",
            name   => "Lemberin",
        },
        412 => {
            parent => 40,
            lang   => "tal",
            name   => "Taliska",
        },
        500 => {
            parent => 50,
            lang   => "eoq",
            name   => "Early Old Qenya",
        },
        501 => {
            parent => 50,
            lang   => "g",
            name   => "Gnomish",
        },
        502 => {
            parent => 50,
            lang   => "eon",
            name   => "Early Old Noldorin",
        },
        503 => {
            parent => 50,
            lang   => "sol",
            name   => "Solosimpi",
        },
        504 => {
            parent => 50,
            lang   => "et",
            name   => "Early Telerin",
        },
        505 => {
            parent => 50,
            lang   => "eilk",
            name   => "Early Ilkorin",
        },
        3000 => {
            parent => 300,
            lang   => "q",
            name   => "Quenya",
        },
        3001 => {
            parent => 300,
            lang   => "van",
            name   => "Vanyarin",
        },
        3010 => {
            parent => 301,
            lang   => "t",
            name   => "Telerin",
        },
        3011 => {
            parent => 301,
            lang   => "lon",
            name   => "Late Old Noldorin",
        },
        3012 => {
            parent => 301,
            lang   => "os",
            name   => "Old Sindarin",
        },
        3013 => {
            parent => 301,
            lang   => "nan",
            name   => "Nandorin",
        },
        3100 => {
            parent => 310,
            lang   => "pad",
            name   => "Primitive Adunaic",
        },
        4000 => {
            parent => 400,
            lang   => "mq",
            name   => "Middle Quenya",
        },
        4001 => {
            parent => 400,
            lang   => "lin",
            name   => "Lindarin",
        },
        4010 => {
            parent => 401,
            lang   => "n",
            name   => "Noldorin",
        },
        5000 => {
            parent => 500,
            lang   => "eq",
            name   => "Early Quenya",
        },
        5020 => {
            parent => 502,
            lang   => "en",
            name   => "Early Noldorin",
        },
        30110 => {
            parent => 3011,
            lang   => "ln",
            name   => "Late Noldorin",
        },
        30120 => {
            parent => 3012,
            lang   => "s",
            name   => "Sindarin",
        },
        30121 => {
            parent => 3012,
            lang   => "norths",
            name   => "North Sindarin",
        },
        31000 => {
            parent => 3100,
            lang   => "ad",
            name   => "Adunaic",
        },
        310000 => {
            parent => 31000,
            lang   => "wes",
            name   => "Westron",
        }
    );
}
