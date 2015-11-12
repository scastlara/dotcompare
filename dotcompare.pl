#!/usr/bin/perl

=head1 NAME

dotcompare - A program to compare DOT files

=head1 VERSION

v0.1.4

=head1 SYNOPSIS

    dotcompare  --files file1.dot,file2.dot \\  
                --colors HARD               \\   
                --dot output.dot            \\   
                --table table.tbl           \\ 
                --venn venn.svg             \\ 
                --web graph.html               

=head1 DESCRIPTION

This script compares two or more DOT (graphviz) files and 
prints the resulting merged DOT file with different 
colors for each group. 

By default, dotcompare will print the resulting graph to
STDOUT, but you can change it with the option -d (see options below).

Dotcompare has some optional outputs, each one specified by one 
option.

=over 8

=item - Venn diagram. 

If given the option -v, dotcompare will create an
svg file containing a venn diagram. In this image, you will be able to see
a comparison of the counts of nodes and relationships in each input DOT file,
and those nodes/relationships common to more than one file. The colors will be
chosen using one of the profiles in data/colors.txt. By default, the color palette
is set to be "SOFT". To change it, use the option -c (see options below).

=item - Table. 

Complementary to the venn diagram, one can choose to create a 
table containing all the counts (so it can be used to create other plots or tables). The 
table is already formated to be used by R. Load it to a dataframe using:

        df <-read.table(file="yourtable.tbl", header=FALSE)

=item - Webpage with the graph. 

With the option -w, one can create a webpage
with a representation of the merged graph (with different colors for nodes and 
relationships depending on their presence in each DOT file). To make this representation,
dotcompare uses the Open Source library cytoscape.js. All the cytoscape.js code is
embedded in the html file to allow maximum portability: the webpage and the graph work
without any external file/script dependencies. This allows for an easy upload of the graph
to any website.

=back


=head1 OPTIONS

=over 8

=item B<-h>, B<--help>               

Shows this help. 

=item B<-f>, B<--files> <file1,file2,...>

REQUIRED. Input DOT files, separated by commas.    

=item B<-d>, B<--dot> <filename.dot>

Creates a merged dot file. Default to STDOUT.

=item B<-c>, B<--colors> <profile>

Color profile to use: SOFT (default), HARD, LARGE or CBLIND.

=item B<-v>, B<--venn> <filename.svg>

Creates a venn diagram with the results. 

=item B<-w>, B<--web> <filename.html>

Writes html file with the graph using cytoscape.js

=back

=head1 AUTHOR

Sergio Castillo Lara - s.cast.lara@gmail.com

=head1 BUGS AND PROBLEMS

=head2 Current Limitations

=over 8

=item I<Undirected_graphs> 

Only works with directed graphs. If undirected, 
dotcompare considers it to be directed.

=item I<Clusters> 

Still no clusters support eg: {A B C} -> D

=item I<Multiline IDs> 

No support for multiline IDs (yet).

=back

=head2 Reporting Bugs

Report Bugs at I<https://github.com/scastlara/dotcompare/issues> (still private)

=head1 COPYRIGHT 

    (C) 2015 - Sergio CASTILLO LARA

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut


#===============================================================================
# MODULES
#===============================================================================
use warnings;
use strict;
use Getopt::Long;
use Algorithm::Combinatorics qw(combinations);
use Cwd 'abs_path';
use Pod::Usage;


#===============================================================================
# VARIABLES AND OPTIONS
#===============================================================================
our $PROGRAM       = "dotcompare";
our $VERSION       = 'v0.1.4';
our $USER          = $ENV{ USER };
our $INSTALL_PATH  = get_installpath(); 
our $MAIL          = 's.cast.lara@gmail.com';

error("Error trying to find Installation path through \$0.")
    unless $INSTALL_PATH;

my $dot_files     = "";
my $help          = "";
my $venn          = "";
my $table         = "";
my $debug         = "";
my $web           = "";
my $color_profile = "SOFT";
my $out_name      = "STDOUT";
my %nodes         = ();
my %interactions  = ();

# If no arguments provided
pod2usage( -verbose => 1,  
           -output  => \*STDERR   ) unless @ARGV;

