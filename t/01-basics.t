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

subtest "type:DateTime obj" => sub {
    plan skip_all => "DateTime module not available"
        unless eval { require DateTime; 1 };

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

subtest "type DateTime::Duration obj" => sub {
    plan skip_all => "DateTime::Duration module not available"
        unless eval { require DateTime::Duration; 1 };

    my $meta = {v=>1.1, args=>{t=>{schema=>[obj=>isa=>"DateTime::Duration"]}}};
    my $res;

    {
        $res = coerce_args(meta=>$meta, args=>{t=>"P1Y2M"});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("DateTime::Duration"));
        is($res->[2]{t}->years, 1);
        is($res->[2]{t}->months, 2);
    }

    {
        $res = coerce_args(meta=>$meta, args=>{t=>"55"});
        is($res->[0], 200) or last;
        ok($res->[2]{t}->isa("DateTime::Duration"));
        is($res->[2]{t}->seconds, 55);
    }
};

subtest "type:Time::Moment obj" => sub {
    plan skip_all => "Time::Moment module not available"
        unless eval { require Time::Moment; 1 };

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


subtest "type:date" => sub {
    plan skip_all => "DateTime module not available"
        unless eval { require DateTime; 1 };
    plan skip_all => "Time::Moment module not available"
        unless eval { require Time::Moment; 1 };

    my $meta = {v=>1.1, args=>{t=>{schema=>'date'}}};
    my $res;

    # no coercion
    subtest "no coercion" => sub {
        # no coercion of YYYY-MM-DD string
        {
            $res = coerce_args(meta=>$meta, args=>{t=>"2015-05-13"});
            is($res->[0], 200) or last;
            is_deeply($res->[2]{t}, "2015-05-13");
        }
        # no coercion of DateTime object
        {
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime"));
        }
        # no coercion of Time::Moment object
        {
            $res = coerce_args(meta=>$meta, args=>{t=>Time::Moment->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("Time::Moment"));
        }
        # no coercion of epoch number
        {
            $res = coerce_args(meta=>$meta, args=>{t=>1_000_000_000});
            is($res->[0], 200) or last;
            is($res->[2]{t}, 1_000_000_000);
        }
    };

    subtest "coercion to DateTime object" => sub {
        # from DateTime object, no-op
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime"));
        }
        # from YYYY-MM-DD string
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"2015-05-13"});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime"));
            is_deeply($res->[2]{t}->ymd, "2015-05-13");
        }
        # from Time::Moment object
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>Time::Moment->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime"));
        }
        # from epoch
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>1_000_000_000});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime"));
            is_deeply($res->[2]{t}->year, 2001);
        }
    };

    subtest "coercion to Time::Moment object" => sub {
        # from Time::Moment object, no-op
        {
            local $meta->{args}{t}{'x.perl.coerce_to_time_moment_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>Time::Moment->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("Time::Moment"));
        }
        # from YYYY-MM-DD string
        {
            local $meta->{args}{t}{'x.perl.coerce_to_time_moment_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"2015-05-13"});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("Time::Moment"));
            is_deeply($res->[2]{t}->strftime("%Y-%m-%d"), "2015-05-13");
        }
        # from DateTime object
        {
            local $meta->{args}{t}{'x.perl.coerce_to_time_moment_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime->now});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("Time::Moment"));
        }
        # from epoch
        {
            local $meta->{args}{t}{'x.perl.coerce_to_time_moment_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>1_000_000_000});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("Time::Moment"));
            is_deeply($res->[2]{t}->year, 2001);
        }
    };

    subtest "coercion to epoch" => sub {
        # from epoch, no-op
        {
            local $meta->{args}{t}{'x.perl.coerce_to_epoch'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>1_000_000_000});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, 1_000_000_000);
        }
        # from YYY-MM-DD string
        {
            local $meta->{args}{t}{'x.perl.coerce_to_epoch'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"2015-05-13"});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            ok($res->[2]{t} > 1_000_000_000);
        }
        # from DateTime object
        {
            local $meta->{args}{t}{'x.perl.coerce_to_epoch'} = 1;
            my $now = time();
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime->from_epoch(epoch => $now)});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            ok($res->[2]{t} > 1_000_000_000);
        }
        # from Time::Moment object
        {
            local $meta->{args}{t}{'x.perl.coerce_to_epoch'} = 1;
            my $now = time();
            $res = coerce_args(meta=>$meta, args=>{t=>Time::Moment->from_epoch($now)});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, $now);
        }
    };
};

subtest "type:duration" => sub {
    plan skip_all => "DateTime::Duration module not available"
        unless eval { require DateTime::Duration; 1 };

    my $meta = {v=>1.1, args=>{t=>{schema=>'duration'}}};
    my $res;

    subtest "no coercion" => sub {
        # no coercion from DateTime::Duration object
        {
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime::Duration->new(seconds=>55)});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime::Duration"));
        }
        # no coercion from P string
        {
            $res = coerce_args(meta=>$meta, args=>{t=>"P1Y2M"});
            is($res->[0], 200) or last;
            is($res->[2]{t}, "P1Y2M");
        }
        # no coercion from string parseable by T:D:P:AsHash
        {
            $res = coerce_args(meta=>$meta, args=>{t=>"1 year 2 months"});
            is($res->[0], 200) or last;
            is($res->[2]{t}, "1 year 2 months");
        }
        # no coercion from secs
        {
            $res = coerce_args(meta=>$meta, args=>{t=>55});
            is($res->[0], 200) or last;
            is_deeply($res->[2]{t}, 55);
        }
    };

    subtest "coercion to DateTime::Duration object" => sub {
        # from DateTime::Duration object, no-op
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_duration_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime::Duration->new(seconds=>55)});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime::Duration"));
        }
        # from P string
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_duration_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"P1Y2M"});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime::Duration"));
            is_deeply($res->[2]{t}->years, 1);
            is_deeply($res->[2]{t}->months, 2);
        }
        # from string parseable by T:D:P:AsHash
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_duration_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"1 year 2 months"});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime::Duration"));
            is_deeply($res->[2]{t}->years, 1);
            is_deeply($res->[2]{t}->months, 2);
        }
        # from secs
        {
            local $meta->{args}{t}{'x.perl.coerce_to_datetime_duration_obj'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>55});
            is($res->[0], 200) or last;
            ok($res->[2]{t}->isa("DateTime::Duration"));
            is_deeply($res->[2]{t}->seconds, 55);
        }
    };

    subtest "coercion to secs" => sub {
        # from secs, no-op
        {
            local $meta->{args}{t}{'x.perl.coerce_to_secs'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>55});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, 55);
        }
        # from DateTime::Duration object
        {
            local $meta->{args}{t}{'x.perl.coerce_to_secs'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>DateTime::Duration->new(years=>1, months=>2, days=>3, hours=>4, minutes=>5, seconds=>55)});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, 36993955);
        }
        # from P string
        {
            local $meta->{args}{t}{'x.perl.coerce_to_secs'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"P1D"});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, 86400);
        }
        # from string parseable by T:D:P:AsHash
        {
            local $meta->{args}{t}{'x.perl.coerce_to_secs'} = 1;
            $res = coerce_args(meta=>$meta, args=>{t=>"3h 4min"});
            is($res->[0], 200) or last;
            ok(!ref($res->[2]{t}));
            is($res->[2]{t}, 11040);
        }
    };
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
