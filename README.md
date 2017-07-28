# EQ-Rampage-Statistics

I'm not the source of the cmd/perl data - [see here.](https://forums.daybreakgames.com/eq/index.php?threads/melee-mitigation-avoidance.219051/)
cmd line instructions / perl:
```
# Gather a file of rampage hits
(zcat Backup/eqlog_Sirenea_cazic.*; cat eqlog_Sirenea_cazic.txt) | egrep "Arc .*Wild Rampage" |egrep -v ' pet ' > r3

#Looks like:
#[Thu Jan 15 20:14:30 2015] Arc Facultas Ingens hits Soandso for 20909 points of damage. (Wild Rampage)

#Join neighboring hits together:
awk '{if ($4.$10 == l) {d+=$12} else {print d,c;l=$4.$10;c=$10;d=$12}}' r3 > r3b

# Append class names
perl -lane 'BEGIN {open(P, "<player_class.txt");while (<P>) {@a=split(" ", $_); $c{$a[0]}=$a[1]}};print "@F $c{$F[1]}"' r3b > r3c

# Summarize the results:
awk '{a[$3]+=$1;n[$3]++} END {for (i in a) {print int(a/n),n,i}}' r3c|sort -n
```
Initial AE Rampage data: [(source post and discussion)](https://forums.daybreakgames.com/eq/index.php?threads/melee-mitigation-avoidance.219051/#post-3191622)

![TDS - AE Rampage Graph 1](http://i.imgur.com/QWKl0WS.png)
![TDS - AE Rampage Graph 2](http://i.imgur.com/SXacsZh.png)

Data from one year later: [(source post and discussion)](https://forums.daybreakgames.com/eq/index.php?threads/melee-mitigation-avoidance.219051/page-5#post-3438113)

![TBM - Akkapan Adan](http://i.imgur.com/fZZ0tb6.png)
![Anniversary raid - Captain Krasnok](http://i.imgur.com/TIMY4QT.png)