my $options = GetOptions (
    'help|?'     => \$help,
    "files=s"  => \$dot_files,    
    "colors=s" => \$color_profile,
    "out=s"    => \$out_name,
    "table=s"  => \$table,
    "venn=s"   => \$venn,
    "web=s"    => \$web,
    "debug"    => \$debug
);

my @files = split /,/, $dot_files;

# If option --help
pod2usage( -verbose => 1,  
           -output  => \*STDERR   ) if $help;

# If no files
unless (@files > 0) {
    error("You have to introduce at least 1 dot file \n\n\t" . 
          'perl DOTCompare.pl -f file1,file2,file3...'
         );
}


#===============================================================================
# MAIN
#===============================================================================

# START REPORT
my $start_time   = time();
my $current_time = localtime();
print STDERR "\nPROGRAM STARTED\n",
             "\tProgram         $PROGRAM\n",
             "\tVersion         $VERSION\n",
             "\tUser            $USER\n",
             "\tInstallpath     $INSTALL_PATH\n",
             "\tColor Profile   $color_profile\n",
             "\tInput files     ", join("\n\t\t\t", @files), "\n\n",
             "\tStart time      $current_time\n\n";
#--

# READ DOT FILES
@files = sort @files;
foreach my $file (@files) {
    read_dot($file, \%nodes, \%interactions);
}

# COLORS AND COUNTS
my $groups           = initialize_groups(\@files);
my $colors           = load_colors($color_profile);
my $groups_to_colors = assign_colors($colors,$groups);

# COUNT NODES AND INTERACTIONS IN GROUPS
count_nodeints(\%nodes, $groups, "nodes");
count_nodeints(\%interactions, $groups, "ints");

# WRITE DOT FILE
my $dot_fh = get_fh($out_name);
print $dot_fh "digraph ALL {\n";
write_dot($dot_fh, \%nodes, $groups_to_colors, "NODES");
write_dot($dot_fh, \%interactions, $groups_to_colors, "INTERACTIONS");
print $dot_fh "}";

# OPTIONAL OUTPUTS
if ($table) {
    results_table($table, $groups);
}

if ($venn) {
    print_venn($venn, $groups, \@files, $groups_to_colors);
}

if ($web) {
    my $json        = create_json(\%nodes, \%interactions, $groups_to_colors); 
    my $color_table = create_ctable($groups_to_colors);
    print_html($web, $json, $color_table);
}

# END REPORT
my $end_time  = time();
$current_time = localtime();
my $run_time  = sprintf("%.2f", (($end_time - $start_time) / 60));
my @out_files = grep {$_} ($out_name, $table, $venn, $web);
print STDERR "PROGRAM FINISHED\n",
             "\tOutput files \t", join("\n\t\t\t", @out_files), "\n\n",
             "\tEnd time \t$current_time\n\n",
             "\tJob took ~ $run_time minutes\n\n"; 
#--

# DEBUGGING
if ($debug) {
    use Data::Dumper;
    print STDERR Dumper(\%nodes);
    print STDERR Data::Dumper->Dump([$groups,   $groups_to_colors], 
                                    [("GROUPS", "GROUPS_2_COLORS") ]), "\n";
}


#===============================================================================
# FUNCTIONS 
#===============================================================================

