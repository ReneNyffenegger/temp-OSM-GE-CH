#!/usr/bin/perl
use warnings;
use strict;

use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=$ENV{github_root}OpenStreetMap/db/area/Pfungen_224_1682188.db", '', '', {sqlite_unicode=>1}) or die "does not exist";

open(my $kml, '>:encoding(utf-8)', 'Pfungen.kml') or die;
start_kml('Pfungen.kml');

draw_admin_borders();
draw_highway_track();


print $kml "</Folder></Document></kml>";

sub start_kml { #_{
  my $name = shift;

  print $kml <<E;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
	<name>$name</name>

  <Style id="border"><LineStyle><color>ff0000ff</color><width>5</width></LineStyle></Style>


	<StyleMap id="m_ylw-pushpin"> <Pair> <key>normal</key> <styleUrl>#s_ylw-pushpin0</styleUrl> </Pair> <Pair> <key>highlight</key> <styleUrl>#s_ylw-pushpin_hl</styleUrl> </Pair> </StyleMap>
	<Style id="s_ylw-pushpin_hl"> <IconStyle> <scale>1.3</scale> <Icon> <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href> </Icon> <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/> </IconStyle> </Style>
	<StyleMap id="m_ylw-pushpin0"> <Pair> <key>normal</key> <styleUrl>#s_ylw-pushpin</styleUrl> </Pair> <Pair> <key>highlight</key> <styleUrl>#s_ylw-pushpin_hl0</styleUrl> </Pair> </StyleMap>
	<Style id="s_ylw-pushpin"> <IconStyle> <scale>1.1</scale> <Icon> <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href> </Icon> <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/> </IconStyle> <LineStyle> <color>ff00ffff</color> <width>2</width> </LineStyle> </Style>
	<Style id="s_ylw-pushpin_hl0"> <IconStyle> <scale>1.3</scale> <Icon> <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href> </Icon> <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/> </IconStyle> <LineStyle> <color>ff00ffff</color> <width>2</width> </LineStyle> </Style>
	<Style id="s_ylw-pushpin0"> <IconStyle> <scale>1.1</scale> <Icon> <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href> </Icon> <hotSpot x="20" y="2" xunits="pixels" yunits="pixels"/> </IconStyle> </Style>


 <Folder><name>PFUNGEN</name><open>1</open>
		<LookAt>
		<longitude>8.648313414890922</longitude>
		<latitude>47.50806653811606</latitude>
			<altitude>0</altitude>
			<heading>11.48094450866536</heading>
		<tilt>10.38162636837978</tilt>
		<range>12713.92910521556</range>
			<gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>
		</LookAt>
E

} #_}

sub draw_admin_borders {
  draw_relation(1682188, 'border'); # Border of Pfungen
}

sub draw_highway_track {

  my $sth = $dbh -> prepare('select way_id from tag where key = ? and val = ?') or die;
  $sth->execute('highway', 'track') or die;

  while (my $rec = $sth -> fetchrow_hashref) {
#   print "$rec->{way_id}\n";

    if (not defined $rec->{way_id}) {
      print "way id not defined\n";
    }
    else{
      draw_way($rec->{way_id}, 'm_ylw-pushpin0');
    }

  }

}

sub draw_relation { #_{
  my $rel_id = shift;

  my $sth = $dbh -> prepare('select nod_id, way_id, rel_id, rol from rel_mem where rel_of = ? order by order_');
  $sth -> execute($rel_id);


  while (my $rec = $sth->fetchrow_hashref) {
  if ($rec->{rol} eq 'admin_centre') {
    draw_node($rec->{nod_id});
  }
  elsif ($rec->{rol} eq 'outer') {

    if (defined $rec->{way_id}) {
      draw_way($rec->{way_id}, 'border');
    }
    else {
      print "huh, way id\n";
    }

  }
  else {
    printf ("%-20s\n", $rec->{rol});
  }
 }


} #_}

sub draw_way { #_{
  my $way_id = shift;
  my $style_id = shift;

  print $kml "
			<Placemark>
       <name>???</name>
				<styleUrl>#$style_id</styleUrl>
				<LineString>
					<tessellate>1</tessellate>
					<coordinates>
    ";


    my $sth = $dbh -> prepare(
      "select
         w.nod_id,
         n.lat,
         n.lon
       from
         nod_way w join
         nod n on n.id = w.nod_id
       where
         w.way_id = ?
       order by
         order_");

    $sth->execute($way_id);

    while (my $rec = $sth->fetchrow_hashref) {
      print $kml "$rec->{lon},$rec->{lat},0 ";
    };

    print $kml "
					</coordinates>
				</LineString>
			</Placemark>
  ";

} #_}

sub draw_node { #_{
  my $nod_id = shift;

  my $sth = $dbh -> prepare('select lat, lon from nod where id = ?');
  $sth -> execute($nod_id);
  my $rec = $sth->fetchrow_hashref;

  my $coord = {
    lat => $rec->{lat},
    lon => $rec->{lon},
  };

  push_pin($coord, 'Pfungen');

} #_}

sub push_pin { #_{
  my $coord = shift;
  my $name  = shift;

  print $kml "

			<Placemark>
        <name>$name</name>
				<styleUrl>#m_ylw-pushpin</styleUrl>
				<Point>
					<gx:drawOrder>1</gx:drawOrder>
          <coordinates>$coord->{lon}, $coord->{lat}</coordinates>
				</Point>
			</Placemark>
  ";

} #_}
