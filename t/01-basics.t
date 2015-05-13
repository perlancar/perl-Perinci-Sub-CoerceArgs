#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::CoerceArgs qw(coerce_args);
use Test::Exception;
use Test::More 0.98;

subtest "opt:meta_is_normalized" => sub {
    my $meta = {v=>1.1, args=>{t=>{schema=>[obj=>isa=>"DateTime"]}}};
    dies_ok { coerce_args(meta=>$meta, meta_is_normalized=>1, args=>{t=>"2015-03-27"}) };
};

subtest "obj DateTime" => sub {
    plan skip_all => "DateTime module not available"
        unless eval "require DateTime; 1";

    my $meta = {v=>1.1, args=>{t=>{schema=>[obj=>isa=>"DateTime"]}}};
    my $res;

    {
        $res = coerce_args(meta=>$meta, args=>{t=>"2015-03-28"});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("DateTime"));
        is($res->[2]{t}->ymd, "2015-03-28");
    }

    {
        local $ENV{TZ} = 'UTC';
        $res = coerce_args(meta=>$meta, args=>{t=>1427521689});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("DateTime"));
        is($res->[2]{t}->ymd, "2015-03-28");
    }
};

subtest "obj DateTime::Duration" => sub {
    plan skip_all => "DateTime::Duration module not available"
        unless eval "require DateTime::Duration; 1";

    my $meta = {v=>1.1, args=>{t=>{schema=>[obj=>isa=>"DateTime::Duration"]}}};
    my $res;

    {
        $res = coerce_args(meta=>$meta, args=>{t=>"P1Y2M"});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("DateTime::Duration"));
        is($res->[2]{t}->years, 1);
        is($res->[2]{t}->months, 2);
    }
};

subtest "obj Time::Moment" => sub {
    plan skip_all => "Time::Moment module not available"
        unless eval "require Time::Moment; 1";

    my $meta = {v=>1.1, args=>{t=>{schema=>[obj=>isa=>"Time::Moment"]}}};
    my $res;

    {
        $res = coerce_args(meta=>$meta, args=>{t=>"2015-03-28"});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("Time::Moment"));
        is($res->[2]{t}->strftime("%Y-%m-%d"), "2015-03-28");
    }

    {
        local $ENV{TZ} = 'UTC';
        $res = coerce_args(meta=>$meta, args=>{t=>1427521689});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("Time::Moment"));
        is($res->[2]{t}->strftime("%Y-%m-%d"), "2015-03-28");
    }
};

subtest "filters" => sub {
    my $meta;

    # code
    $meta = {v=>1.1, args=>{t=>{schema=>['str'], filters=>[sub {"a$_[0]"}]}}};
    is_deeply(coerce_args(meta=>$meta, args=>{t=>"foo"}),
              [200, "OK", {t=>"afoo"}]);

    # trim
    $meta = {v=>1.1, args=>{t=>{schema=>['str'], filters=>['trim']}}};
    is_deeply(coerce_args(meta=>$meta, args=>{t=>"  foo  "}),
              [200, "OK", {t=>"foo"}]);

    # ltrim
    $meta = {v=>1.1, args=>{t=>{schema=>['str'], filters=>['ltrim']}}};
    is_deeply(coerce_args(meta=>$meta, args=>{t=>"foo  "}),
              [200, "OK", {t=>"foo"}]);

    # rtrim
    $meta = {v=>1.1, args=>{t=>{schema=>['str'], filters=>['rtrim']}}};
    is_deeply(coerce_args(meta=>$meta, args=>{t=>"  foo"}),
              [200, "OK", {t=>"foo"}]);

    # ltrim+rtrim
    $meta = {v=>1.1, args=>{t=>{schema=>['str'], filters=>['ltrim', 'rtrim']}}};
    is_deeply(coerce_args(meta=>$meta, args=>{t=>"  foo  "}),
              [200, "OK", {t=>"foo"}]);
};

DONE_TESTING:
done_testing;
