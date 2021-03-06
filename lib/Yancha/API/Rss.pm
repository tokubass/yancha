package Yancha::API::Rss;

use strict;
use warnings;
use utf8;
use Yancha::API;
use parent qw(Yancha::API);
use XML::FeedPP;
use POSIX qw(floor);

our $VERSION = '0.01';

sub run {
    my ( $self, $req ) = @_;
    my $server_info = $self->sys->config->{server_info};
    my $posts = _get_recent_posts($self, $req);

    my $last_update_dt = _get_datetime_from_ms($posts->[0]->{created_at_ms});
    my $server_url = $server_info->{url} || '';

    my $feed = XML::FeedPP::Atom->new();
    $feed->title("yancha::".$server_info->{name});
    $feed->link($server_info->{url});
    $feed->pubDate($last_update_dt);

	foreach my $post ( @$posts) {
		my $url   = $server_url . "quot/" . $post->{id};
		my $entry = $feed->add_item($url);
		my $title = my $content = $post->{nickname}." : ".$post->{text};
		$entry->guid($url);
		$title =~ s/[\r\n]//g;
		$title = substr ($title, 0, 64);
		$entry->link($url);
		$entry->title($title);
		$entry->description($content);
		$entry->pubDate(_get_datetime_from_ms($post->{created_at_ms}));
	}

    my $res = Plack::Response->new(200);

    $res->content_type( "application/rss+xml; charset=utf-8" );
    $res->body( Encode::encode_utf8( $feed->to_string ) );

    return $res;
}

sub _get_recent_posts {
    my ( $self, $req ) = @_;
    my $where = {};
    my $attr  = {};

    $attr->{ limit } = 20;

    return $self->sys->data_storage->search_post( $where, $attr );
}

sub _get_datetime_from_ms {
    return floor($_[0] / 100_000);
}

1;
