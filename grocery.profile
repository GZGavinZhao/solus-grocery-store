#
# grocery-x86_64 configuration
#
# Build Solus packages using the Grocery + unstable repository image.
#
# Copy this file to `/etc/solbuild`, and now you can run `sudo
# solbuild build -p grocery` to build packages based on the Grocery
# repository.
#

image = "unstable-x86_64"

add_repos = ["Grocery"]

[repo.Grocery]
uri = "https://solus-grocery-store-oss.oss-us-east-1.aliyuncs.com/eopkg-index.xml.xz"
# If it's slow (esp. if you're not in North America), use the CDN:
# uri = "https://repo-cdn.gzgz.dev/eopkg-index.xml.xz"

[repo.Unstable]
uri = "http://mirrors.rit.edu/solus/packages/unstable/eopkg-index.xml.xz"
