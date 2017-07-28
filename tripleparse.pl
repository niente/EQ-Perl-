#!C:\Perl\bin\perl -w

# I didn't write this script!
# It was written by Brogett and provided on the EQ forums.
# source: https://forums.daybreakgames.com/eq/index.php?threads/is-there-a-theoretical-dps-calculator.212455/#post-3108181
 
# Breaks an attack into rounds.
# Note this *ONLY* works when mainhand and offhand have the same delay. When
# this is true the order is strictly defined, allowing us to distinguish
# the end of one round and the start of the next. With differing delays we'll
# sometimes get "primary, primary" instead of alternating "primary, secondary"
# adding confusion.
 
#
# Order of events:
# 1. Proc
#    [Wed Mar 03 08:27:44 2010] Brogett hit Test Ninety for 184 points of non-melee damage.
#    [Wed Mar 03 08:27:44 2010] Test Ninety staggers.
#    [Wed Mar 03 08:27:44 2010] You twincast Life Sap IV.
#    [Wed Mar 03 08:27:44 2010] Brogett hit Test Ninety for 184 points of non-melee damage.
#    [Wed Mar 03 08:27:44 2010] Test Ninety staggers.
# (or poisons)
#    [Wed Mar 10 15:35:36 2010] You begin casting Myrmidon's Sloth Poison Strike X.
#    [Wed Mar 10 15:35:36 2010] Your spell was partially successful.
#    [Wed Mar 10 15:35:36 2010] Test Ninety is slowed by poison.
#
# 2. Hits:
#    [Wed Mar 03 08:27:44 2010] You pierce Test Ninety for 284 points of damage.
#    [Wed Mar 03 08:27:44 2010] You try to pierce Test Ninety, but miss!
#
# 3. Flurries
#    [Wed Mar 10 15:35:16 2010] You unleash a flurry of attacks.
 
 
use strict;
# Don't have Date::Parse installed, so hack our own for ease.
 
# Per round data
my $type = "";
my @round = ();
my $flurry = 0;
 
# Accumulative histograms, indexed by attack type
my %flurry_hist;
my %nonflurry_hist;
my %proc_hist;
my %spell_hist;
my %flurry_count;
my %nonflurry_count;
my %hit_dist;
 
# Convert an EQ log line into number of seconds within the day. Hack for now
sub seconds {
    ($_) = @_;
    my @t = ($_ =~ m/(\d+) (\d+):(\d+):(\d+) /);
    return $t[0]*86400 + $t[1]*3600 + $t[2]*60 + $t[3];
}
 
# Each round is output as:
#    <date> <flurry> <type> <event>+
# where <event> consists of <dmg>
#      <dmg> is "-" when a miss occurs.
# <flurry> is 0/1 depending on whether a flurry was seen
sub print_round {
    local $" = "\t";
    my ($line) = @_;
 
    #print substr($line,0,26), " ",scalar(@round),"\t$flurry\t$type\t@round\n";
 
    # Accumulate.
    if ($flurry) {
        $flurry_count{$type}++;
        $flurry_hist{$type}[scalar(@round)]++;
    } else {
        $nonflurry_count{$type}++;
        $nonflurry_hist{$type}[scalar(@round)]++;
    }
 
    @round = ();
    $flurry = 0;
}
 
my $last_time = "";
my $first_sec = "";
my $last_sec;
my $crit = 0; # indicates next round = crit
while (<>) {
    #last if (/Auto attack is off/);
 
    if (/Sirenea.* scores a critical hit/) {
        $crit = 1;
        next;
    }
 
    #---- Start of round - procs & poisons.
    if (/points of non-melee/ || /You begin casting/ || / pet /) {
        if (!/Massive Strike/) {
            print_round $last_time if $type ne "";
            $type = "";
        }
    }
 
    #---- Then hits.
    if (/You (try to )?((slash|hit|pierce|backstab|crush|bite|kick|punch))/) {
        $first_sec = seconds($_) if ($first_sec eq "");
        $last_sec = seconds($_);
        # With equal weapon delays, change of weapon type also indicates
        # end of an attack round.
        if ($2 ne $type && $type ne "") {
            print_round $last_time;
        }
        $type = $2;
 
        if (/You try to/) {
            push(@round, "-");
        } else {
            /for (\d+) points/;
            push(@round, $1);
            print if ($1 < 185);
            $hit_dist{$type}[$crit]{$1}++;
            $crit = 0;
        }
    }
 
 
    #---- Finally, flurries.
    if (/flurry of attacks/) {
        $flurry = 1;
 
        # Flurry is also always last thing, so to counter the very rare
        # case of swapped rounds in the log file we reset here too.
        # (Won't fix many though.)
        print_round $last_time; $type="";
    }
 
    $last_time = $_;
}
 
 
#---- Print the summary stats
my $duration = $last_sec - $first_sec + 1;
print "Duration: $duration\n";
foreach $type (sort keys %nonflurry_hist) {
    my @norm = sort {$a <=> $b} (keys %{$hit_dist{$type}[0]});
    my @crit = sort {$a <=> $b} (keys %{$hit_dist{$type}[1]});
 
    $flurry_count{$type}    = 0 unless exists($flurry_count{$type});
    $nonflurry_count{$type} = 0 unless exists($nonflurry_count{$type});
    for (my $i = 1; $i <= 5; $i++) {
        $flurry_hist{$type}[$i] = 0
            unless exists($flurry_hist{$type}[$i]);
        $nonflurry_hist{$type}[$i] = 0
            unless exists($nonflurry_hist{$type}[$i]);
    }
 
    # Dump histograms
    my $delay = 10*$duration / ($nonflurry_count{$type}+$flurry_count{$type});
    print "\n$type: $delay delay\n";
    print "Normal  min=$norm[0] max=$norm[-1]\n";
    print "Critical min=$crit[0] max=$crit[-1]\n";
    print "  non-flurries = $nonflurry_count{$type} rounds\n";
    for (my $n=0; $n <= 10; $n++) {
        next unless $nonflurry_hist{$type}[$n];
        print "    $n $nonflurry_hist{$type}[$n]\n";
    }
 
    $flurry_count{$type} = 0 unless exists($flurry_count{$type});
    print "  flurries = $flurry_count{$type} rounds\n";
    for (my $n=0; $n <= 10; $n++) {
        next unless $flurry_hist{$type}[$n];
        print "    $n $flurry_hist{$type}[$n]\n";
    }
 
    # Compute probabilities
    my @c = (0, 0);
    for (my $i = 1; $i <= 5; $i++) {
        for (my $j = $i; $j <= 5; $j++) {
            $c[$i] += $flurry_hist{$type}[$j] + $nonflurry_hist{$type}[$j];
        }
    }
 
    print "\n";
    printf("  Double chance = %5.1f%%\n", 100.0 * $c[2]/$c[1]) if $c[1];
    printf("  Triple chance = %5.1f%%\n", 100.0 * $c[3]/$c[2]) if $c[2];
    printf("  Flurry chance = %5.1f%%\n", 100.0 * $c[4]/$c[3]) if $c[3];
    printf("  Dbl flurry    = %5.1f%%\n", 100.0 * $c[5]/$c[4]) if $c[4];
}
