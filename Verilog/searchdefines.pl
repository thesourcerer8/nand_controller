#!/usr/bin/perl -w

# Work through all *.sv and *.v files in the current directory
my @files=(<*.sv>,<*.v>);

my @search=(); # List for remembering all the defines that exist

# First pass: Search for all defines:
foreach my $filename(@files)
{
  #print "$filename\n";
  open IN,"<$filename"; # Opening a file
  while(<IN>) # Reading every line
  {
    if(m/\`define\s+([\w_]+)/) # Is it a define?
    {
      #print "$filename $1\n"; # Print what we found for debugging
      push @search,$1; # Remember that we have to search for this define
    }
  }
  close IN; # Close the file again
}

# Second pass: Now search for the usages of the 
foreach my $filename(@files)
{
  print "$filename\n"; # We print the filename, so that the user sees which files were processed
  open IN,"<$filename"; # We open the file
  my $linenumber=1; # Linenumber counter
  while(<IN>) # We read each line
  {
    s/\/\/.*$//; # We ignore any comments at the end of each line
    foreach my $mysearch(@search) # We iterate over all the defines we have to search
    {
      if(m/[^`]$mysearch/ && !m/\`define/) # Is the define used here? Make sure it's not the original define line
      {
        print "WARNING: $filename:$linenumber $mysearch: $_"; # Print the warning
      }
    }
    $linenumber++; # Linenumber counter
  }
  close IN; # Dont forget to close the files
}


