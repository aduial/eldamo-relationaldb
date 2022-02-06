use strict;
use warnings;
use Encode;
use XML::Twig;
use Array::Utils qw(:all);
use feature 'say';
use File::Path qw(make_path);
use Data::Dumper;
use List::MoreUtils qw(natatime);

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


my $entry_uid = 9999; 

my $doc_uid       = 0; # incremented at top of parsedoc

my $insert_cat;
my $insert_created;
my $insert_doc;
my $insert_relation;
my $insert_entry;
my $insert_form;
my $insert_gloss;
my $insert_language;
my $insert_source;
my $insert_type;

my @cat_rows           = ();
my @source_rows        = ();
my @type_rows          = ();
my @lang_rows          = ();
my @created_rows       = ();
my @form_rows          = ();
my @gloss_rows         = ();
my @relation_rows      = ();
my @entry_rows         = ();
my @doc_rows           = ();

my @raw_forms        = ();
my @raw_glosses      = ();
my @raw_created      = ();

my %parenttypehashkey;
my %sourcetypehashkey;
my %doctypehashkey;
my %relationtypehashkey;
my %entitytypehashkey;
my %entrytypehashkey;
my %entryclasshashkey;
my %classformtypehashkey;
my %classformvartypehashkey;
my %inflecttypehashkey;
my %inflectvartypehashkey;
my %speechtypehashkey;

my %parenttypehashval;
my %sourcetypehashval;
my %doctypehashval;
my %relationtypehashval;
my %entitytypehashval;
my %entrytypehashval;
my %entryclasshashval;
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
my @relationtype;
my @entitytype;
my @entrytype;
my @entryclass;
my @classformtype;
my @classformvartype;
my @inflecttype;
my @inflectvartype;
my @speechtype;

my $relationtype_uid;

my @entry_uid_stack;
my $latestdoc;

# create files and dir if needed
my $SQLFILE;
eval { make_path($outputdir) };
if ($@) {
    print "Couldn't create $outputdir: $@";
}
my $maxrows = 50000;

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
        # clear uid stack and latestdoc (used to avoid duplicate doc rows)
        undef @entry_uid_stack;
        undef $latestdoc;
        parseword($entry);
        print '.' if ( $entry_uid % 800 == 0 );
    }
    say " done.";
    print "   Writing remaining SQL files ...";
    writemainsql() if $mode eq "-s";
    say " There. Done.";
    say "=== end of processing ===";
}

# === LOAD type ======================================================

