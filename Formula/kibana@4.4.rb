require "language/node"

class KibanaAT44 < Formula
  desc "Analytics and search dashboard for Elasticsearch"
  homepage "https://www.elastic.co/products/kibana"
  url "https://github.com/elastic/kibana.git", :tag => "v4.4.2", :revision => "b0ef773a465d0eb27d192ca77f881eba90ef93d5"
  head "https://github.com/elastic/kibana.git"

  bottle do
    sha256 "f60d7c5fffba7332cd873572e2545e831b882be3c3a67614a1d668e47aed2b33" => :sierra
    sha256 "3b03418f6c7294e688e326d79dee99a74324a93696379fd5907481151c859fb3" => :el_capitan
    sha256 "a6142cf1f25064be67a8fd8fd1ef056f95716e3000a74512a2f4887e0d083485" => :yosemite
  end

  keg_only :versioned_formula

  resource "node" do
    url "https://nodejs.org/dist/v4.3.2/node-v4.3.2.tar.gz"
    sha256 "1f92f6d31f7292ce56db57d6703efccf3e6c945948f5901610cefa69e78d3498"
  end

  def install
    resource("node").stage buildpath/"node"
    cd buildpath/"node" do
      system "./configure", "--prefix=#{libexec}/node"
      system "make", "install"
    end

    # do not download binary installs of Node.js
    inreplace buildpath/"tasks/build/index.js", /('_build:downloadNodeBuilds:\w+',)/, "// \\1"

    # do not build packages for other platforms
    platforms = Set.new(["darwin-x64", "linux-x64", "linux-x86", "windows"])
    if MacOS.prefer_64_bit?
      platform = "darwin-x64"
    else
      raise "Installing Kibana via Homebrew is only supported on macOS x86_64"
    end
    platforms.delete(platform)
    sub = platforms.to_a.join("|")
    inreplace buildpath/"tasks/config/platforms.js", /('(#{sub})',?(?!;))/, "// \\1"

    # do not build zip package
    inreplace buildpath/"tasks/build/archives.js", /(await exec\('zip'.*)/, "// \\1"

    ENV.prepend_path "PATH", prefix/"libexec/node/bin"
    Pathname.new("#{ENV["HOME"]}/.npmrc").write Language::Node.npm_cache_config
    system "npm", "install"
    system "npm", "run", "build"
    mkdir "tar" do
      system "tar", "--strip-components", "1", "-xf", Dir[buildpath/"target/kibana-*-#{platform}.tar.gz"].first

      rm_f Dir["bin/*.bat"]
      prefix.install "bin", "config", "node_modules", "optimize", "package.json", "src", "webpackShims"
    end

    inreplace "#{bin}/kibana", %r{/node/bin/node}, "/libexec/node/bin/node"

    cd prefix do
      inreplace "config/kibana.yml", "/var/run/kibana.pid", var/"run/kibana.pid"
      (etc/"kibana").install Dir["config/*"]
      rm_rf "config"
    end
  end

  def post_install
    ln_s etc/"kibana", prefix/"config"
    (prefix/"installedPlugins").mkdir
  end

  plist_options :manual => "kibana"

  def caveats; <<-EOS
    Config: #{etc}/kibana/
    If you wish to preserve your plugins upon upgrade, make a copy of
    #{prefix}/installedPlugins before upgrading, and copy it into the
    new keg location after upgrading.
    EOS
  end

  def plist; <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/kibana</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    ENV["BABEL_CACHE_PATH"] = testpath/".babelcache.json"
    assert_match /#{version}/, shell_output("#{bin}/kibana -V")
  end
end
