# setup vagrant public key
mkdir .ssh
chmod -R 0700 .ssh
cd .ssh
curl https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub > authorized_keys
chmod 0600 authorized_keys

