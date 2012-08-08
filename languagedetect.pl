#!/usr/bin/perl
 
use Email::MIME;
use HTML::Strip;
use Lingua::LanguageGuesser;
use Email::Simple;
use Email::Address;
 
my $hs = HTML::Strip->new();
my $email_simple = Email::Simple->new(join('', <STDIN>));
my $email = Email::MIME->new($email_simple->as_string);
my $detected_language = "";
my %language_to_mail_conversion_table = (
    'german'               => 'info-de',
    'german-utf8'          => 'info-de',
    'english'              => 'info-en',
    'spanish'              => 'info-es',
    'spanish-utf8'         => 'info-es',
    'french'               => 'info-fr',
    'french-utf8'          => 'info-fr',
    'italian'              => 'info-it',
    'italian-utf8'         => 'info-it',
    );

my $to_header = $email_simple->header('To');
my @addresses = Email::Address->parse($to_header);
for my $address (@addresses) {
    ($username, $domain) = ($address->format =~ /(.*)@([^@]*)$/);
}

$email->walk_parts(sub
{
    my ($part) = @_;
    return if $part->subparts;
    if ( $part->content_type =~ m[text/plain]i )
    {
        $detected_language = Lingua::LanguageGuesser->guess($part->body)->suspect('french',
            'english', 'german', 'spanish', 'italian',
            'german-utf8', 'italian-utf8', 'french-utf8', 'spanish-utf8')->best_scoring();
    }
});
 
if (!$detected_language)
{
    $email->walk_parts(sub
    {
        my ($part) = @_;
        return if $part->subparts;
        if ( $part->content_type =~ m[text/html]i )
        {
            $detected_language = Lingua::LanguageGuesser->guess($hs->parse($part->body))->suspect('french',
                'english', 'german', 'spanish', 'italian', 
                'german-utf8', 'italian-utf8', 'french-utf8', 'spanish-utf8')->best_scoring();
            $hs->eof;
        }
    });
}
 
if ($detected_language)
{
    $email->header_set("CC", $language_to_mail_conversion_table{$detected_language} . '@' . $domain);
}
else
{
    $email->header_set("CC", 'info-en' . '@' . $domain);
}
 
print $email->as_string;

