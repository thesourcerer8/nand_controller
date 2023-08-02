#!/usr/bin/perl -w

# Work through all *.sv and *.v files in the current directory
my @files=(<*.sv>,<*.v>);

my @search=(); # List for remembering all the defines that exist

# First pass: Search for all defines:
foreach my $filename(@files)
{
  #print "$filename\n";
  open IN,"<$filename";
  while(<IN>) # Reading every line
  {
    if(m/\`define\s+([\w_]+)/) # Is it a define?
    {
      #print "$filename $1\n";
      push @search,$1; # Remember that we have to search for this define
    }
  }
  close IN;
}

# Second pass: Now search for the usages of the 
foreach my $filename(@files)
{
  print "$filename\n"; # We print the filename, so that the user sees which files were processed
  open IN,"<$filename";
  my $linenumber=1;
  while(<IN>) # read each line
  {
    s/\/\/.*$//; # Ignoring comments at the end of each line
    foreach my $mysearch(@search) # iterate over all the defines we have to search
    {
      if(m/[^`]$mysearch/ && !m/\`define/) # Is the define used here? Filter out the original `define line
      {
        print "WARNING: $filename:$linenumber $mysearch: $_";
      }
    }
    $linenumber++;
  }
  close IN;
}


