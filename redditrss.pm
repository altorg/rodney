package RedditRSS;

use strict;
use warnings;
use diagnostics;
use XML::Feed;

use HTTP::Date;

sub new {
    my $class = shift;
    my %args = @_;
    return bless \%args, $class;
}

sub init {
    my $self = shift;
    my $rss_url = shift || $self->{'rss_url'};
    my $cachedir = shift || $self->{'cachedir'};

    $self->{'cachefile'} = $rss_url;
    $self->{'cachefile'} =~ s/^https:\/\///;
    $self->{'cachefile'} =~ tr/\//./;

    $self->{'cachedir'} = $cachedir if (!$self->{'cachedir'});
    $self->{'cachedir'} = '.' if (!$self->{'cachedir'});
    $self->{'cachedir'} .= '/' if (!($self->{'cachedir'} =~ m/\/$/));
    $self->{'rss_url'} = $rss_url if (!$self->{'rss_url'});
    $self->{'cachedate'} = 0;

    $self->cache_read();
}

sub cache_read {
    my $self = shift;
    open(CACHEFILE,$self->{'cachedir'}.$self->{'cachefile'}) || return;
    while (<CACHEFILE>) {
	my $line = $_;
	$line =~ s/\n+$//;
	$self->{'cachedate'} = scalar($line);
    }
    close(CACHEFILE);
}

sub cache_write {
    my $self = shift;
    my $line = $self->{'cachedate'};
    open(CACHEFILE,'>'.$self->{'cachedir'}.$self->{'cachefile'}) || return;
    print CACHEFILE "$line\n";
    close(CACHEFILE);
}

sub parse_reddit_rss {
    my $feed = shift;

    my @itemlist = ();

    foreach ($feed->entries) {
	my %item = ();

	$item{'title'} = $_->title;
        $item{'link'} = $_->link;
	$item{'pubDate'} = $_->modified->epoch();
	$item{'description'} = "";

        push(@itemlist, \%item);
    }

    return @itemlist;
}

sub update_rss {
    my $self = shift;
    my $feed = XML::Feed->parse(URI->new($self->{'rss_url'}))
	or return '';

    my @items = parse_reddit_rss($feed);
    my $nitems = scalar(@items);

    my $retstr;

    return $retstr if ($nitems < 1);

    my $i;

    for ($i = 0; $i < $nitems; $i++) {
	if ($items[$i]->{pubDate} > $self->{'cachedate'}) {
	    $retstr = 'Reddit: '.$items[$i]->{title}.' ';
	    my $lnk = $items[$i]->{link};
	    my $url = 'https://redd.it/';
	    if ($lnk =~ m/^.+?\/comments\/([a-z0-9]+)\//) {
		$url .= $1;
	    } else {
		$url = $items[$i]->{link};
	    }
	    $retstr .= $url;
	    $self->{'cachedate'} = $items[$i]->{pubDate};
	    return $retstr;
	}
    }
    return $retstr;
}


1;

__END__


# slurp the whole file, not each line.
#undef $/;
#my $infile = 'nethack.rss';
#open INFILE, $infile or die "Could not open $infile: $!";
#my $f = <INFILE>;
#close INFILE;
#my @i = parse_reddit_rss($f);
#my $nitems = scalar(@i);
#print $i[0]->{pubDate}."\n";
#my $t = str2time($i[0]->{pubDate});
#print $t."\n";
#print time2str($t)."\n";
