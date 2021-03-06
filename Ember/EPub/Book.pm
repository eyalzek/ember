#!/usr/bin/perl

package Ember::EPub::Book;

use strict;
use warnings;
use base qw( Ember::Book );
use fields qw( manifest rootpath formatter );

use Ember::EPub::Chapter;
use Ember::Format::HTML;
use Scalar::Util qw( weaken );
use XML::Simple;

sub _open {
    my ($self) = @_;
    my $fs = $self->{fs};
    my $mime = $fs->content('mimetype');

    return 0 if ($mime !~ /application\/epub\+zip/i);

    my $container = $fs->content('META-INF/container.xml');
    my($opf_file, $root_path) = ($container =~ /full-path="((.*?)[^\/]+?)"/);
    my $opf_raw = $fs->content($opf_file);
    my $opf = XMLin($opf_raw);
    my %items = %{$opf->{manifest}{item}};
    my @refs = @{$opf->{spine}{itemref}};
    my(%manifest, @chapters, $prev);

    foreach my $id (keys(%items)) {
        $manifest{$id} = {
            id      => $id,
            file    => $items{$id}{href},
            mime    => $items{$id}{'media-type'},
        };
    }

    foreach my $ref (@refs) {
        my $chapter = Ember::EPub::Chapter->new();
        my $id = $ref->{idref};
        my $item = $manifest{$id};
        my $skip = $ref->{linear} && ($ref->{linear} eq 'no');

        $chapter->{id} = $id;
        $chapter->{path} = $item->{file};
        $chapter->{mime} = $item->{mime};
        $chapter->{skip} = 1 if ($skip);
        weaken($chapter->{book} = $self);

        if ($prev) {
            weaken($chapter->{prev} = $prev);
            weaken($prev->{next} = $chapter);
        }

        $prev = $chapter;
        push(@chapters, $chapter);
    }

    # TODO parse metadata, TOC, etc

    $self->{manifest} = \%manifest;
    $self->{chapters} = \@chapters;
    $self->{rootpath} = $root_path;
    $self->{formatter} = Ember::Format::HTML->new();

    return 1;
}

1;
