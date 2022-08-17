#
# grocery-local-x86_64 configuration
#
# Build Solus packages using the Grocery + unstable + local repository image.
#
# Copy this file to `/etc/solbuild`, and now you can run `sudo
# solbuild build -p grocery-local` to build packages based on the Grocery
# repository **AND** local packges in `/var/lib/solbuild/local/`.
#

image = "unstable-x86_64"

remove_repos = ['Solus']
add_repos = ["Local","Grocery","Solus"]

[repo.Local]
uri = "/var/lib/solbuild/local"
local = true
autoindex = true

[repo.Grocery]
uri = "https://solus-grocery-store-oss.oss-us-east-1.aliyuncs.com/eopkg-index.xml.xz"
# If it's slow (esp. if you're not in North America), use the CDN:
# uri = "https://repo-cdn.gzgz.dev/eopkg-index.xml.xz"

[repo.Solus]
uri = "http://mirrors.rit.edu/solus/packages/unstable/eopkg-index.xml.xz"