# READING DOT FILES
#--------------------------------------------------------------------------------
sub read_dot {
    # Function is TOO long. May need to refactor
    my $dot          = shift;
    my $nodes        = shift;
    my $interactions = shift;
    my $dot_symbol   = clean_name($dot);
    my $multicomm    = 0; 

    open my $dot_fh, "<", $dot
        or error("Can't open dot file $dot: $!");

    while (<$dot_fh>) {
        chomp;
        # Remove spaces
        $_ =~ s/\s+//g; 

        # Comments
        $_ =~ s{\/\*.*?\*\/}{}g; # Remove comments
        $_ =~ s{\/\/.+}{}g;      # Remove regular comments

        # If there are still comments,
        # they must be multiline
        if ($_ =~ m{\/\*}) {
            $multicomm = 1;
        } elsif ( $_ =~ m{\*\/} ) {
            $multicomm = 0;
            $_ =~ s{.*\*\/}{};
            next unless $_ =~ m/[\w\d]/;
        }
        next if $multicomm;


        # Multiple statements per line
        my @statements = ();
        if ($_ =~ m/;/) {
            @statements = split /;/;
        } else {
            push @statements, $_;
        }

        foreach my $stmt (@statements) {
            $stmt =~ s{(?<!\\)\"|(?<!\\)\'}{}g; # Remove unescaped quotes
            $stmt =~ s{\\}{}g;                  # Remove escape character
            $stmt =~ s{\;}{}g;                  # Remove semicolons
            $stmt =~ s{\[.*?\]}{}g;             # Remove attributes 

            next unless $stmt =~ m/[\w\d]/;
    
            # DOT language keywords
            next if ($stmt =~ m/^digraph/i  or # digraph declaration
                     $stmt =~ m/^graph/i    or # graph declaration
                     $stmt =~ m/^subgraph/i or # subgraph declaration
                     $stmt =~ m/^node/i     or # node properties
                     $stmt =~ m/^edge/i     or # edge properties
                     $stmt =~ m/^#/         or # C preprocessor lines
                     $stmt =~ m/^}$/);         # End of sub/di/graph
    
            if ($stmt =~ m/\-\-/) {
                print STDERR "Your graph is undirected. Changed it to directed.\n";
                $stmt =~ s{\-\-}{\->}g
            }

            if ($stmt =~ m/\->/g) { 
                # interactions "node1"->"node2"->"node3"
                my @node_names = split /\->/, $stmt;
                check_IDs(\@node_names) or error("Not allowed character found ".
                                                 "in dotfile $dot at line $.");
                add_nodes(\@node_names, $nodes, $dot_symbol);
                add_interactions(\@node_names,$interactions,$dot_symbol);
            } else { 
                # just defined nodes: node [foo = bar];
                my @node_names = ($stmt);
                check_IDs(\@node_names) or error("Not allowed character found ".
                                                 "in dotfile $dot at line $.");
                add_nodes(\@node_names, $nodes, $dot_symbol);
            } # if node or interaction
    
            }
       
    } # while file

    return;
}

#--------------------------------------------------------------------------------
sub clean_name {
    my $file_name = shift;
    my $cleaned   = $file_name;

    $cleaned =~ s/\.dot//g; 
    $cleaned =~ s/.+\///; 

    return($cleaned);
} 

