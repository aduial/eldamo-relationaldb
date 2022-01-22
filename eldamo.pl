use strict;
use warnings;
use Encode;
use XML::Twig;
use Array::Utils qw(:all);
use Acme::Comment type => 'C++';
use feature 'say';
use File::Path qw(make_path);

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

my $entry_uid     = 9999;
my $lang_uid      = 100;
my $parentcat_uid = 1;
my $cat_uid       = 100;
my $source_uid    = 1;
my $ref_uid       = 1;
my $doc_uid       = 0;
my $type_uid      = 1;
my $form_uid      = 1;
my $gloss_uid     = 1;
my $ngloss_uid    = 1;
my $created_uid   = 1;
my $linked_uid    = 1;
my $example_uid   = 1;
my $rule_uid      = 1;
my $grammar_uid   = 1;

my $insert_type;
my $insert_grammar;
my $insert_language;
my $insert_language_doc;
my $insert_cat;
my $insert_created;
my $insert_source;
my $insert_source_doc;
my $insert_form;
my $insert_gloss;
my $insert_ngloss;
my $insert_entry;
my $insert_rule;
my $insert_ref;
my $insert_entry_doc;
my $insert_doc;
my $insert_entry_grammar;
my $insert_linked_grammar;
my $insert_reflinked;
my $insert_linked;
my $insert_linked_doc;
my $insert_linkedexample;
my $insert_refexample;
my $insert_linked_form;
my $insert_rulesequence;

my @lang_rows          = ();
my @cat_rows           = ();
my @source_rows        = ();
my @doc_rows           = ();
my @form_rows          = ();
my @gloss_rows         = ();
my @ngloss_rows        = ();
my @created_rows       = ();
my @type_rows          = ();
my @srcdoc_rows        = ();
my @entrydoc_rows      = ();
my @langdoc_rows       = ();
my @linkeddoc_rows     = ();
my @entry_rows         = ();
my @reflinked_rows     = ();
my @linked_rows        = ();
my @ref_rows           = ();
my @rule_rows          = ();
my @grammar_rows       = ();
my @entrygrammar_rows  = ();
my @linkedgrammar_rows = ();
my @linkedform_rows    = ();
my @rulesequence_rows  = ();
my @refexample_rows    = ();
my @linkedexample_rows = ();

my @raw_forms        = ();
my @raw_glosses      = ();
my @raw_nglosses     = ();
my @raw_created      = ();
#my @raw_sourcetypes  = ();
my @raw_grammarforms = ();

my @otherlangs;
my %langshashbykey;
my %entrieshashbykey;
my %catshashbykey;
my %sourceshashbykey;
my %createdhashbykey;
my %typeshashbykey;
my %grammarshashbykey;
my %formshashbykey;
my %glosseshashbykey;
my %nglosseshashbykey;

my %langshashbyvalue;
my %entrieshashbyvalue;
my %catshashbyvalue;
my %sourceshashbyvalue;
my %createdhashbyvalue;
my %typeshashbyvalue;
my %grammarshashbyvalue;
my %formshashbyvalue;
my %glosseshashbyvalue;
my %nglosseshashbyvalue;

my $counter = 0;

# hardcoded values, defined below
my %languages;
my @parenttypes;
my @sourcestypes;
my @doctypes;
my @linkedtypes;
my @exampletypes;
my @eictypes;
my @reftypes;
my @doclinktypes;
my @classformtypes;
my @classformvarianttypes;
my @inflecttypes;
my @inflectvarianttypes;
my @speechtypes;


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

loadvariables(); # load hardcoded variables (types, languages)
harvest();       # create ID references
mainloop();      # the rest

# === HARVESTING =============================================

sub harvest {
    say
"   Start harvesting for lookup elements and writing them to SQL files ...";

# !! REQUIRES <language-cat ... in XML to be changed into <language ... & </language>
    hashtypes();   # % = TYPES
    # Grammar is merged with Type
    # hashgrammar(); # % = GRAMMAR (speech, inflect, class ...)
    hashlangs();   # % = mnemonic => UID  / does also language_doc & doc (partly)
    hashcats();    # % = id => UID
    hashcreated(); # % = txt => UID
    hashsources(); # % = prefix => UID / does also source_doc & doc (partly)
    hashforms();   # % = form-txt => UID
    hashglosses(); # % = txt => UID
    hashnglosses();    # % = txt => UID
    say "   Harvesting stage done.";
}

