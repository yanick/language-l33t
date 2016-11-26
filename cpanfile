requires "Carp" => "0";
requires "Const::Fast" => "0";
requires "IO::Socket::INET" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "MooX::HandlesVia" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "MooseX::MungeHas" => "0";
requires "Type::Tiny" => "0";
requires "Types::Standard" => "0";
requires "experimental" => "0";
requires "perl" => "v5.20.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
  requires "Test::Warn" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::PAUSE::Permissions" => "0";
  requires "Test::Vars" => "0";
};