#--------------------------------------------------------------------------------
sub check_IDs {
    my $ids = shift;

    # We didn't use the full DOT specification, as it stands that IDs with 
    # letters that start with a digit are not allowed. Given the fact that 
    # many genes may start with a digit and then some letters, I wasn't very 
    # strict with the characters restriction.

    # Also, note that DOT allows " and ' in IDs (if they are properly escaped).
    # Unescaped quotes were removed before, so only escaped ones remain.

    foreach my $id (@{$ids}) {
        return 0 if ($id =~ m/[^A-Z0-9_\"\']/i);
    } 

    return 1;
}

#--------------------------------------------------------------------------------
sub add_nodes {
    my $node_names = shift;
    my $nodes      = shift;
    my $dot_symbol = shift;

    foreach my $node (@{$node_names}) {
        if (exists $nodes->{$node}) {
            $nodes->{$node} .= ":$dot_symbol"
                unless $nodes->{$node} =~ m/\b$dot_symbol\b/;
        } else {
            $nodes->{$node} = $dot_symbol;
        }
    }

    return;
}

#--------------------------------------------------------------------------------
sub add_interactions {
    my $node_list    = shift;
    my $interactions = shift;
    my $dot_symbol   = shift;

    foreach my $i (0..$#{$node_list} - 1) {
        my $string = $node_list->[$i]."->".$node_list->[$i+1];

        if (exists $interactions->{$string}) {
            $interactions->{$string} .= ":$dot_symbol"
                unless $interactions->{$string} =~ m/\b$dot_symbol\b/;
        } else {
            $interactions->{$string} = $dot_symbol;
        }
        
    } # #foreach

    return;
}


# COLORS AND GROUPS
#--------------------------------------------------------------------------------
sub initialize_groups {
    my $files_array = shift;
    my %count_hash  = ();

    @{$files_array} = map {clean_name($_)} @{$files_array};

    foreach my $idx (1..@{$files_array} ) {
        my $iter = combinations($files_array, $idx);

        while (my $combi = $iter->next) {
            my @sorted = sort @$combi;
            $count_hash{join ":",@sorted}->{nodes} = 0;
            $count_hash{join ":",@sorted}->{ints} = 0;
        } # while

    } # foreach

    return (\%count_hash);

} 

#--------------------------------------------------------------------------------
sub load_colors {
    my $profile = shift;
    my @colors  = ();
    local $/ = "//";

    open my $fh, '<', "$INSTALL_PATH/data/colors.txt"
        or error("Can't open $INSTALL_PATH/data/colors.txt,". 
                 " is your installpath correct? :$!");

    while (<$fh>) {
        chomp;
        my ($name, @prof_colors) = split /\n/;
        next unless $profile eq $name;
        @colors = @prof_colors;
    }

    unless (@colors) {
        error(
              "Your profile \"$profile\" doesn't exist!\n".
              "Choose one of the following:\n\n". 
              "\t- SOFT\n".
              "\t- HARD\n" .
              "\t- LARGE\n" .
              "\t- CBLIND\n"
              );
    }

    return \@colors;
}

#--------------------------------------------------------------------------------
sub assign_colors {
    my $colors = shift;
    my $groups = shift;
    my %g_to_c = ();

    error("There are more groups than colors!")
        if (keys %{$groups} > @{$colors});

    
    foreach my $group (sort keys %{ $groups }) {
        $g_to_c{$group} = shift @{$colors};
    }

    return(\%g_to_c);
}


# COUNTING
#--------------------------------------------------------------------------------
sub count_nodeints {
    my $in_hash = shift;
    my $groups  = shift;
    my $string  = shift;

    foreach my $obj (keys %{ $in_hash }) {
        $groups->{ $in_hash->{$obj} }->{$string}++;
    }

    return;
}


# DOT OUTPUT
#--------------------------------------------------------------------------------
sub get_fh {
    my $filename = shift;
    my $out_fh;

    if ($filename eq "STDOUT") {
        $out_fh =\*STDOUT
    } else {
        open $out_fh, ">", $filename
            or error("Can't write to $filename : $!");
    }

    return($out_fh);
}

#--------------------------------------------------------------------------------
sub write_dot {
    my $fhandle = shift;
    my $in_data = shift;
    my $g_to_c  = shift;
    my $string  = shift;

    print $fhandle "// $string\n";

    foreach my $datum (keys %{ $in_data }) {
        print $fhandle "\t", $datum, "\t", 
                       "[color=\"$g_to_c->{ $in_data->{$datum} }\"]", "\t", 
                       "// $in_data->{$datum}", "\n";
    }

    return;
}


# TABLE OUTPUT
#--------------------------------------------------------------------------------
sub results_table {
    my $out_file = shift;
    my $groups   = shift;

    open my $fh, '>', "$out_file"
        or error("Can't create results.tbl : $!");

    print $fh "GROUP\tNODES\tINTERACTIONS\n";
    foreach my $group (sort keys %{$groups}) {
        print $fh    $group, "\t", 
                     $groups->{$group}->{nodes}, "\t", 
                     $groups->{$group}->{ints}, "\n";
    }

    return;
}


# VENN OUTPUT
#--------------------------------------------------------------------------------
sub print_venn {
    my $out_file      = shift;
    my $groups        = shift;
    my $filenames     = shift;
    my $grp_to_colors = shift;
    my @group_keys    = keys %{$groups}; 
    my $venn_template = "";

    open my $out, ">", $out_file
        or error("Can't create $out_file :$!");

    if (@group_keys == 3) {
        # We have 2 dotfiles -> venn with 2 circles
        $venn_template = "$INSTALL_PATH/data/v2_template.svg";
    } elsif (@group_keys == 7) {
        # We have 3 dotfiles -> venn with 3 circles
        $venn_template = "$INSTALL_PATH/data/v3_template.svg";
    } else {
        print STDERR "You have more than 3 dot files (or less than 2), ", 
                     "I won't draw any venn diagram.\n", 
                     "I suggest you to use the option -t to print a ",
                     "table with the results\n";
        return;
    }

    my ($grp_to_alias, $alias_to_grp) = assign_aliases($filenames, \@group_keys);
    parse_svg($out, $venn_template, $grp_to_alias, $alias_to_grp, $groups, $grp_to_colors);
    return;
}

#--------------------------------------------------------------------------------
sub assign_aliases {
    my $principal_grps = shift;
    my $group_names    = shift;
    my @group_aliases  = qw(GR1 GR2 GR3);
    my %grp_to_alias   = ();
    my %alias_to_grp   = ();

    # Initialize groups
    foreach my $i (0..$#{$principal_grps}) {
        $grp_to_alias{$principal_grps->[$i]} = $group_aliases[$i];
        $alias_to_grp{$group_aliases[$i]}    = $principal_grps->[$i];

    }

    # Get group combinations
    foreach my $group (@{ $group_names }) {
        next unless $group =~ /\:/;
        my @grp_parts      = split /\:/, $group;
        my @aliases        = map { $grp_to_alias{$_} } @grp_parts;
        my $alias          = join(":", @aliases);
        
        $grp_to_alias{$group} = $alias;
        $alias_to_grp{$alias} = $group;
    }

    return(\%grp_to_alias, \%alias_to_grp);
}

#--------------------------------------------------------------------------------
sub parse_svg {
    my $out_filehandle = shift;
    my $template       = shift;
    my $grp_to_alias   = shift;
    my $alias_to_grp   = shift;
    my $grp_numbers    = shift;
    my $grp_to_colors  = shift;

    open my $t_fh, "<", "$template"
        or error ("Can't open $template, is your installpath correct? :$!");

    local $/ = ">DATAHERE";
    my $first = <$t_fh>;
    chomp $first;
    print $out_filehandle "$first\n";

    while (<$t_fh>) {
        chomp;
        my ($element, $code, $rest) = split /&&/;
        my $grp_name = $alias_to_grp->{$code};

        if ($element eq "NODES") {
            print $out_filehandle "$grp_numbers->{$grp_name}->{nodes} $rest";
        } elsif ($element eq "INTERACTIONS") {
            print $out_filehandle "$grp_numbers->{$grp_name}->{ints} $rest";
        } elsif ($element eq "NAME") {
            print $out_filehandle "$alias_to_grp->{$code} $rest";           
        } else {
            print $out_filehandle "$grp_to_colors->{$grp_name}$rest";
        }
    }

    return;
}


# WEB OUTPUT
#--------------------------------------------------------------------------------
sub create_json {
    my $nodes          = shift;
    my $interactions   = shift;
    my $grps_to_colors = shift;
    my $json = "nodes: [\n";

    foreach my $node (keys %{$nodes}) {
        $json .= "\t{ data: { id: '$node', name: '$node', colorNODE: " . 
                 "\'$grps_to_colors->{ $nodes->{$node} }\'}},\n";
    }

    $json .= "],\n edges: [\n";

    foreach my $int (keys %{$interactions}) {
        my ($source, $target) = split /\->/, $int;
        $json .= "\t{ data: { id: '$source-$target', " . 
                 "source: '$source', target: '$target', ".
                 "colorEDGE: \'$grps_to_colors->{ $interactions->{$int} }\' }},\n";
    }

    $json .= "]\n";

    return(\$json);
}

#--------------------------------------------------------------------------------
sub create_ctable {
    my $grps_to_colors = shift;
    my $table          = "";

    foreach my $group (sort keys %{$grps_to_colors}) {
        $table .= "\t<tr><td bgcolor=\"$grps_to_colors->{$group}\">" .
                  "$group</td></tr>\n";
    }

    return($table);
}

#--------------------------------------------------------------------------------
sub print_html {
    my $filename       = shift;
    my $json           = shift;
    my $color_table    = shift;
    my $template       = "$INSTALL_PATH/data/cyt.template";

    local $/ = ">DATAHERE";

    open my $tt_fh, "<", $template
        or error("Can't open $template, is your installpath correct? :$!");

    open my $out_fh, ">", $filename
        or error("Can't create $filename : $!");

    foreach my $element ("", $$json, $color_table) {
        my $html = <$tt_fh>;
        chomp $html;
        print $out_fh $element, $html;
    }

    return;
}


# SCRIPT FUNCTIONS
#--------------------------------------------------------------------------------
sub error {
    my $string = shift;

    die "\n[ERROR] $string\n",
        "\nUse dotcompare -h to get help.\n\n";
}

#--------------------------------------------------------------------------------
sub get_installpath {
    my $path = abs_path($0);
    $path =~ s/(.+)\/.*?$/$1\//;
    return($path);
}

