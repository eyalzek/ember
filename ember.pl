#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin";
use Ember::App;

my $app = Ember::App->new(@ARGV);

$app->run();