sub hashtype {
    print "  => type ............";
    no warnings 'syntax';

    crunchtype( \%parenttypehashkey, \%parenttypehashval, \@parenttype, undef );

    $type_uid = 100;
    crunchtype( \%entrytypehashkey, \%entrytypehashval, \@entrytype, 'entry-type' );
    $type_uid = 200;
    crunchtype( \%sourcetypehashkey, \%sourcetypehashval, \@sourcetype, 'source-type' );
    $type_uid = 300;
    crunchtype( \%doctypehashkey, \%doctypehashval, \@doctype, 'doc-type' );
    $type_uid = 400;
    crunchtype( \%relationtypehashkey, \%relationtypehashval, \@relationtype, 'relation-type' );
    $type_uid = 500;
    crunchtype( \%entitytypehashkey, \%entitytypehashval, \@entitytype, 'entity-type' );
    $type_uid = 600;
    crunchtype( \%entryclasshashkey, \%entryclasshashval, \@entryclass, 'entry-class' );
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
    writesql( $insert_type, \@type_rows, 'type', '>' )
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

    # set $relationtype_uid to 'language'
    $relationtype_uid = $relationtypehashval{'languagenote'};

    # iterate over all language elements in Eldamo to retrieve documentation
    foreach my $doclang ( $root->children('language') ) {
        harvestlangdocs($doclang);
    }

    writesql_no_encode( $insert_language, \@lang_rows, 'language', '>' )
      if $mode eq "-s";    # table LANGUAGE
     # write sql only after all three type of relation's have been added
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

# add the doc to the docs table, create row for langId, docId, ordering, relation_type
sub parselangdoc {
    my ( $lang_uid, $langdoc, $doctype, $ordering ) = @_;
    my $langtypeuid = ( $entitytypehashval{'language'} // 'NULL' );
    my $docypeuid = ( $entitytypehashval{'doc'} // 'NULL' );
    parsedoc( $langdoc, $doctype );    # <- doc_uid gets set here
    # lang_uid is set globally in calling harvestlangdocs
    push @relation_rows, "($lang_uid, $langtypeuid, $doc_uid, $docypeuid, $ordering, $relationtype_uid)";
}

# === HARVEST CATEGORIES =============================================

sub hashcats {
    print "  => categories ";
    foreach my $cats ( $root->children('cats') ) { harvestcats($cats); }
    sayhashkeytovalue( \%cathashkey, \%cathashval );
    writesql( $insert_cat, \@cat_rows, 'cat', '>' ) if $mode eq "-s"; # table CAT
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
    writesql( $insert_created, \@created_rows, 'created', '>' ) if $mode eq "-s";    # table CREATED
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
    
    # set $relationtype_uid to 'source'
    $relationtype_uid = $relationtypehashval{'sourcenote'};
   
    writesql( $insert_source, \@source_rows, 'source', '>') if $mode eq "-s";    # table SOURCE 
    # write sql only after all three type of relation's have been added
    #writesql( $insert_source_doc, \@srcdoc_rows, 'source_doc.sql', '>' ) if $mode eq "-s";    # table SOURCE_DOC
    undef @source_rows;
    say " done.";
}

sub harvestsources {
    my ($source) = @_;
    $ordering = 1;
    $sourcehashkey{$source_uid} = $source->att('prefix');
    my $sourcename = $source->att('name');
    $sourcename =~ s/\'/\'\'/g;
    push @source_rows,
        "($source_uid, '"
      . $sourcename . "', '"
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
    my $sourcetypeuid = ( $entitytypehashval{'source'} // 'NULL' );
    my $docypeuid = ( $entitytypehashval{'doc'} // 'NULL' );
    parsedoc( $doc, $sourcenotetype );    # always call parsedoc first to set uid
    push @relation_rows, "($source_uid, $sourcetypeuid, $doc_uid, $docypeuid, $ordering, $relationtype_uid)";
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
    writesql( $insert_form, \@form_rows, 'form', '>') if $mode eq "-s";    # table FORM
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
    writesql( $insert_gloss, \@gloss_rows, 'gloss', '>') if $mode eq "-s";    # table GLOSS
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

    # GLOBAL!
    $entry_uid++;

    # push first level to the stack (it was cleared before this method)
    # this: @entry_uid_stack[-1]; parent: $entry_uid_stack[-2]
    push @entry_uid_stack, $entry_uid;

    my $uid        = $entry_uid_stack[-1];
    my $parent_uid = ( $entry_uid_stack[-2] // 'NULL' );

    my ( $element, $order, $type ) = @_;

    my $entry_ruleform_uid;
    my $entry_fromform_uid;
    my $entry_stemform_uid;

    if ( !defined $type ) {
        $type = 'entry';
    }
    
    my $entrytype_uid = ( $entitytypehashval{'entry'} // 'NULL' );
    my $doctype_uid = ( $entitytypehashval{'doc'} // 'NULL' );
    my $typetype_uid = ( $entitytypehashval{'type'} // 'NULL' );
    my $createdtype_uid = ( $entitytypehashval{'created'} // 'NULL' );
  
      # create DOC & register RELATION 
    $relationtype_uid = ( $relationtypehashval{'entrynote'} // 'NULL' );
    if ($element->text ne "" && $type ne "#CDATA"){
        if (defined $latestdoc && substr($element->text, 0, 100) eq $latestdoc){
           #say "already exists";
           #say $latestdoc;
           #say substr($element->text, 0, 100);
           pop @doc_rows; # remove last DOC
           pop @relation_rows; # remove last RELATION
        }
        $latestdoc = substr($element->text, 0, 100); # new latest doc var
        parsedoc( $element, $type );    # call parsedoc first to set uid
        push @relation_rows, "($uid, $entrytype_uid, $doc_uid, $doctype_uid, 1, $relationtype_uid)";
    }

    my $entry_form_uid  = ( $formhashval{ $element->att('v') }      // 'NULL' );
    my $entry_lang_uid  = ( $langhashval{ $element->att('l') }      // 'NULL' );
    my $entry_rlang_uid = ( $langhashval{ $element->att('rl') }     // 'NULL' );
    my $entry_gloss_uid = ( $glosshashval{ $element->att('gloss') } // 'NULL' );
    my $entry_ngloss_uid =
      ( $glosshashval{ $element->att('ngloss') } // 'NULL' );
    my $entry_cat_uid = ( $cathashval{ $element->att('cat') } // 'NULL' );
    my $entry_source_uid =
      defined $element->att('source')
      ? (
        $sourcehashval{
            substr(
                $element->att('source'), 0,
                index( $element->att('source'), '/' )
            )
        } // 'NULL'
      )
      : 'NULL';
    my $entry_source = $element->att('source') // '';

    if ( $type =~ m/(change|deriv)/ ) {
        $entry_ruleform_uid = ( $formhashval{ $element->att('i1') } // 'NULL' );
        $entry_fromform_uid = ( $formhashval{ $element->att('i2') } // 'NULL' );
        $entry_stemform_uid = ( $formhashval{ $element->att('i3') } // 'NULL' );
    }
    elsif ( $type =~ m/(start|rule-example)/ ) {
        $entry_ruleform_uid =
          ( $formhashval{ $element->att('rule') } // 'NULL' );
        $entry_fromform_uid =
          ( $formhashval{ $element->att('from') } // 'NULL' );
        $entry_stemform_uid =
          ( $formhashval{ $element->att('stage') } // 'NULL' );
    }
    else {
        $entry_ruleform_uid =
          ( $formhashval{ $element->att('rule') } // 'NULL' );
        $entry_fromform_uid =
          ( $formhashval{ $element->att('from') } // 'NULL' );
        $entry_stemform_uid =
          ( $formhashval{ $element->att('stem') } // 'NULL' );
    }
    my $entry_orthoform_uid =
      ( $formhashval{ $element->att('orthography') } // 'NULL' );
    my $entry_tengwar      = $element->att('tengwar')     // "";
    my $entry_mark         = $element->att('mark')        // "";
    my $entry_neoversion   = $element->att('neo-version') // "";
    my $entry_eldamopageid = $element->att('page-id')     // "";
    my $entry_orderfield   = $element->att('order')       // "";
    my $entry_class_uid =
      defined $element->att('speech')
      ? entryclass( $element->att('speech') )
      : 'NULL';
    my $entry_type_uid = ( $entrytypehashval{$type} // 'NULL' );

    if ($entry_type_uid eq 'NULL'){
        say $type;
    }

    push @entry_rows,
"($uid, $parent_uid, $entry_form_uid, $entry_lang_uid, $entry_rlang_uid, $entry_gloss_uid, $entry_ngloss_uid, $entry_cat_uid, $entry_source_uid, '$entry_source', $entry_ruleform_uid, $entry_fromform_uid, $entry_stemform_uid, $entry_orthoform_uid, '$entry_tengwar', '$entry_mark', '$entry_neoversion', '$entry_eldamopageid', '$entry_orderfield', $entry_class_uid, $entry_type_uid)";

    
    # ==== speech RELATION ====
    $relationtype_uid = ( $relationtypehashval{'entryspeech'} // 'NULL' );
    $order = 1;
    foreach my $speech ( split( ' ', $element->att('speech') ) ) {
        # say "More speech for $entry_uid !" if ($order > 1);
        my $speech_uid = ( $speechtypehashval{$speech} // 'NULL' );
        push @relation_rows, "($uid, $entrytype_uid, $speech_uid, $typetype_uid, $order, $relationtype_uid)";
        $order++;
    }

    # ==== created RELATION ====
    $relationtype_uid = ( $relationtypehashval{'created'} // 'NULL' );
    $order = 1;
    foreach my $creator ( split( ',', $element->att('created') ) ) {
        $creator =~ s/^\s+//;
        my $created_uid = ( $createdhashval{$creator} // 'NULL' );
        push @relation_rows, "($uid, $entrytype_uid, $created_uid, $createdtype_uid, $order, $relationtype_uid)";
        $order++;
    }
    
    $order = 1;
    if ( defined $element->att('form') ) {
        my $formtype_uid;
        $relationtype_uid = $relationtypehashval{$type eq 'class' ? 'classform' : 'inflectform'};
        foreach my $form ( split( ' ', $element->att('form') ) ) {
            $formtype_uid = ($type eq 'class' ? 
                             $classformtypehashval{$form} : 
                             $inflecttypehashval{$form} // 0 );
            # register RELATION
            push @relation_rows, "($uid, $entrytype_uid, $formtype_uid, $typetype_uid, $order, $relationtype_uid)";
            $order++;
        }
    }
    
    $order = 1;
    if ( defined $element->att('variant') ) {
        my $varianttype_uid;
        $relationtype_uid = $relationtypehashval{$type eq 'class' ? 'classvariant' : 'inflectvariant'};
        foreach my $variant ( split( ' ', $element->att('variant') ) ) {
            $varianttype_uid = ($type eq 'class' ? 
                                $classformvartypehashval{$variant} : 
                                $inflectvartypehashval{$variant} // 0 );
            # register RELATION
            push @relation_rows, "($uid, $entrytype_uid, $varianttype_uid, $typetype_uid, $order, $relationtype_uid)";
            $order++;
        }
    }
    
    $order = 1;
    foreach my $child ( $element->children ) {
        parseword( $child, $order, $child->name ) unless ($child->name =~ m/(DATA|ivatives|table|form)/);
        $order++;
    }
    pop @entry_uid_stack;
}

sub entryclass {
    no warnings 'uninitialized';
    my ($speech) = @_;
    if    ( !defined $speech )     { return $entryclasshashval{'unknown'}; }
    elsif ( $speech =~ /phone/ )   { return $entryclasshashval{'phonetical'}; }
    elsif ( $speech =~ /grammar/ ) { return $entryclasshashval{'grammatical'}; }
    elsif ( $speech =~ /root/ )    { return $entryclasshashval{'root'}; }
    else                           { return $entryclasshashval{'lexical'}; }
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
   my $filecount   = 1;

   if ( $arraysize > $maxrows ) {
      my $iterateur = natatime $maxrows, @$arrayed;
      while ( my @picolino = $iterateur->() ) {
         $rows        = 1;
         open( SQLFILE, $writeappend, $outputdir . $filename . "_" . $filecount . ".sql" )
           or die "$! error trying to create or overwrite $SQLFILE";
         say SQLFILE encode_utf8($insertinto);
         foreach my $arrayrow (@picolino) {
            if ( $rows % 1000 == 0 ) {
               say SQLFILE encode_utf8( $arrayrow . ";" );
               say SQLFILE encode_utf8($insertinto)
                 if ( $arraysize % 1000 != 0 && $rows < $maxrows );
            }
            else {
               if ( $rows == $arraysize ) {
                  say SQLFILE encode_utf8( $arrayrow . ";" );
               }
               else {
                  say SQLFILE encode_utf8( $arrayrow . "," );
               }
            }
            $rows++;
         }
         close SQLFILE;
         $filecount++;
      }
   }
   else {
      open( SQLFILE, $writeappend, $outputdir . $filename . ".sql" )
        or die "$! error trying to create or overwrite $SQLFILE";
      say SQLFILE encode_utf8($insertinto);
      foreach my $arrayrow (@$arrayed) {
         if ( $rows % 1000 == 0 ) {
            say SQLFILE encode_utf8( $arrayrow . ";" );
            say SQLFILE encode_utf8($insertinto)
              if ( $arraysize % 1000 != 0 );
         }
         else {
            if ( $rows == $arraysize ) {
               say SQLFILE encode_utf8( $arrayrow . ";" );
            }
            else {
               say SQLFILE encode_utf8( $arrayrow . "," );
            }
         }
         $rows++;
      }
      close SQLFILE;
   }
}


sub writesql_no_encode {
    my $insertinto  = $_[0];
    my $arrayed     = $_[1];
    my $filename    = $_[2];
    my $writeappend = $_[3];
    my $rows        = 1;
    my $arraysize   = @$arrayed;
    open( SQLFILE, $writeappend, $outputdir . $filename . ".sql" )
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
    writesql( $insert_entry, \@entry_rows, 'entry', '>' );
    print ' entries';
    writesql( $insert_doc, \@doc_rows, 'doc', '>' );
    print ', docs';
    writesql( $insert_relation, \@relation_rows, 'relation', '>' );
    print ' and the rest.';
   
}


sub loadvariables {


    # some hardcoded values, contained in the schema xml, not the data xml
    # === LIST type =================================================

    @parenttype = (
        'entry-type',      'source-type',
        'doc-type',        'relation-type',
        'entity-type',     'entry-class',
        'class-form-type', 'class-form-variant-type',
        'inflect-type',    'inflect-variant-type',
        'speech-type'
    );

    @sourcetype = (
        'adunaic',  'appendix',   'index',  'minor-work',
        'minor',    'neologisms', 'quenya', 'secondary',
        'sindarin', 'telerin',    'work'
    );

    @doctype = (
        'before',       'cite',      'class',     'cognate',
        'deprecations', 'deriv',     'eic',       'element',
        'grammar',      'inflect',   'linked',    'names',
        'neologisms',   'notes',     'phonetics', 'phrases',
        'ref',          'related',   'roots',     'vocabulary',
        'words',        'entrynote', 'entry',     'word'
    );

    
    # used in ENTRY
    @entryclass = ('lexical', 'grammatical', 'phonetical', 'root', 'unknown', 'private_constr_lex', 'common_constr_lex');
    
    # used in ENTRY
    @entrytype = (
        'entry',        'element',     'before',        'order-example', 'class',
        'word-cognate', 'cognate',     'combine',       'deprecated',    'word-deriv',
        'word-element', 'inflect',     'notes',         'related',       'deriv',
        'rule',         'see',         'see-also',      'see-further',
        'see-notes',    'word',        'ref',           'change',
        'ref-cognate',  'correction',  'ref-deriv',     'rule-start',
        'rule-example', 'ref-element', 'example',       'inflect',
        'related-ref'
    );

    # used in RELATION-type
    @relationtype = (
        'before',         'change',        'class',          'classform',
        'classvariant',   'cognate',       'combine',        'correction',   
        'created',        'deprecated',    'deriv',          'element',
        'entry',          'entrynote',     'entryspeech',    'example',
        'inflect',        'inflectform',   'inflectvariant', 'languagenote', 
        'notes',          'order-example', 'ref-cognate',    'ref-deriv',
        'ref-element',    'ref',           'related-ref',    'related',
        'rule-example',   'rule-start',    'rule',           'see-also',
        'see-further',    'see-notes',     'see',            'word-cognate',
        'word-deriv',     'word-element',  'word'                 
    );
    
    # used in RELATION FROM- and TO-type
    @entitytype = ( 'entry', 'created', 'type', 'doc', 'language', 'source' );

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
    $insert_relation =
        'INSERT INTO '
      . $schema
      . 'RELATION (FROM_ID, FROM_TYPE_ID, TO_ID, TO_TYPE_ID, "ORDERING", RELATION_TYPE_ID) VALUES ';
    $insert_entry =
        'INSERT INTO '
      . $schema
      . 'ENTRY (ID, PARENT_ID, FORM_ID, LANGUAGE_ID, RLANGUAGE_ID, GLOSS_ID, NGLOSS_ID, CAT_ID, SOURCE_ID, "SOURCE", RULE_FORM_ID, FROM_FORM_ID, STEM_FORM_ID, ORTHO_FORM_ID, TENGWAR, MARK, NEOVERSION, ELDAMO_PAGEID, ORDERFIELD, ENTRY_CLASS_ID, ENTRY_TYPE_ID) VALUES ';
    $insert_form = 'INSERT INTO ' . $schema . 'FORM (ID, TXT) VALUES ';
    $insert_gloss =
      'INSERT INTO ' . $schema . 'GLOSS (ID, LANGUAGE_ID, TXT) VALUES ';
    $insert_language =
      'INSERT INTO ' . $schema . 'LANGUAGE (ID, NAME, LANG, PARENT_ID) VALUES ';
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