sub mainloop {
    print "  Start parsing Entry (Ref, Rule, ...) elements ";
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

# === TYPE =============================================

sub hashtypes {
    print "  => types ...";
    no warnings 'syntax';

    crunchtypes( \@parenttypes, undef );
    sayhashkeytovalue( \%typeshashbykey, \%typeshashbyvalue );

    $type_uid = 100;
    crunchtypes( \@sourcestypes, 'source-type' );
    $type_uid = 200;
    crunchtypes( \@doctypes, 'doc-type' );
    $type_uid = 300;
    crunchtypes( \@linkedtypes, 'linked-type' );
    $type_uid = 400;
    crunchtypes( \@eictypes, 'eic-type' );
    $type_uid = 500;
    crunchtypes( \@exampletypes, 'example-type' );
    $type_uid = 600;
    crunchtypes( \@reftypes, 'ref-type' );
    $type_uid = 700;
    crunchtypes( \@doclinktypes, 'doclink-type' );
    $type_uid = 1000;
    crunchtypes( \@classformtypes, 'class-form-type' );
    $type_uid = 1100;
    crunchtypes( \@classformvarianttypes, 'class-form-variant-type' );
    $type_uid = 1200;
    crunchtypes( \@inflecttypes, 'inflect-type' );
    $type_uid = 2000;
    crunchtypes( \@inflectvarianttypes, 'inflect-variant-type' );
    $type_uid = 2200;
    crunchtypes( \@speechtypes, 'speech-type' );

# undef typeshashbyvalue; it was used to look up parent id's. 
# Then flip it into typeshashbykey for futher usage below
    undef %typeshashbyvalue;
    sayhashkeytovalue( \%typeshashbykey, \%typeshashbyvalue );
    writesql( $insert_type, \@type_rows, 'type.sql', '>' ) if $mode eq "-s";    # table TYPE
    undef %typeshashbykey;
    undef @type_rows;
    say " done.";
}

sub crunchtypes {
    my ( $typearray, $parentname ) = @_;
    my $parent_uid =
      defined $parentname ? $typeshashbyvalue{$parentname} : "NULL";
    foreach my $typestring (@$typearray) {
        $typeshashbykey{$type_uid} = $typestring;
        push @type_rows, "($type_uid, '$typestring', $parent_uid)";
        $type_uid++;
    }
}

/*
# === GRAMMAR ==============================================
# just keeping this as an example for now

sub inflectsandelements {
    my ($element) = @_;
    foreach my $inflect ( $element->children('inflect') ) {
        subinflects($inflect);
    }
    foreach my $element ( $element->children('element') ) {
        subinflects($element);
    }
}

sub subinflects {
    my ($subelement) = @_;
    blobl( \@raw_grammarforms, $subelement->att('form') )
      if defined $subelement->att('form');
    blobl( \@raw_grammarforms, $subelement->att('variant') )
      if defined $subelement->att('variant');
}

sub blobl {
    my ( $bogloe, $kabloobl ) = @_;
    foreach my $globl ( split( ' ', $kabloobl ) ) { push @$bogloe, $globl; }
}
*/

# === LANGUAGE =================================================
# harvesting removed, using hardcoded language from eldamo schema

sub hashlangs {
    print "  => languages ";

    foreach my $language ( sort { $a <=> $b } keys %languages ) {
        print '.' if ( $counter % 6 == 0 );
        push @lang_rows, "($language, '$languages{$language}{name}', '$languages{$language}{lang}', $languages{$language}{parent})";

        say encode_utf8(
            "loaded $languages{$language}{lang} - $languages{$language}{name}")
          if $mode eq "-h";

        $langshashbykey{$language} = '$languages{$language}{lang}';
        $counter++;
    }

    # flip hash to by value
    sayhashkeytovalue( \%langshashbykey, \%langshashbyvalue );

    # iterate over all language elements in Eldamo to retrieve documentation
    foreach my $doclang ( $root->children('language') ) {
        harvestlangdocs($doclang);
    }

    writesql_no_encode( $insert_language, \@lang_rows, 'language.sql', '>>' )
      if $mode eq "-s";    # table LANGUAGE
    writesql( $insert_language_doc, \@langdoc_rows, 'language_doc.sql', '>' )
      if $mode eq "-s";    # table LANGUAGE_DOC
                           #undef %langshashbykey;
    undef @lang_rows;
    say " done.";
}

# find documentation of all doctypes under the given language 
sub harvestlangdocs {
    my ( $doclang ) = @_;
    $lang_uid = $langshashbyvalue($doclang->att('id')) if (defined $lang->att('id'));
    # for every doctype in the hardcoded doctype list: 
    foreach my $doctype (@docstypes) {
        crunchlangdocs( $doclang, $doctype );
    }                     
    foreach my $subdoclang ( $doclang->children('language') ) {
        harvestlangdocs( $subdoclang );
    }
} 

sub crunchlangdocs {
    my ( $doclang, $doctype ) = @_;
    my $ordering = 1;
    # for every doc of type $doctype found under $doclang
    foreach my $langdoc ( $doclang->children($doctype) ) {
        parselangdoc( $langdoc, $doctype, $ordering );
        $ordering++;
    }
}

# add the doc to the docs table, create row for langId, docId, ordering
sub parselangdoc {
    my ( $langdoc, $doctype, $ordering ) = @_;
    parsedoc( $langdoc, $doctype );    # <- doc_uid gets set here
    # lang_uid is set globally in calling harvestlangdocs
    push @langdoc_rows, "($lang_uid, $doc_uid, $ordering)";
}

# === CATEGORY ===============================================

sub hashcats {
    print "  => categories ";
    foreach my $cats ( $root->children('cats') ) { harvestcats($cats); }
    sayhashkeytovalue( \%catshashbykey, \%catshashbyvalue );
    writesql( $insert_cat, \@cat_rows, 'cat.sql', '>' ) if $mode eq "-s"; # table CAT
    undef %catshashbykey;
    undef @cat_rows;
    say " done.";
}

sub harvestcats {
    my ($cats) = @_;
    my $label = '';
    foreach my $parentcat ( $cats->children('cat-group') ) {
        $catshashbykey{$parentcat_uid} = $parentcat->att('id');
        $label = $parentcat->att('label');
        $label =~ s/\'/''/g;
        push @cat_rows, "($parentcat_uid, '$label', NULL)";
        foreach my $cat ( $parentcat->children('cat') ) {
            $catshashbykey{$cat_uid} = $cat->att('id');
            $label = $cat->att('label');
            $label =~ s/\'/''/g;
            push @cat_rows, "($cat_uid, '$label', $parentcat_uid)";
            print '.' if ( $cat_uid % 30 == 0 );
            $cat_uid++;
        }
        $parentcat_uid++;
    }
}

# === CREATED ===============================================

sub hashcreated {
    print "  => created (by) ...";
    foreach my $word ( $root->children('word') ) { harvestcreated($word); }
    foreach my $created ( sort( unique(@raw_created) ) ) {
        if ( $created ne '' ) {
            $createdhashbykey{$created_uid} = $created;
            push @created_rows, "($created_uid, '$created')";
            print '.' if ( $created_uid % 30 == 0 );
            $created_uid++;
        }
    }
    undef @raw_created;
    sayhashkeytovalue( \%createdhashbykey, \%createdhashbyvalue );
    undef %createdhashbykey;
    writesql( $insert_created, \@created_rows, 'created.sql', '>' ) if $mode eq "-s";    # table CREATED
    undef @created_rows;
    say " done.";
}

sub harvestcreated {
    my ($entry) = @_;
    push @raw_created, $entry->att('created')
      if ( defined $entry->att('created') );
    foreach my $subentry ( $entry->children('word') ) {
        harvestcreated($subentry);
    }
}

# === SOURCE ===============================================

sub hashsources {
    print "  => sources ";
    foreach my $source ( $root->children('source') ) {
        harvestsources($source);
    }
    sayhashkeytovalue( \%sourceshashbykey, \%sourceshashbyvalue );
    undef %sourceshashbykey;
    writesql( $insert_source, \@source_rows, 'source.sql', '>') if $mode eq "-s";    # table SOURCE
    writesql( $insert_source_doc, \@srcdoc_rows, 'source_doc.sql', '>' ) if $mode eq "-s";    # table SOURCE_DOC
    undef @source_rows;
    undef @srcdoc_rows;
    say " done.";
}

sub harvestsources {
    my ($source) = @_;
    my $ordering = 1;
    $sourceshashbykey{$source_uid} = $source->att('prefix');
    push @source_rows,
        "($source_uid, '"
      . $source->att('name') . "', '"
      . $source->att('prefix') . "', "
      . (
        defined $source->att('type')
        ? $typeshashbyvalue{ $source->att('type') }
        : "NULL"
      ) . ")";
    foreach my $note ( $source->children('notes') ) {
        parsesourcedoc( $note, 'notes', $ordering );
        $ordering++;
    }
    $ordering = 1;
    foreach my $cite ( $source->children('cite') ) {
        parsesourcedoc( $cite, 'cite', $ordering );
        $ordering++;
    }
    $ordering = 1;
    print '.' if ( $source_uid % 30 == 0 );
    $source_uid++;
}

#source_uid, doc_uid in global context
sub parsesourcedoc {
    no warnings 'uninitialized';
    my ( $doc, $sourcedoctype, $ordering ) = @_; # sourcedoctype = notes or cite
    parsedoc( $doc, $sourcedoctype );    # always call parsedoc first to set uid
    push @srcdoc_rows, "($source_uid, $doc_uid, $ordering)";
}

# === FORM =============================================

sub hashforms {
    print "  => forms ";
    foreach my $word ( $root->children('word') ) { harvestforms($word); }
    foreach my $form ( sort ( unique(@raw_forms) ) ) {
        if ( $form ne '' ) {
            push @form_rows, "($form_uid, '$form')";
            $formshashbykey{$form_uid} = $form;
            print '.' if ( $form_uid % 5000 == 0 );
            $form_uid++;
        }
    }
    undef @raw_forms;
    sayhashkeytovalue( \%formshashbykey, \%formshashbyvalue );
    undef %formshashbykey;
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

    foreach my $before ( $entry->children('before') ) {
        pushform( $before->att('v') );
        foreach my $order ( $before->children('order-example') ) {
            pushform( $order->att('v') );
        }
    }
    procdinges($entry);
    procrule($entry);
    foreach my $see ( $entry->children('see') ) { pushform( $see->att('v') ); }
    foreach my $seefurther ( $entry->children('see-further') ) {
        pushform( $seefurther->att('v') );
    }
    foreach my $seenotes ( $entry->children('see-notes') ) {
        pushform( $seenotes->att('v') );
    }
    foreach my $ref ( $entry->children('ref') ) {
        pushform( $ref->att('v') );
        pushform( $ref->att('from') );
        pushform( $ref->att('rl') );
        pushform( $ref->att('rule') );
        foreach my $change ( $ref->children('change') ) {
            pushform( $change->att('v') );
            pushform( $change->att('i1') );
        }
        procdinges($ref);
        foreach my $correction ( $ref->children('correction') ) {
            pushform( $correction->att('v') );
        }
    }
    foreach my $wordchild ( $entry->children('word') ) {
        harvestforms($wordchild);
    }
}

sub procrule {
    my ($ruleparent) = @_;
    foreach my $rule ( $ruleparent->children('rule') ) {
        pushform( $rule->att('from') );
        pushform( $rule->att('rule') );

        #pushform($rule->att('to'));
    }
}

sub procdinges {
    my ($dingesparent) = @_;
    foreach my $cognate ( $dingesparent->children('cognate') ) {
        pushform( $cognate->att('v') );
    }
    foreach my $deriv ( $dingesparent->children('deriv') ) {
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
    foreach my $example ( $dingesparent->children('example') ) {
        pushform( $example->att('v') );
    }
    foreach my $element ( $dingesparent->children('element') ) {
        pushform( $element->att('v') );
    }
    foreach my $inflect ( $dingesparent->children('inflect') ) {
        pushform( $inflect->att('v') );
    }
    foreach my $related ( $dingesparent->children('related') ) {
        pushform( $related->att('v') );
    }
}

sub pushform {
    my ($formval) = @_;
    push @raw_forms, $formval if ( defined $formval );
}

# === GLOSS ============================================

sub hashglosses {
    print "  => glosses ...";
    foreach my $word ( $root->children('word') ) { harvestglosses($word); }
    foreach my $gloss ( sort( unique(@raw_glosses) ) ) {
        if ( $gloss ne '' ) {
            $glosseshashbykey{$gloss_uid} = $gloss;
            push @gloss_rows, "($gloss_uid, 1010, '$gloss')";
            print '.' if ( $gloss_uid % 2000 == 0 );
            $gloss_uid++;
        }
    }
    undef @raw_glosses;
    sayhashkeytovalue( \%glosseshashbykey, \%glosseshashbyvalue );
    undef %glosseshashbykey;
    writesql( $insert_gloss, \@gloss_rows, 'gloss.sql', '>') if $mode eq "-s";    # table GLOSS
    undef @gloss_rows;
    say " done.";
}

sub harvestglosses {
    my ($entry) = @_;
    push @raw_glosses, $entry->att('gloss') if ( defined $entry->att('gloss') );
    foreach my $ref ( $entry->children('ref') ) {
        push @raw_glosses, $ref->att('gloss') if ( defined $ref->att('gloss') );
    }
    foreach my $subentry ( $entry->children('word') ) {
        harvestglosses($subentry);
    }
}

# === NGLOSS ============================================

sub hashnglosses {
    print "  => nglosses ...";
    foreach my $word ( $root->children('word') ) { harvestnglosses($word); }
    foreach my $ngloss ( sort( unique(@raw_nglosses) ) ) {
        if ( $ngloss ne '' ) {
            $nglosseshashbykey{$ngloss_uid} = $ngloss;
            push @ngloss_rows, "($ngloss_uid, 1010, '$ngloss')";
            print '.' if ( $ngloss_uid % 50 == 0 );
            $ngloss_uid++;
        }
    }
    undef @raw_nglosses;
    sayhashkeytovalue( \%nglosseshashbykey, \%nglosseshashbyvalue );
    undef %nglosseshashbykey;
    writesql( $insert_ngloss, \@ngloss_rows, 'ngloss.sql', '>') if $mode eq "-s";    # table NGLOSS
    undef @ngloss_rows;
    say " done.";
}

sub harvestnglosses {
    my ($entry) = @_;
    push @raw_nglosses, $entry->att('ngloss')
      if ( defined $entry->att('ngloss') );
    foreach my $ref ( $entry->children('ref') ) {
        push @raw_nglosses, $ref->att('ngloss')
          if ( defined $ref->att('ngloss') );
    }
    foreach my $subentry ( $entry->children('word') ) {
        harvestnglosses($subentry);
    }
}

# === END HARVESTING =============================================

# === PARSING =============================================

# === ENTRY =================================================

sub parseword {
    no warnings 'uninitialized';
    my ( $entry, $parent_uid, $childorder ) = @_;
    $entry_uid++;
    my $ordering       = 1;
    my $entry_form_uid = ( $formshashbyvalue{ $entry->att('v') } // 'X' );
    my $entry_lang_uid = ( $langshashbyvalue{ $entry->att('l') } // 'X' );
    my $entry_gloss_uid =
      ( $glosseshashbyvalue{ $entry->att('gloss') } // 'NULL' );
    my $entry_ngloss_uid =
      ( $nglosseshashbyvalue{ $entry->att('ngloss') } // 'NULL' );
    my $entry_cat_uid = ( $catshashbyvalue{ $entry->att('cat') } // 'NULL' );
    my $entry_created_uid =
      ( $createdhashbyvalue{ $entry->att('created') } // 'NULL' );
    my $entry_ruleform_uid =
      ( $formshashbyvalue{ $entry->att('rule') } // 'NULL' );
    my $entry_stemform_uid =
      ( $formshashbyvalue{ $entry->att('stem') } // 'NULL' );
    my $entry_fromform_uid =
      ( $formshashbyvalue{ $entry->att('from') } // 'NULL' );
    my $entry_orthoform_uid =
      ( $formshashbyvalue{ $entry->att('orthography') } // 'NULL' );
    my $entry_tengwar      = $entry->att('tengwar')     // "";
    my $entry_mark         = $entry->att('mark')        // "";
    my $entry_neoversion   = $entry->att('neo-version') // "";
    my $entry_orderfield   = $entry->att('order')       // "";
    my $entry_eldamopageid = $entry->att('page-id')     // "";
    my $entrytype_uid = entrytype( $entry->att('speech') // 'unknown' );
    $parent_uid = $parent_uid // 'NULL';
    push @entry_rows,
"($entry_uid, $entry_form_uid, $entry_lang_uid, $entry_gloss_uid, $entry_ngloss_uid, $entry_cat_uid, $entry_created_uid, $entry_ruleform_uid, $entry_fromform_uid, $entry_stemform_uid, '$entry_tengwar', '$entry_mark', '$entry_neoversion', '$entry_eldamopageid', '$entry_orderfield', $entry_orthoform_uid, $parent_uid, $ordering, $entrytype_uid)";

    $ordering = 1;
    foreach my $speeches ( $entry->att('speech') ) {
        foreach my $speech ( split( ' ', $speeches ) ) {
            push @entrygrammar_rows,
                "($entry_uid, "
              . ( $grammarshashbyvalue{$speech} // 'X' )
              . ", $ordering, "
              . ( $typeshashbyvalue{'speechform'} // 'X' ) . ")";
            $ordering++;
        }
    }
    $ordering = 1;
    foreach my $before ( $entry->children('before') ) {
        parselinked( $before, $ordering, 0, 'before' )
          ;    # entry_uid + to_v + to_l (= after_entry_id)
        $ordering++;
    }
    $ordering = 1;
    foreach my $class ( $entry->children('class') ) {
        parselinked( $class, $ordering, 0, 'class' )
          ;    # entry_uid + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $cognate ( $entry->children('cognate') ) {
        parselinked( $cognate, $ordering, 0, 'cognate' )
          ; # entry_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
        $ordering++;
    }
    $ordering = 1;
    foreach my $deriv ( $entry->children('deriv') ) {
        parselinked( $deriv, $ordering, 0, 'deriv' )
          ;    # this entry_uid + deriv_v + deriv_l (= deriv_entry_id) + mark
        $ordering++;    # + additional multiple FORM_ID + ordering
    }
    $ordering = 1;
    foreach my $element ( $entry->children('element') ) {
        parselinked( $element, $ordering, 0, 'element' )
          ; # entry_uid + element_v + parent_l + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $inflect ( $entry->children('inflect') ) {
        parselinked( $inflect, $ordering, 0, 'inflect' )
          ;    # entry_uid + v + form + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $related ( $entry->children('related') ) {
        parselinked( $related, $ordering, 0, 'related' )
          ; # entry_uid + entry_uid + related_v + related_l (= related_entry_id) + mark
        $ordering++;
    }
    $ordering = 1;
    foreach my $rule ( $entry->children('rule') ) {
        parserule( $rule, $ordering );
        $ordering++;
    }
    $ordering = 1;
    foreach my $see ( $entry->children('see') ) {
        parselinked( $see, $ordering, 0, 'see' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    $ordering = 1;
    foreach my $seefurther ( $entry->children('see-further') ) {
        parselinked( $seefurther, $ordering, 0, 'see-further' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    $ordering = 1;
    foreach my $seenotes ( $entry->children('see-notes') ) {
        parselinked( $seenotes, $ordering, 0, 'see-notes' )
          ;    # entry_uid + see_v + see_l + TYPE
        $ordering++;
    }
    $ordering = 1;
    foreach my $ref ( $entry->children('ref') ) {
        parseref( $ref, $entry_lang_uid, $entrytype_uid, $ordering );
        $ordering++;
    }
    $ordering = 1;
    foreach my $note ( $entry->children('notes') ) {
        parseentrydoc( $note, $ordering );
        $ordering++;
    }
    $ordering = 1;
    foreach my $child ( $entry->children('word') ) {
        parseword( $child, $entry_uid, $ordering );
        $ordering++;
    }
    $ordering = 1;
}

# === RULE =================================================

# context entry_uid
sub parserule {
    my ( $rule, $ruleorder ) = @_;
    my $rule_from_form_uid =
      ( $formshashbyvalue{ $rule->att('from') } // 'NULL' );
    my $rule_rule_form_uid =
      ( $formshashbyvalue{ $rule->att('rule') } // 'NULL' );
    my $rule_lang_uid = ( $langshashbyvalue{ $rule->att('l') } // 'NULL' );
    push @rule_rows,
"($rule_uid, $entry_uid, $rule_from_form_uid, $rule_rule_form_uid, $rule_lang_uid, $ruleorder)";
    $rule_uid++;
}

# === REF =================================================
# context entry_uid
sub parseref {
    my ( $ref, $entrylang_uid, $entrytype_uid, $refordering ) = @_;
    no warnings 'uninitialized';

    # $refordering is in entry context
    my $ordering      = 1;
    my $ref_form_uid  = ( $formshashbyvalue{ $ref->att('v') } // 'X' );
    my $ref_lang_uid  = ( $langshashbyvalue{ $ref->att('l') } // 'NULL' );
    my $ref_gloss_uid = ( $glosseshashbyvalue{ $ref->att('gloss') } // 'NULL' );
    my $ref_rulefrom_form_uid =
      ( $formshashbyvalue{ $ref->att('from') } // 'NULL' );
    my $ref_rlrule_form_uid =
      ( $formshashbyvalue{ $ref->att('rule') } // 'NULL' );
    my $ref_rulerule_form_uid =
      ( $formshashbyvalue{ $ref->att('rl') } // 'NULL' );
    my $ref_mark = $ref->att('mark') // "";
    my $ref_source_uid = (
        $sourceshashbyvalue{
            substr( $ref->att('source'), 0, index( $ref->att('source'), '/' ) )
        } // 'NULL'
    );
    my $ref_source = $ref->att('source') // "";

#say encode_utf8("ref: $ref_uid v=$ref_form_uid l=$ref_lang_uid gloss=$ref_gloss_uid from=$ref_rulefrom_form_uid rule=$ref_rulerule_form_uid rl=$ref_rlrule_form_uid mark=$ref_mark source=$ref_source_uid");

    push @ref_rows,
"($ref_uid, $entry_uid, $ref_form_uid, $ref_gloss_uid, $ref_lang_uid, $ref_source_uid, '$ref_mark', $ref_rulefrom_form_uid, $ref_rlrule_form_uid, $ref_rulerule_form_uid, $ordering, $entrytype_uid, '$ref_source')";

    foreach my $change ( $ref->children('change') ) {
        parselinked( $change, $ordering, 1, 'change' )
          ;    # ref_uid + i1 + source + change_v
        $ordering++;
    }
    $ordering = 1;
    foreach my $cognate ( $ref->children('cognate') ) {
        parselinked( $cognate, $ordering, 1, 'cognate' )
          ; # ref_uid + cognate_v + cognate_l (= cognate_entry_id) + source + mark
        $ordering++;
    }
    $ordering = 1;
    foreach my $correction ( $ref->children('correction') ) {
        parselinked( $correction, $ordering, 1, 'correction' )
          ;    # ref_uid + source + correction_v
        $ordering++;
    }
    $ordering = 1;
    foreach my $deriv ( $ref->children('deriv') ) {
        parselinked( $deriv, $ordering, 1, 'deriv' )
          ;    # ref_uid + v + uses l= of containing WORD (?) + mark + source
        $ordering++;
    }    # additional multiple FORM_ID + ordering
    $ordering = 1;
    foreach my $element ( $ref->children('element') ) {
        parselinked( $element, $ordering, 1, 'element' )
          ; # this ref_uid + v + parent_l + parent_l + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $example ( $ref->children('example') ) {
        parseexample( $example, $ordering, 1 );
        $ordering++;
    }
    $ordering = 1;
    foreach my $inflect ( $ref->children('inflect') ) {
        parselinked( $inflect, $ordering, 1, 'inflect' )
          ;    # ref_uid + source + form + Grammatical type (2x) + ordering
        $ordering++;
    }
    $ordering = 1;
    foreach my $related ( $ref->children('related') ) {
        parselinked( $related, $ordering, 1, 'related' )
          ;    # ref_uid + v + source + mark
        $ordering++;
    }
    $ref_uid++;
}

# === ENTRY_DOC =================================================

#entry_uid, doc_uid in global context
sub parseentrydoc {
    no warnings 'uninitialized';
    my ( $note, $ordering ) = @_;

    # type note,
    parsedoc( $note, 'notes' );    #first call this to set doc_uid
    push @entrydoc_rows, "($entry_uid, $doc_uid, $ordering)";
}

# === DOC =================================================

sub parsedoc {
    $doc_uid++;
    my ( $doc, $doctype ) = @_;
    my $text = $doc->text;
    $text =~ s/\R//g;
    $text =~ s/\'/''/g;
    push @doc_rows,
      "($doc_uid, '$text', " . ( $typeshashbyvalue{$doctype} // 'X' ) . ")";
}

# === LINKED =================================================

# entry_uid & ref_uid in global context; linkedtype -> TYPE
sub parselinked {
    no warnings 'uninitialized';
    my ( $linked, $linkedordering, $isref, $linkedtype ) = @_;

    #take ref_uid ONLY if $isref = 1;
    my $form_grammartype_id =
        $linkedtype eq 'class'
      ? $typeshashbyvalue{'classform'}
      : $typeshashbyvalue{'inflectform'};
    my $variant_grammartype_id =
        $linkedtype eq 'class'
      ? $typeshashbyvalue{'classvariant'}
      : $typeshashbyvalue{'inflectvariant'};
    my $lg_ordering = 1;
    if ( defined $linked->att('form') ) {
        foreach my $form ( split( ' ', $linked->att('form') ) ) {
            push @linkedgrammar_rows,
                "($linked_uid, "
              . ( $grammarshashbyvalue{$form} // 'X' )
              . ", $lg_ordering, $form_grammartype_id)";
            $lg_ordering++;
        }
    }
    $lg_ordering = 1;
    if ( defined $linked->att('variant') ) {
        foreach my $variant ( split( ' ', $linked->att('variant') ) ) {
            push @linkedgrammar_rows,
                "($linked_uid, "
              . ( $grammarshashbyvalue{$variant} // 'X' )
              . ", $lg_ordering, $variant_grammartype_id)";
            $lg_ordering++;
        }
    }
    my $linked_to_lang_uid =
      defined $linked->att('l')
      ? ( $langshashbyvalue{ $linked->att('l') } // 'X' )
      : 'NULL';
    my $linked_mark = $linked->att('mark') // "";
    my $linked_source_uid =
      defined $linked->att('source')
      ? (
        $sourceshashbyvalue{
            substr(
                $linked->att('source'), 0,
                index( $linked->att('source'), '/' )
            )
        } // 'X'
      )
      : 'NULL';
    my $linked_source = $linked->att('source') // "";
    my $ordex_ordering = 1;
    
    foreach my $orderexample ( $linked->children('order-example') ) {
        parseexample( $orderexample, $ordex_ordering, 2 );
        $ordex_ordering++;
    }

    parselinkedform( $linked->att('v'),  1 ) if ( defined $linked->att('v') );
    parselinkedform( $linked->att('i1'), 2 ) if ( defined $linked->att('i1') );
    parselinkedform( $linked->att('i2'), 3 ) if ( defined $linked->att('i2') );
    parselinkedform( $linked->att('i3'), 4 ) if ( defined $linked->att('i3') );
    foreach my $ruleseq ( $linked->children('rule-start') )
    {    # rule-example see parseruleseq()
        parseruleseq($linked);
    }
    if ( $isref == 1 ) {
        push @reflinked_rows,
            "($linked_uid, "
          . ( $typeshashbyvalue{$linkedtype} // 'X' )
          . ", $entry_uid, $ref_uid, $linked_to_lang_uid, $linkedordering, $linked_source_uid, '$linked_mark', '$linked_source')";
    }
    else {
        push @linked_rows,
            "($linked_uid, "
          . ( $typeshashbyvalue{$linkedtype} // 'X' )
          . ", $entry_uid, $linked_to_lang_uid, $linkedordering, $linked_source_uid, '$linked_mark', '$linked_source')";
    }

# there's until now always only 1 [[CDATA for any linked, so hard-coding ordering to 1 for now
    if ( $linked->text ne "" ) {
        my $ordering = 1;
        parsedoc( $linked, 'linked' );   # always call parsedoc first to set uid
        push @linkeddoc_rows, "($linked_uid, $doc_uid, $ordering)";
    }

    $linked_uid++;
}

# === EXAMPLE =================================================

#context linked_uid
sub parseexample {
    my ( $example, $ordering, $type ) = @_;

    #type = 1 links to ref, 2 to linked
    no warnings 'uninitialized';
    my $example_form_uid =
      defined $example->att('v')
      ? ( $formshashbyvalue{ $example->att('v') } // $example->att('v') )
      : 0;
    my $example_source_uid =
      defined $example->att('source')
      ? (
        $sourceshashbyvalue{
            substr(
                $example->att('source'), 0,
                index( $example->att('source'), '/' )
            )
        } // 'X'
      )
      : 0;
    my $example_source = $example->att('source') // "";

    if ( $type == 2 ) {
        push @linkedexample_rows,
            "($linked_uid, $example_source_uid, $example_form_uid, $ordering, "
          . ( $typeshashbyvalue{'orderexample'} // 'X' )
          . ", '$example_source')";
    }
    else {
        push @refexample_rows,
          "($ref_uid, $example_source_uid, $example_form_uid, $ordering, "
          . (
            (
                $typeshashbyvalue{ $example->att('t') . 'example' }
                  // $typeshashbyvalue{'refexample'}
            ) // 'X'
          ) . ", '$example_source')";
    }
    $example_uid++;
}

# === LINKED_FORM =================================================

#linked_uid in global context
sub parselinkedform {
    my ( $linkedform, $ordering ) = @_;
    push @linkedform_rows,
        "($linked_uid, "
      . ( $formshashbyvalue{$linkedform} // 'X' )
      . ", $ordering)";
}

# === RULE_SEQUENCE =================================================

sub parseruleseq {
    my ($linked) = @_;
    my $rsordering = 1;
    foreach my $startrow ( $linked->children('rule-start') ) {
        parseruleseqrow( $startrow, $rsordering );
        $rsordering++;
    }
    foreach my $rulerow ( $linked->children('rule-example') ) {
        parseruleseqrow( $rulerow, $rsordering );
        $rsordering++;
    }
}

#linked_uid; ordering in global context
sub parseruleseqrow {
    my ( $rulerow, $ordering ) = @_;
    my $ruleseq_fromform_uid =
      defined $rulerow->att('from')
      ? ( $formshashbyvalue{ $rulerow->att('from') } // 'X' )
      : 'NULL';
    my $ruleseq_ruleform_uid =
      defined $rulerow->att('rule')
      ? ( $formshashbyvalue{ $rulerow->att('rule') } // 'X' )
      : 'NULL';
    my $ruleseq_stageform_uid =
      defined $rulerow->att('stage')
      ? ( $formshashbyvalue{ $rulerow->att('stage') } // 'X' )
      : 'NULL';
    my $ruleseq_lang_uid =
      defined $rulerow->att('l')
      ? ( $langshashbyvalue{ $rulerow->att('l') } // 'X' )
      : 'NULL';
    push @rulesequence_rows,
"($linked_uid, $ruleseq_fromform_uid, $ruleseq_lang_uid, $ruleseq_ruleform_uid, $ruleseq_stageform_uid, $ordering)";
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

/*
sub hashkeytovalue {
    my $hashedbykey   = $_[0];
    my $hashedbyvalue = $_[1];
    while ( ( $key, $value ) = each %$hashedbykey ) {
        $$hashedbyvalue{$value} = $key;
    }
}
*/

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
    writesql( $insert_entry_grammar, \@entrygrammar_rows, 'linked_grammar.sql', '>' );
    writesql( $insert_linked_grammar, \@linkedgrammar_rows, 'linked_grammar.sql', '>>' );
    writesql( $insert_rule, \@rule_rows, 'rule.sql', '>' );
    writesql( $insert_ref, \@ref_rows, 'ref.sql', '>' );
    writesql( $insert_entry_doc, \@entrydoc_rows, 'entry_doc.sql', '>' );
    writesql( $insert_doc, \@doc_rows, 'doc.sql', '>' );
    writesql( $insert_linked, \@linked_rows, 'linked.sql', '>' );
    writesql( $insert_reflinked, \@reflinked_rows, 'linked.sql', '>>' );
    # TODO see comment above about changes in the schema re. BEFORE examples and RULES
    writesql( $insert_linkedexample, \@linkedexample_rows, 'linkedexample.sql', '>' );
    writesql( $insert_refexample, \@refexample_rows, 'refexample.sql', '>>' );
    writesql( $insert_linked_form, \@linkedform_rows, 'linked_form.sql', '>' );
    writesql( $insert_rulesequence, \@rulesequence_rows, 'rulesequence.sql', '>' );
    writesql( $insert_linked_doc, \@linkeddoc_rows, 'linked_doc.sql', '>' );
}

sub entrytype {
    my ($speech) = @_;
    if    ( $speech =~ /phone/ )   { return $typeshashbyvalue{'phonetical'}; }
    elsif ( $speech =~ /grammar/ ) { return $typeshashbyvalue{'grammatical'}; }
    elsif ( $speech =~ /root/ )    { return $typeshashbyvalue{'root'}; }
    else                           { return $typeshashbyvalue{'lexical'}; }
}


sub loadvariables {

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
				name   => "Inactive	modern Languages",
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

    # some hardcoded values, contained in the schema xml, not the data xml
    # === LIST TYPES =================================================

    @parenttypes = (
        'source-type',             'doc-type',
        'linked-type',             'example-type',
        'ref-type',                'class-form-type',
        'class-form-variant-type', 'inflect-type',
        'inflect-variant-type',    'speech-type'
    );

    @sourcestypes = (
        'adunaic',    'appendix',   'index',  'minor',
        'minor-work', 'neologisms', 'quenya', 'secondary',
        'sindarin',   'telerin',    'work'
    );

	@doctypes = (
		 'cite',    'deprecations', 'grammar',    'linked',
		 'names',   'neologisms',   'notes',      'phonetics',
		 'phrases', 'roots',        'vocabulary', 'words'
	);

    @linkedtypes = (
        'before',   'cognate',     'combine',   'deprecated',
        'deriv',    'element',     'related',   'see',
        'see-also', 'see-further', 'see-notes', 'word'
    );
    
    @eictypes = ( 'element', 'inflect', 'class' );

    @exampletypes = ( 'deriv', 'inflect', 'order' );

    @reftypes = (
        'change', 'cognate', 'correction',
        'deriv',  'example', 'ref',
        'rule', 'rule-start', 'rule-example');
        
    @doclinktypes = (
        'entry', 'language', 'source' );

    @classformtypes = (
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

    @classformvarianttypes = ( 'common', 'fem', 'masc' );

    @inflecttypes = (
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

    @inflectvarianttypes = (
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

    @speechtypes = (
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
      

    $insert_type =
      'INSERT INTO ' . $schema . 'TYPE (ID, TXT, PARENT_ID) VALUES ';
    $insert_grammar = 'INSERT INTO ' . $schema . 'GRAMMAR (ID, TXT) VALUES ';
    $insert_language =
        'INSERT INTO '
      . $schema
      . 'LANGUAGE (ID, NAME, MNEMONIC, PARENT_ID) VALUES ';
    $insert_language_doc =
        'INSERT INTO '
      . $schema
      . 'LANGUAGE_DOC (LANGUAGE_ID, DOC_ID, ORDERING) VALUES ';
    $insert_cat =
      'INSERT INTO ' . $schema . 'CAT (ID, LABEL, PARENT_ID) VALUES ';
    $insert_created = 'INSERT INTO ' . $schema . 'CREATED (ID, TXT) VALUES ';
    $insert_source =
        'INSERT INTO '
      . $schema
      . 'SOURCE (ID, NAME, PREFIX, SOURCETYPE_ID) VALUES ';
    $insert_source_doc =
        'INSERT INTO '
      . $schema
      . 'SOURCE_DOC (SOURCE_ID, DOC_ID, ORDERING) VALUES ';
    $insert_form = 'INSERT INTO ' . $schema . 'FORM (ID, TXT) VALUES ';
    $insert_gloss =
      'INSERT INTO ' . $schema . 'GLOSS (ID, LANGUAGE_ID, TXT) VALUES ';
    $insert_ngloss =
      'INSERT INTO ' . $schema . 'NGLOSS (ID, LANGUAGE_ID, TXT) VALUES ';
    $insert_entry =
        'INSERT INTO '
      . $schema
      . 'ENTRY (ID, FORM_ID, LANGUAGE_ID, GLOSS_ID, NGLOSS_ID, CAT_ID, CREATED_ID, RULE_FORM_ID, FROM_FORM_ID, STEM_FORM_ID, TENGWAR, MARK, NEOVERSION, ELDAMO_PAGEID, ORDERFIELD, ORTHO_FORM_ID, PARENT_ID, ORDERING, ENTRYTYPE_ID) VALUES ';
    $insert_rule =
        'INSERT INTO '
      . $schema
      . 'RULE (ID, ENTRY_ID, FROM_FORM_ID, RULE_FORM_ID, LANGUAGE_ID, ORDERING) VALUES ';
    $insert_ref =
        'INSERT INTO '
      . $schema
      . 'REF (ID, ENTRY_ID, FORM_ID, GLOSS_ID, LANGUAGE_ID, SOURCE_ID, MARK, RULE_FROMFORM_ID, RULE_RLFORM_ID, RULE_RULEFORM_ID, ORDERING, ENTRYTYPE_ID, SOURCE) VALUES ';
    $insert_entry_doc =
        'INSERT INTO '
      . $schema
      . 'ENTRY_DOC (ENTRY_ID, DOC_ID, ORDERING) VALUES ';
    $insert_doc =
      'INSERT INTO ' . $schema . 'DOC (ID, TXT, DOCTYPE_ID) VALUES ';
    $insert_entry_grammar =
        'INSERT INTO '
      . $schema
      . 'LINKED_GRAMMAR (ENTRY_ID, GRAMMAR_ID, ORDERING, GRAMMARTYPE_ID) VALUES ';
    $insert_linked_grammar =
        'INSERT INTO '
      . $schema
      . 'LINKED_GRAMMAR (LINKED_ID, GRAMMAR_ID, ORDERING, GRAMMARTYPE_ID) VALUES ';
    $insert_reflinked =
        'INSERT INTO '
      . $schema
      . 'LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, REF_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK, SOURCE) VALUES ';
    $insert_linked =
        'INSERT INTO '
      . $schema
      . 'LINKED (ID, LINKEDTYPE_ID, ENTRY_ID, TO_LANGUAGE_ID, ORDERING, SOURCE_ID, MARK, SOURCE) VALUES ';
    $insert_linked_doc =
        'INSERT INTO '
      . $schema
      . 'LINKED_DOC (LINKED_ID, DOC_ID, ORDERING) VALUES ';
    $insert_linkedexample =
        'INSERT INTO '
      . $schema
      . 'EXAMPLE (LINKED_ID, SOURCE_ID, FORM_ID, ORDERING, EXAMPLETYPE_ID, SOURCE) VALUES ';
    $insert_refexample =
        'INSERT INTO '
      . $schema
      . 'EXAMPLE (REF_ID, SOURCE_ID, FORM_ID, ORDERING, EXAMPLETYPE_ID, SOURCE) VALUES ';
    $insert_linked_form =
        'INSERT INTO '
      . $schema
      . 'LINKED_FORM (LINKED_ID, FORM_ID, ORDERING) VALUES ';
    $insert_rulesequence =
        'INSERT INTO '
      . $schema
      . 'RULESEQUENCE (DERIV_ID, FROM_FORM_ID, LANGUAGE_ID, RULE_FORM_ID, STAGE_FORM_ID, ORDERING) VALUES ';
}
