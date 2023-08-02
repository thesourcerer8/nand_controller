#!/usr/bin/perl -w


foreach my $definefile(<*.sv>,<*.v>)
{
  #print "$definefile\n";
  open IN,"<$definefile";
  while(<IN>)
  {
    if(m/\`define\s+([\w_]+)/)
    {
      #print "$definefile $1\n";
      push @search,$1;
    }
  }
  close IN;
}

foreach my $definefile(<*.sv>,<*.v>)
{
  print "$definefile\n";
  open IN,"<$definefile";
  my $counter=1;
  while(<IN>)
  {
    s/\/\/.*$//;	  
    foreach my $mysearch(@search)
    {
      if(m/[^`]$mysearch/ && !m/\`define/)
      {
        print "WARNING: $definefile:$counter $mysearch: $_";
      }
    }
    $counter++;
  }
  close IN;
}


