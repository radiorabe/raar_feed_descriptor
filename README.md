# raar_feed_descriptor

Store descriptions for certain shows from the rabe.ch website feed into archiv.rabe.ch.

See configuration in `config/settings.example.yml`. Copy this file to `config/settings.yml`, complete it and run `raar_feed_descriptor.rb`.


## Deployment

## Initial

* Install dependencies: `yum install gcc gcc-c++ glibc-headers rh-ruby27-ruby-devel rh-ruby27-rubygem-bundler libxml2-devel libxslt-devel`
* Create a user on the server:
  * `useradd --home-dir /opt/raar-scripts --create-home --user-group raar-scripts`
  * `usermod -a -G raar-scripts <your-ssh-user>`
  * Add your SSH public key to `/opt/raar-scripts/.ssh/authorized_keys`.
* Perform the every time steps.
* Copy `settings.example.yml` to `settings.yml` and add the missing credentials.
* Copy both systemd files from `config` to `/etc/systemd/system/`.
* Enable and start the systemd timer: `systemctl enable --now raar-feed-descriptor.timer`

## Every time

* Prepare the dependencies on your local machine: `bundle package --all-platforms`
* SCP or Rsync all files: `rsync -avz --exclude .git --exclude .bundle --exclude config/settings.yml . raar-scripts@server:/opt/raar-feed-descriptor/`.
* Install the dependencies on the server (as `raar-scripts` in `/opt/raar-feed-descriptor`):
  `source /opt/rh/rh-ruby27/enable && bundle install --deployment --local`


## License

raar_feed_descriptor is released under the terms of the GNU Affero General Public License.
Copyright 2018-2021 Radio RaBe.
See `LICENSE` for further information.
