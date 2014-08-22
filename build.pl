#!/usr/bin/env perl
use Modern::Perl;

use File::Slurp;
use Template;
use Text::Markdown 'markdown';

my $template = Template->new();

my @index;

# Process articles
for my $file (glob "article/*.mkd") {
    unless($file =~ m|^article/(\d+)-(.*)\.mkd$|) {
        die "invalid article name: $file";
    }

    my $date = $1;
    my $name = $2;

    say " $name ($date)";

    # Render markdown into HTML
    my $body = markdown(scalar read_file($file));

    my $article = {
        date => $date,
        name => $name,
        url => "$date-$name.html",
        title => extract_title($body),
    };

    # Render final page
    $template->process(
        'template/article.tt2',
        { body => $body, article => $article },
        "output/$date-$name.html"
    ) or die "error processing article.tt2: " . $template->error();

    push @index, $article;
}

$template->process(
    'template/index.tt2',
    { index => [ reverse sort { $a->{date} <=> $b->{date} } @index ] },
    'output/index.html'
) or die "error processing index.tt2: " . $template->error();


sub extract_title {
    my $html = shift;

    for my $line (split "\n", $html) {
        when($line =~ m|^\s*<h1>\s*(.*)\s*</h1>\s*$|) {
            return $1;
        }
    }

    die "could not extract title from $html";
}
