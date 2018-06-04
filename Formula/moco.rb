class Moco < Formula
  desc "Stub server with Maven, Gradle, Scala, and shell integration"
  homepage "https://github.com/dreamhead/moco"
  url "https://search.maven.org/remotecontent?filepath=com/github/dreamhead/moco-runner/0.11.0/moco-runner-0.11.0-standalone.jar"
  version "0.11.0"
  sha256 "d3c772333f6a35fe4bc168d0541e97a0d36071afe343ced840f7afd1c037b661"

  bottle :unneeded

  def install
    libexec.install "moco-runner-0.11.0-standalone.jar"
    bin.write_jar_script libexec/"moco-runner-0.11.0-standalone.jar", "moco"
  end

  test do
    require "net/http"

    (testpath/"config.json").write <<-EOS
      [
        {
          "response" :
          {
              "text" : "Hello, Moco"
          }
        }
    ]
    EOS

    port = 12306
    thread = Thread.new do
      system bin/"moco", "http", "-p", port, "-c", testpath/"config.json"
    end

    # Wait for Moco to start.
    sleep 5

    response = Net::HTTP.get URI "http://localhost:#{port}"
    assert_equal "Hello, Moco", response
    thread.exit
  end
end
