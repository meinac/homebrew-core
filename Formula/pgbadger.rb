class Pgbadger < Formula
  desc "Log analyzer for PostgreSQL"
  homepage "https://dalibo.github.io/pgbadger/"
  url "https://github.com/dalibo/pgbadger/archive/v9.1.tar.gz"
  sha256 "2fd7166d74692cc7d87f00b37cc5c7c1c6eddf156372376d382a40f67d694011"

  head "https://github.com/dalibo/pgbadger.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "2fe3fa1558342e01dd2ad4c62cba39dfbc1c5638dec568f7a552e65253877c4e" => :sierra
    sha256 "c0cc5f00e22d8665e5226fd4cad7f004acc03a4b8ea93796066a847a46e54462" => :el_capitan
    sha256 "c0cc5f00e22d8665e5226fd4cad7f004acc03a4b8ea93796066a847a46e54462" => :yosemite
  end

  def install
    system "perl", "Makefile.PL", "DESTDIR=#{buildpath}"
    system "make"
    system "make", "install"

    bin.install "usr/local/bin/pgbadger"
    man1.install "usr/local/share/man/man1/pgbadger.1p"
  end

  def caveats; <<-EOS
    You must configure your PostgreSQL server before using pgBadger.
    Edit postgresql.conf (in #{var}/postgres if you use Homebrew's
    PostgreSQL), set the following parameters, and restart PostgreSQL:

      log_destination = 'stderr'
      log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '
      log_statement = 'none'
      log_duration = off
      log_min_duration_statement = 0
      log_checkpoints = on
      log_connections = on
      log_disconnections = on
      log_lock_waits = on
      log_temp_files = 0
      lc_messages = 'C'
    EOS
  end

  test do
    (testpath/"server.log").write <<-EOS
      LOG:  autovacuum launcher started
      LOG:  database system is ready to accept connections
    EOS
    system bin/"pgbadger", "-f", "syslog", "server.log"
    assert File.exist? "out.html"
  end
end
