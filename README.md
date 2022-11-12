# raar_feed_descriptor

Store descriptions for certain shows from the rabe.ch website feed into archiv.rabe.ch.

See configuration in `config/settings.example.yml`. Copy this file to `config/settings.yml`, complete it and run `raar_feed_descriptor.rb`.


## Deployment

## Initial

* Install dependencies: `yum install gcc gcc-c++ glibc-headers rh-ruby30-ruby-devel rh-ruby30-rubygem-bundler libxml2-devel libxslt-devel`
* Create a user on the server:
  * `useradd --home-dir /opt/raar-scripts --create-home --user-group raar-scripts`
  * `usermod -a -G raar-scripts <your-ssh-user>`
  * Add your SSH public key to `/opt/raar-scripts/.ssh/authorized_keys`.
* Create the script home directory: `mkdir -p /opt/raar-feed-descriptor/`.
* Configure bundler: `cd /opt/raar-feed-descriptor && bundle config set --local deployment 'true'`
* Perform the every time steps.
* Copy `settings.example.yml` to `settings.yml` and add the missing credentials.
* Copy both systemd files from `config` to `/etc/systemd/system/`.
* Enable and start the systemd timer: `systemctl enable --now raar-feed-descriptor.timer`

## Every time

* Prepare the dependencies on your local machine: `bundle package --all-platforms`
* SCP or Rsync all files: `rsync -avz --exclude .git --exclude .bundle --exclude config/settings.yml . raar-scripts@server:/opt/raar-feed-descriptor/`.
* Install the dependencies on the server (as `raar-scripts` in `/opt/raar-feed-descriptor`):
  `source /opt/rh/rh-ruby30/enable && bundle install --local`


## License

raar_feed_descriptor is released under the terms of the GNU Affero General Public License.
Copyright 2018-2022 Radio RaBe.
See `LICENSE` for further information.
